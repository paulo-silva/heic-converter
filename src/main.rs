use anyhow::{Context, Result};
use clap::Parser;
use image::DynamicImage;
use indicatif::{MultiProgress, ProgressBar, ProgressStyle};
use rayon::prelude::*;
use std::fs;
use std::path::{Path, PathBuf};
use walkdir::WalkDir;

#[derive(Parser, Debug)]
#[command(
    name = "heic2jpg",
    version = "0.1.0",
    about = "Fast HEIC to JPG converter with multi-core support",
    long_about = "Converts HEIC images to JPG format with configurable compression.\nSupports single files, directories, and recursive directory traversal.\nUtilizes all available CPU cores for maximum performance."
)]
struct Args {
    /// Input path (file or directory)
    #[arg(value_name = "INPUT")]
    input: PathBuf,

    /// Output directory (optional, defaults to same directory as input)
    #[arg(short, long, value_name = "DIR")]
    output: Option<PathBuf>,

    /// JPEG quality (1-100, default: 90)
    #[arg(short, long, default_value = "90", value_parser = clap::value_parser!(u8).range(1..=100))]
    quality: u8,

    /// Brightness adjustment factor (0.5-2.0, default: 1.15 for Display P3 compensation)
    #[arg(short, long, default_value = "1.15")]
    brightness: f32,

    /// Process directories recursively
    #[arg(short, long)]
    recursive: bool,

    /// Number of parallel jobs (default: number of CPU cores)
    #[arg(short, long)]
    jobs: Option<usize>,

    /// Overwrite existing files
    #[arg(long)]
    overwrite: bool,

    /// Verbose output
    #[arg(short, long)]
    verbose: bool,
}

#[derive(Debug)]
struct ConversionTask {
    input_path: PathBuf,
    output_path: PathBuf,
}

#[derive(Debug)]
struct ConversionResult {
    input_path: PathBuf,
    #[allow(dead_code)]
    output_path: PathBuf,
    success: bool,
    error: Option<String>,
}

fn main() -> Result<()> {
    let args = Args::parse();

    // Validate input path
    if !args.input.exists() {
        anyhow::bail!("Input path does not exist: {}", args.input.display());
    }

    // Configure thread pool
    if let Some(jobs) = args.jobs {
        rayon::ThreadPoolBuilder::new()
            .num_threads(jobs)
            .build_global()
            .context("Failed to configure thread pool")?;
    }

    // Collect all HEIC files to process
    let tasks = collect_tasks(&args)?;

    if tasks.is_empty() {
        println!("No HEIC files found to convert.");
        return Ok(());
    }

    println!(
        "Found {} HEIC file(s) to convert (quality: {}, threads: {})",
        tasks.len(),
        args.quality,
        rayon::current_num_threads()
    );

    // Setup progress tracking
    let multi_progress = MultiProgress::new();
    let main_progress = multi_progress.add(ProgressBar::new(tasks.len() as u64));
    main_progress.set_style(
        ProgressStyle::default_bar()
            .template(
                "{spinner:.green} [{elapsed_precise}] [{bar:40.cyan/blue}] {pos}/{len} ({eta})",
            )
            .unwrap()
            .progress_chars("#>-"),
    );

    // Process files in parallel
    let results: Vec<ConversionResult> = tasks
        .par_iter()
        .map(|task| {
            let result = convert_heic_to_jpg(
                &task.input_path,
                &task.output_path,
                args.quality,
                args.brightness,
                args.verbose,
            );

            let conversion_result = match result {
                Ok(_) => ConversionResult {
                    input_path: task.input_path.clone(),
                    output_path: task.output_path.clone(),
                    success: true,
                    error: None,
                },
                Err(e) => ConversionResult {
                    input_path: task.input_path.clone(),
                    output_path: task.output_path.clone(),
                    success: false,
                    error: Some(e.to_string()),
                },
            };

            main_progress.inc(1);
            conversion_result
        })
        .collect();

    main_progress.finish_with_message("Conversion complete!");

    // Print summary
    let success_count = results.iter().filter(|r| r.success).count();
    let failure_count = results.len() - success_count;

    println!("\n=== Conversion Summary ===");
    println!("✓ Successfully converted: {}", success_count);

    if failure_count > 0 {
        println!("✗ Failed: {}", failure_count);
        println!("\nFailed files:");
        for result in results.iter().filter(|r| !r.success) {
            println!(
                "  {} -> {}",
                result.input_path.display(),
                result
                    .error
                    .as_ref()
                    .unwrap_or(&"Unknown error".to_string())
            );
        }
    }

    if failure_count > 0 {
        anyhow::bail!("Some conversions failed");
    }

    Ok(())
}

