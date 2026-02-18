#!/usr/bin/env python3
"""
B E N C H M A R K _ D A T A _ P R O C E S S I N G . P Y
Cross-platform benchmark script (macOS / Linux / Windows)
Resilient: continues even if one step fails.
"""

import csv
import os
import subprocess
import sys
import time
from datetime import datetime

# --- Paths ---
SRC_PTH = ".."
DATA_PTH = os.path.join(SRC_PTH, "test", "data.csv")

# --- Output CSV setup ---
timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
script_dir = os.path.dirname(os.path.abspath(__file__))
benchmark_csv_path = os.path.join(script_dir, f"benchmark_results_{timestamp}.csv")

# --- Benchmark storage ---
benchmarks = []


def invoke_timed_command(label, cmd):
    """Run a command, time it, and record duration (errors are caught)."""
    print(f"\n------==================== {label} ====================------")

    start = time.time()
    duration = None
    try:
        subprocess.run(cmd, check=True)
    except FileNotFoundError:
        print(f"⚠️  [{label}] command not found: {cmd[0]}", file=sys.stderr)
    except subprocess.CalledProcessError as e:
        print(f"⚠️  [{label}] exited with non-zero code {e.returncode}", file=sys.stderr)
    except Exception as e:
        print(f"⚠️  [{label}] unexpected error: {e}", file=sys.stderr)
    finally:
        duration = round(time.time() - start, 3)

    print(f"[{label}] completed in {duration} seconds")
    benchmarks.append({"Step": label, "Duration": duration})


# --- Run benchmark steps ---
invoke_timed_command("bfbs.cpp", [os.path.join(SRC_PTH, "bfbs_cpp"), "--precision", "340", "--digits", "80", DATA_PTH])

invoke_timed_command("bfbs.f90", [os.path.join(SRC_PTH, "bfbs_fortran"), "-prec", "340", "-digits", "80", DATA_PTH])

invoke_timed_command("bfbs.go", [os.path.join(SRC_PTH, "bfbs_go"), "-precision", "340", "-output_digits", "80", DATA_PTH])

invoke_timed_command("bfbs.java", ["java", "-classpath", SRC_PTH, "bfbs", "--precision=80", DATA_PTH])

invoke_timed_command("bfbs.jl", ["julia", os.path.join(SRC_PTH, "bfbs.jl"), "-P", "340", "-p", "80", "-R", DATA_PTH])

invoke_timed_command("bfbs.pl", ["perl", os.path.join(SRC_PTH, "bfbs.pl"), "--precision", "1", DATA_PTH])

invoke_timed_command("bfbs.py", ["python3", os.path.join(SRC_PTH, "bfbs.py"), "--precision", "80", DATA_PTH])

invoke_timed_command("bfbs.rb", ["ruby", os.path.join(SRC_PTH, "bfbs.rb"), "-P", "80", DATA_PTH])

invoke_timed_command("bfbs.rs", [os.path.join(SRC_PTH, "bfbs_rust"), "-P", "340", "-p", "80", DATA_PTH])


# --- Write results to CSV ---
try:
    with open(benchmark_csv_path, "w", newline="", encoding="utf-8") as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=["Step", "Duration"])
        writer.writeheader()
        writer.writerows(benchmarks)
    print(f"\n✅ Benchmark results saved to:\n{benchmark_csv_path}")
except Exception as e:
    print(f"❌ Failed to write CSV: {e}", file=sys.stderr)
