# bfbs
The "big float basic statistics" (bfbs) project has morphed from a
<a href="https://julialang.org/">Julia</a> language
BigFloat exploration into an arbitrary-precision arithmetic multi-language basic
statistics project. Each bfbs program is a command line utility that reads data
files containing comma separated values (CSV), and outputs at least some of the
basic statistics for each column in the file. In this project the minimum set of
basic statistics are taken to be sum, mean, variance and standard deviation. So far
this project has c++, golang, java, julia, perl, python, ruby, rust and Rscript language examples.
This does not exhaust the list of languages that have arbitrary-precision arithmetic
capability by any means as there are quite a lot of languages that have
arbitrary-precision arithmetic available. (See
<a href="https://en.wikipedia.org/wiki/List_of_arbitrary-precision_arithmetic_software">
Wikipedia's List of arbitrary-precision arithmetic software</a>
for more detail.)
Some languages like python and ruby don't just have arbitrary-precision integer capability,
but have decimal floating point packages. Compiled languages like rust and go also have
arbitrary-precision floating point capability. Even if a language does not have this
capability it does not mean it cannot be used to do basic statistics as lower precision
may be perfectly acceptable. If the original data being explored was acquired with a
high level of uncertainty then statistical analysis may of great help, but this does
not imply that high precision statistical calculations are required.
(N.B. Other word choices fit "bfbs" too. For instance although extra precision provided
by arbitrary precision (big float) floating point arithmetic may reduce worry about
truncation, cancellation and accumulation errors effecting the results, other factors
about the data can still make using the results output by bfbs just BS.)
There are examples of basic statistics calculations in a large variety of computer
languages on the
<a href="https://rosettacode.org/wiki/Statistics/Basic">rosettacode.org</a> website.
There are examples of data files with known values of mean and standard deviation
in the
<a href="https://www.itl.nist.gov/div898/strd/univ/homepage.html">
Univariate Summary Statistics</a> section of the
<a href="https://www.itl.nist.gov/div898/strd/">NIST Statistical Reference Dataset</a> website.
## bfbs.cpp
The C++ version of bfbs uses the 
<a href="https://www.mpfr.org/">MPFR</a> (arbitrary-precision floating-point) library and the
<a href="https://gmplib.org/">GMP</a> (multiple-precision arithmetic) library code to provide
the basis of all the calculations. This program compiles on Ubuntu 22.04 LTS Linux after
the MPFR and GMP dev libraries are installed using the apt package manager. It outputs
minimum, median, maximum and range in addition to sum, mean, sample variance (s^2) and
sample standard deviation (s). The results are produced without any noticeable delay.
## bfbs.go
The golang version of bfbs uses the
<a href="https://pkg.go.dev/math/big">math/big</a> package and builds and runs without trouble
on Linux, MacOS and Windows. It outputs min, median, max, range, skew and kurtosis in
addition to sum, mean, variance and standard deviation. N.B. that the skew and kurtosis
are calculated as float64 values and big float values in the current (v0.0.6) version.
The results are produced without any noticeable delay.
## bfbs.java
The java bfbs code uses the
<a href="https://docs.oracle.com/javase/10/docs/api/index.html?java/math/BigDecimal.html">java.math.BigDecimal</a>
package, which is part of the standard
library. It provides decimal arbitrary-precision calculations and bfbs.java compiles ok
and runs ok on open JDK 21. The java code outputs min, median, max and range
in addition to sum, mean, variance and standard deviation. There is no observable
delay before results appear.
## bfbs.jl
The julia bfbs code uses the built-in
<a href="https://docs.julialang.org/en/v1/manual/integers-and-floating-point-numbers/#Arbitrary-Precision-Arithmetic">
BigFloat</a> number type and runs ok on Linux, 
MacOS and Windows. It outputs min, median, max, range in addition to sum, mean,
variance and standard deviation. There is a noticeable delay before results appear
particularly on computers with modest specs. This code outputs stats for all rows
as well as columns of numbers, unless the -R option is specified. Analyzing rows
may be useful if the data was created by data acquisition software that sampled a
signal a number of time at a given set of test conditions and wrote all the data
for that set of test conditions into the same row, before taking the data for the
next and subsequent set of test conditions on following rows in the results file.
## bfbs.pl
The perl bfbs code uses the
<a href="https://perldoc.perl.org/Math::BigFloat">Math::BigFloat</a>
package, which does decimal arbitrary-precision
calculations and runs ok on Linux, MacOS and Windows. It outputs min, median, max, range
in addition to sum, mean, variance and standard deviation. Even though perl uses an
interpreter there is only a minor delay before results appear on the computer
with modest specs.
## bfbs.py
The
<a href="https://www.python.org">Python</a>
(python3) bfbs code uses the
<a href="https://docs.python.org/3/library/decimal.html">Decimal</a>
module, which does decimal arbitrary-precision
calculations and runs ok on Linux, MacOS and Windows. It outputs min, median, max and range
in addition to sum, mean, variance and standard deviation. Even though python uses an
interpreter there isn't a noticeable delay before results appear. 
## bfbs.rb
The
<a href="https://www.ruby-lang.org/en/">Ruby</a>
bfbs code uses the
<a href="https://ruby-doc.org/stdlib-3.1.0/libdoc/bigdecimal/rdoc/BigDecimal.html">bigdecimal</a>
module, which does decimal arbitrary-precision
calculations and runs on Linux, MacOS and Windows. It outputs min, median, max and range
in addition to sum, mean, variance and standard deviation. Even though ruby uses an
interpreter there is only a slight delay before results appear.
## bfbs.rs
The
<a href="https://rust-lang.org">Rust</a>
version of bfbs uses the
<a href="https://crates.io/crates/rug">rug crate</a> and builds and runs without trouble
on MacOS. On Ubuntu Linux the m4 macro processor needed to be installed before the
build was successful. It did not build for me on Windows and looks like it may require
modified library linking? It outputs minimum, maximum, sum, mean, median, variance and
standard deviation. The results are produced without any noticeable delay. There is currently
still an annoyance with out-of-order presentation of column statistics.
## bfbs.R
The
<a href= "https://www.r-project.org/about.html">R</a>
(Rscript) version of bfbs uses the
<a href="https://cran.r-project.org/web/packages/Rmpfr/vignettes/Rmpfr-pkg.pdf">
Rmpfr package</a>
and runs without trouble on Windows and Linux when executed by Rscript version 4.4 or 4.5.
It should run on MacOS too, as long as there is an up-to-date version of R installed,
but it has only been tested on Windows and Linux. It outputs sum, mean, variance, standard
deviation, skew, kurtosis and standard error. The standard error appears weird for the
version 0v1 code and the test/data.csv case, but was left for later investigation.
This script can output PDF graphics of the histogram of each column of the input data,
when the user provides the --histogram option in the command line. Unlike other bfbs
programs/scripts this script only handles a single CSV file at a time. The results are
produced after a very noticeable delay, particularly if there a lot of rows in each column.
It seems to be the slowest way to get results, but it does output more of them.
Since R is generally used in an interactive fashion, not in the Rscript form used in
this project, the speed of response is less of a negetive.

