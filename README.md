# bfbs
The "big float basic statistics" (bfbs) project has morphed from a julia language
BigFloat exploration into an arbitrary-precision arithmetic multi-language project.
Each bfbs program is a command line utility that reads data files containing comma
separated values (CSV), and outputs the basic statistics for each column in the file.
The minimum set of basic statistics are sum, mean, variance and standard deviation.
There are quite a few languages that have arbitrary-precision arithmetic available.
(See
<a href="https://en.wikipedia.org/wiki/List_of_arbitrary-precision_arithmetic_software">
Wikipedia's List of arbitrary-precision arithmetic software</a>
for more detail.)
Some languages like python and ruby don't just have arbitrary-precision integer capability,
but have decimal floating point packages. Compiled languages like rust and go also have
arbitrary-precision floating point capabilty.
(N.B. Other word choices fit "bfbs" too. For instance although extra precision provided
by arbitrary precision (big float) floating point arithmetic may reduce worry about
truncation, cancellation and accumulation errors effecting the results, other factors
about the data can still make using the results output by bfbs just BS.)
## bfbs.go
The golang version of bfbs uses the math/big package and builds and runs without trouble
on Linux, MacOS and Windows. It outputs min, median, max, range, skew and kurtosis in
addition to sum, mean, variance and standard deviation. N.B. that the skew and kurtosis
are float64 calculations in the current (v0.0.5) version. The results are produced without
any noticable delay.
## bfbs.rs
The rust version of bfbs uses the rug crate and builds and runs without trouble
on MacOS. On Ubuntu Linux the m4 macro processor needed to be installed before the
build was successful. It did not build for me on Windows and looks like it may require
Microsoft Visual C tooling? It outputs sum, mean, variance and standard deviation. The
results are produced without any noticable delay.
## bfbs.jl
The julia bfbs code uses the built-in BigFloat number type and runs ok on Linux, 
MacOS and Windows. It outputs min, median, max, range in addition to sum, mean,
variance and standard deviation. There is a noticiable delay before results appear
particularly on computers with modest specs. This code outputs stats for all rows
as well as columns of numbers, unless the -R option is specified.
## bfbs.pl
The perl bfbs code uses the Math::BigFloat package, which does decimal arbitrary-precision
calculations and runs ok on Linux, MacOS and Windows. It outputs min, median, max, range
in addition to sum, mean, variance and standard deviation. Even though perl uses an
interpreter there is only a minor delay before results appear on the computer
with modest specs.
## bfbs.py
The python3 bfbs code uses the Decimal module, which does decimal arbitrary-precision
calculations and runs ok on Linux, MacOS and Windows. It outputs min, max, range
in addition to sum, mean, variance and standard deviation. Even though python uses an
interpreter there isn't a noticable delay before results appear. However this maybe due
to median not being calculated and output. The current code does not handle comments
in the CSV file.
## bfbs.rb
The ruby bfbs code uses the bigdecimal module, which does decimal arbitrary-precision
calculations and runs ok on Linux, MacOS and Windows. It outputs the minimal set of sum,
mean, variance and standard deviation. Even though ruby uses an interpreter there is
only a slight delay before results appear. However, like python, this maybe due to what
is not calculated and output by the ruby code which is median, min and max for each
column of numbers. The current code does not handle comments in the CSV file.
## CSV data files
The input data files (or file) are assumed by default to be in comma separated value (CSV)
format. (See
<a href="https://www.ietf.org/rfc/rfc4180.txt">RFC 4180</a>
for a formal CSV definition.)
All data files are assumed to have no missing entries and
no NaN values in the columns of numbers. Unlike the RFC 4180 standard bfbs accepts data files
that contain blank lines and these are ignored. It also accepts data files that contain
comment lines, which also are ignored. Comment lines by default are assumed to start with
the hash ("#") character.

