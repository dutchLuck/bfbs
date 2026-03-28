#!/usr/bin/env -S deno run --allow-read

//
// B F B S . T S
//
// bfbs.ts last edited on Sat Mar 28 23:50:51 2026 as version 0.0.3
//

// A Deno script to compute statistics from CSV files with arbitrary precision.

// bfbs.ts originated from free ChatGPT code and is licensed
// under the MIT License. The original prompt was; -
// Please write a javascript script to be executed by deno
// (i.e. command line) that reads one or more comma separated
// value data files containing one or more columns of numbers
// and calculates the min, median, mean, max, range, sum,
// variance and standard deviation for each column using an
// arbitrary-precision floating point arithmetic package and
// writes out the results for each column in each file. Ensure
// that the script can handle leading spaces on numbers, blank
// rows in files and comment lines beginning with a hash. Allow
// the precision to be controlled by the user from the command
// line. Please make the calculated variance the sample form of
// variance i.e. = sum((x - mean)^2) / (n - 1) unless the user
// sets an option in the command line. Please enhance the script
// to handle headers in the top of row of the CSV columns when
// the user flags this in the command line.

// Usage/Help message is; -
// Usage: deno run --allow-read bfbs.ts [options] <file1.csv> [file2.csv...]
// Options:
//   --precision N or -P N   Set decimal precision to N (default is 40)
//   --header or -H   First row contains column headers
//   --help or -h     Show this help message
//   --quiet or -q    Suppress some output information

// 0.0.3 - Check for unknown options. Calc both sample and population
//         variance / standard deviation. Removed --population option.
// 0.0.2 - Added --quiet option to suppress some output information.
// 0.0.1 - Initial version.

import Decimal from "https://esm.sh/decimal.js@10.4.3";

// MARK: Command line parsing

// --------------------
// Command line parsing
// --------------------

interface Options {
  precision: number;
  header: boolean;
  population: boolean;
  quiet: boolean;
  help: boolean;
  files: string[];
}

function parseArgs(args: string[]): Options {
  const options: Options = {
    precision: 40,
    header: false,
    population: false,
    quiet: false,
    help: false,
    files: [],
  };

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];

    if ((arg === "--precision" || arg === "-P") && args[i + 1]) {
      options.precision = parseInt(args[++i], 10);
    } else if (arg === "--header" || arg === "-H") {
      options.header = true;
    } else if (arg === "--quiet" || arg === "-q") {
      options.quiet = true;
    } else if (arg === "--help" || arg === "-h") {
      options.help = true;
    } else if (arg.slice(0, 2) === "--") {
      console.error(`Warning: Ignoring unknown long option: ${arg}`);
    } else if (arg.slice(0, 1) === "-") {
      console.error(`Warning: Ignoring unknown short option: ${arg}`);
    }  else {
      options.files.push(arg);
    }
  }

  if (options.files.length === 0 || options.help ) {
    console.error("Usage: deno run --allow-read bfbs.ts [options] <file1.csv> [file2.csv...]");
    console.error("Options:");
    console.error("  --precision N or -P N   Set decimal precision to N (default is 40)");
    console.error("  --help or -h     Show this help message");
    console.error("  --header or -H   First row contains column headers");
    console.error("  --quiet or -q    Suppress some output information");
    Deno.exit(1);
  }

  return options;
}

const options = parseArgs(Deno.args);

// Configure decimal precision
Decimal.set({ precision: options.precision });

// MARK: Utility functions

// -----------------
// Utility functions
// -----------------

function median(values: Decimal[]): Decimal {
  const sorted = [...values].sort((a, b) => a.comparedTo(b));
  const n = sorted.length;

  if (n === 0) return new Decimal(0);

  if (n % 2 === 0) {
    return sorted[n / 2 - 1].plus(sorted[n / 2]).div(2);
  } else {
    return sorted[Math.floor(n / 2)];
  }
}

