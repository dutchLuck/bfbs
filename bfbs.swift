//
// B F B S . S W I F T
//
// bfbs.swift last edited on Sun Apr  5 21:20:26 2026 as 0v2
//
// Arbitrary Precision Basic Statistics for one or more
// files of one or more CSV columns. This version uses
// MPFR and GMP libraries for calculations.
//

// This program is free software: you can redistribute it and/or modify it.
// It is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
// without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
// This program was largley written by free A.I. It is not a product of any company or
// organization and is intended for (self) education and non-commercial use.

// The libraries used by this program (MPFR and GMP) are also free software, licensed under the LGPL.
// ( MPFR: https://www.mpfr.org/ and GMP: https://gmplib.org/ ) 
// It is assumed that the user has these libraries installed and properly configured. On Apple
// MacOS, these can be installed via Homebrew with "brew install mpfr gmp" and on (Ubuntu) Linux with
// "sudo apt install libmpfr-dev libgmp-dev". The C header files and libraries must be accessible to
// the Swift compiler.

// 0v3 (2026-04-05) - Attempted to speed up the autocorrelation calculation.
// 0v2 (2026-04-05) - Added -P & -p options and print out for mantissa bits conversion to approx decimal places.
// 0v1 (2026-03-18) - Initial version: Only known to compile and run on Apple Silicon MacOS.

// Short-comings; -
// CMPFR has copies of mpfr.h and gmp.h with local references so manual update is required if MPFR or GMP is updated.
// Doesn't have a skip lines at start of file option (e.g. for NIST files).
// Doesn't calculate standard error.
// Doesn't have an option to specify which columns to process (e.g. for files with many columns where only a few are of interest).
// - No error handling for invalid CSV files or non-numeric data (except skipping non-numeric lines)
// - No support for quoted CSV fields with embedded commas
// - No support for locale-specific number formats (e.g. 1.234,56 in some European locales)
//


import Foundation
import CMPFR


let PROGRAM_NAME = "bfbs_swift"
let PROGRAM_VERSION = "0v3 (2026-04-05)"


struct Options {
    var precision: Int32 = 256
    var digits: Int32 = 64
    var hasHeader = false
    var quiet = false
    var help = false
    var files: [String] = []
}

// MARK: - parse arguments

func parseArgs() -> Options {
    var opts = Options()
    var i = 1

    let args = CommandLine.arguments

    while i < args.count {
        let arg = args[i]

        switch arg {
        case "-P", "--precision":
            i += 1
            opts.precision = Int32(args[i])!
        case "-p", "--print_digits":
            i += 1
            opts.digits = Int32(args[i])!
        case "-H", "--header":
            opts.hasHeader = true
        case "-q", "--quiet":
            opts.quiet = true
        case "-h", "--help":
            opts.help = true
        default:
            if arg.hasPrefix("-") {
                print("Warning: unknown option \(arg)")
            } else {
                opts.files.append(arg)
            }
        }

        i += 1
    }

    if opts.files.isEmpty || opts.help {
        print("""
Usage:
bfbs_swift file1.csv [file2.csv ...] [--help] [--quiet] [--header] [--precision N] [--print_digits N]

Options:
  -h or --help            Show help / usage information and exit
  -q or --quiet           Suppress banner and timing information
  -H or --header          First CSV row is column names
  -P or --precision N     Use N mantissa bits in MPFR calculations (default 256)
  -p or --print_digits N  Use up to N digits in printed output (default 64)
""")
        exit(1)
    }

    return opts
}

func printBanner(_ opts: Options) {
    if !opts.quiet {
        print("\(PROGRAM_NAME) version \(PROGRAM_VERSION)")
        print("Info: MPFR version:", String(cString: mpfr_get_version()))
    }

    print("Info: Using \(opts.precision) bit mantissa precision (about \(Int(floor(Double(opts.precision) * log10(2)))) decimal digits)")
    print("Info: Using \(opts.digits) output digits\n")
}

// MARK: - read and process CSV

func readCSV(
    file: String,
    columns: inout [[MPFRFloat]],
    headers: inout [String],
    opts: Options
) throws {

    let text = try String(contentsOfFile: file, encoding: .utf8)

    var firstLine = true

    for rawLine in text.components(separatedBy: .newlines) {

        let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)

        if line.isEmpty { continue }
        if line.first == "#" { continue }

        // Skip clearly non-numeric lines (e.g. NIST headers) unless it's the first line and --header is specified
        if !(firstLine && opts.hasHeader) &&
            line.rangeOfCharacter(from: CharacterSet(charactersIn: "0123456789.-")) == nil {
            continue
        }

        let cells: [String]

        if line.contains(",") {
            // CSV
            cells = line.split(separator: ",", omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespaces) }
        } else {
            // whitespace-separated
            cells = line.split(whereSeparator: { $0.isWhitespace })
                .map { String($0) }
        }

        if firstLine && opts.hasHeader {
            headers = cells
            firstLine = false
            continue
        }

        if columns.count < cells.count {
            for _ in columns.count..<cells.count {
                columns.append([])
            }
        }

        for (i, cell) in cells.enumerated() {
            let v = MPFRFloat(cell)
            columns[i].append(v)
        }

        firstLine = false
    }
}