A suitable, but contrived file of test data has the following contents; -
```
% cat test/data.csv 
# Test file for julia bfbs.jl
#

1.000000000000000000000000000000000000001e+50, 4.000000000000000000000000000000000000004e+50, 7.000000000000000000000000000000000000007e+50

2.000000000000000000000000000000000000002e+50, 5.000000000000000000000000000000000000005e+50, 8.000000000000000000000000000000000000008e+50

3.000000000000000000000000000000000000003e+50, 6.000000000000000000000000000000000000006e+50, 9.000000000000000000000000000000000000009e+50
%
```
The results from bfbs.jl on the just shown file contents are; -
```
% julia bfbs.jl -p 80 -P 340 test/data.csv
bfbs version 0v10 (2025-09-05)
Julia version 1.11.6
BigFloat precision: 340 bits
Results output using 80 digits in general number format

Basic Statistics for Data from file: "test/data.csv"
Row: 1
 Count     : 3
 Minimum   : 100000000000000000000000000000000000000100000000000
 Median    : 400000000000000000000000000000000000000400000000000
 Maximum   : 700000000000000000000000000000000000000700000000000
 Range     : 600000000000000000000000000000000000000600000000000
 Mean      : 400000000000000000000000000000000000000400000000000
 Sum       : 1200000000000000000000000000000000000001200000000000
 Variance  : 9.000000000000000000000000000000000000018000000000000000000000000000000000000009e+100
 Std. Dev. : 300000000000000000000000000000000000000300000000000
Row: 2
 Count     : 3
 Minimum   : 200000000000000000000000000000000000000200000000000
 Median    : 500000000000000000000000000000000000000500000000000
 Maximum   : 800000000000000000000000000000000000000800000000000
 Range     : 600000000000000000000000000000000000000600000000000
 Mean      : 500000000000000000000000000000000000000500000000000
 Sum       : 1500000000000000000000000000000000000001500000000000
 Variance  : 9.000000000000000000000000000000000000018000000000000000000000000000000000000009e+100
 Std. Dev. : 300000000000000000000000000000000000000300000000000
Row: 3
 Count     : 3
 Minimum   : 300000000000000000000000000000000000000300000000000
 Median    : 600000000000000000000000000000000000000600000000000
 Maximum   : 900000000000000000000000000000000000000900000000000
 Range     : 600000000000000000000000000000000000000600000000000
 Mean      : 600000000000000000000000000000000000000600000000000
 Sum       : 1800000000000000000000000000000000000001800000000000
 Variance  : 9.000000000000000000000000000000000000018000000000000000000000000000000000000009e+100
 Std. Dev. : 300000000000000000000000000000000000000300000000000
Column: 1
 Count     : 3
 Minimum   : 100000000000000000000000000000000000000100000000000
 Median    : 200000000000000000000000000000000000000200000000000
 Maximum   : 300000000000000000000000000000000000000300000000000
 Range     : 200000000000000000000000000000000000000200000000000
 Mean      : 200000000000000000000000000000000000000200000000000
 Sum       : 600000000000000000000000000000000000000600000000000
 Variance  : 1.000000000000000000000000000000000000002000000000000000000000000000000000000001e+100
 Std. Dev. : 100000000000000000000000000000000000000100000000000
Column: 2
 Count     : 3
 Minimum   : 400000000000000000000000000000000000000400000000000
 Median    : 500000000000000000000000000000000000000500000000000
 Maximum   : 600000000000000000000000000000000000000600000000000
 Range     : 200000000000000000000000000000000000000200000000000
 Mean      : 500000000000000000000000000000000000000500000000000
 Sum       : 1500000000000000000000000000000000000001500000000000
 Variance  : 1.000000000000000000000000000000000000002000000000000000000000000000000000000001e+100
 Std. Dev. : 100000000000000000000000000000000000000100000000000
Column: 3
 Count     : 3
 Minimum   : 700000000000000000000000000000000000000700000000000
 Median    : 800000000000000000000000000000000000000800000000000
 Maximum   : 900000000000000000000000000000000000000900000000000
 Range     : 200000000000000000000000000000000000000200000000000
 Mean      : 800000000000000000000000000000000000000800000000000
 Sum       : 2400000000000000000000000000000000000002400000000000
 Variance  : 1.000000000000000000000000000000000000002000000000000000000000000000000000000001e+100
 Std. Dev. : 100000000000000000000000000000000000000100000000000
%
```
The useage information for bfbs.jl is; -
```
% julia bfbs.jl --help
bfbs version 0v10 (2025-09-05)
usage: bfbs.jl [-c COMMENT_CHAR] [-C] [-d DELIMITER_CHAR] [-D] [-e]
               [-H] [-n] [-p PRINT_DIGITS] [-P PRECISION] [-R]
               [-s SKIP] [-v] [-V] [-h] [files...]

positional arguments:
  files                 Input files containing 1 or more columns of
                        numbers. Default file format has comma
                        separated columns.

optional arguments:
  -c, --comment_char COMMENT_CHAR
                        Define the Comment Delimiter character as
                        "COMMENT_CHAR". If not provided, hash ("#") is
                        used.
  -C, --no_column_stats
                        Disable column statistics calculation and
                        output.
  -d, --delimiter_char DELIMITER_CHAR
                        Define the Column Delimiter character as
                        "DELIMITER_CHAR". If not provided, comma (",")
                        is used.
  -D, --debug           Provide copious amounts of information about
                        the current run and the data.
  -e, --scientific      Output statistics results in scientific number
                        format.
  -H, --header          The first row is treated as a header.
  -n, --n_divisor       Use the actual number of samples n as the
                        Standard Deviation divisor, rather than n-1.
  -p, --print_digits PRINT_DIGITS
                        Write output with "PRINT-DIGITS" digits. If
                        not provided, 64 output digits are used.
  -P, --precision PRECISION
                        Calculate using "PRECISION" bits. If not
                        provided, 256 bits of precision are used.
  -R, --no_row_stats    Disable row statistics calculation and output.
  -s, --skip SKIP       Skip first "SKIP" lines in data file(s). If
                        not provided, zero lines are skipped.
  -v, --verbose         Provide extra information about the current
                        run and the data.
  -V, --version         Provide version information.
  -h, --help            show this help message and exit

%
```
This bfbs.jl code was produced out of a combination of curiosity as to what julia would be like
to code in and a desire to have better than double precision floating point
statistic calculations on my Apple Silicon laptop. Apple computers with Intel CPU's
appear to have (80 bit?) long double precision floating point available,
but at least in C language coding Apple Silicon computers have no difference in precision
between double and long double floating point calculations.
The output of the Number mode of the helloWorld (C code) utility on my MacOS
Sequoia 15.4.1 Apple Silicon laptop is; -
```
% ./helloWorld -N | tail -14
The double precision number has a size of ("__SIZEOF_DOUBLE__") 8 bytes
The double precision maximum floating point value ("DBL_MAX") is 1.79769e+308
The double precision minimum floating point value ("DBL_MIN") is 2.22507e-308
The double precision floating point value ("DBL_DIG") has 15 digits
The double precision floating point value ("DBL_DECIMAL_DIG") has 17 decimal digits
The double precision floating point value ("DBL_MANT_DIG") has 53 mantissa bits
The double precision epsilon floating point value ("DBL_EPSILON") is 2.22045e-16
The long double precision number has a size of ("__SIZEOF_LONG_DOUBLE__") 8 bytes
The long double precision maximum floating point value ("LDBL_MAX") is 1.79769e+308
The long double precision minimum floating point value ("LDBL_MIN") is 2.22507e-308
The long double precision floating point value ("LDBL_DIG") has 15 digits
The long double precision floating point value ("LDBL_DECIMAL_DIG") has 17 decimal digits
The long double precision floating point value ("LDBL_MANT_DIG") has 53 mantissa bits
The long double precision epsilon floating point value ("LDBL_EPSILON") is 2.22045e-16
%
```
By way of comparison the same C code run on MacOS High Sierra 10.13.6
on an Intel i7 machine outputs: -
```
% ./helloWorld -N | tail -14
The double precision number has a size of ("__SIZEOF_DOUBLE__") 8 bytes
The double precision maximum floating point value ("DBL_MAX") is 1.79769e+308
The double precision minimum floating point value ("DBL_MIN") is 2.22507e-308
The double precision floating point value ("DBL_DIG") has 15 digits
The double precision floating point value ("DBL_DECIMAL_DIG") has 17 decimal digits
The double precision floating point value ("DBL_MANT_DIG") has 53 mantissa bits
The double precision epsilon floating point value ("DBL_EPSILON") is 2.22045e-16
The long double precision number has a size of ("__SIZEOF_LONG_DOUBLE__") 16 bytes
The long double precision maximum floating point value ("LDBL_MAX") is 1.18973e+4932
The long double precision minimum floating point value ("LDBL_MIN") is 3.3621e-4932
The long double precision floating point value ("LDBL_DIG") has 18 digits
The long double precision floating point value ("LDBL_DECIMAL_DIG") has 21 decimal digits
The long double precision floating point value ("LDBL_MANT_DIG") has 64 mantissa bits
The long double precision epsilon floating point value ("LDBL_EPSILON") is 1.0842e-19
```
For comparison purposes; -
### go
```
% go run bfbs.go -precision 340 -output_digits 80 test/data.csv
bfbs.go v0.0.5
Built with Go version: go1.25.0
Using precision: 340 bits
Displaying output with: 80 digits

Info: Processing file: "test/data.csv"
  Column 1:
    Count     : 3
    Min       : 100000000000000000000000000000000000000100000000000
    Median    : 200000000000000000000000000000000000000200000000000
    Max       : 300000000000000000000000000000000000000300000000000
    Range     : 200000000000000000000000000000000000000200000000000
    Sum       : 600000000000000000000000000000000000000600000000000
    Mean      : 200000000000000000000000000000000000000200000000000
    Variance  : 1.000000000000000000000000000000000000002000000000000000000000000000000000000001e+100
    Std. Dev. : 100000000000000000000000000000000000000100000000000
    Skew      : 0.000000
    Kurtosis  : 0.000000

  Column 2:
    Count     : 3
    Min       : 400000000000000000000000000000000000000400000000000
    Median    : 500000000000000000000000000000000000000500000000000
    Max       : 600000000000000000000000000000000000000600000000000
    Range     : 200000000000000000000000000000000000000200000000000
    Sum       : 1500000000000000000000000000000000000001500000000000
    Mean      : 500000000000000000000000000000000000000500000000000
    Variance  : 1.000000000000000000000000000000000000002000000000000000000000000000000000000001e+100
    Std. Dev. : 100000000000000000000000000000000000000100000000000
    Skew      : 0.000000
    Kurtosis  : 0.000000

  Column 3:
    Count     : 3
    Min       : 700000000000000000000000000000000000000700000000000
    Median    : 800000000000000000000000000000000000000800000000000
    Max       : 900000000000000000000000000000000000000900000000000
    Range     : 200000000000000000000000000000000000000200000000000
    Sum       : 2400000000000000000000000000000000000002400000000000
    Mean      : 800000000000000000000000000000000000000800000000000
    Variance  : 1.000000000000000000000000000000000000002000000000000000000000000000000000000001e+100
    Std. Dev. : 100000000000000000000000000000000000000100000000000
    Skew      : 0.000000
    Kurtosis  : 0.000000

%
```
### rust
```
% cargo run -- --precision 340 --print_digits 80 test/data.csv
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 0.07s
     Running `target/debug/bfbs --precision 340 --print_digits 80 test/data.csv`
bfbs.rs v0.1.2
Using 340 bit precision for calculation and 80 digit decimal print out.

Processing file: "test/data.csv"
Column: 3
  Sum       : 2400000000000000000000000000000000000002400000000000.0000000000000000000000000000
  Mean      : 800000000000000000000000000000000000000800000000000.00000000000000000000000000000
  Variance  : 1.0000000000000000000000000000000000000020000000000000000000000000000000000000010e100
  Std. Dev. : 100000000000000000000000000000000000000100000000000.00000000000000000000000000000
Column: 2
  Sum       : 1500000000000000000000000000000000000001500000000000.0000000000000000000000000000
  Mean      : 500000000000000000000000000000000000000500000000000.00000000000000000000000000000
  Variance  : 1.0000000000000000000000000000000000000020000000000000000000000000000000000000010e100
  Std. Dev. : 100000000000000000000000000000000000000100000000000.00000000000000000000000000000
Column: 1
  Sum       : 600000000000000000000000000000000000000600000000000.00000000000000000000000000000
  Mean      : 200000000000000000000000000000000000000200000000000.00000000000000000000000000000
  Variance  : 1.0000000000000000000000000000000000000020000000000000000000000000000000000000010e100
  Std. Dev. : 100000000000000000000000000000000000000100000000000.00000000000000000000000000000
%
```
### perl
```
% perl bfbs.pl --precision 1 test/data.csv              
bfbs.pl version 0.0.5
Perl version: v5.34.1
Getopt::Long Version: 2.52
Math::BigFloat Version: 1.999818
Precision: 1 digits
Output Format: Decimal

File: test/data.csv

Column: 1
  Count     : 3
  Min       : 100000000000000000000000000000000000000100000000000.0
  Median    : 200000000000000000000000000000000000000200000000000.0
  Max       : 300000000000000000000000000000000000000300000000000.0
  Range     : 200000000000000000000000000000000000000200000000000.0
  Sum       : 600000000000000000000000000000000000000600000000000.0
  Mean      : 200000000000000000000000000000000000000200000000000.0
  Variance  : 10000000000000000000000000000000000000020000000000000000000000000000000000000010000000000000000000000.0 (sample)
  Std Dev   : 100000000000000000000000000000000000000100000000000.0 (sample)

Column: 2
  Count     : 3
  Min       : 400000000000000000000000000000000000000400000000000.0
  Median    : 500000000000000000000000000000000000000500000000000.0
  Max       : 600000000000000000000000000000000000000600000000000.0
  Range     : 200000000000000000000000000000000000000200000000000.0
  Sum       : 1500000000000000000000000000000000000001500000000000.0
  Mean      : 500000000000000000000000000000000000000500000000000.0
  Variance  : 10000000000000000000000000000000000000020000000000000000000000000000000000000010000000000000000000000.0 (sample)
  Std Dev   : 100000000000000000000000000000000000000100000000000.0 (sample)

Column: 3
  Count     : 3
  Min       : 700000000000000000000000000000000000000700000000000.0
  Median    : 800000000000000000000000000000000000000800000000000.0
  Max       : 900000000000000000000000000000000000000900000000000.0
  Range     : 200000000000000000000000000000000000000200000000000.0
  Sum       : 2400000000000000000000000000000000000002400000000000.0
  Mean      : 800000000000000000000000000000000000000800000000000.0
  Variance  : 10000000000000000000000000000000000000020000000000000000000000000000000000000010000000000000000000000.0 (sample)
  Std Dev   : 100000000000000000000000000000000000000100000000000.0 (sample)
%
```
