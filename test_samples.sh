#!/usr/bin/env bash

# Test script for HEIC to JPG Converter
# This script demonstrates various usage scenarios and can be used for testing

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
BINARY_PATH="$SCRIPT_DIR/target/release/heic2jpg"
TEST_DIR="$SCRIPT_DIR/test_data"
OUTPUT_DIR="$SCRIPT_DIR/test_output"

# Print functions
print_header() {
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}\n"
}

print_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1" >&2
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

# Cleanup function
cleanup() {
    if [ -d "$OUTPUT_DIR" ]; then
        rm -rf "$OUTPUT_DIR"
        print_info "Cleaned up test output directory"
    fi
}

# Check if binary exists
check_binary() {
    if [ ! -f "$BINARY_PATH" ]; then
        print_error "Binary not found at $BINARY_PATH"
        print_info "Building in release mode..."
        cd "$SCRIPT_DIR"
        cargo build --release

        if [ ! -f "$BINARY_PATH" ]; then
            print_error "Build failed"
            exit 1
        fi
        print_success "Build complete"
    else
        print_success "Binary found at $BINARY_PATH"
    fi
}

# Create test directory structure
create_test_structure() {
    print_header "Setting Up Test Environment"

    mkdir -p "$TEST_DIR"
    mkdir -p "$TEST_DIR/nested/level1"
    mkdir -p "$TEST_DIR/nested/level2/deep"
    mkdir -p "$OUTPUT_DIR"

    print_info "Test directories created:"
    print_info "  - $TEST_DIR"
    print_info "  - $OUTPUT_DIR"

    # Check if user has HEIC files
    print_info "\nTo run full tests, place HEIC files in: $TEST_DIR"
    print_info "You can also place files in nested subdirectories for recursive testing"
}

# Test 1: Display help
test_help() {
    print_header "TEST 1: Display Help"
    print_test "Running: heic2jpg --help"

    if "$BINARY_PATH" --help; then
        print_success "Help command executed successfully"
    else
        print_error "Help command failed"
        return 1
    fi
}

# Test 2: Display version
test_version() {
    print_header "TEST 2: Display Version"
    print_test "Running: heic2jpg --version"

    if "$BINARY_PATH" --version; then
        print_success "Version command executed successfully"
    else
        print_error "Version command failed"
        return 1
    fi
}

# Test 3: Check if HEIC files exist
check_heic_files() {
    print_header "Checking for HEIC Test Files"

    local heic_count=$(find "$TEST_DIR" -type f \( -iname "*.heic" -o -iname "*.heif" \) 2>/dev/null | wc -l)

    if [ "$heic_count" -eq 0 ]; then
        print_error "No HEIC files found in $TEST_DIR"
        print_info "\nTo run conversion tests:"
        print_info "  1. Copy some HEIC files to: $TEST_DIR"
        print_info "  2. Run this script again"
        print_info "\nSkipping conversion tests..."
        return 1
    else
        print_success "Found $heic_count HEIC file(s) for testing"
        return 0
    fi
}

# Test 4: Single file conversion
test_single_file() {
    print_header "TEST 3: Single File Conversion"

    local heic_file=$(find "$TEST_DIR" -maxdepth 1 -type f \( -iname "*.heic" -o -iname "*.heif" \) | head -n 1)

    if [ -z "$heic_file" ]; then
        print_info "No HEIC files in root test directory - skipping single file test"
        return 0
    fi

    print_test "Converting: $(basename "$heic_file")"
    print_test "Command: heic2jpg \"$heic_file\" -o \"$OUTPUT_DIR/single.jpg\""

    if "$BINARY_PATH" "$heic_file" -o "$OUTPUT_DIR/single.jpg"; then
        if [ -f "$OUTPUT_DIR/single.jpg" ]; then
            local size=$(du -h "$OUTPUT_DIR/single.jpg" | cut -f1)
            print_success "Conversion successful - Output: $size"
        else
            print_error "Output file not created"
            return 1
        fi
    else
        print_error "Conversion failed"
        return 1
    fi
}

# Test 5: Directory conversion (non-recursive)
test_directory() {
    print_header "TEST 4: Directory Conversion (Non-Recursive)"

    local heic_count=$(find "$TEST_DIR" -maxdepth 1 -type f \( -iname "*.heic" -o -iname "*.heif" \) | wc -l)

    if [ "$heic_count" -eq 0 ]; then
        print_info "No HEIC files in root test directory - skipping directory test"
        return 0
    fi

    print_test "Converting directory: $TEST_DIR"
    print_test "Command: heic2jpg \"$TEST_DIR\" -o \"$OUTPUT_DIR/dir_output\" -q 85"

    mkdir -p "$OUTPUT_DIR/dir_output"

    if "$BINARY_PATH" "$TEST_DIR" -o "$OUTPUT_DIR/dir_output" -q 85; then
        local jpg_count=$(find "$OUTPUT_DIR/dir_output" -maxdepth 1 -type f -iname "*.jpg" | wc -l)
        print_success "Converted $jpg_count file(s)"
    else
        print_error "Directory conversion failed"
        return 1
    fi
}