func sortColumn(_ col: [MPFRFloat]) -> [MPFRFloat] {
    return col.sorted()
}

// MARK: - compute stats

func computeStats(column: [MPFRFloat], name: String, digits: Int32) {

    let n = column.count
    if n == 0 { return }

    let sorted = column.sorted()

    let sum = MPFRFloat()
    let minVal = MPFRFloat(copy: column[0])
    let maxVal = MPFRFloat(copy: column[0])

    for v in column {

        sum.add(v)

        if v < minVal { minVal.set(v) }
        if v > maxVal { maxVal.set(v) }
    }

    let mean = MPFRFloat(copy: sum)
    mean.divideByUInt(UInt(n))

    let range = maxVal - minVal

    // variance

    let variance = MPFRFloat()

    for v in column {

        let diff = v - mean
        let sq = diff * diff
        variance.add(sq)
    }

    let pVariance = MPFRFloat(copy: variance)
    let denominator = MPFRFloat(copy: variance) // used for denominator in autocorrelation calculation

    if n > 1 {
        variance.divideByUInt(UInt(n-1))
    }

    if n > 0 {
        pVariance.divideByUInt(UInt(n))
    }

    let stddev = variance.sqrt()
    let pStddev = pVariance.sqrt()

    // --- Autocorrelation r(1) ---

    let numerator = MPFRFloat()

    // denominator = sum((x - mean)^2)
    // numerator = sum((xi - mean)*(xi+1 - mean))
    if column.count > 1 {
        for i in 0..<(column.count - 1) {
            let a = column[i] - mean
            let b = column[i + 1] - mean
            let prod = a * b
            numerator.add(prod)
        }
    }

    // r(1) = numerator / denominator
    let autocorr: MPFRFloat
    if column.count > 1 {
    // check denominator != 0
        if denominator == MPFRFloat("0") {
            autocorr = MPFRFloat("0")
        } else {
            autocorr = numerator / denominator
        }
    } else {
        autocorr = MPFRFloat("0")
    }

    let median: MPFRFloat

    if n % 2 == 1 {
        median = sorted[n/2]
    } else {
        median = (sorted[n/2 - 1] + sorted[n/2]) / MPFRFloat("2")
    }

    print("Column:", name)
    print("  Count         :", n)
    print("  Minimum       :", minVal.toString(digits: digits))
    print("  Mean          :", mean.toString(digits: digits))
    print("  Median        :", median.toString(digits: digits))
    print("  Maximum       :", maxVal.toString(digits: digits))
    print("  Range         :", range.toString(digits: digits))
    print("  Sum           :", sum.toString(digits: digits))
    print("  Variance (s\u{00B2}) :", variance.toString(digits: digits))
    print("  Std.Dev. (s)  :", stddev.toString(digits: digits))
    print("  Autocorr r(1) :", autocorr.toString(digits: digits))
    print("  Variance (\u{03C3}\u{00B2}) :", pVariance.toString(digits: digits))
    print("  Std.Dev. (\u{03C3})  :", pStddev.toString(digits: digits))
    print()
}

// MARK: - run program

func runProgram() {

    let start = Date()

    let opts = parseArgs()

    MPFRFloat.defaultPrecision = mpfr_prec_t(opts.precision)

    printBanner(opts)

    for file in opts.files {

        guard FileManager.default.fileExists(atPath: file) else {
            print("\nError: File named \"\(file)\" not found.\n")
            continue
        }

        print("Processing file:", file)

        var columns: [[MPFRFloat]] = []
        var headers: [String] = []

        try! readCSV(file:file, columns:&columns, headers:&headers, opts:opts)

        for i in 0..<columns.count {

            let name = opts.hasHeader && i < headers.count
                ? headers[i]
                : "Column \(i+1)"

            computeStats(column: columns[i], name: name, digits: opts.digits)
        }
    }

    if !opts.quiet {
        let elapsed = Date().timeIntervalSince(start) * 1000
        print(String(format:"Info: bfbs (swift) execution time: %.3f ms", elapsed))
    }

}

// MARK: - Main

@main
struct BFBS {
    static func main() {
        runProgram()
    }
}
