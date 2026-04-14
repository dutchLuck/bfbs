#!/usr/bin/perl
#
# B F B S . P L
#
# bfbs.pl last edited on Sat Feb 28 17:17:13 2026 as version 0v9
#
# This script reads one or more CSV files, containing one or more columns of
# numbers and calculates basic statistics for each column (including sum,
# average, variance and standard deviation) and outputs the results.
#

# ChatGPT prompts that produced this bfbs.pl script; -
# 1. Please write a perl script that reads one or more 
#    comma separated value data files containing one or more
#    columns of numbers and calculates the sum, mean,
#    variance and standard deviation for each column
#    using the arbitrary-precision floating point
#    arithmetic package Math::BigFloat and writes
#    out the results for each column in each file.
#    Ensure that the script can handle leading spaces
#    on numbers, blank rows in files and comment lines
#    beginning with a hash. Allow the precision to be
#    controlled by the user from the command line.
# 2. Please make the calculated variance the sample form
#    of variance i.e. = sum((x - mean)^2) / (n - 1)
#    unless the user sets an option in the command line.
# 3. Please enhance the script to calculate and output
#    min, median, max and range.
# 4. Please enhance the script to handle headers in the
#    top of row of the CSV columns when the user flags
#    this in the command line.
# 5. Please add a command line option to make the output
#    use scientific format e.g. 1.0e1
# 6. ~ Fix errors
# 7. Please add announcement info at the start of output
#    that has the program name and version number,
#    then the version of perl that is running the code and
#    then the version numbers of the packages used if they
#    exist and finally output the precision and output format
#    being used.

#
# 0v9 Added population variance and population standard deviation calculations and output
# 0v8 Add --quiet option to suppress elapsed time output
# 0v7 Add code execution elapsed calculation
# 0v6 Cosmetic changes to output labels

# Deviations from other bfbs implementations; -
# 1. This Perl version of bfbs aborts with an error if the
# input file cannot be opened, whereas the Ruby and Python
# versions print a warning and skip to the next file, if there
# is a next file.

# Perl Math::BigFloat's precision method sets the
# number of significant digits, not decimal places.
# This 0v8 version of bfbs.pl uses the "accuracy"
# method to set the number of digits each result
# should have, which is more intuitive for users
# who want to specify precision in terms of digits.
# The "precision" method in Math::BigFloat sets the
# number of significant digits, which can lead to
# confusion when dealing with numbers of varying
# magnitudes. By using "accuracy", we ensure that
# all results are consistently formatted to the
# specified number of digits, regardless of their size.
# (see https://perldoc.perl.org/Math::BigFloat)

# MARK: 
# === Modules ===
use strict;
use warnings;
use Getopt::Long;
use Math::BigFloat;     # arbitrary-precision floating point arithmetic
use Time::HiRes qw(time);   # elapsed time measurement

# === Start Timing ===
my $start_time = time();

# === Program Info ===
my $PROGRAM_NAME    = "bfbs.pl";
my $PROGRAM_VERSION = "0v9 (2026-04-14)";

# MARK:
# === Settings ===
my $precision       = 40;
my $use_header      = 0;
my $use_scientific  = 0;
my $quiet           = 0;
my $help            = 0;
my $helpMsg         = << "HELP_MSG";
[--header] [--help] [--precision=N] [--scientific] [--quiet] file1.csv [file2.csv ...]
 where:
  --header       : Treat first CSV row as column headers
  --help         : Show this help message and exit
  --precision=N  : Set precision to N digits (default: 40)
  --scientific   : Output numbers in scientific notation (e.g. 1.0e1)
  --quiet        : Suppress version and elapsed time info output
  file1.csv ...  : One or more CSV files to process
HELP_MSG

GetOptions(
    "precision=i"   => \$precision,
    "header"        => \$use_header,
    "help"          => \$help,
    "scientific"    => \$use_scientific,
    "quiet"         => \$quiet,
) or die "Usage: $0 $helpMsg\n";

# Show help and exit if requested
if ($help) { die "Usage: $0 $helpMsg\n" };

# Set global Math::BigFloat precision
Math::BigFloat->accuracy($precision);  # "accuracy()" sets the number of digits each result should have

# Require at least one file
@ARGV or die "Error: No input files specified.\nUsage: $0 $helpMsg\n";