# Test 6: Recursive directory conversion
test_recursive() {
    print_header "TEST 5: Recursive Directory Conversion"

    local heic_count=$(find "$TEST_DIR" -type f \( -iname "*.heic" -o -iname "*.heif" \) | wc -l)

    if [ "$heic_count" -eq 0 ]; then
        print_info "No HEIC files found - skipping recursive test"
        return 0
    fi

    print_test "Converting directory tree: $TEST_DIR"
    print_test "Command: heic2jpg -r \"$TEST_DIR\" -o \"$OUTPUT_DIR/recursive\" -q 90 -v"

    mkdir -p "$OUTPUT_DIR/recursive"

    if "$BINARY_PATH" -r "$TEST_DIR" -o "$OUTPUT_DIR/recursive" -q 90 -v; then
        local jpg_count=$(find "$OUTPUT_DIR/recursive" -type f -iname "*.jpg" | wc -l)
        print_success "Recursively converted $jpg_count file(s)"
    else
        print_error "Recursive conversion failed"
        return 1
    fi
}

# Test 7: Quality variations
test_quality() {
    print_header "TEST 6: Quality Variations"

    local heic_file=$(find "$TEST_DIR" -type f \( -iname "*.heic" -o -iname "*.heif" \) | head -n 1)

    if [ -z "$heic_file" ]; then
        print_info "No HEIC files available - skipping quality test"
        return 0
    fi

    mkdir -p "$OUTPUT_DIR/quality_test"

    for quality in 50 75 90 95; do
        print_test "Converting with quality: $quality"
        local output="$OUTPUT_DIR/quality_test/quality_${quality}.jpg"

        if "$BINARY_PATH" "$heic_file" -o "$output" -q "$quality" 2>/dev/null; then
            local size=$(du -h "$output" | cut -f1)
            print_success "Quality $quality: $size"
        else
            print_error "Failed at quality $quality"
        fi
    done
}

# Test 8: Parallel processing
test_parallel() {
    print_header "TEST 7: Parallel Processing"

    local heic_count=$(find "$TEST_DIR" -type f \( -iname "*.heic" -o -iname "*.heif" \) | wc -l)

    if [ "$heic_count" -lt 2 ]; then
        print_info "Need at least 2 HEIC files for parallel test - skipping"
        return 0
    fi

    mkdir -p "$OUTPUT_DIR/parallel"

    print_test "Testing with 1 thread"
    time "$BINARY_PATH" -r "$TEST_DIR" -o "$OUTPUT_DIR/parallel/single" -j 1 --overwrite 2>/dev/null || true

    print_test "Testing with all cores"
    time "$BINARY_PATH" -r "$TEST_DIR" -o "$OUTPUT_DIR/parallel/multi" --overwrite 2>/dev/null || true

    print_success "Parallel processing test complete"
}

# Test 9: Error handling
test_error_handling() {
    print_header "TEST 8: Error Handling"

    print_test "Testing non-existent file"
    if "$BINARY_PATH" "/non/existent/file.heic" 2>/dev/null; then
        print_error "Should have failed on non-existent file"
    else
        print_success "Correctly handled non-existent file"
    fi

    print_test "Testing invalid quality value"
    local heic_file=$(find "$TEST_DIR" -type f \( -iname "*.heic" -o -iname "*.heif" \) | head -n 1)
    if [ -n "$heic_file" ]; then
        if "$BINARY_PATH" "$heic_file" -q 150 2>/dev/null; then
            print_error "Should have failed on invalid quality"
        else
            print_success "Correctly rejected invalid quality value"
        fi
    fi
}

# Summary
print_summary() {
    print_header "Test Summary"

    if [ -d "$OUTPUT_DIR" ]; then
        local total_jpgs=$(find "$OUTPUT_DIR" -type f -iname "*.jpg" 2>/dev/null | wc -l)
        local total_size=$(du -sh "$OUTPUT_DIR" 2>/dev/null | cut -f1)

        print_info "Total JPG files created: $total_jpgs"
        print_info "Total output size: $total_size"
        print_info "Output directory: $OUTPUT_DIR"
    fi

    echo ""
    print_success "All tests completed!"
    echo ""

    print_info "To clean up test outputs, run: rm -rf $OUTPUT_DIR"
}

# Main execution
main() {
    print_header "HEIC to JPG Converter - Test Suite"

    # Setup
    check_binary
    create_test_structure

    # Run tests
    test_help
    test_version

    # Check for HEIC files
    if check_heic_files; then
        test_single_file
        test_directory
        test_recursive
        test_quality
        test_parallel
    fi

    test_error_handling

    # Summary
    print_summary
}

# Trap cleanup on exit
trap cleanup EXIT

# Run main function
main "$@"
