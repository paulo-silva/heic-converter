# Troubleshooting Guide

This guide covers common issues you might encounter when using the HEIC to JPG converter and how to resolve them.

## Table of Contents

- [Installation Issues](#installation-issues)
- [Build Issues](#build-issues)
- [Runtime Issues](#runtime-issues)
- [Performance Issues](#performance-issues)
- [Image Quality Issues](#image-quality-issues)
- [Common Error Messages](#common-error-messages)

---

## Installation Issues

### libheif not found

**Error:**
```
Package libheif was not found in the pkg-config search path
```

**Solution:**

Install libheif using your package manager:

**macOS:**
```bash
brew install libheif
```

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install libheif-dev
```

**Fedora:**
```bash
sudo dnf install libheif-devel
```

**Arch Linux:**
```bash
sudo pacman -S libheif
```

After installing, rebuild the project:
```bash
cargo clean
cargo build --release
```

---

### Rust/Cargo not found

**Error:**
```
cargo: command not found
```

**Solution:**

Install Rust from the official website:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
```

Verify installation:
```bash
cargo --version
```

---

### Permission denied when installing

**Error:**
```
cp: /usr/local/bin/heic2jpg: Permission denied
```

**Solution:**

Use `sudo` to install to system directories:

```bash
sudo cp target/release/heic2jpg /usr/local/bin/
```

Or install to a user directory:
```bash
mkdir -p ~/.local/bin
cp target/release/heic2jpg ~/.local/bin/
export PATH="$HOME/.local/bin:$PATH"
```

Add the export line to your `~/.bashrc` or `~/.zshrc` to make it permanent.

---

## Build Issues

### Old Rust version

**Error:**
```
feature `edition2024` is required
```

**Solution:**

Update Rust to the latest stable version:

```bash
rustup update stable
rustup default stable
```

Then rebuild:
```bash
cargo clean
cargo build --release
```

---

### Dependency conflicts

**Error:**
```
failed to select a version for the requirement
```

**Solution:**

1. Delete `Cargo.lock`:
```bash
rm Cargo.lock
```

2. Clean the build:
```bash
cargo clean
```

3. Rebuild:
```bash
cargo build --release
```

If issues persist, try updating dependencies:
```bash
cargo update
cargo build --release
```

---

### Slow build times

**Solution:**

1. Use release mode for production (it's slower to build but much faster to run):
```bash
cargo build --release
```

2. Use more threads for compilation:
```bash
cargo build --release -j $(nproc)
```

3. Enable incremental compilation (for debug builds):
```bash
export CARGO_INCREMENTAL=1
cargo build
```

---

## Runtime Issues

### "Invalid buffer length" or panic with buffer size mismatch

**Error:**
```
assertion `left == right` failed: Invalid buffer length: expected X got Y
```

**Cause:**
This was an issue with HEIC images that have stride padding in the decoded data.

**Solution:**
This has been fixed in the latest version. Make sure you're using the latest code:

```bash
cd ~/Development/heic-converter
git pull  # if using git
cargo build --release
```

If you still encounter this, run with verbose mode to see image details:
```bash
heic2jpg -v your-image.heic
```

---

### "No HEIC files found"

**Issue:**
The tool reports finding 0 files even though you have HEIC files.

**Solutions:**

1. **Check file extensions:**
   ```bash
   ls -la *.heic *.heif *.HEIC *.HEIF
   ```
   The tool looks for `.heic` and `.heif` extensions (case-insensitive).

2. **Verify you're in the correct directory:**
   ```bash
   pwd
   ls
   ```

3. **Use absolute paths:**
   ```bash
   heic2jpg -r /full/path/to/photos
   ```

4. **Make sure you use `-r` for subdirectories:**
   ```bash
   heic2jpg -r ./photos  # With -r flag
   ```

---

### "Output file already exists"

**Error:**
```
Output file already exists: /path/to/file.jpg (use --overwrite to replace)
```

**Solution:**

The tool won't overwrite existing files by default. Either:

1. **Use the --overwrite flag:**
   ```bash
   heic2jpg -r --overwrite ./photos
   ```

2. **Delete existing JPG files first:**
   ```bash
   rm ./photos/*.jpg
   heic2jpg -r ./photos
   ```

3. **Output to a different directory:**
   ```bash
   heic2jpg -r ./photos -o ./photos-converted
   ```

---

### Crash with corrupted HEIC files

**Error:**
```
Failed to read HEIC context
Failed to decode HEIC image
```

**Solutions:**

1. **Verify the file is a valid HEIC:**
   ```bash
   file your-image.heic
   ```
   Should show: `ISO Media, HEIF Image` or similar

2. **Try opening in another application:**
   - macOS: Preview, Photos
   - Windows: Paint, Photos
   - Linux: GIMP (with HEIF support)

3. **Skip corrupted files:**
   The tool will continue processing other files even if one fails.

4. **Use verbose mode to identify problem files:**
   ```bash
   heic2jpg -v -r ./photos
   ```

---

### Out of memory errors

**Error:**
```
memory allocation of X bytes failed
Out of memory
```

**Solutions:**

1. **Limit parallel jobs:**
   ```bash
   heic2jpg -j 2 -r ./photos  # Use only 2 threads
   ```

2. **Process in smaller batches:**
   ```bash
   heic2jpg -r ./photos/batch1
   heic2jpg -r ./photos/batch2
   ```

3. **Close other applications:**
   Free up RAM before processing large batches.

4. **For very large images (>50MP):**
   ```bash
   heic2jpg -j 1 large-image.heic  # Process one at a time
   ```

---

## Performance Issues

### Very slow conversion

**Causes & Solutions:**

1. **Using debug build instead of release:**
   ```bash
   # Always use release mode for production!
   cargo build --release
   ./target/release/heic2jpg ...  # Not target/debug/
   ```

2. **Processing from/to network drives:**
   - Copy files to local SSD first
   - Or output to local drive then copy

3. **Limited by I/O, not CPU:**
   ```bash
   # Check if CPU is actually being used
   top  # or htop
   
   # If low CPU usage, you're I/O bound - use SSD
   ```

4. **Too many threads for small batches:**
   ```bash
   # For < 10 files, limit threads
   heic2jpg -j 4 ./small-batch
   ```

5. **High quality settings:**
   - Quality 95-100 is slower
   - Consider using 85-90 for faster processing

---

### CPU not fully utilized

**Issue:**
Only using 1-2 cores instead of all available.

**Solutions:**

1. **Verify parallel processing is working:**
   ```bash
   heic2jpg -r -v ./photos
   # Should show: "threads: X" where X > 1
   ```

2. **Check you have multiple files:**
   Single file conversion can't be parallelized (only multi-file batches)

3. **Manually set thread count:**
   ```bash
   heic2jpg -j 8 -r ./photos  # Force 8 threads
   ```

4. **Monitor with htop:**
   ```bash
   htop
   # Run converter in another terminal, watch CPU usage
   ```

---

## Image Quality Issues

### Output images are too large

**Solution:**

Lower the quality setting:

```bash
# Default is 90
heic2jpg -q 75 -r ./photos  # Smaller files
heic2jpg -q 60 -r ./photos  # Even smaller
```

**Quality recommendations:**
- **60-70**: Small files, good for web/email
- **75-85**: Balanced quality and size
- **85-90**: High quality (default: 90)
- **95-98**: Very high quality, large files

---

### Output images look worse than original

**Solutions:**

1. **Increase quality:**
   ```bash
   heic2jpg -q 95 -r ./photos
   ```

2. **Verify original is good quality:**
   Some HEIC files are already compressed and can't be improved.

3. **Check display settings:**
   Some displays/viewers apply additional processing.

---

### Colors look different

**Issue:**
HEIC and JPG may handle color spaces differently.

**Solutions:**

1. **This is usually normal:**
   HEIC can use different color profiles than JPEG.

2. **Verify in multiple viewers:**
   Compare in different applications to see if it's a viewer issue.

3. **For critical color work:**
   Consider professional tools that preserve color profiles.

---

## Common Error Messages

### "Input path does not exist"

**Fix:**
```bash
# Check the path
ls /path/to/photos

# Use absolute path
heic2jpg -r "$(pwd)/photos"
```

---

### "Failed to create output directory"

**Fix:**
```bash
# Check permissions
ls -ld /output/directory

# Create directory manually
mkdir -p /output/directory

# Or output to writable location
heic2jpg input.heic -o ~/Pictures/output.jpg
```

---

### "Some conversions failed"

**Issue:**
Summary shows some files failed to convert.

**Solutions:**

1. **Use verbose mode to see which files failed:**
   ```bash
   heic2jpg -v -r ./photos
   ```

2. **Check failed files individually:**
   ```bash
   heic2jpg -v problem-file.heic
   ```

3. **Common causes:**
   - Corrupted HEIC files
   - Insufficient disk space
   - Permission issues
   - Unsupported HEIC variants

---

### "thread 'main' panicked at..."

**Solution:**

1. **Enable full backtrace:**
   ```bash
   RUST_BACKTRACE=full heic2jpg your-file.heic
   ```

2. **Report the issue:**
   - Save the backtrace
   - Note the image dimensions (if shown)
   - Try to reproduce with the same file

3. **Workaround:**
   - Try converting the problem file with another tool first
   - Skip the problem file and continue with others

---

## Getting More Help

### Enable verbose output

Always use `-v` when troubleshooting:

```bash
heic2jpg -v -r ./photos
```

This shows:
- Each file being processed
- Image dimensions
- Buffer information
- Detailed error messages

---

### Enable Rust backtrace

For crashes, get full debugging information:

```bash
RUST_BACKTRACE=1 heic2jpg ./problem-file.heic
```

Or for even more detail:

```bash
RUST_BACKTRACE=full heic2jpg ./problem-file.heic
```

---

### Check system information

```bash
# Check libheif version
pkg-config --modversion libheif

# Check Rust version
rustc --version
cargo --version

# Check binary info
file target/release/heic2jpg
ls -lh target/release/heic2jpg
```

---

### Test with a sample file

Create a test to isolate the issue:

```bash
# Test with a single file
heic2jpg -v test-image.heic

# Test with small batch
mkdir test-batch
cp sample1.heic sample2.heic test-batch/
heic2jpg -v -r test-batch
```

---

## Reporting Bugs

If you encounter a bug, please include:

1. **Command used:**
   ```
   heic2jpg -r -q 90 ./photos
   ```

2. **Error message:**
   ```
   Full error output here
   ```

3. **System information:**
   ```bash
   uname -a
   rustc --version
   pkg-config --modversion libheif
   ```

4. **Image information (if applicable):**
   ```bash
   file problem-image.heic
   ls -lh problem-image.heic
   ```

5. **Verbose output:**
   ```bash
   heic2jpg -v problem-image.heic
   ```

---

## Still Having Issues?

1. **Check the README:**
   - [README.md](README.md) - Full documentation

2. **Quick Start Guide:**
   - [QUICK_START.md](QUICK_START.md) - Basic usage

3. **Clean rebuild:**
   ```bash
   cargo clean
   cargo build --release
   ```

4. **Update everything:**
   ```bash
   rustup update
   brew update && brew upgrade libheif  # macOS
   cargo update
   cargo build --release
   ```

5. **Try the test script:**
   ```bash
   ./test_samples.sh
   ```

---

**Last Updated:** 2024
**Version:** 0.1.0