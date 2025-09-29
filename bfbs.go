//
// B F B S . G O
//
// bfbs.go last edited on Mon Sep 29 18:18:29 2025
//
// This script reads one or more CSV files, containing one or more columns of
// numbers and calculates basic statistics for each column (including sum,
// average, variance and standard deviation) and outputs the results.
//
// This code is the results of the following ChatGPT prompts; -
//  1. Please write a golang program that reads one or more
//  comma separated value data files containing one or more
//  columns of numbers and calculates the sum, mean, variance
//  and standard deviation for each column using the arbitrary-
//  precision floating point arithmetic package math/big
//  and writes out the results grouped by column number.
//  2. Please adjust the code to tolerate leading spaces in front
//  of the numbers.
//  3. Please adjust the code so that when more than one file is provided
//  that the stats are reset for the new files data columns
//  and also output the name of each file as it is processed.
//  4. Please enhance the code to include column headers if they exist,
//  and to handle blank rows and handle missing values more gracefully.
//  5. Please enhance the code to ignore lines that begin with the hash
//  character as comment lines and allow a number of lines at the
//  start of each file to be skipped as specified by a command line
//  option.
//  6. Running the code with --headers code gives the following error:
//  >bfbs.exe --headers data.csv
//  Processing file: data.csv
//  2025/09/01 21:34:52 Error reading header in data.csv: record on line 2: wrong number of fields
//  7. Please provide a --precision option to control the precision of
//  the conversion and calculations and provide a --output_digits option
//  to control how many digits are output in the results.
//  8. Please add min, median, max, range, skew, kurtosis as additional statistics
//  9. Please add output to a CSV file.
//  10. Please add an option to show the output on scientific format.
//  11. Please add an announcement info at the start of output that has
//  the program name and version number, then the version of golang
//  that built the code and then the version numbers of the packages
//  used if they exist and finally output the precision and output
//  digits being used.
//

// Note that the math/big package does not provide functions for
// skewness and kurtosis so these are calculated using float64
// approximations which may be less accurate for very large or
// very small numbers.

// This code has been tested on Windows 10 with Go 1.25.0 and
// appears to work correctly. It also builds and appears to work
// correctly with Go 1.25.0 on MacOS Sequoia. It should work on
// any platform that supports Go and the math/big package.

// v0.0.7 2025-09-29 Added --quiet option and rearranged CSV output order.
// v0.0.6 2025-09-12 Added Big kurtosis & skewness calculation and output.

package main

import (
	"encoding/csv"
	"flag"
	"fmt"
	"log"
	"math"
	"math/big"
	"os"
	"runtime"
	"sort"
	"strings"
)

const (
	programName    = "bfbs"
	programVersion = "v0.0.7"
)

type ColumnStats struct {
	Header   string
	Values   []*big.Float
	Sum      *big.Float
	Mean     *big.Float
	Var      *big.Float
	StdDev   *big.Float
	VarN     *big.Float
	StdDevN  *big.Float
	Min      *big.Float
	Max      *big.Float
	Median   *big.Float
	Range    *big.Float
	SkewBig  *big.Float
	KurtBig  *big.Float
	Skew     float64
	Kurtosis float64
}

