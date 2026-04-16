#!/usr/bin/env bash

# HEIC to JPG Converter - Bash Wrapper Script
# This script provides a convenient wrapper around the heic2jpg Rust binary

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARY_PATH="$SCRIPT_DIR/target/release/heic2jpg"

# Function to print colored messages
print_error() {
    echo -e "${RED}Error: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}$1${NC}"
}

print_info() {
    echo -e "${BLUE}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}$1${NC}"
}

# Function to check if binary exists and offer to build
check_binary() {
    if [ ! -f "$BINARY_PATH" ]; then
        print_warning "Binary not found at $BINARY_PATH"
        echo -n "Would you like to build it now? (y/n): "
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            build_binary
        else
            print_error "Cannot proceed without building the binary first"
            echo "Run: cd $SCRIPT_DIR && cargo build --release"
            exit 1
        fi
    fi
}

# Function to build the binary
build_binary() {
    print_info "Building heic2jpg in release mode..."
    cd "$SCRIPT_DIR"

    if ! command -v cargo &> /dev/null; then
        print_error "Cargo not found. Please install Rust from https://rustup.rs/"
        exit 1
    fi

    if cargo build --release; then
        print_success "Build successful!"
    else
        print_error "Build failed. Please check the error messages above."
        exit 1
    fi
}

# Function to show usage
show_usage() {
    cat << EOF
HEIC to JPG Converter - Bash Wrapper

Usage: $0 [command] [options]

Commands:
    build           Build the Rust binary in release mode
    convert         Convert HEIC files (default if no command specified)
    install         Install binary to /usr/local/bin
    help            Show this help message

Convert Options:
    -i, --input     Input file or directory (required)
    -o, --output    Output directory or file
    -q, --quality   JPEG quality 1-100 (default: 90)
    -r, --recursive Process directories recursively
    -j, --jobs      Number of parallel jobs (default: all cores)
    --overwrite     Overwrite existing files
    -v, --verbose   Verbose output

Examples:
    # Convert a single file
    $0 -i photo.heic

    # Convert directory with high quality
    $0 -i ./photos -q 95

    # Convert recursively with custom output
    $0 -r -i ./photos -o ./converted

    # Build the binary
    $0 build

    # Install to system
    $0 install

For direct binary usage, run:
    $BINARY_PATH --help

EOF
}

# Function to install binary
install_binary() {
    check_binary

    local install_path="/usr/local/bin/heic2jpg"

    print_info "Installing heic2jpg to $install_path"

    if [ -w "/usr/local/bin" ]; then
        cp "$BINARY_PATH" "$install_path"
    else
        print_info "Requires sudo privileges..."
        sudo cp "$BINARY_PATH" "$install_path"
    fi

    if [ -f "$install_path" ]; then
        print_success "Successfully installed to $install_path"
        print_info "You can now run 'heic2jpg' from anywhere"
    else
        print_error "Installation failed"
        exit 1
    fi
}

# Main script logic
main() {
    # If no arguments, show usage
    if [ $# -eq 0 ]; then
        show_usage
        exit 0
    fi

    # Parse command
    case "$1" in
        build)
            build_binary
            exit 0
            ;;
        install)
            install_binary
            exit 0
            ;;
        help|--help|-h)
            show_usage
            exit 0
            ;;
        convert)
            shift
            check_binary
            "$BINARY_PATH" "$@"
            exit $?
            ;;
        *)
            # If first argument doesn't match a command, treat all args as binary options
            check_binary
            "$BINARY_PATH" "$@"
            exit $?
            ;;
    esac
}

main "$@"
