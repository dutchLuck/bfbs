#! /usr/bin/env julia
#
# B F B S . J L
#
# Big Float Basic Statistics
#
# bfbs.jl last updated on Fri Mar 27 22:46:14 2026 by O.H. as 0v12
#
# Descendant of readdatafile.jl 0v1
#

# Read in one or more files containing one or more rows and columns
# of numbers. Then use julia's big float calculation capability to
# calculate basic statistics like median, arithmetic mean, sum,
# variance and standard deviation for those rows and columns.
# Finally output the basic statistics results to the stdout.

## Recipe for Linux (Ubuntu 22.04 LTS) julia install, bfbs.jl clone and run ##
# sudo apt install curl
# curl -fsSL http://install.julialang.org | sh
# >Proceed with installation
# "restart the terminal"
# mkdir src
# cd src
# mkdir julia
# cd julia
# git clone https://github.com/dutchLuck/bfbs
# cd bfbs
# chmod u+x bfbs.jl
# julia
# ]
# add ArgParse
# ^D
# ./bfbs.jl -V
# bfbs version 0v9 (2025-09-05)
##

#
# 0v12 added --quiet option to suppress output of time and version information
#      and added population variance & standard deviation calculations to output
# 0v11 output the elapsed time for the script to run
# 0v10 corrected --help message
# 0v9 output Results digits and changed grouping of row/column stats
#     output and added --scientific -e option for scientific format
# 0v8 added --precision option and limited print_digits to 100 digits 
# 0v7 removed unused --output option and rationalized print output 
# 0v6 added -n option to swap from n-1 to n as the Standard Deviation divisor
# 0v5 added -D option to enable debug level of information output
# 0v4 added control of print_digits used in output format with -p option
# 0v3 added output of count, minimum, median, maximum and range
# 0v2 added better handling of non-existent files
#

using DelimitedFiles
using Statistics
using Printf
using ArgParse
using InteractiveUtils	# for versioninfo()

# MARK: Parse Arguments

function parse_arguments()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--comment_char", "-c"
        arg_type = String
        help = "Define the Comment Delimiter character as \"COMMENT_CHAR\". If not provided, hash (\"#\") is used."
		
        "--no_column_stats", "-C"
        action = :store_true
        help = "Disable column statistics calculation and output."
		
        "--delimiter_char", "-d"
        arg_type = String
        help = "Define the Column Delimiter character as \"DELIMITER_CHAR\". If not provided, comma (\",\") is used."

        "--debug", "-D"
        action = :store_true
        help = "Provide copious amounts of information about the current run and the data."

        "--scientific", "-e"
        action = :store_true
        help = "Output statistics results in scientific number format."

        "--header", "-H"
        action = :store_true
        help = "The first row is treated as a header."

        "--print_digits", "-p"
        arg_type = String
        help = "Write output with \"PRINT-DIGITS\" digits. If not provided, 64 output digits are used."

        "--precision", "-P"
        arg_type = String
        help = "Calculate using \"PRECISION\" bits. If not provided, 256 bits of precision are used."

        "--no_row_stats", "-R"
        action = :store_true
        help = "Disable row statistics calculation and output."

        "--skip", "-s"
        arg_type = String
        help = "Skip first \"SKIP\" lines in data file(s). If not provided, zero lines are skipped."

        "--verbose", "-v"
        action = :store_true
        help = "Provide extra information about the current run and the data."

        "--version", "-V"
        action = :store_true
        help = "Provide version information."

        "--quiet", "-q"
        action = :store_true
        help = "Suppress output of time and version information and over-ride --verbose."

        "files"
        nargs = '*'
        help = "Input files containing 1 or more columns of numbers. Default file format has comma separated columns."
    end

    return parse_args(s)
end

# MARK: Read CSV into BigFloat

# Function to read a file and convert to BigFloat matrix
function read_bignum_matrix(filepath::String, delimiter::Char, header::Bool, verbose::Bool, linestoskip::Integer, comment_start::Char)
	if header
		raw_data, raw_hdr = readdlm(filepath, delimiter, String;
			header=true, skipstart=linestoskip, skipblanks=true, comments=true, comment_char=comment_start)
		if verbose
			println("Header: $raw_hdr")
		end
	else
		raw_data = readdlm(filepath, delimiter, String;
			header=false, skipstart=linestoskip, skipblanks=true, comments=true, comment_char=comment_start)
    end
	num_rows, num_cols = size(raw_data)
    mat = Matrix{BigFloat}(undef, num_rows, num_cols)
    for i in 1:num_rows, j in 1:num_cols
        mat[i, j] = parse(BigFloat, raw_data[i, j])
    end
    return mat
