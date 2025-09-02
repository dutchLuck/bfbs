//
//
// B F B S . G O
//
// bfbs.go last edited on Sun Aug 24 18:34:41 2025
//
// This script reads a headerless CSV file, calculates statistics for each column
// (including sum, average, variance and standard deviation) and outputs the results.
//
// Results of ChatGPT prompt; -
//  1. Please write a golang program that reads
//  one or more comma separated value data files
//  containing one or more columns of numbers
//  and calculates the sum, mean, variance
//  and standard deviation for each column
//  using the arbitrary-precision floating point
//  arithmetic package math/big
//  and writes out the results grouped by column number.
//  2. Please adjust the code to tolerate leading
//  spaces in front of the numbers.
//  3. Please adjust the code so that when more than one file is provided
//  that the stats are reset for the new files data columns
//  and also output the name of each file as it is processed.
//  4. Please enhance the code to include column headers if they exist,
//  and to handle blank rows and handle missing values more gracefully.
//  5. Please enhance the code to ignore lines that
//  begin with the hash character as comment lines
//  and allow a number of lines at the start of each file
//  to be skipped as specified by a command line option.
//  6. Running the code with --headers code gives the following error:
//  >bfbs.exe --headers data.csv
//  Processing file: data.csv
//  2025/09/01 21:34:52 Error reading header in data.csv: record on line 2: wrong number of fields
//

package main

import (
	"encoding/csv"
	"flag"
	"fmt"
	"log"
	"math/big"
	"os"
	"strings"
)

const (
	programName    = "bfbs.go"
	programVersion = "v0.0.4"
)

// ColumnStats holds data and stats for a single column
type ColumnStats struct {
	Header string
	Values []*big.Float
	Sum    *big.Float
	Mean   *big.Float
	Var    *big.Float
	StdDev *big.Float
}

func main() {
	headersFlag := flag.Bool("headers", false, "Indicates that the first non-skipped row of the CSV contains headers")
	skipLines := flag.Int("skip", 0, "Number of lines to skip at the start of each file (before headers or data)")
	flag.Parse()
	files := flag.Args()

	fmt.Printf("%s %s\n", programName, programVersion)

	if len(files) == 0 {
		log.Fatalf("Usage: %s [--headers] [--skip N] <file1.csv> [file2.csv] ...", os.Args[0])
	}

	for _, filename := range files {
		fmt.Printf("Processing file: %s\n", filename)

		file, err := os.Open(filename)
		if err != nil {
			log.Fatalf("Failed to open file %s: %v", filename, err)
		}
		defer file.Close()

		reader := csv.NewReader(file)
		reader.LazyQuotes = true
		reader.FieldsPerRecord = -1

		var headers []string
		var columns = make(map[int]*ColumnStats)

		// Skip specified number of lines
		linesRead := 0
		for linesRead < *skipLines {
			_, err := reader.Read()
			if err != nil {
				log.Fatalf("Error skipping line %d in %s: %v", linesRead+1, filename, err)
			}
			linesRead++
		}

		// Read headers if needed
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
				break // EOF
			}
			rowIndex++

			if isCommentOrBlank(record) {
				continue
			}

			for i, field := range record {
				trimmed := strings.TrimSpace(field)
				if trimmed == "" {
					continue // skip blank/missing
				}

				val, _, err := big.ParseFloat(trimmed, 10, 256, big.ToNearestEven)
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
						Header: header,
						Sum:    big.NewFloat(0),
						Mean:   big.NewFloat(0),
						Var:    big.NewFloat(0),
						StdDev: big.NewFloat(0),
					}
				}

				columns[i].Values = append(columns[i].Values, val)
				columns[i].Sum.Add(columns[i].Sum, val)
			}
		}

		// Compute and print stats
		for i := 0; i < len(columns); i++ {
			stats, ok := columns[i]
			if !ok || len(stats.Values) == 0 {
				fmt.Printf("  %s: No valid data\n", getColumnName(headers, i))
				continue
			}

			n := big.NewFloat(float64(len(stats.Values)))
			stats.Mean.Quo(stats.Sum, n)

			sumSquares := big.NewFloat(0)
			for _, x := range stats.Values {
				diff := new(big.Float).Sub(x, stats.Mean)
				square := new(big.Float).Mul(diff, diff)
				sumSquares.Add(sumSquares, square)
			}

			if len(stats.Values) <= 1 {
				stats.Var.SetFloat64(0)
				stats.StdDev.SetFloat64(0)
			} else {
				nMinus1 := new(big.Float).Sub(n, big.NewFloat(1))
				stats.Var.Quo(sumSquares, nMinus1)
				stats.StdDev.Sqrt(stats.Var)
			}

			// Output stats
			fmt.Printf("  %s:\n", stats.Header)
			fmt.Printf("    Count:  %s\n", n.Text('f', -1))
			fmt.Printf("    Sum:    %s\n", stats.Sum.Text('f', -1))
			fmt.Printf("    Mean:   %s\n", stats.Mean.Text('f', -1))
			fmt.Printf("    Var:    %s\n", stats.Var.Text('f', -1))
			fmt.Printf("    StdDev: %s\n", stats.StdDev.Text('f', -1))
			fmt.Println()
		}
	}
}

// Returns the header name or a fallback column label
func getColumnName(headers []string, index int) string {
	if index < len(headers) {
		return strings.TrimSpace(headers[index])
	}
	return fmt.Sprintf("Column %d", index+1)
}

// Checks if a CSV record is blank or a comment
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
