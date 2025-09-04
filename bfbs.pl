#!/usr/bin/perl
#
# B F B S . P L
#
# bfbs.pl last edited on Wed Sep  3 22:09:34 2025
#
# This script reads one or more CSV files, containing one or more columns of
# numbers and calculates basic statistics for each column (including sum,
# average, variance and standard deviation) and outputs the results.
#

use strict;
use warnings;
use Getopt::Long;
use Math::BigFloat;

# ChatGPT prompts that produced thid bfbs.pl script; -
# 1. Please write a perl script that reads one or more 
# comma separated value data files containing one or more
# columns of numbers and calculates the sum, mean,
# variance and standard deviation for each column
# using the arbitrary-precision floating point
# arithmetic package Math::BigFloat and writes
# out the results for each column in each file.
# Ensure that the script can handle leading spaces
# on numbers, blank rows in files and comment lines
# beginning with a hash. Allow the precision to be
# controlled by the user from the command line.

# Default precision
my $precision = 40;
GetOptions("precision=i" => \$precision) or die "Usage: $0 [--precision=N] file1.csv file2.csv ...\n";

# Set global Math::BigFloat precision
Math::BigFloat->precision(-$precision);  # negative precision = significant digits

# Check for files
@ARGV or die "Usage: $0 [--precision=N] file1.csv file2.csv ...\n";

foreach my $file (@ARGV) {
    open my $fh, '<', $file or die "Cannot open $file: $!";

    print "\nFile: $file\n";

    my @columns;  # array of arrayrefs, one per column

    while (my $line = <$fh>) {
        chomp $line;
        $line =~ s/\r//g;  # Handle Windows line endings

        next if $line =~ /^\s*$/;        # Skip blank lines
        next if $line =~ /^\s*#/;        # Skip comment lines

        my @fields = split /\s*,\s*/, $line;

        for my $i (0 .. $#fields) {
            my $val = $fields[$i];
            $val =~ s/^\s+//;  # Remove leading whitespace

            # Initialize column if not exists
            $columns[$i] ||= [];
            push @{$columns[$i]}, Math::BigFloat->new($val);
        }
    }

    close $fh;

    # Compute statistics for each column
    for my $i (0 .. $#columns) {
        my $data = $columns[$i];
        next unless @$data;

        my $n = scalar @$data;
        my $sum = Math::BigFloat->new(0);
        $sum->badd($_) for @$data;

        my $mean = $sum->copy()->bdiv($n);

        # Variance = sum((x - mean)^2) / n
        my $var_sum = Math::BigFloat->new(0);
        for my $x (@$data) {
            my $diff = $x->copy()->bsub($mean);
            $var_sum->badd($diff->bpow(2));
        }
        my $variance = $var_sum->copy()->bdiv($n);
        my $stddev = $variance->copy()->bsqrt();

        print "\nColumn ", $i + 1, ":\n";
        print "  Count     : $n\n";
        print "  Sum       : $sum\n";
        print "  Mean      : $mean\n";
        print "  Variance  : $variance\n";
        print "  Std Dev   : $stddev\n";
    }
}