end

# MARK: Calculate row stats

# Function to compute average and stddev for each row
function row_stats(mat::Matrix{BigFloat})
    row_cnts = [length(row) for row in eachrow(mat)]
    row_mins = [minimum(row) for row in eachrow(mat)]
    row_medians = [median(row) for row in eachrow(mat)]
    row_maxs = [maximum(row) for row in eachrow(mat)]
	row_ranges = row_maxs - row_mins
    row_means = [mean(row) for row in eachrow(mat)]
    row_sums = [sum(row) for row in eachrow(mat)]
    row_vars  = [var(row; corrected = true) for row in eachrow(mat)]	# n-1 divisor for sample variance
    row_stds  = [std(row; corrected = true) for row in eachrow(mat)]	# n-1 divisor for sample standard deviation
    row_varn  = [var(row; corrected = false) for row in eachrow(mat)]	# n divisor for population variance
    row_stdn  = [std(row; corrected = false) for row in eachrow(mat)]	# n divisor for population standard deviation
    row_medians  = [median(row) for row in eachrow(mat)]
    return row_cnts, row_mins, row_medians, row_maxs, row_ranges, row_means, row_sums, row_vars, row_stds, row_varn, row_stdn, row_medians
end

# MARK: Calculate column stats

# Function to compute average and stddev for each column
function col_stats(mat::Matrix{BigFloat})
    col_cnts = [length(col) for col in eachcol(mat)]
    col_mins = [minimum(col) for col in eachcol(mat)]
    col_medians = [median(col) for col in eachcol(mat)]
    col_maxs = [maximum(col) for col in eachcol(mat)]
	col_ranges = col_maxs - col_mins
    col_means = [mean(col) for col in eachcol(mat)]
    col_sums = [sum(col) for col in eachcol(mat)]
    col_vars  = [var(col; corrected = true) for col in eachcol(mat)]	# n-1 divisor for sample variance
    col_stds  = [std(col; corrected = true) for col in eachcol(mat)]	# n-1 divisor for sample standard deviation
    col_varn  = [var(col; corrected = false) for col in eachcol(mat)]	# n divisor for population variance
    col_stdn  = [std(col; corrected = false) for col in eachcol(mat)]	# n divisor for population standard deviation
    return col_cnts, col_mins, col_medians, col_maxs, col_ranges, col_means, col_sums, col_vars, col_stds, col_varn, col_stdn, col_medians
end

# Print a matrix of BigFloats with high precision
function print_bigfloat_matrix(mat::Matrix{BigFloat}, digits::Int64)
    println("\nBigFloat Matrix:")
    for row in eachrow(mat)
        for val in row
            @printf("%.*e ", digits, val)	# print in e format with digits number of digits
        end
        println()
    end
end

function print_basic_statistics(str::String, format_digits::Int64, cnts, mins, medians, maxs, ranges, means, sums, vars, stds, varn, stdn)
	# Display row or column results
	println("$str Counts:")
	foreach(x -> @printf("%d\n", x), cnts)
	# Display results in scientific format with specified number of digits
	println("$str Minimums:")
	foreach(x -> @printf("%.*e\n", format_digits, x), mins)
	println("$str Means:")
	foreach(x -> @printf("%.*e\n", format_digits, x), means)
	println("$str Medians:")
	foreach(x -> @printf("%.*e\n", format_digits, x), medians)
	println("$str Maximums:")
	foreach(x -> @printf("%.*e\n", format_digits, x), maxs)
	println("$str Ranges:")
	foreach(x -> @printf("%.*e\n", format_digits, x), ranges)
	println("$str Sums:")
	foreach(x -> @printf("%.*e\n", format_digits, x), sums)
	println("$str Sample Variances s²:")
	foreach(x -> @printf("%.*e\n", format_digits, x), vars)
	println("$str Sample Standard Deviations s:")
	foreach(x -> @printf("%.*e\n", format_digits, x), stds)
	println("$str Population Variances σ²:")
	foreach(x -> @printf("%.*e\n", format_digits, x), varn)
	println("$str Population Standard Deviations σ:")
	foreach(x -> @printf("%.*e\n", format_digits, x), stdn)
end

# MARK: Exponent Format Output

