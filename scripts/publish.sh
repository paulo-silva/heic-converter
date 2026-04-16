#!/usr/bin/env bash

# Homebrew Publishing Automation Script
# Automates the process of creating releases for Homebrew distribution

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Print functions
print_header() {
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_step() {
    echo -e "${CYAN}▶${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Get current version from Cargo.toml
get_current_version() {
    grep "^version" "$PROJECT_ROOT/Cargo.toml" | head -1 | sed 's/version = "\(.*\)"/\1/'
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"

    local all_good=true

    # Check git
    if command_exists git; then
        print_success "git found"
    else
        print_error "git not found"
        all_good=false
    fi

    # Check cargo
    if command_exists cargo; then
        print_success "cargo found"
    else
        print_error "cargo not found"
        all_good=false
    fi

    # Check if in git repository
    if git -C "$PROJECT_ROOT" rev-parse --git-dir > /dev/null 2>&1; then
        print_success "git repository initialized"
    else
        print_error "not a git repository"
        all_good=false
    fi

    # Check for uncommitted changes
    if [[ -z $(git -C "$PROJECT_ROOT" status --porcelain) ]]; then
        print_success "no uncommitted changes"
    else
        print_warning "uncommitted changes detected"
        git -C "$PROJECT_ROOT" status --short
    fi

    # Check if remote exists
    if git -C "$PROJECT_ROOT" remote get-url origin > /dev/null 2>&1; then
        local remote_url=$(git -C "$PROJECT_ROOT" remote get-url origin)
        print_success "git remote: $remote_url"
    else
        print_warning "no git remote 'origin' configured"
    fi

    if [ "$all_good" = false ]; then
        print_error "prerequisites not met"
        exit 1
    fi

    echo ""
}

# Build release
build_release() {
    print_header "Building Release"

    cd "$PROJECT_ROOT"

    print_step "Running tests..."
    if cargo test --quiet; then
        print_success "tests passed"
    else
        print_error "tests failed"
        exit 1
    fi

    print_step "Building release binary..."
    if cargo build --release --quiet; then
        print_success "build successful"

        local binary_size=$(du -h "$PROJECT_ROOT/target/release/heic2jpg" | cut -f1)
        print_info "binary size: $binary_size"
    else
        print_error "build failed"
        exit 1
    fi

    echo ""
}

# Create release tarball and calculate SHA256
create_tarball() {
    local version=$1

    print_header "Creating Release Tarball"

    cd "$PROJECT_ROOT"

    # Create dist directory
    mkdir -p dist
    cd target/release

    # Determine architecture
    local arch=$(uname -m)
    local os="apple-darwin"
    local tarball_name="heic2jpg-v${version}-${arch}-${os}.tar.gz"

    print_step "Creating tarball: $tarball_name"

    tar czf "../../dist/$tarball_name" heic2jpg

    cd "$PROJECT_ROOT/dist"

    # Calculate SHA256
    local sha256=$(shasum -a 256 "$tarball_name" | cut -d' ' -f1)

    print_success "tarball created"
    print_info "location: $PROJECT_ROOT/dist/$tarball_name"
    print_info "SHA256: $sha256"

    # Save SHA256 to file
    echo "$sha256  $tarball_name" > "${tarball_name}.sha256"

    echo ""
    echo "$sha256"
}

# Create git tag
create_tag() {
    local version=$1
    local tag="v${version}"

    print_header "Creating Git Tag"

    cd "$PROJECT_ROOT"

    # Check if tag already exists
    if git rev-parse "$tag" >/dev/null 2>&1; then
        print_error "tag $tag already exists"
        echo -n "Delete and recreate? (y/N): "
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            git tag -d "$tag"
            print_info "deleted local tag $tag"
        else
            print_error "aborted"
            exit 1
        fi
    fi

    # Create annotated tag
    print_step "Creating tag $tag"
    git tag -a "$tag" -m "Release $tag"
    print_success "tag created: $tag"

    echo ""
}

# Push to GitHub
push_to_github() {
    local version=$1
    local tag="v${version}"

    print_header "Pushing to GitHub"

    cd "$PROJECT_ROOT"

    # Check if remote exists
    if ! git remote get-url origin > /dev/null 2>&1; then
        print_error "no remote 'origin' configured"
        exit 1
    fi

    print_step "Pushing commits..."
    git push origin main || git push origin master || {
        print_error "failed to push commits"
        exit 1
    }
    print_success "commits pushed"

    print_step "Pushing tag $tag..."
    git push origin "$tag"
    print_success "tag pushed"

    local repo_url=$(git remote get-url origin | sed 's/\.git$//')
    print_info "release will be available at: ${repo_url}/releases/tag/${tag}"

    echo ""
}

# Generate Homebrew formula snippet
generate_formula_snippet() {
    local version=$1
    local sha256=$2

    print_header "Homebrew Formula Update"

    # Get GitHub username from remote URL
    local remote_url=$(git -C "$PROJECT_ROOT" remote get-url origin)
    local github_user=$(echo "$remote_url" | sed -n 's|.*github.com[:/]\([^/]*\)/.*|\1|p')

    cat << EOF
Update your Homebrew formula with:

class Heic2jpg < Formula
  desc "Fast HEIC to JPG converter with multi-core support"
  homepage "https://github.com/${github_user}/heic-converter"
  url "https://github.com/${github_user}/heic-converter/archive/refs/tags/v${version}.tar.gz"
  sha256 "${sha256}"
  license "MIT"

  depends_on "rust" => :build
  depends_on "libheif"

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match "${version}", shell_output("#{bin}/heic2jpg --version")
  end
end

Formula location: ~/Development/homebrew-tap/Formula/heic2jpg.rb
EOF

    echo ""
}

# Show next steps
show_next_steps() {
    local version=$1
    local github_user=$2

    print_header "Next Steps"

    cat << EOF
${GREEN}Release v${version} is ready!${NC}

${CYAN}1. Verify GitHub Release:${NC}
   https://github.com/${github_user}/heic-converter/releases/tag/v${version}

${CYAN}2. Update Homebrew Tap:${NC}
   cd ~/Development/homebrew-tap
   # Edit Formula/heic2jpg.rb with the snippet above
   git add Formula/heic2jpg.rb
   git commit -m "heic2jpg: update to ${version}"
   git push

${CYAN}3. Test Installation:${NC}
   brew uninstall heic2jpg
   brew update
   brew install ${github_user}/tap/heic2jpg
   heic2jpg --version

${CYAN}4. Announce:${NC}
   - Update README with latest version
   - Create release notes
   - Share on social media

EOF
}

# Main menu
show_menu() {
    local current_version=$(get_current_version)

    print_header "Homebrew Publishing Tool"

    echo "Current version: ${GREEN}${current_version}${NC}"
    echo ""
    echo "What would you like to do?"
    echo ""
    echo "  1) Full release (build, tag, push, and show formula)"
    echo "  2) Build release binary only"
    echo "  3) Create git tag only"
    echo "  4) Calculate SHA256 for existing tarball"
    echo "  5) Generate formula snippet"
    echo "  0) Exit"
    echo ""
    echo -n "Select option: "
}

# Full release workflow
full_release() {
    local version=$(get_current_version)

    print_header "Full Release Workflow for v${version}"

    echo "This will:"
    echo "  • Run tests"
    echo "  • Build release binary"
    echo "  • Create tarball"
    echo "  • Create git tag v${version}"
    echo "  • Push to GitHub"
    echo "  • Generate Homebrew formula snippet"
    echo ""
    echo -n "Continue? (y/N): "
    read -r response

    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_info "aborted"
        exit 0
    fi

    check_prerequisites
    build_release
    sha256=$(create_tarball "$version")
    create_tag "$version"
    push_to_github "$version"
    generate_formula_snippet "$version" "$sha256"

    # Get GitHub user for next steps
    local remote_url=$(git -C "$PROJECT_ROOT" remote get-url origin)
    local github_user=$(echo "$remote_url" | sed -n 's|.*github.com[:/]\([^/]*\)/.*|\1|p')

    show_next_steps "$version" "$github_user"
}

# Main script
main() {
    cd "$PROJECT_ROOT"

    if [ $# -eq 0 ]; then
        # Interactive mode
        while true; do
            show_menu
            read -r choice
            echo ""

            case $choice in
                1)
                    full_release
                    break
                    ;;
                2)
                    check_prerequisites
                    build_release
                    ;;
                3)
                    version=$(get_current_version)
                    create_tag "$version"
                    ;;
                4)
                    version=$(get_current_version)
                    create_tarball "$version"
                    ;;
                5)
                    version=$(get_current_version)
                    echo -n "Enter SHA256 hash: "
                    read -r sha256
                    generate_formula_snippet "$version" "$sha256"
                    ;;
                0)
                    print_info "goodbye!"
                    exit 0
                    ;;
                *)
                    print_error "invalid option"
                    ;;
            esac
            echo ""
        done
    else
        # Command-line mode
        case "$1" in
            release|full)
                full_release
                ;;
            build)
                check_prerequisites
                build_release
                ;;
            tag)
                version=$(get_current_version)
                create_tag "$version"
                ;;
            tarball)
                version=$(get_current_version)
                create_tarball "$version"
                ;;
            *)
                print_error "unknown command: $1"
                echo ""
                echo "Usage: $0 [release|build|tag|tarball]"
                echo "  or run without arguments for interactive mode"
                exit 1
                ;;
        esac
    fi
}

main "$@"
