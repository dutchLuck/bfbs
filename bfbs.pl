#!/usr/bin/perl
#
# B F B S . P L
#
# bfbs.pl last edited on Sat Sep 20 21:45:59 2025
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
# 0v6 Cosmetic changes to output labels
#

use strict;
use warnings;
use Getopt::Long;
use Math::BigFloat;

# === Program Info ===
my $PROGRAM_NAME    = "bfbs.pl";
my $PROGRAM_VERSION = "0v6 (2025-09-20)";

# === Settings ===
my $precision       = 40;
my $use_population  = 0;
my $use_header      = 0;
my $use_scientific  = 0;
my $helpMsg         = "[--header] [--population] [--precision=N] [--scientific] file1.csv [file2.csv ...]";

GetOptions(
    "precision=i"   => \$precision,
    "population"    => \$use_population,
    "header"        => \$use_header,
    "scientific"    => \$use_scientific,
) or die "Usage: $0 $helpMsg\n";

# Set global Math::BigFloat precision
Math::BigFloat->precision(-$precision);  # Negative => significant digits

# Require at least one file
@ARGV or die "Usage: $0 $helpMsg\n";

# === Announce Info ===
print "$PROGRAM_NAME version $PROGRAM_VERSION\n";
print "Perl version: $^V\n";
print "Getopt::Long Version: ", ($Getopt::Long::VERSION // 'unknown'), "\n";
print "Math::BigFloat Version: ", ($Math::BigFloat::VERSION // 'unknown'), "\n";
print "Precision: $precision digits\n";
print "Output Format: ", ($use_scientific ? "Scientific" : "Decimal"), "\n";

# === File Processing ===
foreach my $file (@ARGV) {
    open my $fh, '<', $file or die "Cannot open $file: $!";

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

        my $divisor;
        if ($use_population) {
            $divisor = Math::BigFloat->new($n);
        } else {
            if ($n <= 1) {
                warn "Not enough data in $label to compute sample variance (n = $n)\n";
                next;
            }
            $divisor = Math::BigFloat->new($n - 1);
        }

        my $variance = $var_sum->copy()->bdiv($divisor);
        my $stddev   = $variance->copy()->bsqrt();

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
        print "  Count     : $n\n";
        print "  Minimum   : ", ($use_scientific ? $min->bnstr() : $min->bstr()), "\n";
        print "  Mean      : ", ($use_scientific ? $mean->bnstr() : $mean->bstr()), "\n";
        print "  Median    : ", ($use_scientific ? $median->bnstr() : $median->bstr()), "\n";
        print "  Maximum   : ", ($use_scientific ? $max->bnstr() : $max->bstr()), "\n";
        print "  Range     : ", ($use_scientific ? $range->bnstr() : $range->bstr()), "\n";
        print "  Sum       : ", ($use_scientific ? $sum->bnstr() : $sum->bstr()), "\n";
        print "  Variance  : ", ($use_scientific ? $variance->bnstr() : $variance->bstr()), " ", ($use_population ? "(population)" : "(sample)"), "\n";
        print "  Std. Dev. : ", ($use_scientific ? $stddev->bnstr() : $stddev->bstr()), " ", ($use_population ? "(population)" : "(sample)"),"\n";
    }
}
