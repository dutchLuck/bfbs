//
// B F B S . S W I F T
//
// bfbs.swift last edited on Wed Mar 18 14:41:34 2026
//
// Arbitrary Precision Basic Statistics for one or more
// files of one or more CSV columns. This version uses
// MPFR and GMP libraries for calculations.
//

import Foundation
import CMPFR


let PROGRAM_NAME = "bfbs_swift"
let PROGRAM_VERSION = "0v1 (2026-03-18)"


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
        case "--precision":
            i += 1
            opts.precision = Int32(args[i])!
        case "--digits":
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
bfbs_swift file1.csv [file2.csv ...] [--help] [--quiet] [--header] [--precision N] [--digits N]

Options:
  -h --help        Show help / usage information and exit
  -q --quiet       Suppress banner and timing information
  -H --header      First row is column names
  --precision N    MPFR precision bits (default 256)
  --digits N       Output digits (default 64)
""")
        exit(1)
    }

    return opts
}

func printBanner(_ opts: Options) {
    if !opts.quiet {
        print("\(PROGRAM_NAME) version \(PROGRAM_VERSION)")
        print("MPFR version:", String(cString: mpfr_get_version()))
    }

    print("Using \(opts.precision) bit precision and \(opts.digits) output digits\n")
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
    let denominator = MPFRFloat()

    // denominator = sum((x - mean)^2)
    for v in column {
        let diff = v - mean
        let sq = diff * diff
        denominator.add(sq)
    }

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
