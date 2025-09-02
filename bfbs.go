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
	programVersion = "v0.0.2"
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
	headersFlag := flag.Bool("headers", false, "Indicates that the first row of the CSV contains headers")
	flag.Parse()
	files := flag.Args()

	fmt.Printf("%s %s\n", programName, programVersion)

	if len(files) == 0 {
		log.Fatalf("Usage: %s [--headers] <file1.csv> [file2.csv] ...", os.Args[0])
	}

	for _, filename := range files {
		fmt.Printf("Processing file: %s\n", filename)

		file, err := os.Open(filename)
		if err != nil {
			log.Fatalf("Failed to open file %s: %v", filename, err)
		}
		defer file.Close()

		reader := csv.NewReader(file)

		// Read header row if needed
		var headers []string
		if *headersFlag {
			headerRow, err := reader.Read()
			if err != nil {
				log.Fatalf("Failed to read header row in file %s: %v", filename, err)
			}
			headers = headerRow
		}

		// Reset stats per file
		columns := make(map[int]*ColumnStats)

		rowIndex := 1
		for {
			record, err := reader.Read()
			if err != nil {
				break // EOF or error
			}
			rowIndex++

			// Skip completely blank rows
			allBlank := true
			for _, field := range record {
				if strings.TrimSpace(field) != "" {
					allBlank = false
					break
				}
			}
			if allBlank {
				continue
			}

			for i, field := range record {
				trimmed := strings.TrimSpace(field)

				if trimmed == "" {
					continue // skip missing values
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
						header = headers[i]
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

		// Calculate and print stats
		for i := 0; i < len(columns); i++ {
			stats, ok := columns[i]
			if !ok || len(stats.Values) == 0 {
				fmt.Printf("  %s: No valid data\n", getColumnName(headers, i))
				continue
			}

			n := big.NewFloat(float64(len(stats.Values)))

			// Mean = Sum / n
			stats.Mean.Quo(stats.Sum, n)

			// Sample Variance = sum((x - mean)^2) / (n - 1)
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

			// Output
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

// getColumnName returns header name or fallback column number
func getColumnName(headers []string, index int) string {
	if index < len(headers) {
		return headers[index]
	}
	return fmt.Sprintf("Column %d", index+1)
}
