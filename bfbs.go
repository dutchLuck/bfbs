//
// B F B S 0 . G O
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

package main

import (
	"encoding/csv"
	"fmt"
	"log"
	"math/big"
	"os"
	"strings" // help deal with leading spaces
)

const (
	programName    = "bfbs.go"
	programVersion = "v0.0.0"
)

// ColumnStats holds data and stats for a single column
type ColumnStats struct {
	Values []*big.Float
	Sum    *big.Float
	Mean   *big.Float
	Var    *big.Float
	StdDev *big.Float
}

func main() {
	fmt.Printf("%s %s\n", programName, programVersion)

	if len(os.Args) < 2 {
		log.Fatalf("Usage: %s <file1.csv> [file2.csv] ...", os.Args[0])
	}

	// Map column index to stats
	columns := make(map[int]*ColumnStats)

	for _, filename := range os.Args[1:] {
		file, err := os.Open(filename)
		if err != nil {
			log.Fatalf("Failed to open file %s: %v", filename, err)
		}
		defer file.Close()

		reader := csv.NewReader(file)
		for {
			record, err := reader.Read()
			if err != nil {
				break
			}

			for i, field := range record {
				trimmed := strings.TrimSpace(field) // Trim leading/trailing spaces
				val, _, err := big.ParseFloat(trimmed, 10, 256, big.ToNearestEven)
				if err != nil {
					log.Fatalf("Failed to parse float (from \"%s\" at line %d): %v", trimmed, i+1, err)
				}

				if _, exists := columns[i]; !exists {
					columns[i] = &ColumnStats{
						Sum:    big.NewFloat(0),
						Var:    big.NewFloat(0),
						Mean:   big.NewFloat(0),
						StdDev: big.NewFloat(0),
					}
				}

				columns[i].Values = append(columns[i].Values, val)
				columns[i].Sum.Add(columns[i].Sum, val)
			}
		}
	}

	// Now calculate statistics
	for idx, stats := range columns {
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

		nMinus1 := new(big.Float).Sub(n, big.NewFloat(1))
		if n.Cmp(big.NewFloat(1)) <= 0 {
			stats.Var.SetFloat64(0) // Avoid division by zero if n <= 1
			stats.StdDev.SetFloat64(0)
		} else {
			stats.Var.Quo(sumSquares, nMinus1)
			stats.StdDev.Sqrt(stats.Var)
		}

		// Print results
		fmt.Printf("Column %d:\n", idx+1)
		fmt.Printf("  Count: %s\n", n.Text('f', -1))
		fmt.Printf("  Sum:   %s\n", stats.Sum.Text('f', -1))
		fmt.Printf("  Mean:  %s\n", stats.Mean.Text('f', -1))
		fmt.Printf("  Var:   %s\n", stats.Var.Text('f', -1))
		fmt.Printf("  StdDev:%s\n", stats.StdDev.Text('f', -1))
		fmt.Println()
	}
}