/// Collects all HEIC files to be converted based on the input arguments
fn collect_tasks(args: &Args) -> Result<Vec<ConversionTask>> {
    let mut tasks = Vec::new();

    if args.input.is_file() {
        // Single file conversion
        if !is_heic_file(&args.input) {
            anyhow::bail!("Input file is not a HEIC file: {}", args.input.display());
        }

        let output_path = determine_output_path(&args.input, args.output.as_deref())?;

        if !args.overwrite && output_path.exists() {
            anyhow::bail!(
                "Output file already exists: {} (use --overwrite to replace)",
                output_path.display()
            );
        }

        tasks.push(ConversionTask {
            input_path: args.input.clone(),
            output_path,
        });
    } else if args.input.is_dir() {
        // Directory conversion
        let walker = if args.recursive {
            WalkDir::new(&args.input).follow_links(false)
        } else {
            WalkDir::new(&args.input).max_depth(1).follow_links(false)
        };

        for entry in walker.into_iter().filter_map(|e| e.ok()) {
            let path = entry.path();

            if path.is_file() && is_heic_file(path) {
                let output_path = if let Some(output_dir) = &args.output {
                    // Calculate relative path from input directory
                    let relative = path
                        .strip_prefix(&args.input)
                        .context("Failed to calculate relative path")?;

                    let mut out_path = output_dir.join(relative);
                    out_path.set_extension("jpg");
                    out_path
                } else {
                    // Same directory as input
                    let mut out_path = path.to_path_buf();
                    out_path.set_extension("jpg");
                    out_path
                };

                if args.overwrite || !output_path.exists() {
                    tasks.push(ConversionTask {
                        input_path: path.to_path_buf(),
                        output_path,
                    });
                } else if args.verbose {
                    println!("Skipping (already exists): {}", output_path.display());
                }
            }
        }
    } else {
        anyhow::bail!("Input path is neither a file nor a directory");
    }

    Ok(tasks)
}

/// Determines the output path for a single file
fn determine_output_path(input: &Path, output: Option<&Path>) -> Result<PathBuf> {
    match output {
        Some(out) => {
            if out.is_dir() {
                // Output is a directory, place file there with same name
                let file_name = input.file_stem().context("Invalid input file name")?;
                Ok(out.join(file_name).with_extension("jpg"))
            } else {
                // Output is a file path
                Ok(out.to_path_buf())
            }
        }
        None => {
            // Same directory as input, just change extension
            Ok(input.with_extension("jpg"))
        }
    }
}

/// Checks if a file has a HEIC extension
fn is_heic_file(path: &Path) -> bool {
    if let Some(ext) = path.extension() {
        let ext_lower = ext.to_string_lossy().to_lowercase();
        ext_lower == "heic" || ext_lower == "heif"
    } else {
        false
    }
}