## CSV data files
The input data files (or file) are assumed by default to be in comma separated value (CSV)
format. (See
<a href="https://www.ietf.org/rfc/rfc4180.txt">RFC 4180</a>
for a formal CSV definition.)
All data files are assumed to have no missing entries and no NaN values
in the columns of numbers. Unlike the RFC 4180 standard bfbs.jl accepts data files
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
Julia version 1.11.7
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
This bfbs.jl code was produced out of a combination of curiosity as to what julia would
be like to code in and a desire to have better than double precision floating point
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
## Output from languages other than julia; -
### C++
```
$ ./bfbs_cpp --precision 340 --digits 80 test/data.csv 
bfbs version 0v2
Compiler version: 11.4.0
MPFR version: 4.1.0
GMP version:  6.2.1
Using 340 bits Calculation precision and 80 digits Output precision with Rounding mode: MPFR_RNDN (round to nearest)

Processing file: test/data.csv
Column: Column 1
  Count            : 3
  Minimum          : 1.0000000000000000000000000000000000000010000000000000000000000000000000000000000e50
  Mean             : 2.0000000000000000000000000000000000000020000000000000000000000000000000000000000e50
  Median           : 2.0000000000000000000000000000000000000020000000000000000000000000000000000000000e50
  Maximum          : 3.0000000000000000000000000000000000000030000000000000000000000000000000000000000e50
  Range            : 2.0000000000000000000000000000000000000020000000000000000000000000000000000000000e50
  Sum              : 6.0000000000000000000000000000000000000060000000000000000000000000000000000000000e50
  Sample Variance  : 1.0000000000000000000000000000000000000020000000000000000000000000000000000000010e100
  Sample Std. Dev. : 1.0000000000000000000000000000000000000010000000000000000000000000000000000000000e50

Column: Column 2
  Count            : 3
  Minimum          : 4.0000000000000000000000000000000000000040000000000000000000000000000000000000000e50
  Mean             : 5.0000000000000000000000000000000000000050000000000000000000000000000000000000000e50
  Median           : 5.0000000000000000000000000000000000000050000000000000000000000000000000000000000e50
  Maximum          : 6.0000000000000000000000000000000000000060000000000000000000000000000000000000000e50
  Range            : 2.0000000000000000000000000000000000000020000000000000000000000000000000000000000e50
  Sum              : 1.5000000000000000000000000000000000000015000000000000000000000000000000000000000e51
  Sample Variance  : 1.0000000000000000000000000000000000000020000000000000000000000000000000000000010e100
  Sample Std. Dev. : 1.0000000000000000000000000000000000000010000000000000000000000000000000000000000e50

Column: Column 3
  Count            : 3
  Minimum          : 7.0000000000000000000000000000000000000070000000000000000000000000000000000000000e50
  Mean             : 8.0000000000000000000000000000000000000080000000000000000000000000000000000000000e50
  Median           : 8.0000000000000000000000000000000000000080000000000000000000000000000000000000000e50
  Maximum          : 9.0000000000000000000000000000000000000090000000000000000000000000000000000000000e50
  Range            : 2.0000000000000000000000000000000000000020000000000000000000000000000000000000000e50
  Sum              : 2.4000000000000000000000000000000000000024000000000000000000000000000000000000000e51
  Sample Variance  : 1.0000000000000000000000000000000000000020000000000000000000000000000000000000010e100
  Sample Std. Dev. : 1.0000000000000000000000000000000000000010000000000000000000000000000000000000000e50

$
```
### go
```
% go run bfbs.go -precision 340 -output_digits 80 test/data.csv
bfbs v0.0.7
Built with Go version: go1.25.0
Using 340 bits calculation precision and 80 digits output precision

Info: Processing file: "test/data.csv"
Column 1:
  Count      : 3
  Min        : 100000000000000000000000000000000000000100000000000
  Mean       : 200000000000000000000000000000000000000200000000000
  Median     : 200000000000000000000000000000000000000200000000000
  Max        : 300000000000000000000000000000000000000300000000000
  Range      : 200000000000000000000000000000000000000200000000000
  Sum        : 600000000000000000000000000000000000000600000000000
  Variance   : 1.000000000000000000000000000000000000002000000000000000000000000000000000000001e+100
  Std. Dev.  : 100000000000000000000000000000000000000100000000000
  VarianceN  : 6.6666666666666666666666666666666666666800000000000000000000000000000000000000067e+99
  Std. Dev.N : 81649658092772603273242802490196379732279899013315.110217696328377522208961642699
  Skewness   : 0
  Excess Kurt: -1.5
  f64 Skew   : 0.000000
  f64 Kurt   : 0.000000

Column 2:
  Count      : 3
  Min        : 400000000000000000000000000000000000000400000000000
  Mean       : 500000000000000000000000000000000000000500000000000
  Median     : 500000000000000000000000000000000000000500000000000
  Max        : 600000000000000000000000000000000000000600000000000
  Range      : 200000000000000000000000000000000000000200000000000
  Sum        : 1500000000000000000000000000000000000001500000000000
  Variance   : 1.000000000000000000000000000000000000002000000000000000000000000000000000000001e+100
  Std. Dev.  : 100000000000000000000000000000000000000100000000000
  VarianceN  : 6.6666666666666666666666666666666666666800000000000000000000000000000000000000067e+99
  Std. Dev.N : 81649658092772603273242802490196379732279899013315.110217696328377522208961642699
  Skewness   : 0
  Excess Kurt: -1.5
  f64 Skew   : 0.000000
  f64 Kurt   : 0.000000

Column 3:
  Count      : 3
  Min        : 700000000000000000000000000000000000000700000000000
  Mean       : 800000000000000000000000000000000000000800000000000
  Median     : 800000000000000000000000000000000000000800000000000
  Max        : 900000000000000000000000000000000000000900000000000
  Range      : 200000000000000000000000000000000000000200000000000
  Sum        : 2400000000000000000000000000000000000002400000000000
  Variance   : 1.000000000000000000000000000000000000002000000000000000000000000000000000000001e+100
  Std. Dev.  : 100000000000000000000000000000000000000100000000000
  VarianceN  : 6.6666666666666666666666666666666666666800000000000000000000000000000000000000067e+99
  Std. Dev.N : 81649658092772603273242802490196379732279899013315.110217696328377522208961642699
  Skewness   : 0
  Excess Kurt: -1.5
  f64 Skew   : 0.000000
  f64 Kurt   : 0.000000

%
```
### java
```
>java bfbs --precision=80 test\data.csv
bfbs 0v9
Running on Java version: 21.0.8
Using java.math.BigDecimal (standard library)
Calculation precision: 80 digits
Output rounding: full precision

Processing file: test\data.csv
Column 1:
  Count            : 3
  Minimum          : 100000000000000000000000000000000000000100000000000
  Mean             : 200000000000000000000000000000000000000200000000000
  Median           : 200000000000000000000000000000000000000200000000000
  Maximum          : 300000000000000000000000000000000000000300000000000
  Range            : 200000000000000000000000000000000000000200000000000
  Sum              : 600000000000000000000000000000000000000600000000000
  Sample Variance  : 10000000000000000000000000000000000000020000000000000000000000000000000000000010000000000000000000000
  Sample Std. Dev. : 100000000000000000000000000000000000000100000000000.00000000000000000000000000000

Column 2:
  Count            : 3
  Minimum          : 400000000000000000000000000000000000000400000000000
  Mean             : 500000000000000000000000000000000000000500000000000
  Median           : 500000000000000000000000000000000000000500000000000
  Maximum          : 600000000000000000000000000000000000000600000000000
  Range            : 200000000000000000000000000000000000000200000000000
  Sum              : 1500000000000000000000000000000000000001500000000000
  Sample Variance  : 10000000000000000000000000000000000000020000000000000000000000000000000000000010000000000000000000000
  Sample Std. Dev. : 100000000000000000000000000000000000000100000000000.00000000000000000000000000000

Column 3:
  Count            : 3
  Minimum          : 700000000000000000000000000000000000000700000000000
  Mean             : 800000000000000000000000000000000000000800000000000
  Median           : 800000000000000000000000000000000000000800000000000
  Maximum          : 900000000000000000000000000000000000000900000000000
  Range            : 200000000000000000000000000000000000000200000000000
  Sum              : 2400000000000000000000000000000000000002400000000000
  Sample Variance  : 10000000000000000000000000000000000000020000000000000000000000000000000000000010000000000000000000000
  Sample Std. Dev. : 100000000000000000000000000000000000000100000000000.00000000000000000000000000000


>
```
### perl
```
% perl bfbs.pl --precision 40 ./test/data.csv
bfbs.pl version 0v6 (2025-09-20)
Perl version: v5.34.1
Getopt::Long Version: 2.52
Math::BigFloat Version: 1.999818
Precision: 40 digits
Output Format: Decimal

File: ./test/data.csv

Column: 1
  Count     : 3
  Minimum   : 100000000000000000000000000000000000000100000000000.0000000000000000000000000000000000000000
  Mean      : 200000000000000000000000000000000000000200000000000.0000000000000000000000000000000000000000
  Median    : 200000000000000000000000000000000000000200000000000.0000000000000000000000000000000000000000
  Maximum   : 300000000000000000000000000000000000000300000000000.0000000000000000000000000000000000000000
  Range     : 200000000000000000000000000000000000000200000000000.0000000000000000000000000000000000000000
  Sum       : 600000000000000000000000000000000000000600000000000.0000000000000000000000000000000000000000
  Variance  : 10000000000000000000000000000000000000020000000000000000000000000000000000000010000000000000000000000.0000000000000000000000000000000000000000 (sample)
  Std. Dev. : 100000000000000000000000000000000000000100000000000.0000000000000000000000000000000000000000 (sample)

Column: 2
  Count     : 3
  Minimum   : 400000000000000000000000000000000000000400000000000.0000000000000000000000000000000000000000
  Mean      : 500000000000000000000000000000000000000500000000000.0000000000000000000000000000000000000000
  Median    : 500000000000000000000000000000000000000500000000000.0000000000000000000000000000000000000000
  Maximum   : 600000000000000000000000000000000000000600000000000.0000000000000000000000000000000000000000
  Range     : 200000000000000000000000000000000000000200000000000.0000000000000000000000000000000000000000
  Sum       : 1500000000000000000000000000000000000001500000000000.0000000000000000000000000000000000000000
  Variance  : 10000000000000000000000000000000000000020000000000000000000000000000000000000010000000000000000000000.0000000000000000000000000000000000000000 (sample)
  Std. Dev. : 100000000000000000000000000000000000000100000000000.0000000000000000000000000000000000000000 (sample)

Column: 3
  Count     : 3
  Minimum   : 700000000000000000000000000000000000000700000000000.0000000000000000000000000000000000000000
  Mean      : 800000000000000000000000000000000000000800000000000.0000000000000000000000000000000000000000
  Median    : 800000000000000000000000000000000000000800000000000.0000000000000000000000000000000000000000
  Maximum   : 900000000000000000000000000000000000000900000000000.0000000000000000000000000000000000000000
  Range     : 200000000000000000000000000000000000000200000000000.0000000000000000000000000000000000000000
  Sum       : 2400000000000000000000000000000000000002400000000000.0000000000000000000000000000000000000000
  Variance  : 10000000000000000000000000000000000000020000000000000000000000000000000000000010000000000000000000000.0000000000000000000000000000000000000000 (sample)
  Std. Dev. : 100000000000000000000000000000000000000100000000000.0000000000000000000000000000000000000000 (sample)
%
```
### python
```
> python bfbs.py --precision 80 test/data.csv
bfbs.py version 0v3
python version: 3.13.9
csv module version: 1.0
decimal module version: 3.13.9
Using 80 digits of decimal precision.

Processing file: "test/data.csv"

Column 1:
  Count     : 3
  Minimum   : 1.000000000000000000000000000000000000001E+50
  Mean      : 200000000000000000000000000000000000000200000000000
  Median    : 2.000000000000000000000000000000000000002E+50
  Maximum   : 3.000000000000000000000000000000000000003E+50
  Range     : 2.000000000000000000000000000000000000002E+50
  Sum       : 600000000000000000000000000000000000000600000000000
  Variance  : 1.0000000000000000000000000000000000000020000000000000000000000000000000000000010E+100
  Std. Dev. : 1.0000000000000000000000000000000000000010E+50

Column 2:
  Count     : 3
  Minimum   : 4.000000000000000000000000000000000000004E+50
  Mean      : 500000000000000000000000000000000000000500000000000
  Median    : 5.000000000000000000000000000000000000005E+50
  Maximum   : 6.000000000000000000000000000000000000006E+50
  Range     : 2.000000000000000000000000000000000000002E+50
  Sum       : 1500000000000000000000000000000000000001500000000000
  Variance  : 1.0000000000000000000000000000000000000020000000000000000000000000000000000000010E+100
  Std. Dev. : 1.0000000000000000000000000000000000000010E+50

Column 3:
  Count     : 3
  Minimum   : 7.000000000000000000000000000000000000007E+50
  Mean      : 800000000000000000000000000000000000000800000000000
  Median    : 8.000000000000000000000000000000000000008E+50
  Maximum   : 9.000000000000000000000000000000000000009E+50
  Range     : 2.000000000000000000000000000000000000002E+50
  Sum       : 2400000000000000000000000000000000000002400000000000
  Variance  : 1.0000000000000000000000000000000000000020000000000000000000000000000000000000010E+100
  Std. Dev. : 1.0000000000000000000000000000000000000010E+50
>
```
### ruby
```
> ruby bfbs.rb -P 80 test/data.csv
bfbs.rb version 0v4
ruby version: 3.2.9
csv module version: 3.2.6
bigdecimal module version: 3.1.3
Using 80 digits of bigdecimal precision.

Processing file: "test/data.csv"
Column: 1
  Count     : 3
  Minimum   : 0.1000000000000000000000000000000000000001e51
  Mean      : 0.2000000000000000000000000000000000000002e51
  Median    : 0.2000000000000000000000000000000000000002e51
  Maximum   : 0.3000000000000000000000000000000000000003e51
  Range     : 0.2000000000000000000000000000000000000002e51
  Sum       : 0.6000000000000000000000000000000000000006e51
  Variance  : 0.1000000000000000000000000000000000000002000000000000000000000000000000000000001e101
  Std. Dev. : 0.1000000000000000000000000000000000000001e51
Column: 2
  Count     : 3
  Minimum   : 0.4000000000000000000000000000000000000004e51
  Mean      : 0.5000000000000000000000000000000000000005e51
  Median    : 0.5000000000000000000000000000000000000005e51
  Maximum   : 0.6000000000000000000000000000000000000006e51
  Range     : 0.2000000000000000000000000000000000000002e51
  Sum       : 0.15000000000000000000000000000000000000015e52
  Variance  : 0.1000000000000000000000000000000000000002000000000000000000000000000000000000001e101
  Std. Dev. : 0.1000000000000000000000000000000000000001e51
Column: 3
  Count     : 3
  Minimum   : 0.7000000000000000000000000000000000000007e51
  Mean      : 0.8000000000000000000000000000000000000008e51
  Median    : 0.8000000000000000000000000000000000000008e51
  Maximum   : 0.9000000000000000000000000000000000000009e51
  Range     : 0.2000000000000000000000000000000000000002e51
  Sum       : 0.24000000000000000000000000000000000000024e52
  Variance  : 0.1000000000000000000000000000000000000002000000000000000000000000000000000000001e101
  Std. Dev. : 0.1000000000000000000000000000000000000001e51
>
```
### rust
```
% cargo run -- --precision 340 --print_digits 80 test/data.csv
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 0.12s
     Running `target/debug/bfbs --precision 340 --print_digits 80 test/data.csv`
bfbs version v0.1.6
Using 340 bit precision for calculation and 80 digit decimal print out.

Processing file: "test/data.csv"
Column: 3
  Count     : 3
  Minimum   : 700000000000000000000000000000000000000700000000000.00000000000000000000000000000
  Mean      : 800000000000000000000000000000000000000800000000000.00000000000000000000000000000
  Median    : 800000000000000000000000000000000000000800000000000.00000000000000000000000000000
  Maximum   : 900000000000000000000000000000000000000900000000000.00000000000000000000000000000
  Range     : 200000000000000000000000000000000000000200000000000.00000000000000000000000000000
  Sum       : 2400000000000000000000000000000000000002400000000000.0000000000000000000000000000
  Variance  : 1.0000000000000000000000000000000000000020000000000000000000000000000000000000010e100
  Std. Dev. : 100000000000000000000000000000000000000100000000000.00000000000000000000000000000
Column: 1
  Count     : 3
  Minimum   : 100000000000000000000000000000000000000100000000000.00000000000000000000000000000
  Mean      : 200000000000000000000000000000000000000200000000000.00000000000000000000000000000
  Median    : 200000000000000000000000000000000000000200000000000.00000000000000000000000000000
  Maximum   : 300000000000000000000000000000000000000300000000000.00000000000000000000000000000
  Range     : 200000000000000000000000000000000000000200000000000.00000000000000000000000000000
  Sum       : 600000000000000000000000000000000000000600000000000.00000000000000000000000000000
  Variance  : 1.0000000000000000000000000000000000000020000000000000000000000000000000000000010e100
  Std. Dev. : 100000000000000000000000000000000000000100000000000.00000000000000000000000000000
Column: 2
  Count     : 3
  Minimum   : 400000000000000000000000000000000000000400000000000.00000000000000000000000000000
  Mean      : 500000000000000000000000000000000000000500000000000.00000000000000000000000000000
  Median    : 500000000000000000000000000000000000000500000000000.00000000000000000000000000000
  Maximum   : 600000000000000000000000000000000000000600000000000.00000000000000000000000000000
  Range     : 200000000000000000000000000000000000000200000000000.00000000000000000000000000000
  Sum       : 1500000000000000000000000000000000000001500000000000.0000000000000000000000000000
  Variance  : 1.0000000000000000000000000000000000000020000000000000000000000000000000000000010e100
  Std. Dev. : 100000000000000000000000000000000000000100000000000.00000000000000000000000000000
%
```
### Rscript
```
>Rscript.bat --version
Rscript (R) version 4.5.1 (2025-06-13)

>Rscript.bat bfbs.R --no-header -P 340 -p 80 test\data.csv
bfbs version 0v1
340  bit precision for calculations with  80  digits printed on output.
Column: V1
  Count      : 3
  Minimum    : 100000000000000000000000000000000000000100000000000.00000000000000000000000000000
  Mean       : 200000000000000000000000000000000000000200000000000.00000000000000000000000000000
  Maximum    : 300000000000000000000000000000000000000300000000000.00000000000000000000000000000
  Range      : 200000000000000000000000000000000000000200000000000.00000000000000000000000000000
  Sum        : 600000000000000000000000000000000000000600000000000.00000000000000000000000000000
  Variance   : 1.0000000000000000000000000000000000000020000000000000000000000000000000000000010e+100
  StdDev     : 100000000000000000000000000000000000000100000000000.00000000000000000000000000000
  Skewness   : 0.0000000000000000000000000000000000000000000000000000000000000000000000000000000
  Kurtosis   : -1.5000000000000000000000000000000000000000000000000000000000000000000000000000000
  StdErr     : 57735026918962576450914878050195745564817910153931.650178311147526447962975858095

Column: V2
  Count      : 3
  Minimum    : 400000000000000000000000000000000000000400000000000.00000000000000000000000000000
  Mean       : 500000000000000000000000000000000000000500000000000.00000000000000000000000000000
  Maximum    : 600000000000000000000000000000000000000600000000000.00000000000000000000000000000
  Range      : 200000000000000000000000000000000000000200000000000.00000000000000000000000000000
  Sum        : 1500000000000000000000000000000000000001500000000000.0000000000000000000000000000
  Variance   : 1.0000000000000000000000000000000000000020000000000000000000000000000000000000010e+100
  StdDev     : 100000000000000000000000000000000000000100000000000.00000000000000000000000000000
  Skewness   : 0.0000000000000000000000000000000000000000000000000000000000000000000000000000000
  Kurtosis   : -1.5000000000000000000000000000000000000000000000000000000000000000000000000000000
  StdErr     : 57735026918962576450914878050195745564817910153931.650178311147526447962975858095

Column: V3
  Count      : 3
  Minimum    : 700000000000000000000000000000000000000700000000000.00000000000000000000000000000
  Mean       : 800000000000000000000000000000000000000800000000000.00000000000000000000000000000
  Maximum    : 900000000000000000000000000000000000000900000000000.00000000000000000000000000000
  Range      : 200000000000000000000000000000000000000200000000000.00000000000000000000000000000
  Sum        : 2400000000000000000000000000000000000002400000000000.0000000000000000000000000000
  Variance   : 1.0000000000000000000000000000000000000020000000000000000000000000000000000000010e+100
  StdDev     : 100000000000000000000000000000000000000100000000000.00000000000000000000000000000
  Skewness   : 0.0000000000000000000000000000000000000000000000000000000000000000000000000000000
  Kurtosis   : -1.5000000000000000000000000000000000000000000000000000000000000000000000000000000
  StdErr     : 57735026918962576450914878050195745564817910153931.650178311147526447962975858095


>
```
### Comparison Table
Straw poll of current performance on linux; -

| bfbs | 3x3 speed | 1001x1 speed | 2331x4 speed |
--------------------------------------------------
| c++ | 4 mS | | |
------------------
| go | 5 mS | | |
-----------------
| java | 25 mS | | |
--------------------
| julia | 10 S | | |
---------------------
| perl | 100 mS | | |
---------------------
| python | 70 mS | | |
----------------------
| ruby | 150 mS | | |
---------------------
| rust | 4 mS | | |
-------------------
| Rscript | 15 S | | |
----------------------
