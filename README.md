# HEIC to JPG Converter

A high-performance command-line tool written in Rust that converts HEIC/HEIF images to JPG format with configurable compression. Built with multi-core processing for maximum speed.

## Features

- ⚡ **Fast**: Utilizes all available CPU cores for parallel processing
- 📁 **Flexible**: Convert single files or entire directories
- 🌲 **Recursive**: Automatically traverse nested folder structures
- 🎨 **Quality Control**: Configurable JPEG compression (1-100)
- 📊 **Progress Tracking**: Real-time progress bars with time estimates
- 🔒 **Safe**: Won't overwrite existing files unless explicitly told to
- 🚀 **Optimized**: Release builds are highly optimized for performance

## Prerequisites

### macOS
```bash
brew install libheif
```

### Ubuntu/Debian
```bash
sudo apt-get install libheif-dev
```

### Fedora
```bash
sudo dnf install libheif-devel
```

## Installation

### From Source

1. **Install Rust** (if not already installed):
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

2. **Clone and build**:
```bash
cd ~/Development/heic-converter
cargo build --release
```

3. **Install binary** (optional):
```bash
cargo install --path .
```

Or copy the binary manually:
```bash
cp target/release/heic2jpg /usr/local/bin/
```

## Usage

### Basic Syntax
```bash
heic2jpg [OPTIONS] <INPUT>
```

### Examples

#### Convert a single file
```bash
# Convert with default quality (90) and brightness compensation (1.15)
heic2jpg photo.heic

# Convert with custom quality
heic2jpg -q 85 photo.heic

# Adjust brightness (useful for Display P3 images)
heic2jpg -b 1.2 photo.heic

# No brightness adjustment (use original brightness)
heic2jpg -b 1.0 photo.heic

# Specify output location
heic2jpg photo.heic -o output.jpg
```
</text>

<old_text line=113>
## Options

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--quality` | `-q` | JPEG quality (1-100) | 90 |
| `--output` | `-o` | Output directory or file path | Same as input |
| `--recursive` | `-r` | Process directories recursively | false |
| `--jobs` | `-j` | Number of parallel jobs | CPU cores |
| `--overwrite` | | Overwrite existing files | false |
| `--verbose` | `-v` | Verbose output | false |
| `--help` | `-h` | Show help message | |
| `--version` | `-V` | Show version | |

#### Convert a directory (non-recursive)
```bash
# Convert all HEIC files in current directory
heic2jpg ./photos

# With custom quality
heic2jpg -q 95 ./photos
```

#### Convert nested directories (recursive)
```bash
# Process all HEIC files in directory tree
heic2jpg -r ./photos

# Output to a different directory (preserves structure)
heic2jpg -r ./photos -o ./converted
```

#### Advanced Usage
```bash
# Use specific number of threads
heic2jpg -r -j 8 ./photos

# Overwrite existing JPG files
heic2jpg -r --overwrite ./photos

# Verbose output to see each file being processed
heic2jpg -r -v ./photos

# Low quality for smaller file sizes
heic2jpg -q 60 -r ./photos

# High quality for maximum image quality

# Brighter output (recommended for Display P3 images)
heic2jpg -b 1.2 -r ./photos

# No brightness adjustment (preserve original)
heic2jpg -b 1.0 -r ./photos
heic2jpg -q 98 -r ./photos

# Adjust brightness for darker/brighter images
heic2jpg -b 1.25 -r ./photos

# No brightness adjustment (preserve original)
heic2jpg -b 1.0 -r ./photos
```

## Options

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--quality` | `-q` | JPEG quality (1-100) | 90 |
| `--output` | `-o` | Output directory or file path | Same as input |
| `--brightness` | `-b` | Brightness adjustment (0.5-2.0) | 1.15 |
| `--recursive` | `-r` | Process directories recursively | false |
| `--jobs` | `-j` | Number of parallel jobs | CPU cores |
| `--overwrite` | | Overwrite existing files | false |
| `--verbose` | `-v` | Verbose output | false |
| `--help` | `-h` | Show help message | |
| `--version` | `-V` | Show version | |

## Performance Tips

1. **Let it use all cores**: The default behavior uses all CPU cores for maximum speed
2. **SSD Storage**: Processing from/to SSD drives is significantly faster
3. **Quality vs Speed**: Lower quality settings (60-80) process faster
4. **Batch Processing**: Converting multiple files is much more efficient than running the tool multiple times

## Output

The tool provides:
- Real-time progress bar with elapsed time and ETA
- Conversion summary showing successful and failed conversions
- Detailed error messages for failed conversions (when verbose mode is enabled)

Example output:
```
Found 150 HEIC file(s) to convert (quality: 90, threads: 8)
⠋ [00:00:15] [#####################>------------------] 75/150 (00:00:15)

=== Conversion Summary ===
✓ Successfully converted: 150
```

## File Naming

- Input files with `.heic` or `.heif` extensions are processed
- Output files will have `.jpg` extension
- Original files are never modified or deleted
- Directory structure is preserved when using output directory

## Error Handling

The tool will:
- Skip files that would overwrite existing files (unless `--overwrite` is used)
- Continue processing other files if one fails
- Provide a summary of all failures at the end
- Return a non-zero exit code if any conversions fail

## Building for Production

For maximum performance, always build in release mode:

```bash
cargo build --release
```

The release build includes:
- Maximum optimization (`opt-level = 3`)
- Link-time optimization (LTO)
- Binary stripping for smaller size
- Single codegen unit for better optimization

## Troubleshooting

### "libheif not found" error
Make sure libheif is installed (see Prerequisites section)

### Slow performance
- Check if you're using the release build (`cargo build --release`)
- Ensure you're not limiting threads with `-j`
- Verify disk I/O isn't the bottleneck

### Out of memory
- Reduce the number of parallel jobs: `heic2jpg -j 2 ./photos`
- Process files in smaller batches

## License

MIT

## Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest features
- Submit pull requests

## Technical Details

Built with:
- **Rust** - Systems programming language
- **libheif-rs** - HEIF/HEIC decoding
- **image** - Image processing and JPEG encoding
- **rayon** - Data parallelism
- **clap** - Command-line argument parsing
- **indicatif** - Progress bars