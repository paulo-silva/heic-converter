# Homebrew Publishing Checklist

Quick reference checklist for publishing heic2jpg to Homebrew.

## Pre-Release Checklist

- [ ] All tests passing (`cargo test`)
- [ ] Code formatted (`cargo fmt`)
- [ ] No clippy warnings (`cargo clippy`)
- [ ] Documentation updated (README.md)
- [ ] CHANGELOG.md updated with new features
- [ ] Version bumped in `Cargo.toml`
- [ ] All changes committed to git
- [ ] No uncommitted changes (`git status`)

## First-Time Setup (One-Time Only)

### 1. Create GitHub Repository

- [ ] Go to https://github.com/new
- [ ] Name: `heic-converter`
- [ ] Description: "Fast HEIC to JPG converter with multi-core support"
- [ ] Set to Public
- [ ] Create repository

### 2. Initialize and Push

```bash
cd ~/Development/heic-converter
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/YOUR_USERNAME/heic-converter.git
git branch -M main
git push -u origin main
```

- [ ] Repository pushed to GitHub
- [ ] Verify files visible on GitHub

### 3. Create Homebrew Tap

- [ ] Go to https://github.com/new
- [ ] Name: `homebrew-tap` (MUST start with "homebrew-")
- [ ] Description: "Homebrew formulas"
- [ ] Set to Public
- [ ] Create repository

```bash
cd ~/Development
git clone https://github.com/YOUR_USERNAME/homebrew-tap.git
cd homebrew-tap
mkdir -p Formula
```

- [ ] Tap repository created
- [ ] Formula directory created

## Release Workflow (Every Release)

### Step 1: Prepare Release

- [ ] Update version in `Cargo.toml`
- [ ] Update CHANGELOG.md
- [ ] Test build: `cargo build --release`
- [ ] Test binary: `./target/release/heic2jpg --version`
- [ ] Commit version bump: `git commit -am "Bump version to X.Y.Z"`

### Step 2: Create Release

**Option A: Using the automated script (recommended)**

```bash
./scripts/publish.sh
# Select option 1: Full release
```

**Option B: Manual process**

```bash
# Get current version
VERSION=$(grep '^version' Cargo.toml | head -1 | sed 's/version = "\(.*\)"/\1/')

# Build release
cargo build --release

# Create tarball
cd target/release
tar czf ../../heic2jpg-v${VERSION}.tar.gz heic2jpg
cd ../..

# Calculate SHA256
SHA256=$(shasum -a 256 heic2jpg-v${VERSION}.tar.gz | cut -d' ' -f1)
echo "SHA256: $SHA256"

# Create and push tag
git tag -a v${VERSION} -m "Release v${VERSION}"
git push origin main
git push origin v${VERSION}
```

- [ ] Release tarball created
- [ ] SHA256 calculated and saved
- [ ] Git tag created
- [ ] Tag pushed to GitHub

### Step 3: Create GitHub Release

**If using GitHub Actions (automated):**

- [ ] Wait for GitHub Actions to complete
- [ ] Verify release at: `https://github.com/YOUR_USERNAME/heic-converter/releases`
- [ ] Download tarball and verify SHA256

**If creating manually:**

- [ ] Go to: `https://github.com/YOUR_USERNAME/heic-converter/releases/new`
- [ ] Tag: `vX.Y.Z`
- [ ] Release title: `vX.Y.Z`
- [ ] Description: Release notes
- [ ] Attach tarball file
- [ ] Publish release

### Step 4: Update Homebrew Formula

```bash
cd ~/Development/homebrew-tap

# Download and get SHA256 of the release
curl -L https://github.com/YOUR_USERNAME/heic-converter/archive/refs/tags/vX.Y.Z.tar.gz -o heic2jpg.tar.gz
SHA256=$(shasum -a 256 heic2jpg.tar.gz | cut -d' ' -f1)
echo "SHA256: $SHA256"
```

Edit `Formula/heic2jpg.rb`:

