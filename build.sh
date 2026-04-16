#!/usr/bin/env bash

# Build script for HEIC to JPG Converter
# This script builds the project in release mode and optionally installs it

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARY_NAME="heic2jpg"
BINARY_PATH="$SCRIPT_DIR/target/release/$BINARY_NAME"

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

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"

    local all_good=true

    # Check for Rust/Cargo
    if command_exists cargo; then
        local cargo_version=$(cargo --version)
        print_success "Cargo found: $cargo_version"
    else
        print_error "Cargo not found"
        print_info "Install Rust from: https://rustup.rs/"
        print_info "Run: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        all_good=false
    fi

    # Check for libheif
    local os=$(detect_os)
    local libheif_found=false

    if [[ "$os" == "macos" ]]; then
        if command_exists brew; then
            if brew list libheif &>/dev/null; then
                print_success "libheif found (via Homebrew)"
                libheif_found=true
            fi
        fi

        if [ "$libheif_found" = false ]; then
            print_warning "libheif not detected"
            print_info "Install with: brew install libheif"
        fi
    elif [[ "$os" == "linux" ]]; then
        if pkg-config --exists libheif 2>/dev/null; then
            print_success "libheif found (via pkg-config)"
            libheif_found=true
        elif ldconfig -p | grep -q libheif 2>/dev/null; then
            print_success "libheif found (via ldconfig)"
            libheif_found=true
        else
            print_warning "libheif not detected"
            print_info "Install with:"
            print_info "  - Ubuntu/Debian: sudo apt-get install libheif-dev"
            print_info "  - Fedora: sudo dnf install libheif-devel"
        fi
    fi

    if [ "$all_good" = false ]; then
        print_error "Missing required dependencies"
        exit 1
    fi

    echo ""
}

# Build the project
build_project() {
    print_header "Building Project"

    cd "$SCRIPT_DIR"

    print_info "Building in release mode (this may take a few minutes)..."
    echo ""

    if cargo build --release; then
        echo ""
        print_success "Build completed successfully!"

        if [ -f "$BINARY_PATH" ]; then
            local size=$(du -h "$BINARY_PATH" | cut -f1)
            print_info "Binary location: $BINARY_PATH"
            print_info "Binary size: $size"
        fi
    else
        echo ""
        print_error "Build failed"
        exit 1
    fi
}

# Install the binary
install_binary() {
    print_header "Installing Binary"

    if [ ! -f "$BINARY_PATH" ]; then
        print_error "Binary not found. Please build first."
        exit 1
    fi

    local install_dir="/usr/local/bin"
    local install_path="$install_dir/$BINARY_NAME"

    # Check if install directory exists
    if [ ! -d "$install_dir" ]; then
        print_warning "Install directory $install_dir does not exist"
        print_info "Creating directory..."
        sudo mkdir -p "$install_dir"
    fi

    # Check if we can write to the directory
    if [ -w "$install_dir" ]; then
        cp "$BINARY_PATH" "$install_path"
    else
        print_info "Sudo privileges required to install to $install_dir"
        sudo cp "$BINARY_PATH" "$install_path"
    fi

    # Verify installation
    if [ -f "$install_path" ]; then
        chmod +x "$install_path"
        print_success "Installed to: $install_path"
        print_success "You can now run '$BINARY_NAME' from anywhere"

        # Test the installation
        if command_exists "$BINARY_NAME"; then
            echo ""
            print_info "Testing installation..."
            "$BINARY_NAME" --version
        fi
    else
        print_error "Installation failed"
        exit 1
    fi
}

# Run tests
run_tests() {
    print_header "Running Tests"

    cd "$SCRIPT_DIR"

    if cargo test; then
        print_success "All tests passed"
    else
        print_error "Tests failed"
        exit 1
    fi
}

# Show usage
show_usage() {
    cat << EOF
HEIC to JPG Converter - Build Script

Usage: $0 [OPTIONS]

Options:
    --build-only    Build the project without installing
    --install       Build and install to /usr/local/bin
    --test          Run tests after building
    --clean         Clean build artifacts before building
    --help          Show this help message

Examples:
    $0                      # Build only (default)
    $0 --install            # Build and install
    $0 --clean --install    # Clean, build, and install
    $0 --test               # Build and test

EOF
}

# Clean build artifacts
clean_build() {
    print_header "Cleaning Build Artifacts"

    cd "$SCRIPT_DIR"

    if [ -d "target" ]; then
        print_info "Removing target directory..."
        cargo clean
        print_success "Build artifacts cleaned"
    else
        print_info "Nothing to clean"
    fi
}

# Main function
main() {
    local do_build=true
    local do_install=false
    local do_test=false
    local do_clean=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --build-only)
                do_build=true
                do_install=false
                shift
                ;;
            --install)
                do_build=true
                do_install=true
                shift
                ;;
            --test)
                do_test=true
                shift
                ;;
            --clean)
                do_clean=true
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    print_header "HEIC to JPG Converter - Build Script"

    # Execute requested actions
    check_prerequisites

    if [ "$do_clean" = true ]; then
        clean_build
    fi

    if [ "$do_build" = true ]; then
        build_project
    fi

    if [ "$do_test" = true ]; then
        run_tests
    fi

    if [ "$do_install" = true ]; then
        install_binary
    fi

    # Final message
    print_header "Done!"

    if [ "$do_install" = true ]; then
        print_success "Build and installation complete"
        print_info "Run '$BINARY_NAME --help' to get started"
    else
        print_success "Build complete"
        print_info "Binary location: $BINARY_PATH"
        print_info "To install, run: $0 --install"
        print_info "Or manually copy: sudo cp $BINARY_PATH /usr/local/bin/"
    fi

    echo ""
}

main "$@"
