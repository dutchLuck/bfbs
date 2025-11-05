#!/usr/bin/env python3
#
# B F B S . P Y
#
# bfbs.py last edited on Wed Nov  5 22:46:30 2025
#
# This script reads a CSV file, calculates basic statistics for each column,
# including sum, mean (average), variance, standard deviation and range,
# and outputs the results.
#
# Calculations use the  decimal  module which provides
# arbitrary-precision decimal floating-point arithmetic
# to minimize floating-point errors.
#
# This script should run correctly on any platform with Python 3.x installed
# and does not require any external libraries beyond the standard library.
#

#
# 0v4 Added wall clock timer and reformatted with black
# 0v3 Added calculation of median
# 0v2 Cosmetic changes to output
#

import sys
import os
import platform
import time as _time
import argparse
import csv
from decimal import Decimal, getcontext
import math


def getClockTime():
    if sys.platform == "win32":
        systemWallClockTime = _time.time_ns() / 1000000000.0
    else:
        systemWallClockTime = _time.time()  # best on most systems
    return systemWallClockTime


def safe_decimal(val):
    try:
        return Decimal(val)
    except:
        return None


# Start
startTime = getClockTime()

# Set precision (adjust this as needed)
calc_precision = 40

parser = argparse.ArgumentParser(
    description="Process one or more CSV files and report stats for each column."
)
parser.add_argument("files", nargs="+", help="One or more CSV files to analyze")
parser.add_argument(
    "-H",
    "--header",
    action="store_true",
    help="Treat the first non-comment row as a header row",
)
parser.add_argument(
    "-P",
    "--precision",
    type=int,
    help="Set the calculation precision to PRECISION decimal digits",
)

args = parser.parse_args()

if (
    args.precision is not None
):  # Check the user precision input number if it is specified
    if args.precision < 2:
        calc_precision = 2
    elif args.precision > 1024:
        calc_precision = 1024
    else:
        calc_precision = args.precision

getcontext().prec = calc_precision

# Output version and environment information
print("bfbs.py version 0v4")
print(f"python version: {platform.python_version()}")
print(f"csv module version: {csv.__version__}")
print(f"decimal module version: {platform.python_version()}")
print(f"Using {calc_precision} digits of decimal precision.")

# Process all files
for file_path in args.files:
    if os.path.isfile(file_path):
        print(f'\nProcessing file: "{file_path}"')
    else:
        print(f'\nError: "{file_path}" is not an existing file.')
        continue

    data = []
    with open(file_path, newline="") as csvfile:
        reader = csv.reader(csvfile)
        #        data = list(reader)
        for row in reader:
            if not row or row[0].startswith(
                "#"
            ):  # skip blank rows and comments identified by #
                continue
            data.append(row)

    # If first row is header (i.e. column labels)
    if args.header:
        headers = data[0]
        rows = data[1:]
    else:
        # Assuming no header row
        headers = [f"Column {i+1}" for i in range(len(data[0]))]
        rows = data[0:]

    # Transpose rows to columns
    columns = list(zip(*rows))

    # Convert each column to Decimal, skipping non-numeric entries
    numeric_columns = []
    for col in columns:
        decimals = [safe_decimal(val) for val in col if safe_decimal(val) is not None]
        numeric_columns.append(decimals)

    # Calculate statistics
    for i, col in enumerate(numeric_columns):
        if not col:
            print(f"{headers[i]}: No valid numeric data")
            continue

        count = len(col)
        total = sum(col)
        mean = total / count

        # Sample standard deviation
        variance = (
            sum((mean - x) ** 2 for x in col) / (count - 1) if count > 1 else Decimal(0)
        )
        stddev = variance.sqrt()

        min_val = min(col)
        max_val = max(col)
        range_val = max_val - min_val

        # Sample median
        if count < 2:
            median = col[0]
        else:
            indx = int(count) >> 1  # halve count
            col_sorted = sorted(col)
            if (count & 1) == 1:  # is count an odd number
                median = col_sorted[indx]
            else:
                median = (col_sorted[indx - 1] + col_sorted[indx]) / safe_decimal("2")

        print(f"\n{headers[i]}:")
        print(f"  Count     : {count}")
        print(f"  Minimum   : {min_val}")
        print(f"  Mean      : {mean}")
        print(f"  Median    : {median}")
        print(f"  Maximum   : {max_val}")
        print(f"  Range     : {range_val}")
        print(f"  Sum       : {total}")
        print(f"  Variance  : {variance}")
        print(f"  Std. Dev. : {stddev}")

print("bfbs.py execution time was: %9.3f mS" % ((getClockTime() - startTime) * 1000))