# === Announce Info ===
unless ($quiet) {
    print "$PROGRAM_NAME version $PROGRAM_VERSION\n";
    print "Perl version: $^V\n";
    print "Getopt::Long Version: ", ($Getopt::Long::VERSION // 'unknown'), "\n";
    print "Math::BigFloat Version: ", ($Math::BigFloat::VERSION // 'unknown'), "\n";
}
print "Precision: $precision digits, Output Format: ", ($use_scientific ? "Scientific" : "Decimal"), "\n";

# MARK:
# === File Processing ===
foreach my $file (@ARGV) {
    open my $fh, '<', $file or die "Error: Cannot open \"$file\": $!";

    print "\nFile: $file\n";

    my @columns;       # Array of arrayrefs for column data
    my @headers;       # Column headers
    my $header_found = 0;

    while (my $line = <$fh>) {
        chomp $line;
        $line =~ s/\r//g;

        next if $line =~ /^\s*$/;    # Blank lines
        next if $line =~ /^\s*#/;    # Comments

        my @fields = split /\s*,\s*/, $line;

        if ($use_header && !$header_found) {
            @headers = @fields;
            $header_found = 1;
            next;
        }

        for my $i (0 .. $#fields) {
            my $val = $fields[$i];
            $val =~ s/^\s+//;

            $columns[$i] ||= [];
            push @{$columns[$i]}, Math::BigFloat->new($val);
        }
    }

    close $fh;

    for my $i (0 .. $#columns) {
        my $data = $columns[$i];
        next unless @$data;

        my $label = $use_header ? ($headers[$i] // ($i + 1)) : ($i + 1);

        my $n = scalar @$data;
        my $sum = Math::BigFloat->new(0);
        $sum->badd($_) for @$data;

        my $mean = $sum->copy()->bdiv($n);

        # Variance
        my $var_sum = Math::BigFloat->new(0);
        for my $x (@$data) {
            my $diff = $x->copy()->bsub($mean);
            $var_sum->badd($diff->bpow(2));
        }

        my $ndivisor;
        my $n1divisor;
        if ($n <= 1) {
            warn "Not enough data in $label to compute sample variance (n = $n)\n";
            next;
        }
        $ndivisor = Math::BigFloat->new($n);
        $n1divisor = Math::BigFloat->new($n - 1);

        my $pvariance = $var_sum->copy()->bdiv($ndivisor);
        my $pstddev   = $pvariance->copy()->bsqrt();
        my $svariance = $var_sum->copy()->bdiv($n1divisor);
        my $sstddev   = $svariance->copy()->bsqrt();

        # Min, Median, Max, Range
        my @sorted = sort { $a->bcmp($b) } @$data;
        my $min    = $sorted[0]->copy();
        my $max    = $sorted[-1]->copy();
        my $range  = $max->copy()->bsub($min);
        my $median;

        if ($n % 2 == 1) {
            $median = $sorted[int($n / 2)]->copy();
        } else {
            my $mid1 = $sorted[$n/2 - 1]->copy();
            my $mid2 = $sorted[$n/2]->copy();
            $median = $mid1->badd($mid2)->bdiv(2);
        }

        print "\nColumn: $label\n";
        print "  Count        : $n\n";
        print "  Minimum      : ", ($use_scientific ? $min->bnstr() : $min->bstr()), "\n";
        print "  Mean         : ", ($use_scientific ? $mean->bnstr() : $mean->bstr()), "\n";
        print "  Median       : ", ($use_scientific ? $median->bnstr() : $median->bstr()), "\n";
        print "  Maximum      : ", ($use_scientific ? $max->bnstr() : $max->bstr()), "\n";
        print "  Range        : ", ($use_scientific ? $range->bnstr() : $range->bstr()), "\n";
        print "  Sum          : ", ($use_scientific ? $sum->bnstr() : $sum->bstr()), "\n";
        print "  Variance (s²): ", ($use_scientific ? $svariance->bnstr() : $svariance->bstr()), "\n";
        print "  Std. Dev. (s): ", ($use_scientific ? $sstddev->bnstr() : $sstddev->bstr()), "\n";
        print "  Variance (σ²): ", ($use_scientific ? $pvariance->bnstr() : $pvariance->bstr()), "\n";
        print "  Std. Dev. (σ): ", ($use_scientific ? $pstddev->bnstr() : $pstddev->bstr()), "\n";
    }
}

# === Elapsed Time Calculation ===
unless ($quiet) {
    my $end_time = time();
    my $elapsed = $end_time - $start_time;
    printf("\nbfbs.pl execution elapsed time: %.6f [sec]\n", $elapsed);
}