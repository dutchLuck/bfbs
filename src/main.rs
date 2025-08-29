//
// B F B S . R S
//
// main.rs last edited on Fri Aug 29 22:55:46 2025
//
// This ChatGPT code appears to calculate test cases correctly
// However cargo did not successfully compile the needed 
// dependencies on Windows, like it did on linux and MacOS.
//
// requires Cargo.toml as follows; -
// [package]
// name = "bfbs"
// version = "0.1.0"
// edition = "2024"
//
// [dependencies]
// csv = "1"
// rug = "1"
// clap = { version = "4", features = ["derive"] }
//
//
use clap::Parser;
use csv::ReaderBuilder;
use std::io::{BufRead, BufReader};
use rug::{Float};
use std::collections::HashMap;
use std::fs::File;
use std::path::PathBuf;

/// Default precision to use for calculations (in bits)
const DEFAULT_PRECISION: u32 = 160;

/// Command-line arguments
#[derive(Parser, Debug)]
#[command(name = "CSV Stats")]
#[command(about = "Calculate stats (sum, mean, variance, stddev) from CSV columns")]
struct Args {
    /// Input CSV files
    #[arg(required = true)]
    files: Vec<PathBuf>,

    /// Comment line prefix character
    #[arg(short = 'c', long = "comment_char", default_value = "#")]
    comment_char: char,

    /// Specify if the CSV has a header row
    #[arg(short = 'H', long = "header")]
    has_header: bool,

    /// Bit precision for calculations (between 16 and 1024)
    #[arg(short = 'P', long = "precision", default_value_t = DEFAULT_PRECISION,
        value_parser = clap::value_parser!(u32).range(16..=1024))]
    precision: u32,

    /// Number of lines to skip at the start of each file
    #[arg(short = 's', long = "skip", default_value_t = 0)]
    skip_lines: usize,
}

#[derive(Debug)]
struct ColumnStats {
    count: usize,
    sum: Float,
    values: Vec<Float>,
}

impl ColumnStats {
    fn new(precision: u32) -> Self {
        Self {
            count: 0,
            sum: Float::with_val(precision, 0),
            values: Vec::new(),
        }
    }

    fn add(&mut self, value: Float) {
        self.sum += &value;
        self.values.push(value);
        self.count += 1;
    }

    fn sum(&self, _precision: u32) -> &Float {
        &self.sum
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
            .map(|i| format!("col{}", i))
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
    let args = Args::parse();

    for file in args.files.iter() {
        println!("Processing file: {:?}", file);
        println!("Using precision: {} bits\n", args.precision);
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
                    println!("  Count   : {}", data.count);
                    println!("  Sum     : {}", data.sum(args.precision).to_string_radix(10, None));
                    println!("  Mean    : {}", data.mean(args.precision).to_string_radix(10, None));
                    println!(
                        "  Variance: {}",
                        data.variance(args.precision).to_string_radix(10, None)
                    );
                    println!(
                        "  StdDev  : {}",
                        data.stddev(args.precision).to_string_radix(10, None)
                    );
                    println!();
                }
            }
            Err(e) => eprintln!("Error processing {:?}: {}\n", file, e),
        }
    }
}
