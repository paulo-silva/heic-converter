# Documentation: https://docs.brew.sh/Formula-Cookbook
#               https://rubydoc.brew.sh/Formula
class Heic2jpg < Formula
  desc "Fast HEIC to JPG converter with multi-core support"
  homepage "https://github.com/YOUR_USERNAME/heic-converter"
  url "https://github.com/YOUR_USERNAME/heic-converter/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "REPLACE_WITH_ACTUAL_SHA256"
  license "MIT"
  head "https://github.com/YOUR_USERNAME/heic-converter.git", branch: "main"

  depends_on "rust" => :build
  depends_on "libheif"

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    # Test version output
    assert_match version.to_s, shell_output("#{bin}/heic2jpg --version")

    # Test help output
    assert_match "Fast HEIC to JPG converter", shell_output("#{bin}/heic2jpg --help")
  end
end
