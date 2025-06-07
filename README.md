# bfbs
The bfbs.jl program is a command line utility that reads 1 or more data files
containing columns of numbers and outputs the basic statistics of the file contents.
The bfbs.jl code is written in the julia language, as the .jl implies, and
uses the julia big float number type to calculate statistics like sum, mean,
variance and standard deviation to a higher precision than the usual floating point
number types. The "bfbs" name stands for "big float basic statistics".
The input data files (or file) are assumed by default to be in comma separated value (CSV)
format. All data files are assumed to have no missing entries and
no NaN values in the columns of numbers. The data files may contain blank lines
and these are ignored. It may also contain comment lines, which also are ignored.
Comment lines by default are assumed to start with the hash ("#") character.

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
% julia bfbs.jl -p 40 test/data.csv
Row Counts:
3
3
3
Row Minimums:
1.0000000000000000000000000000000000000010e+50
2.0000000000000000000000000000000000000020e+50
3.0000000000000000000000000000000000000030e+50
Row Medians:
4.0000000000000000000000000000000000000040e+50
5.0000000000000000000000000000000000000050e+50
6.0000000000000000000000000000000000000060e+50
Row Maximums:
7.0000000000000000000000000000000000000070e+50
8.0000000000000000000000000000000000000080e+50
9.0000000000000000000000000000000000000090e+50
Row Ranges:
6.0000000000000000000000000000000000000060e+50
6.0000000000000000000000000000000000000060e+50
6.0000000000000000000000000000000000000060e+50
Row Means:
4.0000000000000000000000000000000000000040e+50
5.0000000000000000000000000000000000000050e+50
6.0000000000000000000000000000000000000060e+50
Row Sums:
1.2000000000000000000000000000000000000012e+51
1.5000000000000000000000000000000000000015e+51
1.8000000000000000000000000000000000000018e+51
Row Variances:
9.0000000000000000000000000000000000000180e+100
9.0000000000000000000000000000000000000180e+100
9.0000000000000000000000000000000000000180e+100
Row Standard Deviations:
3.0000000000000000000000000000000000000030e+50
3.0000000000000000000000000000000000000030e+50
3.0000000000000000000000000000000000000030e+50
Column Counts:
3
3
3
Column Minimums:
1.0000000000000000000000000000000000000010e+50
4.0000000000000000000000000000000000000040e+50
7.0000000000000000000000000000000000000070e+50
Column Medians:
2.0000000000000000000000000000000000000020e+50
5.0000000000000000000000000000000000000050e+50
8.0000000000000000000000000000000000000080e+50
Column Maximums:
3.0000000000000000000000000000000000000030e+50
6.0000000000000000000000000000000000000060e+50
9.0000000000000000000000000000000000000090e+50
Column Ranges:
2.0000000000000000000000000000000000000020e+50
2.0000000000000000000000000000000000000020e+50
2.0000000000000000000000000000000000000020e+50
Column Means:
2.0000000000000000000000000000000000000020e+50
5.0000000000000000000000000000000000000050e+50
8.0000000000000000000000000000000000000080e+50
Column Sums:
6.0000000000000000000000000000000000000060e+50
1.5000000000000000000000000000000000000015e+51
2.4000000000000000000000000000000000000024e+51
Column Variances:
1.0000000000000000000000000000000000000020e+100
1.0000000000000000000000000000000000000020e+100
1.0000000000000000000000000000000000000020e+100
Column Standard Deviations:
1.0000000000000000000000000000000000000010e+50
1.0000000000000000000000000000000000000010e+50
1.0000000000000000000000000000000000000010e+50
% 
```
The useage information for bfbs.jl is; -
```
% julia bfbs.jl --help                 
usage: bfbs.jl [-c COMMENT_CHAR] [-C] [-d DELIMITER_CHAR] [-D] [-H]
               [-n] [-p PRINT_DIGITS] [-R] [-s SKIP] [-v] [-V] [-h]
               [files...]

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
  -H, --header          The first row is treated as a header.
  -n, --n_divisor       Use the actual number of samples n as the
                        Standard Deviation divisor, rather than n-1.
  -p, --print_digits PRINT_DIGITS
                        Write output with "PRINT-DIGITS" digits. If
                        not provided, 25 output digits are used.
  -R, --no_row_stats    Disable row statistics calculation and output.
  -s, --skip SKIP       Skip first "SKIP" lines in data file(s). If
                        not provided, zero lines are skipped.
  -v, --verbose         Provide extra information about the current
                        run and the data.
  -V, --version         Provide version information.
  -h, --help            show this help message and exit

%
```
This code was produced out of a combination of curiosity as to what julia would be like
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
