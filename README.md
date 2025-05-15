# bfbs
The bfbs.jl program is a command line utility that reads 1 or more data files containing columns of numbers and outputs the basic statistics of the file contents.
The bfbs.jl code is written in the julia language, as the .jl implies, and uses the julia big float number type to calculate statistics like sum, mean,
variance and standard deviation to a higher precision than the usual floating point number types. The "bfbs" name stands for "big float basic statistics".
The input data files (or file) are assumed by default to be in comma separated value (CSV) format. All data files are assumed to have no missing entries and
no NaN values in the columns of numbers. The data files may contain blank lines and comment lines, which by default start with the hash ("#") character.

This code was produced out of a combination of curiosity as to what julia would be like to code in and a desire to have better than double precision floating point
statistic calculations on my Apple Silicon laptop. Apple computers with Intel CPU's appear to have (80 bit?) long double precision floating point available,
but at least in C language coding Apple Silicon computers have no difference in precision between double and long double floating point calculations.
The output of the Number mode of the helloWorld (C code) utility on my MacOS Sequoia 15.4.1 Apple Silicon laptop is; -
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