function print_basic_stats_e_format(str::String, format_digits::Int64, cnts, mins, medians, maxs, ranges, means, sums, vars, stds, varn, stdn)
	# Display row or column results
	i = 1
	for x in cnts
		@printf("%s: %d\n", str, i)
		@printf(" Count       : %d\n", x)
		@printf(" Minimum     : %.*e\n", format_digits, mins[i])
		@printf(" Mean        : %.*e\n", format_digits, means[i])
		@printf(" Median      : %.*e\n", format_digits, medians[i])
		@printf(" Maximum     : %.*e\n", format_digits, maxs[i])
		@printf(" Range       : %.*e\n", format_digits, ranges[i])
		@printf(" Sum         : %.*e\n", format_digits, sums[i])
		@printf(" Variance s\u00B2 : %.*e\n", format_digits, vars[i])
		@printf(" Std. Dev. s : %.*e\n", format_digits, stds[i])
		@printf(" Variance \u03C3\u00B2 : %.*e\n", format_digits, varn[i])
		@printf(" Std. Dev. \u03C3 : %.*e\n", format_digits, stdn[i])
		i += 1
	end
end

# MARK: General Format Output

function print_basic_stats_g_format(str::String, format_digits::Int64, cnts, mins, medians, maxs, ranges, means, sums, vars, stds, varn, stdn)
	# Display row or column results
	i = 1
	for x in cnts
		@printf("%s: %d\n", str, i)
		@printf(" Count       : %d\n", x)
		@printf(" Minimum     : %.*g\n", format_digits, mins[i])
		@printf(" Mean        : %.*g\n", format_digits, means[i])
		@printf(" Median      : %.*g\n", format_digits, medians[i])
		@printf(" Maximum     : %.*g\n", format_digits, maxs[i])
		@printf(" Range       : %.*g\n", format_digits, ranges[i])
		@printf(" Sum         : %.*g\n", format_digits, sums[i])
		@printf(" Variance s\u00B2 : %.*g\n", format_digits, vars[i])
		@printf(" Std. Dev. s : %.*g\n", format_digits, stds[i])
		@printf(" Variance \u03C3\u00B2 : %.*g\n", format_digits, varn[i])
		@printf(" Std. Dev. \u03C3 : %.*g\n", format_digits, stdn[i])
		i += 1
	end
end

# MARK: Main()

