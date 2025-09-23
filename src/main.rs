//
// B F B S . R S
//
// main.rs last edited on Tue Sep 23 23:05:43 2025
//
// This ChatGPT code appears to calculate test cases correctly
// However cargo did not successfully compile the needed 
// dependencies on Windows, like it did on linux and MacOS.
//
// The rug crate provides arbitrary precision calculation
// capability (using gmp-mpfr-sys) and the csv crate provides
// the ability to read in comma separated variable data.
//
// requires Cargo.toml as follows; -
// [package]
// name = "bfbs"
// version = "0.1.3"
// edition = "2024"
//
// [dependencies]
// csv = "1"
// rug = "1"
// clap = { version = "4", features = ["derive"] }
//
// Build with `cargo build --release`
// Run with `cargo run -- <options> <csv file>`
// Options are shown with `cargo run -- --help`
//
// Usage examples:
//   cargo run -- test/heights.csv
//   cargo r -- -P 80 -p 16 -s 60 test/NIST_StRD_NumAcc4.dat
//
// Building on Ubuntu may require installation of m4 (i.e. sudo apt install m4)
// to allow gmp-mpfr-sys to build correctly.
//

//
// v0.1.3 Added minimum, maximum and range to output
//

use clap::Parser;
use csv::ReaderBuilder;
use std::io::{BufRead, BufReader};
use rug::{Float};
use std::collections::HashMap;
use std::fs::File;
use std::path::PathBuf;

/// Default precision to use for calculations (in bits)
const DEFAULT_PRECISION: u32 = 256;
const DEFAULT_DIGITS: usize= 64;

pub const MAIN_NAME: &'static str = env!("CARGO_PKG_NAME");
pub const MAIN_VERSION: &'static str = env!("CARGO_PKG_VERSION");

/// Command-line arguments
#[derive(Parser, Debug)]
#[command(name = "bfbs:")]
#[command(about = "Calculate stats (minimum, mean, maximum, range, sum, variance, stddev) from CSV columns")]
#[clap(author, version, about = None, long_about = None)]
struct Args {
    /// Input CSV files
    #[arg(required = true)]
    files: Vec<PathBuf>,

    /// Comment line prefix character
    #[arg(short = 'c', long = "comment_char", default_value = "#")]
    comment_char: char,

    /// Display numbers using scientific notation
    #[arg(short = 'e', long = "scientific" )]
    scientific: bool,

    /// Specify if the CSV has a header row
    #[arg(short = 'H', long = "header")]
    has_header: bool,

    /// Number of digits to show in output
    #[arg(short = 'p', long = "print_digits", default_value_t = DEFAULT_DIGITS)]
    digits: usize,

    /// Bit precision for calculations (between 16 and 1024)
    #[arg(short = 'P', long = "precision", default_value_t = DEFAULT_PRECISION,
        value_parser = clap::value_parser!(u32).range(16..=1024))]
    precision: u32,

    /// Number of lines to skip at the start of each file
    #[arg(short = 's', long = "skip", default_value_t = 0)]
    skip_lines: usize,

    /// Output extra information
    #[arg(short = 'v', long = "verbose")]
    verbose: bool,
    
}

#[derive(Debug)]
struct ColumnStats {
    count: usize,
    sum: Float,
    max: Float,
    min: Float,
    values: Vec<Float>,
}

impl ColumnStats {
    fn new(precision: u32) -> Self {
        Self {
            count: 0,
            sum: Float::with_val(precision, 0),
            max: Float::with_val(precision, 0),
            min: Float::with_val(precision, 0),
            values: Vec::new(),
        }
    }

    fn add(&mut self, value: Float) {
        self.sum += &value;
        if self.count == 0 {
            self.max = value.clone();
            self.min = value.clone();
        } else {
            if self.max < value {
                self.max = value.clone()
            }
            if self.min > value {
                self.min = value.clone()
            } 
        }
        self.values.push(value);
        self.count += 1;
    }

    fn sum(&self, _precision: u32) -> &Float {
        &self.sum
    }

    fn maximum(&self, _precision: u32) -> &Float {
        &self.max
    }

    fn minimum(&self, _precision: u32) -> &Float {
        &self.min
    }

    fn range(&self, _precision: u32) -> Float {
        &self.max - self.min.clone()
    }

    fn mean(&self, precision: u32) -> Float {
        if self.count == 0 {
            return Float::with_val(precision, 0);
        }
        &self.sum / Float::with_val(precision, self.count)
    }

    fn variance(&self, precision: u32) -> Float {
        if self.count == 0 {
            return Float::with_val(precision, 0);
        }
        let mean = self.mean(precision);
        let mut sum_sq_diff = Float::with_val(precision, 0);
        for v in &self.values {
            let diff = Float::with_val(precision, v - &mean);
            sum_sq_diff += diff.square();
        }
        sum_sq_diff / Float::with_val(precision, self.count - 1)
    }

