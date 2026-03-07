#!/usr/bin/env tclsh
#
# B F B S . T C L
#
# bfbs.tcl last edited on Sat Mar  7 10:21:58 2026

# This script reads the columns of data contained in one or more
# CSV files and outputs the basic statistics of each column. It
# uses arbitrary precision calculations to provide a print-out
# of stats such as mean and standard deviation. The script was
# mostly written by AI, but AI really did a lot of looping through
# small check scripts and struggled to come up with a script
# that worked for both integer data and floating point data on
# the old tcl version that comes with MacOS (tcl 8.5.9). This
# script is only known to work on MacOS and tcl version 8.5.9,
# but it may work on later tcl versions and on other operating
# systems. Currently it has not been tested on anything other than
# MacOS.

# Requirements:
#   tcllib (for math::bigfloat)

# Usage:
#   bfbs.tcl ?-h? ?-p N? ?-P N? ?--quiet? file1.csv file2.csv ...
#       -h / --help  this usage / help message
#       -p N / --print-digits N  number of fractional digits to print (default 10)
#       -P N / --precision N  sets math::bigfloat precision (default 40 digits)
#        N.B. if the installed tcllib is too old precision may be ignored
#       -q / --quiet suppress timing and header output

# Known or suspected script short-comings; -
# 1. AI seems to have over-developed it and included excess lines of code
# 2. May prove to be a tcl version 8.5 specific implementation

# 0.1.0  Original version of bfbs.tcl

package require Tcl 8.5
package require math::bigfloat

# start timing the script
set start_time [clock milliseconds]

# script version
set script_version "0.1.0"

# ---- Command line argument processing ----

set precision 40   ;# default arithmetic precision (bits)
set digits 10      ;# default number of fractional digits to print
set quiet 0        ;# default: show timing
set files {}

proc helpMsg {cmd} {
    global precision
    global digits

    puts stderr "\nUsage: $cmd ?-h? ?--quiet? ?-p N? ?-P N? file1.csv file2.csv ..."
    puts stderr "  Where; -"
    puts stderr "   -h / --help      print this usage / help message and exit"
    puts stderr "   -p N / --print-digits N   number of fractional digits to print (default $digits)"
    puts stderr "   -P N / --precision N      sets math::bigfloat precision (default $precision digits)"
    puts stderr "              N.B. if the installed tcllib is too old precision may be ignored"
    puts stderr "   -q / --quiet     suppress timing and header output"
    puts stderr "   -v / --version   print version message and exit\n"
}


for {set i 0} {$i < $argc} {incr i} {
    set arg [lindex $argv $i]
    if {$arg eq "--precision" || $arg eq "-P"} {
        incr i
        if {$i >= $argc} {
            puts stderr "Missing value for -precision"
            exit 1
        }
        set precision [lindex $argv $i]
    } elseif {$arg eq "-p" || $arg eq "--print-digits"} {
        incr i
        if {$i >= $argc} {
            puts stderr "Missing value for -p"
            exit 1
        }
        set digits [lindex $argv $i]
    } elseif {$arg eq "-q" || $arg eq "--quiet"} {
        set quiet 1
    } elseif {$arg eq "-h" || $arg eq "--help"} {
        helpMsg $argv0
        exit 1
    } elseif {$arg eq "-v" || $arg eq "--version"} {
        puts "${argv0} version $script_version"
        exit 0
    } elseif {[string match "-*" $arg]} {
        puts "Warning: option \"$arg\" not recognised"
    } else {
        lappend files $arg
    }
}

# print version and tclsh info unless quiet
if {!$quiet} {
    puts "Info: ${argv0} version $script_version"
    puts "Info: tclsh version [info patchlevel]"
    puts "Info: math::bigfloat version info is [package versions math::bigfloat]"
}

puts "Info: precision: $precision, print digits: $digits"

# print the help/usage if no files are specified
if {[llength $files] == 0} {
    helpMsg $argv0
    exit 1
}

# determine whether bigfloat precision can be controlled
set has_precision 1
if {[info commands math::bigfloat::precision] ne ""} {
    math::bigfloat::precision $precision
} else {
    set has_precision 0
    puts stderr "Warning: math::bigfloat::precision command not available."
}


# helper to format doubles when precision support absent
proc format_double {val digits} {
    # val assumed to be a numeric value (string) readable by double
    return [format %.*f $digits $val]
}


# ---- helper for sorting values when computing median ----
proc bf_compare {a b} {
    # return -1/0/1 depending on a<b, a==b, a>b
    set cmp [math::bigfloat::compare $a $b]
    if {$cmp < 0} {return -1} elseif {$cmp > 0} {return 1} else {return 0}
}


# integer comparator
proc int_compare {a b} {
    if {$a < $b} {return -1} elseif {$a > $b} {return 1} else {return 0}
}


