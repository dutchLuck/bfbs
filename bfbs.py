#!/usr/bin/env python3
#
# B F B S . P Y
#
# bfbs.py last edited on Sun Aug 31 23:38:30 2025
#
# This script reads a CSV file, calculates statistics for each column,
# including sum, average, standard deviation, and range, and outputs the results.
#
# Calculations use the  decimal  module which provides
# arbitrary-precision decimal floating-point arithmetic
# to minimize floating-point errors.
#
# This script should run correctly on any platform with Python 3.x installed
# and does not require any external libraries beyond the standard library.
#

import sys
import platform
import csv
from decimal import Decimal, getcontext
import math

# Set precision (adjust this as needed)
precision = 40
getcontext().prec = precision

# Output version and environment information
print("bfbs.py 0v1")
print(f"python version: {platform.python_version()}")
print(f"csv module version: {csv.__version__}")
print(f"decimal module version: {platform.python_version()}")
print(f"Using {precision} digits of decimal precision.")

# Read CSV file name from command line or use default
filename = sys.argv[1] if len(sys.argv) > 1 else "tmp.csv"
print(f"\nProcessing file: \"{filename}\"")

def safe_decimal(val):
    try:
        return Decimal(val)
    except:
        return None

with open(filename, newline='') as csvfile:
    reader = csv.reader(csvfile)
    data = list(reader)

# Assuming first row is header
#headers = data[0]

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
    variance = sum((mean - x) ** 2 for x in col) / (count - 1) if count > 1 else Decimal(0)
    stddev = variance.sqrt()

    min_val = min(col)
    max_val = max(col)
    range_val = max_val - min_val

    print(f"{headers[i]}:")
    print(f"  Count     : {count}")
    print(f"  Min       : {min_val}")
    print(f"  Max       : {max_val}")
    print(f"  Range     : {range_val}")
    print(f"  Sum       : {total}")
    print(f"  Mean      : {mean}")
    print(f"  Variance  : {variance}")
    print(f"  Std. Dev. : {stddev}")