function computeStats(values: Decimal[]) {
  const n = values.length;

  if (n === 0) return null;

  const sum = values.reduce((acc, v) => acc.plus(v), new Decimal(0));
  const mean = sum.div(n);

  let variance = new Decimal(0);
  let pvariance = new Decimal(0);

  if (n > 0) {
    const squaredDiffs = values.map(v => v.minus(mean).pow(2));
    const numerator = squaredDiffs.reduce((acc, v) => acc.plus(v), new Decimal(0));
    if (n > 1) {
      variance = numerator.div(n - 1);
    }
    pvariance = numerator.div(n);
  }

  const stddev = variance.sqrt();
  const pstddev = pvariance.sqrt();

  const min = values.reduce((a, b) => Decimal.min(a, b));
  const max = values.reduce((a, b) => Decimal.max(a, b));
  const range = max.minus(min);

  return {
    count: n,
    sum,
    mean,
    median: median(values),
    min,
    max,
    range,
    variance,
    stddev,
    pvariance,
    pstddev
  };
}

// MARK: Process a File

// -------------------
// CSV File Processing
// -------------------

async function processFile(filename: string) {
  const text = await Deno.readTextFile(filename);
  const lines = text.split(/\r?\n/);

  let headers: string[] = [];
  const columns: Decimal[][] = [];

  let firstDataRow = true;

  for (const rawLine of lines) {
    const line = rawLine.trim();

    if (line === "") continue;
    if (line.startsWith("#")) continue;

    const parts = rawLine.split(",");

    if (firstDataRow && options.header) {
      headers = parts.map(h => h.trim());
      firstDataRow = false;
      continue;
    }

    firstDataRow = false;

    parts.forEach((value, i) => {
      const trimmed = value.trim();
      if (trimmed === "") return;

      try {
        const num = new Decimal(trimmed);
        if (!columns[i]) columns[i] = [];
        columns[i].push(num);
      } catch {
        // Ignore non-numeric values
      }
    });
  }

  console.log(`\nProcessing file: ${filename}`);

  columns.forEach((col, i) => {
    const stats = computeStats(col);
    if (!stats) return;

    const name = options.header && headers[i]
      ? headers[i]
      : `Column: ${i + 1}`;

    console.log(`\n${name}`);
    console.log(`Count.       : ${stats.count}`);
    console.log(`Min.         : ${stats.min.toString()}`);
    console.log(`Mean.        : ${stats.mean.toString()}`);
    console.log(`Median.      : ${stats.median.toString()}`);
    console.log(`Max.         : ${stats.max.toString()}`);
    console.log(`Range.       : ${stats.range.toString()}`);
    console.log(`Sum.         : ${stats.sum.toString()}`);
    console.log(`Variance (s²): ${stats.variance.toString()}`);
    console.log(`Std. Dev. (s): ${stats.stddev.toString()}`);
    console.log(`Variance (σ²): ${stats.pvariance.toString()}`);
    console.log(`Std. Dev. (σ): ${stats.pstddev.toString()}`);
  });
}

// MARK: Main processing loop

// ------------------------
// Run main processing loop
// ------------------------

const start = performance.now();
if (!options.quiet) {
  console.log("bfbs.ts version 0.0.3");
  console.log(`Processing files with ${options.precision} digits of precision `);
}

for (const file of options.files) {
  try {
    await processFile(file);
  } catch (error) {
    if (error instanceof Deno.errors.NotFound) {
      console.error(`\nWarning: Unable to find File named "${file}", as it does not exist.`);
    } else if (error instanceof Deno.errors.PermissionDenied) {
      console.error(`\nWarning: Permission denied for file named "${file}" on read attempt.`);
    } else if (error instanceof Deno.errors.IsADirectory) {
      console.error(`\nWarning: Skipping file named "${file}" as it is a directory.`);
    } else {
      throw error;
    }
  }
}

if (!options.quiet) {
  const end = performance.now();
  console.log(`\nbfbs.ts processing took ${(end - start).toFixed(2)} [mS].`);
}