# ---- Format BigFloat for printing with specified fractional digits (rounding)
proc format_bf {bf digits} {
    
    if {$digits < 0} {set digits 0}

    # If zero fractional digits requested, round to integer
    if {$digits == 0} {
        set rounded [math::bigfloat::round $bf]
        set val [math::bigfloat::add [math::bigfloat::fromstr "0.0"] $rounded]
        set result [math::bigfloat::tostr $val]
        return [string trim $result]
    }

    # Get the string representation from bigfloat
    set s [math::bigfloat::tostr $bf]
    set s [string trim $s]
    
    # If in scientific notation, return as-is (we can't improve on it without precision)
    if {[string first e $s] >= 0 || [string first E $s] >= 0} {
        return $s
    }
    
    # For decimal numbers, format to the desired width
    if {[string first "." $s] == -1} {
        # No decimal point, add one with zeros
        return [format "%s.%s" $s [string repeat 0 $digits]]
    }
    
    set parts [split $s .]
    set intpart [lindex $parts 0]
    set fracpart [lindex $parts 1]
    set flen [string length $fracpart]
    
    if {$flen < $digits} {
        # Pad with zeros
        append fracpart [string repeat 0 [expr {$digits - $flen}]]
    } elseif {$flen > $digits} {
        # Truncate to desired width
        set fracpart [string range $fracpart 0 [expr {$digits-1}]]
    }
    
    return [format "%s.%s" $intpart $fracpart]
}


# ---- Initialize accumulators ----
proc initColumnStats {ncol} {
    global precision
    set stats {}
    for {set i 0} {$i < $ncol} {incr i} {
        dict set s sum        [math::bigfloat::fromstr "0.0" $precision]
        dict set s sumsq      [math::bigfloat::fromstr "0.0" $precision]
        dict set s count      0
        dict set s min        ""  ;# will hold first value seen
        dict set s max        ""
        dict set s values     {}
        lappend stats $s
    }
    return $stats
}