function main()
	# Start the timer at the beginning of the script
	start_time = time()

	# Parse command line arguments
    args = parse_arguments()

	if args["quiet"]
		verbose = false		# --quiet command line argument overrides --verbose
	else
		# Announce bfbs version if --quiet is not active
		println("bfbs version 0v12 (2026-03-27)")
		verbose = args["verbose"]	# --verbose command line argument
	end
	comment_delimiter_string = get(args, "comment_char", nothing)	# --comment_char command line argument
	delimiter_string = get(args, "delimiter_char", nothing)			# --delimiter_char command line argument
	has_header = args["header"]		# --header command line argument
	print_digits_string = get(args, "print_digits", nothing)	# --print_digits command line argument
	precision_bits_string = get(args, "precision", nothing)		# --precision command line argument
	skip_lines_string = get(args, "skip", nothing)				# --skip_lines_string command line argument
	files = args["files"]			# names of data files 

	# Set default values for options if not provided on command line
	# and check for valid values if provided
	if isnothing(delimiter_string)
		delimiter = ','		# set default column delimiter value to comma
	else
		if delimiter_string[begin] == '\\' && delimiter_string[begin+1] == 't'
			delimiter = '\t'	# set tab character as delimiter
		else
			delimiter = delimiter_string[begin]		# set supplied char as column delimiter
		end
	end

	if isnothing(comment_delimiter_string)
		comment_start = '#'		# set default comment delimiter value to hash
	else
		comment_start = comment_delimiter_string[begin]		# set supplied char as comment delimiter
	end

	if isnothing(skip_lines_string)
		skip_lines = 0			# set default lines to skip to 0 value
	else
		skip_lines = parse(Int64, skip_lines_string)
		if skip_lines < 0		# Don't allow negetive skip value
			println("Warning: Unable to skip $skip_lines lines - defaulting to zero")
			skip_lines = 0
		end
	end

	if isnothing(print_digits_string)
		print_format_digits = 64			# set default value of output format to effectively "%.64g" or "%.64e"
	else
		print_format_digits = parse(Int64, print_digits_string)
		if print_format_digits < 0		# Don't allow negetive numbers in the "%.*e" output format
			println("Warning: Unable to set print_digits to \"$print_format_digits\" digits - limiting to 0 digits")
			print_format_digits = 0
		elseif print_format_digits > 256	# Limit the print_digits to 256 digits
			println("Warning: Unable to set print_digits to \"$print_format_digits\" digits - limiting to 256 digits")
			print_format_digits = 256
		end
	end

	if isnothing(precision_bits_string)
		precision_bits = 256			# set default value of calculation precision to effectively "256 bits"
	else
		precision_bits = parse(Int64, precision_bits_string)
		if precision_bits < 16		# Don't allow negetive or too small precision value
			println("Warning: Unable to set calculation precision to \"$precision_bits\" bits - limiting to 16 bits")
			precision_bits = 16
		elseif precision_bits > 1024	# Limit the print_digits to 1024 digits
			println("Warning: Unable to set calculation precision to \"$precision_bits\" bits - limiting to 1024 bits")
			precision_bits = 1024
		end
	end

	# Announce Julia version
	if verbose || args["debug"]
		versioninfo()	# Show Julia version information
	elseif !args["quiet"]		# test --quiet option for version output supression
		println("Julia version $(VERSION)")
	end

	# Report current precision and settings if verbose or debug mode is active
	setprecision(BigFloat, precision_bits)	# Defaults to set BigFloat precision to 256 bits (about 77 decimal digits)
	println("BigFloat precision: $precision_bits bits")
	print("Results output using $print_format_digits digits in ")
	if args["scientific"]
		println("scientific number format")
	else
		println("general number format")
	end

	if verbose || args["debug"]
		println("Column delimiter is: '$delimiter'")
		println("Start of Comment delimiter is: '$comment_start'")
		println("Skip lines before starting to read data: $skip_lines")
	end

	if args["version"]
		return		# terminate the execution (a bit like the help option)
	end

	if isempty(files)
		println("Warning: No input files provided. Nothing to do. Use --help option for usage information.")
		return
	end

	# Loop through any file names on the command line
    for filepath in files
		if !isfile(filepath)
			println("\nWarning: file \"$filepath\" not found?!")
			continue	# skip this one, but if there are more files on the command line then try to process them
		end

		println("\nBasic Statistics for Data from file: \"$filepath\"")
	
		# Read data from the file into a matrix
		bignum_matrix = read_bignum_matrix(filepath, delimiter, has_header, verbose, skip_lines, comment_start)
		num_rows, num_cols = size(bignum_matrix)

		# Show matrix with full BigFloat precision if Debug mode is active
		debug_print_digits = print_format_digits + 10	# use more digits in debug printout to show more of the precision
		if args["debug"]
			println("Data dimensions are $num_cols columns x $num_rows rows")
			print_bigfloat_matrix(bignum_matrix, debug_print_digits)
			println()
		end

		# Now compute stats with high precision
		if !args["no_row_stats"] && num_cols > 1		# Don't calc row stats unless more than 1 column
			# Calculate row results with high precision
			row_cnts, row_mins, row_medians, row_maxs, row_ranges, row_means, row_sums, row_vars, row_stds, row_varn, row_stdn = row_stats(bignum_matrix)
			# Display rows results
			if args["scientific"]
				print_basic_stats_e_format("Row", print_format_digits, row_cnts, row_mins, row_medians, row_maxs, row_ranges, row_means, row_sums, row_vars, row_stds, row_varn, row_stdn)
			else
				print_basic_stats_g_format("Row", print_format_digits, row_cnts, row_mins, row_medians, row_maxs, row_ranges, row_means, row_sums, row_vars, row_stds, row_varn, row_stdn)
			end
			if args["debug"]
				print_basic_statistics("\nDebug Row(s): - ", debug_print_digits, row_cnts, row_mins, row_medians, row_maxs, row_ranges, row_means, row_sums, row_vars, row_stds, row_varn, row_stdn)
				println()
			end
		end
		if !args["no_column_stats"] && num_rows > 1		# Don't calc column stats unless more than 1 row
			# Calculate column results with high precision
			col_cnts, col_mins, col_medians, col_maxs, col_ranges, col_means, col_sums, col_vars, col_stds, col_varn, col_stdn = col_stats(bignum_matrix)
			# Display column results
			if args["scientific"]
				print_basic_stats_e_format("Column", print_format_digits, col_cnts, col_mins, col_medians, col_maxs, col_ranges, col_means, col_sums, col_vars, col_stds, col_varn, col_stdn)
			else
				print_basic_stats_g_format("Column", print_format_digits, col_cnts, col_mins, col_medians, col_maxs, col_ranges, col_means, col_sums, col_vars, col_stds, col_varn, col_stdn)
			end
			if args["debug"]
				print_basic_statistics("\nDebug Column(s): - ", debug_print_digits, col_cnts, col_mins, col_medians, col_maxs, col_ranges, col_means, col_sums, col_vars, col_stds, col_varn, col_stdn)
				println()
			end
		end
    end

	if !args["quiet"]		# test --quiet option for timing output supression
		# End the timer at the end of the script
		end_time = time()

		# Calculate the elapsed time and print it
		elapsed_time = end_time - start_time
		@printf("bfbs.jl script execution time: %.4g  [sec]\n", elapsed_time )
	end
end

main()
