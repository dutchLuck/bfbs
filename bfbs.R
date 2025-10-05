#!/usr/bin/env Rscript
#
# B F B S . R
#
# bfbs.R last updated on Sun Oct  5 22:30:07 2025 by O.H. as 0v4
#
# Uses the Rmpfr & gmp combination of arbitrary-precision arithmetic packages
# to calculate basic statistics for each column of data in a CSV file.
# It requires the Rmpfr package to be installed in R.
# This can be done in R with:  install.packages("Rmpfr")
#

#
# Works with Rscript version 4.5.1, but may not work with older versions?
#

#
# Reads a CSV file and outputs statistics for each column in the file.
# It doesn't handle multiple files. Last option supplied by user is assumed
# to be a CSV file name.
#

#
# 0v1 Descendant of precision_stats.R 0v4 
#

suppressMessages(library(Rmpfr))

printHelp <- function() {
  cat("Usage:\n Rscript bfbs.R [-h][--help][--no-header][--summary][--histogram][-P INT][-p INT] path/to/data.csv\n")
}
# ----------------------------
# Parse Command-Line Arguments
# ----------------------------
args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0 ) {
  cat("Error: Please specify the name of the CSV file to process\n")
  printHelp()
  quit(status = 1)
}

help <- FALSE
has_header <- TRUE
has_summary <- FALSE
has_histogram <- FALSE
nxt_is_precision <- FALSE
nxt_is_print_digits <- FALSE
csv_file <- NULL
precision_bits <- 192   # decimal_digits ~= 0.3 * mantissa_bits (i.e. 192 bits ~57 dec digits)
output_digits <- 48     # mantissa_bits ~= 3.33 * decimal_digits (i.e. 50 dec digits ~168 bits)

# ----------------------
# Step 0: Handle options
# ----------------------
indx <- 1
last <- length(args)
for ( arg in args ) {
  if ( indx == last ) {   # Last option is assumed to be the CSV file
    csv_file <- arg
    base_csv_file_name <- basename( csv_file )
  } else {    # Process non-file-name options
    if ( nxt_is_precision ) {
      precision_bits <- as.integer( arg )
      nxt_is_precision <- FALSE
    } else if ( nxt_is_print_digits ) {
      output_digits <- as.integer( arg )
      nxt_is_print_digits <- FALSE
    } else {
      switch( arg,
        "-h" = {
          help <- TRUE
        },
        "--help" = {
          help <- TRUE
        },
        "--histogram" = {
          has_histogram <- TRUE
        },
        "--no-header" = {
          has_header <- FALSE
        },
        "-P" = {
          nxt_is_precision <- TRUE
        },
        "-p" = {
          nxt_is_print_digits <- TRUE
        },
        "--summary" = {
          has_summary <- TRUE
        },
        cat("Warning: Unknown option:", arg, "\n")
      )
    }
  }
  indx <- indx + 1
}

#
# If help is requested then print usage and exit
#
if ( help ) {
  printHelp()
  quit(status = 1)
}

if( is.na( precision_bits )) {   # Did user supplied -P INT convert to integer ok?
  precision_bits <- 192
} else if( precision_bits > 1024 ) {   # clamp range of calculation precision
  precision_bits <- 1024
} else if ( precision_bits < 32 ) {
  precision_bits <- 32
}

if( is.na( output_digits )) {   # Did user supplied -p INT convert to integer ok?
  output_digits <- 48
} else if( output_digits > 120 ) {   # clamp range of output digits
  output_digits <- 120
} else if ( output_digits < 5 ) {
  output_digits <- 5
}

# ------------------------------
# Step 1: Load CSV as characters
# ------------------------------
data_raw <- read.csv(
  csv_file,
  colClasses = "character",
  stringsAsFactors = FALSE,
  header = has_header
)

# ----------------------------
# Step 2: Convert to mpfr list
# ----------------------------
convert_to_mpfr <- function(df, precBits = precision_bits) {
  result <- list()
  for (colname in names(df)) {
    vals <- df[[colname]]
    vals[vals == "" | tolower(vals) == "na"] <- NA
    vals <- as.character(vals)
    valid_mask <- !is.na(vals) & grepl("^[ ]*[-+]?[0-9]*\\.?[0-9]+([eE][-+]?[0-9]+)?$", vals)

    # Allocate mpfr vector with NA_real_
    mpfr_col <- mpfr(rep(NA_real_, length(vals)), precBits)

    # Assign valid values
    if (any(valid_mask)) {
      mpfr_col[valid_mask] <- mpfr(vals[valid_mask], precBits)
    }

    result[[colname]] <- mpfr_col
  }
  return(result)  # Named list, not data.frame
}

