# Quick Start Guide

Get started with HEIC to JPG conversion in under 5 minutes!

## 1. Install Dependencies

### macOS
```bash
brew install libheif
```

### Linux (Ubuntu/Debian)
```bash
sudo apt-get install libheif-dev
```

### Linux (Fedora)
```bash
sudo dnf install libheif-devel
```

## 2. Install Rust (if needed)

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
```

## 3. Build the Project

### Option A: Using the build script (recommended)
```bash
cd ~/Development/heic-converter
./build.sh --install
```

### Option B: Using Cargo directly
```bash
cd ~/Development/heic-converter
cargo build --release
sudo cp target/release/heic2jpg /usr/local/bin/
```

### Option C: Using Make
```bash
cd ~/Development/heic-converter
make install
```

## 4. Start Converting! 🚀

### Convert a single file
```bash
heic2jpg photo.heic
```

### Convert all HEIC files in a folder
```bash
heic2jpg -r ~/Pictures/Photos
```

### Convert with custom quality
```bash
heic2jpg -q 85 -r ~/Pictures/Photos
```

## Common Use Cases

### 1. Convert iPhone photos in a directory
```bash
# Navigate to your iPhone photo import folder
heic2jpg -r ~/Pictures/iPhone-Import

# Output: Creates .jpg files alongside .heic files
```

### 2. Convert to a separate output folder
```bash
# Keep originals, output JPGs elsewhere
heic2jpg -r ~/Pictures/HEIC-Photos -o ~/Pictures/JPG-Photos

# Output: Preserves directory structure in output folder
```

### 3. High-quality conversion for printing
```bash
heic2jpg -q 95 -r ~/Pictures/Print-Ready
```

### 4. Lower quality for web/email
```bash
heic2jpg -q 70 -r ~/Pictures/Web-Photos -o ~/Pictures/Web-Compressed
```

### 5. Convert and overwrite existing JPGs
```bash
heic2jpg -r ~/Pictures --overwrite
```

### 6. Limit CPU usage
```bash
# Use only 4 threads instead of all cores
heic2jpg -r -j 4 ~/Pictures/Photos
```

## Quick Reference

| Task | Command |
|------|---------|
| Single file | `heic2jpg photo.heic` |
| Directory (flat) | `heic2jpg ./photos` |
| Directory (recursive) | `heic2jpg -r ./photos` |
| Custom quality | `heic2jpg -q 85 photo.heic` |
| Custom output | `heic2jpg photo.heic -o output.jpg` |
| Show help | `heic2jpg --help` |
| Show version | `heic2jpg --version` |

## Quality Guidelines

- **60-70**: Small file size, good for web/email
- **75-80**: Balanced quality and size
- **85-90**: High quality (default is 90)
- **95-98**: Maximum quality, large files
- **100**: Lossless (largest files)

## Performance Tips

✅ **DO:**
- Let the tool use all CPU cores (default behavior)
- Process large batches at once
- Use SSD storage for faster I/O

❌ **DON'T:**
- Limit threads unnecessarily
- Process files one at a time
- Use network drives for large batches

## Troubleshooting

### "libheif not found"
Install libheif using the commands in step 1 above.

### "Permission denied"
Use `sudo` when installing:
```bash
sudo cp target/release/heic2jpg /usr/local/bin/
```

### Files not converting
Check that files have `.heic` or `.heif` extension:
```bash
ls -la *.heic *.heif
```

### Very slow performance
Make sure you built in release mode:
```bash
cargo build --release  # Not just 'cargo build'
```

## Next Steps

- 📖 Read the full [README.md](README.md) for detailed documentation
- 🧪 Run tests: `./test_samples.sh`
- ⚙️ View all options: `heic2jpg --help`
- 🛠️ Build from scratch: `make help`

## Example Workflow

Here's a complete workflow for converting iPhone photos:

```bash
# 1. Connect iPhone and import HEIC photos to a folder
# 2. Convert all photos to JPG with good quality
heic2jpg -r -q 90 ~/Pictures/iPhone-2024-01 -o ~/Pictures/iPhone-2024-01-JPG

# 3. Check results
ls -lh ~/Pictures/iPhone-2024-01-JPG/

# 4. (Optional) Delete HEIC originals if satisfied
# rm ~/Pictures/iPhone-2024-01/*.heic
```

## Benchmarks

On a modern 8-core CPU:
- **Single 4K photo**: ~100-200ms
- **100 photos**: ~15-30 seconds
- **1000 photos**: ~2-5 minutes

*Times vary based on image size, quality settings, and CPU speed.*

---

**Need help?** Open an issue or check the [README.md](README.md) for more details.

**Ready to convert?** Just run: `heic2jpg -r ~/path/to/photos` 🎉