func main() {
	headersFlag := flag.Bool("headers", false, "Indicates that the first non-skipped row of the CSV contains headers")
	skipLines := flag.Int("skip", 0, "Number of lines to skip at the start of each file (before headers or data)")
	precisionFlag := flag.Int("precision", 256, "Floating-point precision (in bits) for calculations")
	outputDigits := flag.Int("output_digits", 64, "Number of digits to show in output")
	outputCSV := flag.String("out", "", "Write computed statistics to a CSV file")
	scientificFlag := flag.Bool("scientific", false, "Show numeric output in scientific notation")
	quietFlag := flag.Bool("quiet", false, "Suppress version output")

	flag.Parse()
	files := flag.Args()

	if !*quietFlag {
		fmt.Printf("%s %s\n", programName, programVersion)
		fmt.Printf("Built with Go version: %s\n", runtime.Version())
	}
	// Note: math/big is part of the Go standard library so no version number
	fmt.Printf("Using %d bits calculation precision", *precisionFlag)
	fmt.Printf(" and %d digits output precision\n", *outputDigits)

	// Check for input files
	if len(files) == 0 {
		fmt.Fprintf(os.Stderr, "\nError: No input files specified. Please provide at least one file name.\n")
		fmt.Fprintf(os.Stderr, "Usage: %s [options] <file1.csv> [<file2.csv> ...]\n", os.Args[0])
		log.Fatalf(" run  %s --help  to see the available options", os.Args[0])
	}

	// Prepare CSV output if requested
	var outFile *os.File
	var csvWriter *csv.Writer
	if *outputCSV != "" {
		var err error
		outFile, err = os.Create(*outputCSV)
		if err != nil {
			log.Fatalf("\nError: Failed to create output CSV file: %v", err)
		}
		defer outFile.Close()

		csvWriter = csv.NewWriter(outFile)
		defer csvWriter.Flush()

		// Write CSV header
		csvWriter.Write([]string{
			"File", "Column", "Count", "Min", "Mean", "Median", "Max", "Range", "Sum", "Variance", "StdDev",
			"Skew", "Kurtosis",
		})
	}

	// Process each file
	for _, filename := range files {
		fmt.Printf("\nInfo: Processing file: \"%s\"\n", filename)

		file, err := os.Open(filename)
		if err != nil {
			fmt.Fprintf(os.Stderr, "\nError: Failed to open file named \"%s\": %v\n", filename, err)
			continue
		} else {
			defer file.Close()
		}

		reader := csv.NewReader(file)
		reader.LazyQuotes = true
		reader.FieldsPerRecord = -1

		var headers []string
		var columns = make(map[int]*ColumnStats)

		linesRead := 0
		for linesRead < *skipLines {
			_, err := reader.Read()
			if err != nil {
				log.Fatalf("Error skipping line %d in %s: %v", linesRead+1, filename, err)
			}
			linesRead++
		}

		if *headersFlag {
			for {
				record, err := reader.Read()
				if err != nil {
					log.Fatalf("Error reading header in %s: %v", filename, err)
				}
				linesRead++

				if isCommentOrBlank(record) {
					continue
				}

				headers = record
				break
			}
		}

		rowIndex := linesRead
		for {
			record, err := reader.Read()
			if err != nil {
				break
			}
			rowIndex++

			if isCommentOrBlank(record) {
				continue
			}

			for i, field := range record {
				trimmed := strings.TrimSpace(field)
				if trimmed == "" {
					continue
				}

				val, _, err := big.ParseFloat(trimmed, 10, uint(*precisionFlag), big.ToNearestEven)
				if err != nil {
					fmt.Fprintf(os.Stderr, "Warning: skipping invalid value '%s' at row %d, column %d in file %s\n",
						field, rowIndex, i+1, filename)
					continue
				}

				if _, exists := columns[i]; !exists {
					header := fmt.Sprintf("Column %d", i+1)
					if i < len(headers) {
						header = strings.TrimSpace(headers[i])
					}
					columns[i] = &ColumnStats{
						Header:  header,
						Min:     newFloatWithPrec(*precisionFlag),
						Mean:    newFloatWithPrec(*precisionFlag),
						Max:     newFloatWithPrec(*precisionFlag),
						Sum:     newFloatWithPrec(*precisionFlag),
						Var:     newFloatWithPrec(*precisionFlag),
						StdDev:  newFloatWithPrec(*precisionFlag),
						VarN:    newFloatWithPrec(*precisionFlag),
						StdDevN: newFloatWithPrec(*precisionFlag),
						SkewBig: newFloatWithPrec(*precisionFlag),
						KurtBig: newFloatWithPrec(*precisionFlag),
					}
				}

				columns[i].Values = append(columns[i].Values, val)
				columns[i].Sum.Add(columns[i].Sum, val)
			}
		}

		// Calculate stats
		for i := 0; i < len(columns); i++ {
			stats, ok := columns[i]
			if !ok || len(stats.Values) == 0 {
				fmt.Printf("  %s: No valid data\n", getColumnName(headers, i))
				continue
			}

			n := newFloatWithPrec(*precisionFlag).SetFloat64(float64(len(stats.Values)))
			stats.Mean.Quo(stats.Sum, n)

			sumSquares := newFloatWithPrec(*precisionFlag)
			sumCubes := newFloatWithPrec(*precisionFlag)
			sum4thPowers := newFloatWithPrec(*precisionFlag)
			for _, x := range stats.Values {
				diff := newFloatWithPrec(*precisionFlag).Sub(x, stats.Mean)
				square := newFloatWithPrec(*precisionFlag).Mul(diff, diff)
				sumSquares.Add(sumSquares, square)
				cube := newFloatWithPrec(*precisionFlag).Mul(square, diff)
				sumCubes.Add(sumCubes, cube)
				fourthPower := newFloatWithPrec(*precisionFlag).Mul(cube, diff)
				sum4thPowers.Add(sum4thPowers, fourthPower)
			}

			if len(stats.Values) <= 1 {
				stats.Var.SetFloat64(0)
				stats.StdDev.SetFloat64(0)
				stats.SkewBig.SetFloat64(0)
			} else {
				nMinus1 := newFloatWithPrec(*precisionFlag).Sub(n, big.NewFloat(1))
				stats.Var.Quo(sumSquares, nMinus1)
				stats.StdDev.Sqrt(stats.Var)
				stats.VarN.Quo(sumSquares, n)
				stats.StdDevN.Sqrt(stats.VarN)
				stats.SkewBig.Quo(sumCubes, n)
				stats.SkewBig.Quo(stats.SkewBig, stats.VarN)
				stats.SkewBig.Quo(stats.SkewBig, stats.StdDevN)
				stats.KurtBig.Quo(sum4thPowers, n)
				stats.KurtBig.Quo(stats.KurtBig, stats.VarN)
				stats.KurtBig.Quo(stats.KurtBig, stats.VarN)
				stats.KurtBig.Sub(stats.KurtBig, big.NewFloat(3)) // Excess kurtosis
			}

			// Sort values for median, min, max
			sorted := make([]*big.Float, len(stats.Values))
			copy(sorted, stats.Values)
			sort.Slice(sorted, func(i, j int) bool {
				return sorted[i].Cmp(sorted[j]) < 0
			})

			stats.Min = sorted[0]
			stats.Max = sorted[len(sorted)-1]
			stats.Range = newFloatWithPrec(*precisionFlag).Sub(stats.Max, stats.Min)

			// Median
			mid := len(sorted) / 2
			if len(sorted)%2 == 1 {
				stats.Median = sorted[mid]
			} else {
				sum := newFloatWithPrec(*precisionFlag).Add(sorted[mid-1], sorted[mid])
				stats.Median = newFloatWithPrec(*precisionFlag).Quo(sum, big.NewFloat(2))
			}

			// Skewness and Kurtosis (using float64 approximation)
			floatVals := make([]float64, len(stats.Values))
			for i, v := range stats.Values {
				f64, _ := v.Float64()
				floatVals[i] = f64
			}

			stats.Skew = calcSkewness(floatVals)
			stats.Kurtosis = calcKurtosis(floatVals)

			// Determine output format for big.Float numbers
			var format byte
			if *scientificFlag {
				format = 'e' // scientific notation
			} else {
				format = 'g' // fixed decimal or scientific based on size
			}

			// Output results to stdout
			fmt.Printf("%s:\n", stats.Header)
			fmt.Printf("  Count      : %s\n", n.Text('g', -1))
			fmt.Printf("  Min        : %s\n", stats.Min.Text(format, *outputDigits))
			fmt.Printf("  Mean       : %s\n", stats.Mean.Text(format, *outputDigits))
			fmt.Printf("  Median     : %s\n", stats.Median.Text(format, *outputDigits))
			fmt.Printf("  Max        : %s\n", stats.Max.Text(format, *outputDigits))
			fmt.Printf("  Range      : %s\n", stats.Range.Text(format, *outputDigits))
			fmt.Printf("  Sum        : %s\n", stats.Sum.Text(format, *outputDigits))
			fmt.Printf("  Variance   : %s\n", stats.Var.Text(format, *outputDigits))
			fmt.Printf("  Std. Dev.  : %s\n", stats.StdDev.Text(format, *outputDigits))
			fmt.Printf("  VarianceN  : %s\n", stats.VarN.Text(format, *outputDigits))
			fmt.Printf("  Std. Dev.N : %s\n", stats.StdDevN.Text(format, *outputDigits))
			fmt.Printf("  Skewness   : %s\n", stats.SkewBig.Text(format, *outputDigits))
			fmt.Printf("  Excess Kurt: %s\n", stats.KurtBig.Text(format, *outputDigits))
			fmt.Printf("  f64 Skew   : %.6f\n", stats.Skew)
			fmt.Printf("  f64 Kurt   : %.6f\n", stats.Kurtosis)
			fmt.Println()

			// Output results to CSV if requested
			if csvWriter != nil {
				csvWriter.Write([]string{
					filename,
					stats.Header,
					n.Text('g', -1),
					stats.Min.Text(format, *outputDigits),
					stats.Mean.Text(format, *outputDigits),
					stats.Median.Text(format, *outputDigits),
					stats.Max.Text(format, *outputDigits),
					stats.Range.Text(format, *outputDigits),
					stats.Sum.Text(format, *outputDigits),
					stats.Var.Text(format, *outputDigits),
					stats.StdDev.Text(format, *outputDigits),
					fmt.Sprintf("%.6f", stats.Skew),
					fmt.Sprintf("%.6f", stats.Kurtosis),
				})
			}

		}
	}
}