# ---- Process a single file ----
proc processFile {fname precision} {
    global digits has_precision
    puts "Processing: $fname  (precision = $precision bits)"

    if {[catch {set f [open $fname r]} err]} {
        puts stderr "Cannot open file $fname: $err"
        return
    }

    set stats {}
    set ncol 0

    while {[gets $f line] >= 0} {
        # Skip comment lines & blank lines
        if {[regexp {^\s*$} $line]} continue
        if {[string index $line 0] eq "#"} continue

        # Split CSV row (simple split on commas)
        set fields [split $line ,]

        # Determine number of columns from first data line
        if {$ncol == 0} {
            set ncol [llength $fields]
            set stats [initColumnStats $ncol]
        }

        # Process each column
        for {set i 0} {$i < $ncol} {incr i} {
            set v [string trim [lindex $fields $i]]
            if {$v eq ""} continue   ;# skip empty entries

            # Convert to either integer or bigfloat (errors if not numeric)
            if {[catch {set bf [math::bigfloat::fromstr $v]}]} {
                continue   ;# ignore non-numeric values
            }

            if {[math::bigfloat::isInt $bf]} {      # handle integer input number case
                # ensure bf is a BigFloat (fromstr returns BigInt for integers)
                set bf [math::bigfloat::add [math::bigfloat::fromstr "0.0" $precision] $bf]
            } else {      # handle floating point input number case
                set bf [math::bigfloat::fromstr $v $precision]
            }

            # Get previous column statistics
            set column [lindex $stats $i]

            # Update sum, sumsq, count
            set sum        [dict get $column sum]
            set sumsq      [dict get $column sumsq]
            set count      [dict get $column count]

            set sum   [math::bigfloat::add $sum $bf]
            set sq    [math::bigfloat::mul $bf $bf]
            set sumsq [math::bigfloat::add $sumsq $sq]
            incr count

            # update min/max
            if {$count == 1} {
                set min $bf
                set max $bf
            } else {
                set min [dict get $column min]
                set max [dict get $column max]
                if {[math::bigfloat::compare $bf $min] < 0} {
                    set min $bf
                }
                if {[math::bigfloat::compare $bf $max] > 0} {
                    set max $bf
                }
            }

            # append value to list for median
            set vals [dict get $column values]
            lappend vals $bf

            dict set column sum   $sum
            dict set column sumsq $sumsq
            dict set column count $count
            dict set column min   $min
            dict set column max   $max
            dict set column values $vals
            set stats [lreplace $stats $i $i $column]
        }
    }
    close $f

    # ---- Compute and print statistics ----
    for {set i 0} {$i < $ncol} {incr i} {
        set column [lindex $stats $i]
        set count  [dict get $column count]

        if {$count == 0} {
            puts "Column [expr {$i+1}]: No numeric data"
            continue
        }

        if {$has_precision} {
            # convert count, sum, and sumsq to BigFloat values to avoid
            # integer division (fromstr returns plain integer if input has no
            # decimal point)
            set n     [math::bigfloat::add [math::bigfloat::fromstr "0.0"] \
                          [math::bigfloat::fromstr $count]]
            set one   [math::bigfloat::fromstr "1.0"]
            set n_m_1 [math::bigfloat::sub $n $one]
            set sum   [math::bigfloat::add [math::bigfloat::fromstr "0.0"] \
                          [dict get $column sum]]
            set sumsq [math::bigfloat::add [math::bigfloat::fromstr "0.0"] \
                             [dict get $column sumsq]]

            set mean [math::bigfloat::div $sum $n]

            # variance = E[x^2] - (E[x])^2
            set ex2  [math::bigfloat::div $sumsq $n]
            set mean2 [math::bigfloat::mul $mean $mean]
            set var   [math::bigfloat::sub $ex2 $mean2]
            # coerce to a proper BigFloat object; subtraction may return an
            # integer string when the result is exact, and sqrt() requires an
            # actual BigFloat.  adding a 0.0 bigfloat forces the conversion.
            set var [math::bigfloat::add [math::bigfloat::fromstr "0.0"] $var]
        } else {
            # still use math::bigfloat (precision cannot be controlled  but library works)
            set n     [math::bigfloat::add [math::bigfloat::fromstr "0.0" $precision] \
                          [math::bigfloat::fromstr $count]]
            set one   [math::bigfloat::fromstr "1.0" $precision]
            set n_m_1 [math::bigfloat::sub $n $one]
            set sum   [math::bigfloat::add [math::bigfloat::fromstr "0.0" $precision] \
                          [dict get $column sum]]
            set sumsq [math::bigfloat::add [math::bigfloat::fromstr "0.0" $precision] \
                             [dict get $column sumsq]]

            set mean [math::bigfloat::div $sum $n]

            # variance (sigma^2) = E[x^2] - (E[x])^2
            set ex2  [math::bigfloat::div $sumsq $n]
            set mean2 [math::bigfloat::mul $mean $mean]
            set var_n [math::bigfloat::sub $ex2 $mean2]
            set var_n [math::bigfloat::add [math::bigfloat::fromstr "0.0" $precision] $var_n]

            # variance (s^2) = (SumSq − (Sum × Sum) / n) / (n − 1)
            set mean2 [math::bigfloat::mul $sum $sum]
            set ex2 [math::bigfloat::div $mean2 $n]
            set mean2  [math::bigfloat::sub $sumsq $ex2]
            set var  [math::bigfloat::div $mean2 $n_m_1]
            set var [math::bigfloat::add [math::bigfloat::fromstr "0.0" $precision] $var]
        }

        # std deviation = sqrt(variance)
        set stddev_n [math::bigfloat::sqrt $var_n]
        set stddev [math::bigfloat::sqrt $var]

        # get min/max for range
        set min     [dict get $column min]
        set max     [dict get $column max]
        set range   [math::bigfloat::sub $max $min]

        # compute median: sort values list
        set vals [dict get $column values]
        set med ""
        if {[llength $vals] > 0} {
            set sorted [lsort -command bf_compare $vals]
            set len [llength $sorted]
            if {$len % 2} {
                set med [lindex $sorted [expr {$len/2}]]
            } else {
                set m1 [lindex $sorted [expr {$len/2 - 1}]]
                set m2 [lindex $sorted [expr {$len/2}]]
                set med [math::bigfloat::div [math::bigfloat::add $m1 $m2] [math::bigfloat::fromstr "2.0"]]
            }
        }

        # output in desired order: minimum, mean, median, maximum, range, sum, variance, stddev
        puts "Column [expr {$i+1}]:"
        puts "    count      = $count"
        puts "    minimum    = [format_bf $min $digits]"
        puts "    mean       = [format_bf $mean $digits]"
        if {$med ne ""} {
            puts "    median     = [format_bf $med $digits]"
        }
        puts "    maximum    = [format_bf $max $digits]"
        puts "    range      = [format_bf $range $digits]"
        puts "    sum        = [format_bf $sum $digits]"
        puts "    variance   = [format_bf $var $digits]"
        puts "    stddev     = [format_bf $stddev $digits]"
        puts "    variance n = [format_bf $var_n $digits]"
        puts "    stddev n   = [format_bf $stddev_n $digits]"
    }

    puts ""
}

# ---- Run on all files ----
foreach f $files {
    processFile $f $precision
}

set end_time [clock milliseconds]
set elapsed_secs [expr {($end_time - $start_time) / 1000.0}]

if {!$quiet} {
    puts "Info: bfbs (tcl) time taken: [format {%.6f} $elapsed_secs] \[sec\]"
}
