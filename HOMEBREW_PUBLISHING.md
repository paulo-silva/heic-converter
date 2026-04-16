# Homebrew Publishing Guide

Complete guide to publishing `heic2jpg` on Homebrew.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Step 1: Prepare Your GitHub Repository](#step-1-prepare-your-github-repository)
- [Step 2: Create Your First Release](#step-2-create-your-first-release)
- [Step 3: Create a Homebrew Tap](#step-3-create-a-homebrew-tap)
- [Step 4: Write the Formula](#step-4-write-the-formula)
- [Step 5: Test the Formula](#step-5-test-the-formula)
- [Step 6: Publish Your Tap](#step-6-publish-your-tap)
- [Step 7: Submit to Homebrew Core (Optional)](#step-7-submit-to-homebrew-core-optional)
- [Maintenance](#maintenance)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

### 1. GitHub Account
- Create a GitHub account if you don't have one
- Install `gh` CLI (optional but recommended):
  ```bash
  brew install gh
  gh auth login
  ```

### 2. Git Setup
```bash
# Configure git
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### 3. Homebrew Installed
```bash
# Verify Homebrew is installed
brew --version
```

---

## Step 1: Prepare Your GitHub Repository

### 1.1 Create GitHub Repository

1. Go to https://github.com/new
2. Repository name: `heic-converter`
3. Description: `Fast HEIC to JPG converter with multi-core support`
4. Choose: **Public**
5. Do NOT initialize with README (we already have one)
6. Click **Create repository**

### 1.2 Initialize Git (if not already done)

```bash
cd ~/Development/heic-converter

# Initialize git
git init

# Add all files
git add .

# Create initial commit
git commit -m "Initial commit: HEIC to JPG converter"
```

### 1.3 Push to GitHub

Replace `YOUR_USERNAME` with your actual GitHub username:

```bash
# Add remote
git remote add origin https://github.com/YOUR_USERNAME/heic-converter.git

# Push to GitHub
git branch -M main
git push -u origin main
```

### 1.4 Verify Upload

Visit: `https://github.com/YOUR_USERNAME/heic-converter`

You should see all your files there.

---

## Step 2: Create Your First Release

### 2.1 Update Version in Cargo.toml

Make sure `Cargo.toml` has the correct version:

```toml
[package]
name = "heic2jpg"
version = "0.1.0"
```

### 2.2 Create and Push a Git Tag

```bash
cd ~/Development/heic-converter

# Create annotated tag
git tag -a v0.1.0 -m "Release v0.1.0 - Initial release"

# Push the tag
git push origin v0.1.0
```

### 2.3 Wait for GitHub Actions

The workflow we created will automatically:
- Build binaries for macOS (Intel & ARM) and Linux
- Create a GitHub Release
- Upload the binaries

Check progress at:
`https://github.com/YOUR_USERNAME/heic-converter/actions`

### 2.4 Verify Release

Go to: `https://github.com/YOUR_USERNAME/heic-converter/releases`

You should see:
- Release v0.1.0
- Attached binary files (`.tar.gz` for each platform)
- SHA256 checksums

**Note:** If you don't have GitHub Actions set up yet, create a manual release:

```bash
# Build release binary
cargo build --release

# Create tarball
cd target/release
tar czf heic2jpg-v0.1.0-$(uname -m)-apple-darwin.tar.gz heic2jpg
shasum -a 256 heic2jpg-v0.1.0-*.tar.gz

# Upload manually via GitHub web interface
```

---

## Step 3: Create a Homebrew Tap

A "tap" is a third-party Homebrew repository. This is the recommended way to distribute your formula.

### 3.1 Create Tap Repository

1. Go to: https://github.com/new
2. Repository name: `homebrew-tap` (MUST start with `homebrew-`)
3. Description: `Homebrew formulas`
4. Public repository
5. Click **Create repository**

### 3.2 Clone the Tap Repository

```bash
cd ~/Development
git clone https://github.com/YOUR_USERNAME/homebrew-tap.git
cd homebrew-tap
```

### 3.3 Create Formula Directory

```bash
mkdir -p Formula
```

---

## Step 4: Write the Formula

### 4.1 Get Release Information

First, get the SHA256 of your release tarball:

```bash
# Download your release tarball
curl -L https://github.com/YOUR_USERNAME/heic-converter/archive/refs/tags/v0.1.0.tar.gz -o heic2jpg.tar.gz

# Calculate SHA256
shasum -a 256 heic2jpg.tar.gz
```

Copy the SHA256 hash.

### 4.2 Create the Formula

Create `Formula/heic2jpg.rb`:

```ruby
class Heic2jpg < Formula
  desc "Fast HEIC to JPG converter with multi-core support"
  homepage "https://github.com/YOUR_USERNAME/heic-converter"
  url "https://github.com/YOUR_USERNAME/heic-converter/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "PASTE_YOUR_SHA256_HERE"
  license "MIT"
  head "https://github.com/YOUR_USERNAME/heic-converter.git", branch: "main"

  depends_on "rust" => :build
  depends_on "libheif"

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/heic2jpg --version")
    assert_match "Fast HEIC to JPG converter", shell_output("#{bin}/heic2jpg --help")
  end
end
```

**Important:** Replace:
- `YOUR_USERNAME` with your GitHub username
- `PASTE_YOUR_SHA256_HERE` with the actual SHA256 hash

### 4.3 Alternative: Binary Distribution (Faster Installation)

If you want users to download pre-built binaries instead of compiling:

```ruby
class Heic2jpg < Formula
  desc "Fast HEIC to JPG converter with multi-core support"
  homepage "https://github.com/YOUR_USERNAME/heic-converter"
  version "0.1.0"
  license "MIT"

  if Hardware::CPU.intel?
    url "https://github.com/YOUR_USERNAME/heic-converter/releases/download/v0.1.0/heic2jpg-v0.1.0-x86_64-apple-darwin.tar.gz"
    sha256 "INTEL_SHA256"
  elsif Hardware::CPU.arm?
    url "https://github.com/YOUR_USERNAME/heic-converter/releases/download/v0.1.0/heic2jpg-v0.1.0-aarch64-apple-darwin.tar.gz"
    sha256 "ARM_SHA256"
  end

  depends_on "libheif"

  def install
    bin.install "heic2jpg"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/heic2jpg --version")
  end
end
```

---

## Step 5: Test the Formula

### 5.1 Install Locally for Testing

```bash
# From your homebrew-tap directory
brew install --build-from-source Formula/heic2jpg.rb

# Or if using binary distribution:
brew install Formula/heic2jpg.rb
```

### 5.2 Test the Installation

```bash
# Check version
heic2jpg --version

# Check help
heic2jpg --help

# Test with a real file (if you have one)
heic2jpg test.heic
```

### 5.3 Run Homebrew Audit

```bash
brew audit --strict --online Formula/heic2jpg.rb
```

Fix any warnings or errors.

### 5.4 Run Homebrew Tests

```bash
brew test heic2jpg
```

### 5.5 Uninstall (for clean testing)

```bash
brew uninstall heic2jpg
```

---

## Step 6: Publish Your Tap

### 6.1 Commit and Push the Formula

```bash
cd ~/Development/homebrew-tap

# Add the formula
git add Formula/heic2jpg.rb

# Commit
git commit -m "Add heic2jpg formula v0.1.0"

# Push to GitHub
git push origin main
```

### 6.2 Create a README

Create `README.md` in your tap repository:

```markdown
# Homebrew Tap

Custom Homebrew formulas.

## Installation

```bash
brew tap YOUR_USERNAME/tap
brew install heic2jpg
```

## Formulas

### heic2jpg

Fast HEIC to JPG converter with multi-core support.

```bash
brew install heic2jpg
```

See [heic-converter](https://github.com/YOUR_USERNAME/heic-converter) for documentation.
```

Commit and push:

```bash
git add README.md
git commit -m "Add README"
git push origin main
```

### 6.3 Test Installation from Tap

Now anyone can install your tool:

```bash
# Add your tap
brew tap YOUR_USERNAME/tap

# Install
brew install heic2jpg

# Test
heic2jpg --version
```

---

## Step 7: Submit to Homebrew Core (Optional)

If your tool becomes popular, you can submit it to the official Homebrew repository.

### Requirements for Homebrew Core

1. **Stable and widely used** - Tool should be useful to many people
2. **Active maintenance** - You commit to maintaining it
3. **No legal issues** - Open source license (MIT ✓)
4. **Not a duplicate** - No similar tool already in Homebrew
5. **Build from source** - Must compile reliably

### 7.1 Create Fork of Homebrew Core

```bash
# Fork homebrew-core on GitHub
open https://github.com/Homebrew/homebrew-core

# Click "Fork" button

# Clone your fork
cd ~/Development
git clone https://github.com/YOUR_USERNAME/homebrew-core.git
cd homebrew-core
```

### 7.2 Create New Branch

```bash
git checkout -b heic2jpg
```

### 7.3 Copy Your Formula

```bash
# Copy your tested formula
cp ~/Development/homebrew-tap/Formula/heic2jpg.rb Formula/heic2jpg.rb
```

### 7.4 Test Thoroughly

```bash
# Uninstall from your tap first
brew uninstall heic2jpg
brew untap YOUR_USERNAME/tap

# Test the formula
brew install --build-from-source Formula/heic2jpg.rb
brew test heic2jpg
brew audit --strict --online Formula/heic2jpg.rb

# Clean up
brew uninstall heic2jpg
```

### 7.5 Create Pull Request

```bash
# Commit your formula
git add Formula/heic2jpg.rb
git commit -m "heic2jpg 0.1.0 (new formula)"

# Push to your fork
git push origin heic2jpg
```

Then:
1. Go to https://github.com/Homebrew/homebrew-core
2. Click "Pull requests" → "New pull request"
3. Click "compare across forks"
4. Select your fork and branch
5. Create the PR with a good description

**Note:** This is optional and only recommended when your tool is mature and widely used.

---

## Maintenance

### Releasing a New Version

When you release a new version:

#### 1. Update Cargo.toml

```toml
version = "0.2.0"
```

#### 2. Commit Changes

```bash
git add Cargo.toml
git commit -m "Bump version to 0.2.0"
git push
```

#### 3. Create New Tag

```bash
git tag -a v0.2.0 -m "Release v0.2.0"
git push origin v0.2.0
```

#### 4. GitHub Actions Creates Release

Wait for the automated build to complete.

#### 5. Update Homebrew Formula

```bash
cd ~/Development/homebrew-tap

# Get new SHA256
curl -L https://github.com/YOUR_USERNAME/heic-converter/archive/refs/tags/v0.2.0.tar.gz | shasum -a 256
```

Edit `Formula/heic2jpg.rb`:
- Update `url` to v0.2.0
- Update `sha256` with new hash

```bash
git add Formula/heic2jpg.rb
git commit -m "heic2jpg: update to 0.2.0"
git push
```

#### 6. Test Update

```bash
brew update
brew upgrade heic2jpg
heic2jpg --version
```

---

## Troubleshooting

### "Formula not found"

Make sure you've tapped the repository:
```bash
brew tap YOUR_USERNAME/tap
```

### "SHA256 mismatch"

Recalculate the SHA256:
```bash
curl -L YOUR_TARBALL_URL | shasum -a 256
```

Update the formula with the correct hash.

### Build failures

Check that all dependencies are listed:
```ruby
depends_on "rust" => :build
depends_on "libheif"
```

Test building locally:
```bash
brew install --build-from-source --verbose Formula/heic2jpg.rb
```

### Installation from binary fails

Make sure the binary is built for the right architecture:
```bash
# Check what architecture the binary is
file target/release/heic2jpg
```

### Formula audit fails

Run audit and fix issues:
```bash
brew audit --strict --online Formula/heic2jpg.rb
```

Common issues:
- Missing or incorrect license
- Bad URL format
- Missing dependencies
- Incorrect indentation (use 2 spaces)

---

## Quick Reference

### Installation Commands for Users

```bash
# Install from your tap
brew tap YOUR_USERNAME/tap
brew install heic2jpg

# Update
brew upgrade heic2jpg

# Uninstall
brew uninstall heic2jpg
brew untap YOUR_USERNAME/tap
```

### Developer Commands

```bash
# Test formula locally
brew install --build-from-source Formula/heic2jpg.rb

# Audit formula
brew audit --strict Formula/heic2jpg.rb

# Run tests
brew test heic2jpg

# Get formula info
brew info heic2jpg

# Edit formula
brew edit heic2jpg
```

---

## Example URLs

After publishing, your tool will be available at:

- **GitHub Repo:** `https://github.com/YOUR_USERNAME/heic-converter`
- **Homebrew Tap:** `https://github.com/YOUR_USERNAME/homebrew-tap`
- **Installation:** `brew install YOUR_USERNAME/tap/heic2jpg`

---

## Resources

- [Homebrew Formula Cookbook](https://docs.brew.sh/Formula-Cookbook)
- [Homebrew Acceptable Formulae](https://docs.brew.sh/Acceptable-Formulae)
- [Creating Taps](https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap)
- [Ruby Formula Reference](https://rubydoc.brew.sh/Formula)

---

## Summary Checklist

- [ ] GitHub repository created and pushed
- [ ] First release (v0.1.0) created with tag
- [ ] Homebrew tap repository created
- [ ] Formula written and tested locally
- [ ] Formula pushed to tap repository
- [ ] Installation tested from tap
- [ ] README added to tap
- [ ] Documentation updated

Once complete, users can install with:

```bash
brew tap YOUR_USERNAME/tap
brew install heic2jpg
```

Congratulations! Your tool is now available via Homebrew! 🎉