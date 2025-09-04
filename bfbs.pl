#!/usr/bin/perl
#
# B F B S . P L
#
# bfbs.pl last edited on Wed Sep  3 22:29:34 2025
#
# This script reads one or more CSV files, containing one or more columns of
# numbers and calculates basic statistics for each column (including sum,
# average, variance and standard deviation) and outputs the results.
#

use strict;
use warnings;
use Getopt::Long;
use Math::BigFloat;

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

# Default settings
my $precision = 40;
my $use_population = 0;
my $use_header = 0;

GetOptions(
    "precision=i"   => \$precision,
    "population"    => \$use_population,
    "header"        => \$use_header,
) or die "Usage: $0 [--precision=N] [--population] [--header] file1.csv file2.csv ...\n";

# Set global Math::BigFloat precision
Math::BigFloat->precision(-$precision);  # Negative => significant digits

# Require at least one file
@ARGV or die "Usage: $0 [--precision=N] [--population] [--header] file1.csv file2.csv ...\n";

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

        my $label = $use_header ? ($headers[$i] // "Column " . ($i + 1)) : "Column " . ($i + 1);

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

        print "\n$label:\n";
        print "  Count     : $n\n";
        print "  Min       : $min\n";
        print "  Median    : $median\n";
        print "  Max       : $max\n";
        print "  Range     : $range\n";
        print "  Sum       : $sum\n";
        print "  Mean      : $mean\n";
        print "  Variance  : $variance ", ($use_population ? "(population)" : "(sample)"), "\n";
        print "  Std Dev   : $stddev ", ($use_population ? "(population)" : "(sample)"), "\n";
    }
}
