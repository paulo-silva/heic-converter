# Color Space & Brightness Guide

Understanding color spaces and brightness adjustments when converting HEIC to JPG.

## Table of Contents

- [Why Brightness Adjustment?](#why-brightness-adjustment)
- [Understanding Color Spaces](#understanding-color-spaces)
- [Default Settings](#default-settings)
- [Recommended Settings](#recommended-settings)
- [Visual Examples](#visual-examples)
- [Technical Details](#technical-details)
- [FAQ](#faq)

---

## Why Brightness Adjustment?

When converting HEIC images to JPG, you may notice the output appears **darker** or less vibrant than the original. This happens because:

1. **iPhone photos use Display P3 color space** - a wider color gamut
2. **JPG typically uses sRGB color space** - a standard but narrower gamut
3. **Direct conversion loses brightness information** during color space transformation

This tool applies a **default 1.15x brightness adjustment** to compensate for this color space conversion, producing JPG images that better match the original HEIC appearance.

---

## Understanding Color Spaces

### Display P3
- **Used by**: iPhone cameras, modern Apple devices
- **Color gamut**: ~25% wider than sRGB
- **Characteristics**: Brighter, more vibrant colors
- **Common in**: HEIC/HEIF images from iOS devices

### sRGB
- **Used by**: Most displays, web browsers, JPG files
- **Color gammt**: Standard color space
- **Characteristics**: Universal compatibility
- **Common in**: JPG, PNG, most digital images

### The Problem
When converting Display P3 → sRGB, colors that exist in P3 but not in sRGB must be "mapped" to the closest sRGB equivalent. This mapping often results in:
- Reduced brightness
- Less vibrant colors
- Darker shadows
- Muted highlights

---

## Default Settings

### Automatic Compensation (Recommended)

```bash
# Uses default brightness: 1.15x
heic2jpg photo.heic
```

**When to use:**
- ✅ iPhone/iPad photos
- ✅ Display P3 HEIC images
- ✅ Most modern smartphone photos
- ✅ When output looks darker than expected

### No Adjustment

```bash
# Preserve original brightness: 1.0x
heic2jpg -b 1.0 photo.heic
```

**When to use:**
- ✅ Already properly exposed images
- ✅ Professional photography with color profiles
- ✅ When you want exact pixel values
- ✅ Images not from Display P3 sources

---

## Recommended Settings

### By Source Device

| Device | Brightness Setting | Reason |
|--------|-------------------|---------|
| iPhone 7 and newer | `1.15` (default) | Uses Display P3 |
| iPhone 6s and older | `1.0` | Uses sRGB |
| iPad Pro | `1.15` (default) | Uses Display P3 |
| Android (modern) | `1.10` | Varies by device |
| Digital cameras | `1.0` | Usually sRGB |
| Screen captures (iOS) | `1.15` (default) | Display P3 |

### By Image Type

| Image Type | Recommended | Example Command |
|------------|-------------|-----------------|
| Daylight photos | `1.15` | `heic2jpg -b 1.15 photo.heic` |
| Indoor/dark photos | `1.20 - 1.25` | `heic2jpg -b 1.2 photo.heic` |
| Already bright | `1.05 - 1.10` | `heic2jpg -b 1.1 photo.heic` |
| Professional edits | `1.0` | `heic2jpg -b 1.0 photo.heic` |
| Screenshots | `1.15` | `heic2jpg -b 1.15 photo.heic` |
| Night mode | `1.25 - 1.3` | `heic2jpg -b 1.25 photo.heic` |

### By Use Case

| Use Case | Brightness | Quality | Example |
|----------|-----------|---------|---------|
| Social media | `1.15` | `85` | `heic2jpg -b 1.15 -q 85 photo.heic` |
| Printing | `1.10` | `95` | `heic2jpg -b 1.1 -q 95 photo.heic` |
| Web display | `1.15` | `85` | `heic2jpg -b 1.15 -q 85 photo.heic` |
| Email/sharing | `1.15` | `75` | `heic2jpg -b 1.15 -q 75 photo.heic` |
| Archiving | `1.0` | `95` | `heic2jpg -b 1.0 -q 95 photo.heic` |
| Professional work | `1.0` | `98` | `heic2jpg -b 1.0 -q 98 photo.heic` |

---

## Visual Examples

### Example 1: Default Brightness (1.15x)

```bash
heic2jpg IMG_1234.heic
# or explicitly:
heic2jpg -b 1.15 IMG_1234.heic
```

**Result:** Balanced brightness that closely matches the original HEIC when viewed on most displays.

### Example 2: No Adjustment (1.0x)

```bash
heic2jpg -b 1.0 IMG_1234.heic
```

**Result:** Darker output, preserves exact pixel values from HEIC decode.

### Example 3: Higher Adjustment (1.25x)

```bash
heic2jpg -b 1.25 IMG_1234.heic
```

**Result:** Brighter output, useful for indoor or underexposed photos.

### Example 4: Batch Processing with Custom Brightness

```bash
# Process all photos with 1.2x brightness
heic2jpg -b 1.2 -r ~/Pictures/Vacation2024

# Different settings for different folders
heic2jpg -b 1.15 -r ~/Pictures/Daylight
heic2jpg -b 1.25 -r ~/Pictures/Indoor
heic2jpg -b 1.0 -r ~/Pictures/Professional
```

---

## Technical Details

### How Brightness Adjustment Works

1. **Decode HEIC** → RGB color data
2. **Extract metadata** → Detect color space (Display P3)
3. **Apply brightness** → Multiply each pixel by brightness factor
4. **Clamp values** → Ensure 0-255 range
5. **Encode to JPG** → Save as sRGB JPEG

### Formula

```
adjusted_pixel = min(255, max(0, original_pixel × brightness_factor))
```

### What Gets Adjusted

- **Red channel** → Multiplied by brightness factor
- **Green channel** → Multiplied by brightness factor  
- **Blue channel** → Multiplied by brightness factor
- **Applied uniformly** → All pixels adjusted equally

### What Doesn't Change

- ❌ Image dimensions
- ❌ EXIF data (preserved)
- ❌ Image structure
- ❌ Aspect ratio

### Brightness Range

| Value | Effect | Use Case |
|-------|--------|----------|
| `0.5` | 50% darker | Reduce overexposure |
| `0.8` | 20% darker | Slightly dim |
| `1.0` | No change | Preserve original |
| `1.15` | 15% brighter | Default (Display P3 compensation) |
| `1.25` | 25% brighter | Dark photos |
| `1.5` | 50% brighter | Very dark images |
| `2.0` | 100% brighter | Maximum |

---

## FAQ

### Q: Why is the default 1.15 instead of 1.0?

**A:** Most HEIC files come from iPhones using Display P3 color space. Testing shows that 1.15x brightness produces JPG images that closely match the original HEIC appearance when viewed on standard displays.

### Q: Should I always use the default?

**A:** For iPhone photos, yes. For other sources or professional work, consider using `-b 1.0` to preserve exact values.

### Q: Will this blow out highlights?

**A:** The adjustment is clamped at 255, so bright areas won't exceed maximum white. However, very bright images may lose some highlight detail. Use `-b 1.0` or `-b 1.05` for such images.

### Q: Can I use values below 1.0?

**A:** Yes! Use `-b 0.8` to make images darker, useful for overexposed images.

### Q: Does this affect image quality?

**A:** Minimally. The brightness adjustment is applied to pixel values before JPEG encoding, so it doesn't introduce additional compression artifacts.

### Q: How do I know what brightness to use?

**A:** 
1. Start with default (1.15)
2. Compare output with original
3. Adjust if needed:
   - Too dark? Use 1.2 or 1.25
   - Too bright? Use 1.0 or 1.05
4. Use that value for similar photos

### Q: Can I see the brightness before saving?

**A:** Use `-v` (verbose) mode to see what brightness is being applied:

```bash
heic2jpg -v -b 1.2 photo.heic
# Output shows: "Applying brightness adjustment: 1.20x"
```

### Q: Does this work for all HEIC files?

**A:** Yes, brightness adjustment works regardless of the original color space. It's most useful for Display P3 images but can be applied to any HEIC file.

### Q: What about color profiles?

**A:** Currently, the tool converts to RGB without embedding ICC profiles. The brightness adjustment compensates for the most common scenario (Display P3 → sRGB).

---

## Testing Your Images

### Side-by-Side Comparison

1. **Convert with different settings:**
   ```bash
   heic2jpg -b 1.0 photo.heic -o photo_1.0.jpg
   heic2jpg -b 1.15 photo.heic -o photo_1.15.jpg
   heic2jpg -b 1.25 photo.heic -o photo_1.25.jpg
   ```

2. **Open all versions:**
   ```bash
   open photo.heic photo_1.0.jpg photo_1.15.jpg photo_1.25.jpg
   ```

3. **Compare and choose your preferred brightness**

### Batch Testing

```bash
# Create test outputs
mkdir brightness_test
heic2jpg -b 1.0 photo.heic -o brightness_test/b_1.0.jpg
heic2jpg -b 1.15 photo.heic -o brightness_test/b_1.15.jpg
heic2jpg -b 1.25 photo.heic -o brightness_test/b_1.25.jpg
heic2jpg -b 1.35 photo.heic -o brightness_test/b_1.35.jpg

# View all
open brightness_test/
```

---

## Best Practices

### ✅ DO

- Use default (1.15) for iPhone photos
- Test on a representative sample before batch processing
- Use verbose mode (`-v`) to verify settings
- Adjust based on lighting conditions
- Keep originals until satisfied with output

### ❌ DON'T

- Don't use very high values (>1.5) unless necessary
- Don't apply to already-processed images
- Don't forget to check highlights in bright images
- Don't use the same setting for all image types
- Don't delete originals before reviewing output

---

## Command Reference

### Quick Commands

```bash
# Default (recommended for iPhone)
heic2jpg photo.heic

# No brightness adjustment
heic2jpg -b 1.0 photo.heic

# Bright adjustment for dark photos
heic2jpg -b 1.25 photo.heic

# Batch with brightness
heic2jpg -b 1.15 -r ./photos

# Verbose mode to see brightness applied
heic2jpg -v -b 1.2 photo.heic

# Test multiple brightness levels
for b in 1.0 1.1 1.15 1.2 1.25; do
  heic2jpg -b $b photo.heic -o "photo_b${b}.jpg"
done
```

---

## Getting Help

If you're unsure what brightness to use:

1. **Check your images:**
   ```bash
   sips -g space ~/Downloads/photo.heic
   # If "profile: Display P3" → use 1.15 (default)
   # If "profile: sRGB" → use 1.0
   ```

2. **Try verbose mode:**
   ```bash
   heic2jpg -v photo.heic
   ```

3. **Compare outputs:**
   Convert with 1.0, 1.15, and 1.25 to see what looks best

4. **Read the full docs:**
   - [README.md](README.md)
   - [QUICK_START.md](QUICK_START.md)
   - [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

**Remember:** The goal is to produce JPG images that look similar to the original HEIC when viewed on standard displays. The default 1.15x brightness achieves this for most iPhone photos!