    fn stddev(&self, precision: u32) -> Float {
        self.variance(precision).sqrt()
    }
}

fn format_float(value: &Float, scientific: bool, digits: usize) -> String {
    if scientific {
        format!("{:.*e}", digits, value)
    } else {
        format!("{:.*}", digits, value)
    }
}

fn process_file(
    path: &PathBuf,
    precision: u32,
    has_header: bool,
    skip_lines: usize,
    comment_char: char,
) -> csv::Result<HashMap<String, ColumnStats>> {
    let file = File::open(path)?;
    let reader = BufReader::new(file);

    // Filter lines: skip blank and comment lines
    let filtered_lines: Vec<String> = reader
        .lines()
        .skip(skip_lines) // Skip N lines at the start
        .filter_map(|line| {
            if let Ok(ref l) = line {
                let trimmed = l.trim();
                if trimmed.is_empty() || trimmed.starts_with(comment_char) {
                    return None;
                }
            }
            line.ok()
        })
        .collect();

    let csv_data = filtered_lines.join("\n");
    let mut rdr = ReaderBuilder::new()
        .has_headers(has_header)
        .from_reader(csv_data.as_bytes());
        
    let headers: Vec<String>;
    let mut stats: HashMap<String, ColumnStats>;

    if has_header {
        let hdrs = rdr.headers()?.clone();
        headers = hdrs.iter().map(|s| s.to_string()).collect();
    } else {
        // Read first record to get column count and generate default headers
        let mut records = rdr.records();
        let first_record = match records.next() {
            Some(Ok(rec)) => rec,
            Some(Err(e)) => return Err(e),
            None => return Ok(HashMap::new()), // empty file
        };

        let col_count = first_record.len();
        headers = (1..=col_count)
            .map(|i| format!("{}", i))
            .collect();

        stats = headers
            .iter()
            .map(|h| (h.clone(), ColumnStats::new(precision)))
            .collect();

        for (header, value_str) in headers.iter().zip(first_record.iter()) {
            if let Ok(value) = Float::parse(value_str) {
                if let Some(col) = stats.get_mut(header) {
                    col.add(Float::with_val(precision, value));
                }
            }
        }

        // Continue with remaining records
        for result in records {
            let record = result?;
            for (header, value_str) in headers.iter().zip(record.iter()) {
                if let Ok(value) = Float::parse(value_str) {
                    if let Some(col) = stats.get_mut(header) {
                        col.add(Float::with_val(precision, value));
                    }
                }
            }
        }

        return Ok(stats);
    }

    // Case: has_header = true
    stats = headers
        .iter()
        .map(|h| (h.clone(), ColumnStats::new(precision)))
        .collect();

    for result in rdr.records() {
        let record = result?;
        for (header, value_str) in headers.iter().zip(record.iter()) {
            if let Ok(value) = Float::parse(value_str) {
                if let Some(col) = stats.get_mut(header) {
                    col.add(Float::with_val(precision, value));
                }
            }
        }
    }

    Ok(stats)
}

fn main() {
    let mut args = Args::parse();
    args.digits = args.digits.clamp(0, 256);    // No user warning, but limit number of digits to output
    args.skip_lines = args.skip_lines.clamp(0, 2048);    // No user warning, but limit skipped input lines

    // Output version and environment information
    println!("{}.rs version v{}", MAIN_NAME, MAIN_VERSION);
    println!(
        "Using {} bit precision for calculation and {} digit {} print out.",
        args.precision, args.digits,
        if args.scientific { "scientific" } else { "decimal" }
    );

    for file in args.files.iter() {
        println!("\nProcessing file: {:?}", file);

        match process_file(
            file,
            args.precision,
            args.has_header,
            args.skip_lines,
            args.comment_char,
        ) {
            Ok(stats) => {
                for (col, data) in stats {
                    println!("Column: {}", col);
                    println!("  Minimum   : {}", format_float(&data.minimum(args.precision), args.scientific, args.digits));
                    println!("  Mean      : {}", format_float(&data.mean(args.precision), args.scientific, args.digits));
                    println!("  Maximum   : {}", format_float(&data.maximum(args.precision), args.scientific, args.digits));
                    println!("  Range     : {}", format_float(&data.range(args.precision), args.scientific, args.digits));
                    println!("  Sum       : {}", format_float(data.sum(args.precision), args.scientific, args.digits));
                    println!("  Variance  : {}", format_float(&data.variance(args.precision), args.scientific, args.digits));
                    println!("  Std. Dev. : {}", format_float(&data.stddev(args.precision), args.scientific, args.digits));
                }
            }
            Err(e) => eprintln!("Error processing {:?}: {}\n", file, e),
        }
    }
}