data_mpfr <- convert_to_mpfr(data_raw, precision_bits)

# -----------------------------------------
# Step 3: High-Precision Welford Statistics
# -----------------------------------------
compute_welford_mpfr <- function(x) {
  x <- x[!is.na(x)]
  n <- mpfr(0, precBits = precision_bits)
  sum <- mpfr(0, precBits = precision_bits)
  mean <- mpfr(0, precBits = precision_bits)
  M2 <- M3 <- M4 <- mpfr(0, precBits = precision_bits)
  min_x <- x[1]
  max_x <- x[1]

  for (i in seq_along(x)) {
    xi <- x[i]
    sum <- sum + xi
    n1 <- n
    n <- n + 1
    delta <- xi - mean
    delta_n <- delta / n
    delta_n2 <- delta_n^2
    term1 <- delta * delta_n * n1
    mean <- mean + delta_n
    M4 <- M4 + term1 * delta_n2 * (n^2 - 3 * n + 3) + 6 * delta_n2 * M2 - 4 * delta_n * M3
    M3 <- M3 + term1 * delta_n * (n - 2) - 3 * delta_n * M2
    M2 <- M2 + term1

    if (xi < min_x) min_x <- xi
    if (xi > max_x) max_x <- xi
  }

  if (n < 2) return(NULL)

  variance <- M2 / (n - 1)
  sd <- sqrt(variance)
  se <- sd / sqrt(n)
  skew <- (sqrt(n) * M3) / (M2^(3/2))
  kurtosis_excess <- (n * M4) / (M2^2) - 3

  list(
    Count = as.numeric(n),
    Minimum = min_x,
    Mean = mean,
    Maximum = max_x,
    Range = max_x - min_x,
    Sum = sum,
    Variance = variance,
    StdDev = sd,
    Skewness = skew,
    Kurtosis = kurtosis_excess,
    StdErr = se
  )
}

# ---------------------------------------
# Step 4: Print Arbitrary-Precision Stats
# ---------------------------------------
cat("bfbs version 0v1\n")
cat(precision_bits, " bit precision for calculations with ", output_digits, " digits printed on output.\n")
# === Arbitrary-Precision Welford Statistics ===
for (col in names(data_mpfr)) {
  x <- data_mpfr[[col]]
  if (!inherits(x, "mpfr")) next

  cat(sprintf("Column: %s\n", col))
  stats <- compute_welford_mpfr(x)
  if (is.null(stats)) {
    cat("  Not enough data or invalid values.\n\n")
    next
  }

  for (name in names(stats)) {
    val <- stats[[name]]
    if (inherits(val, "mpfr")) {
      cat(sprintf("  %-10s : %s\n", name, formatMpfr(val, digits = output_digits)))
    } else {
      cat(sprintf("  %-10s : %s\n", name, val))
    }
  }
  cat("\n")
}

# ------------------------
# Step 5: Base R summary()
# ------------------------
if ( has_summary ) {
  cat("=== Base R summary() on numeric approximation ===\n\n")
  options( digits = 18 )

  for (col in names(data_mpfr)) {
    x <- data_mpfr[[col]]
    if (inherits(x, "mpfr")) {
      cat(sprintf("Summary of column: %s\n", col))
      print(summary(as.numeric(x)))
      cat("\n")
    }
  }
}

# ---------------------
# Step 6: Base R hist()
# ---------------------
if ( has_histogram ) {
  cat("=== Base R hist() on numeric approximation ===\n\n")
  options( digits = 10 )

  for (colm in names(data_mpfr)) {
    x <- data_mpfr[[colm]]
    if (inherits(x, "mpfr")) {
      cat(sprintf("Creating histogram of %s column: %s as PDF file %s_%s_hist.pdf\n", base_csv_file_name, colm, base_csv_file_name, colm ))
      pdf(file = paste0(base_csv_file_name, "_", colm, "_hist.pdf"))
      hist(as.numeric(x), main = paste0("Histogram of \"", base_csv_file_name, "\" column \"", colm, "\"" ), xlab = paste0(colm, " Data" ))
      dev.off()
    }
  }
}