// Helper: create *big.Float with user-specified precision
func newFloatWithPrec(p int) *big.Float {
	return new(big.Float).SetPrec(uint(p))
}

// Helper: get column name or fallback
func getColumnName(headers []string, index int) string {
	if index < len(headers) {
		return strings.TrimSpace(headers[index])
	}
	return fmt.Sprintf("Column %d", index+1)
}

// Helper: detect blank or comment lines
func isCommentOrBlank(record []string) bool {
	if len(record) == 0 {
		return true
	}
	firstField := strings.TrimSpace(record[0])
	if strings.HasPrefix(firstField, "#") {
		return true
	}
	for _, field := range record {
		if strings.TrimSpace(field) != "" {
			return false
		}
	}
	return true
}

func calcSkewness(data []float64) float64 {
	n := float64(len(data))
	if n < 3 {
		return 0
	}
	mean := mean(data)
	std := stddev(data)
	var skew float64
	for _, x := range data {
		skew += math.Pow((x-mean)/std, 3)
	}
	return skew * (n / ((n - 1) * (n - 2)))
}

func calcKurtosis(data []float64) float64 {
	n := float64(len(data))
	if n < 4 {
		return 0
	}
	mean := mean(data)
	std := stddev(data)
	var kurt float64
	for _, x := range data {
		kurt += math.Pow((x-mean)/std, 4)
	}
	return (kurt * (n * (n + 1)) / ((n - 1) * (n - 2) * (n - 3))) - (3*(n-1)*(n-1))/((n-2)*(n-3))
}

func mean(data []float64) float64 {
	sum := 0.0
	for _, x := range data {
		sum += x
	}
	return sum / float64(len(data))
}

func stddev(data []float64) float64 {
	m := mean(data)
	var sum float64
	for _, x := range data {
		sum += (x - m) * (x - m)
	}
	return math.Sqrt(sum / float64(len(data)-1))
}