/// Converts a single HEIC file to JPG
fn convert_heic_to_jpg(
    input_path: &Path,
    output_path: &Path,
    quality: u8,
    brightness: f32,
    verbose: bool,
) -> Result<()> {
    if verbose {
        println!(
            "Converting: {} -> {}",
            input_path.display(),
            output_path.display()
        );
    }

    // Create output directory if it doesn't exist
    if let Some(parent) = output_path.parent() {
        fs::create_dir_all(parent).context(format!(
            "Failed to create output directory: {}",
            parent.display()
        ))?;
    }

    // Read and decode HEIC file
    let img_data = fs::read(input_path).context(format!(
        "Failed to read input file: {}",
        input_path.display()
    ))?;

    let ctx = libheif_rs::HeifContext::read_from_bytes(&img_data)
        .context("Failed to read HEIC context")?;

    let handle = ctx
        .primary_image_handle()
        .context("Failed to get primary image handle")?;

    // Decode to RGB
    let img = libheif_rs::LibHeif::new();
    let decoded = img
        .decode(
            &handle,
            libheif_rs::ColorSpace::Rgb(libheif_rs::RgbChroma::Rgb),
            None,
        )
        .context("Failed to decode HEIC image")?;

    let width = decoded.width();
    let height = decoded.height();

    if verbose {
        println!("  Image dimensions: {}x{} pixels", width, height);
    }

    let planes = decoded.planes();
    let interleaved_plane = planes
        .interleaved
        .context("Failed to get interleaved plane")?;

    // Handle stride - the decoded data may have padding at the end of each row
    let stride = interleaved_plane.stride;
    let rgb_data = interleaved_plane.data;
    let expected_size = (width * height * 3) as usize;
    let expected_stride = width * 3;

    if verbose {
        println!(
            "  Buffer info - stride: {}, expected: {}, data size: {}",
            stride,
            expected_stride,
            rgb_data.len()
        );
    }

    // Copy data row by row if stride doesn't match width * 3
    let mut rgb_buffer = if stride as u32 == width * 3 {
        // No padding, use data directly
        if verbose {
            println!("  No stride padding, using data directly");
        }
        rgb_data.to_vec()
    } else {
        // Has padding, need to copy row by row
        if verbose {
            println!(
                "  Handling stride padding ({} bytes per row)",
                stride as u32 - expected_stride
            );
        }
        let mut buffer = Vec::with_capacity(expected_size);
        for y in 0..height {
            let row_start = (y * stride as u32) as usize;
            let row_end = row_start + (width * 3) as usize;
            buffer.extend_from_slice(&rgb_data[row_start..row_end]);
        }
        buffer
    };

    // Apply brightness adjustment for color space compensation (Display P3 to sRGB)
    // Using a tone curve that preserves highlights while brightening midtones/shadows
    if (brightness - 1.0).abs() > 0.001 {
        if verbose {
            println!("  Applying tone curve adjustment: {:.2}x", brightness);
        }

        // Use a power curve that preserves highlights
        // Formula: out = 255 * ((in/255) ^ (1/gamma))
        // where gamma is derived from brightness factor
        let gamma = 2.0 / brightness; // Higher brightness = lower gamma = brighter output

        for pixel in rgb_buffer.iter_mut() {
            let normalized = *pixel as f32 / 255.0;
            // Apply power curve - preserves highlights better than linear multiplication
            let adjusted = (normalized.powf(1.0 / gamma) * 255.0).min(255.0).max(0.0);
            *pixel = adjusted as u8;
        }
    }

    let img_buffer = image::RgbImage::from_raw(width, height, rgb_buffer)
        .context("Failed to create RGB image buffer")?;

    let dynamic_img = DynamicImage::ImageRgb8(img_buffer);

    // Save as JPEG with specified quality
    let mut output_file = fs::File::create(output_path).context(format!(
        "Failed to create output file: {}",
        output_path.display()
    ))?;

    let encoder = image::codecs::jpeg::JpegEncoder::new_with_quality(&mut output_file, quality);
    dynamic_img
        .write_with_encoder(encoder)
        .context("Failed to encode JPEG")?;

    if verbose {
        println!("✓ Completed: {}", output_path.display());
    }

    Ok(())
}