```ruby
class Heic2jpg < Formula
  desc "Fast HEIC to JPG converter with multi-core support"
  homepage "https://github.com/YOUR_USERNAME/heic-converter"
  url "https://github.com/YOUR_USERNAME/heic-converter/archive/refs/tags/vX.Y.Z.tar.gz"
  sha256 "PASTE_SHA256_HERE"
  license "MIT"
  
  depends_on "rust" => :build
  depends_on "libheif"
  
  def install
    system "cargo", "install", *std_cargo_args
  end
  
  test do
    assert_match "X.Y.Z", shell_output("#{bin}/heic2jpg --version")
  end
end
```

- [ ] URL updated to new version
- [ ] SHA256 updated
- [ ] Version in test block updated
- [ ] Formula saved

### Step 5: Test Formula Locally

```bash
# Uninstall old version if exists
brew uninstall heic2jpg 2>/dev/null || true

# Test new formula
brew install --build-from-source Formula/heic2jpg.rb

# Verify installation
heic2jpg --version

# Run tests
brew test heic2jpg

# Audit
brew audit --strict Formula/heic2jpg.rb

# Uninstall
brew uninstall heic2jpg
```

- [ ] Formula installs successfully
- [ ] Version is correct
- [ ] Tests pass
- [ ] Audit passes with no errors

### Step 6: Publish Formula

```bash
cd ~/Development/homebrew-tap

git add Formula/heic2jpg.rb
git commit -m "heic2jpg: update to X.Y.Z"
git push origin main
```

- [ ] Formula committed
- [ ] Formula pushed to GitHub

### Step 7: Test Installation from Tap

```bash
# Remove local formula if installed
brew uninstall heic2jpg 2>/dev/null || true

# Update tap
brew update

# Install from tap
brew install YOUR_USERNAME/tap/heic2jpg

# Test
heic2jpg --version
heic2jpg --help

# Test with actual file
heic2jpg test.heic
```

- [ ] Installs from tap successfully
- [ ] Version is correct
- [ ] Works as expected

## Post-Release

- [ ] Announcement on GitHub Discussions
- [ ] Update main README with installation instructions
- [ ] Tweet/share (optional)
- [ ] Monitor for issues

## Quick Reference Commands

### Get Current Version
```bash
grep '^version' Cargo.toml | head -1 | sed 's/version = "\(.*\)"/\1/'
```

### Calculate SHA256
```bash
shasum -a 256 file.tar.gz
```

### Test Installation
```bash
brew uninstall heic2jpg
brew install YOUR_USERNAME/tap/heic2jpg
heic2jpg --version
```

### Update Formula Version
```bash
# In homebrew-tap directory
sed -i '' 's/vX.Y.Z/vNEW.VER.SION/g' Formula/heic2jpg.rb
# Update SHA256 manually
```

## Troubleshooting

### "Formula not found"
- Check that tap is added: `brew tap YOUR_USERNAME/tap`
- Check Formula path: `~/Development/homebrew-tap/Formula/heic2jpg.rb`

### "SHA256 mismatch"
- Recalculate: `curl -L URL | shasum -a 256`
- Ensure URL is correct
- Clear brew cache: `rm -rf $(brew --cache)`

### Build fails
- Test locally first: `cargo build --release`
- Check dependencies are listed in formula
- Test with verbose: `brew install --build-from-source --verbose Formula/heic2jpg.rb`

### Audit fails
- Fix indentation (2 spaces, no tabs)
- Check all required fields present
- Run: `brew audit --strict --online Formula/heic2jpg.rb`

## Resources

- [Full Publishing Guide](HOMEBREW_PUBLISHING.md)
- [Homebrew Formula Cookbook](https://docs.brew.sh/Formula-Cookbook)
- [Creating Taps](https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap)

## Summary

**Every release:**
1. ✅ Bump version in Cargo.toml
2. ✅ Create git tag and push
3. ✅ Create GitHub release
4. ✅ Update Homebrew formula with new version and SHA256
5. ✅ Test locally
6. ✅ Push formula to tap
7. ✅ Test installation from tap

**Installation command for users:**
```bash
brew tap YOUR_USERNAME/tap
brew install heic2jpg
```

---

**Last Updated:** 2024
**Current Version:** 0.1.0