#! /usr/bin/env julia
#
# B F B S . J L
#
# Big Float Basic Statistics
#
# bfbs.jl last updated on Fri Sep  5 19:54:07 2025 by O.H. as 0v11
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

        "--n_divisor", "-n"
        action = :store_true
        help = "Use the actual number of samples n as the Standard Deviation divisor, rather than n-1."

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

        "files"
        nargs = '*'
        help = "Input files containing 1 or more columns of numbers. Default file format has comma separated columns."
    end

    return parse_args(s)
end

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

# Function to compute average and stddev for each row
function row_stats(mat::Matrix{BigFloat}, use_n::Bool )
    row_cnts = [length(row) for row in eachrow(mat)]
    row_mins = [minimum(row) for row in eachrow(mat)]
    row_medians = [median(row) for row in eachrow(mat)]
    row_maxs = [maximum(row) for row in eachrow(mat)]
	row_ranges = row_maxs - row_mins
    row_means = [mean(row) for row in eachrow(mat)]
    row_sums = [sum(row) for row in eachrow(mat)]
    row_vars  = [var(row) for row in eachrow(mat)]
    row_stds  = [std(row; corrected = !use_n) for row in eachrow(mat)]
    row_medians  = [median(row) for row in eachrow(mat)]
    return row_cnts, row_mins, row_medians, row_maxs, row_ranges, row_means, row_sums, row_vars, row_stds
end

# Function to compute average and stddev for each column
function col_stats(mat::Matrix{BigFloat}, use_n::Bool)
    col_cnts = [length(col) for col in eachcol(mat)]
    col_mins = [minimum(col) for col in eachcol(mat)]
    col_medians = [median(col) for col in eachcol(mat)]
    col_maxs = [maximum(col) for col in eachcol(mat)]
	col_ranges = col_maxs - col_mins
    col_means = [mean(col) for col in eachcol(mat)]
    col_sums = [sum(col) for col in eachcol(mat)]
    col_vars  = [var(col) for col in eachcol(mat)]
    col_stds  = [std(col; corrected = !use_n) for col in eachcol(mat)]
    return col_cnts, col_mins, col_medians, col_maxs, col_ranges, col_means, col_sums, col_vars, col_stds 
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

function print_basic_statistics(str::String, precision::Int64, cnts, mins, medians, maxs, ranges, means, sums, vars, stds)
	# Display rows results
	println("$str Counts:")
	foreach(x -> @printf("%d\n", x), cnts)
	# Display row results with precision
	println("$str Minimums:")
	foreach(x -> @printf("%.*e\n", precision, x), mins)
	println("$str Medians:")
	foreach(x -> @printf("%.*e\n", precision, x), medians)
	println("$str Maximums:")
	foreach(x -> @printf("%.*e\n", precision, x), maxs)
	println("$str Ranges:")
	foreach(x -> @printf("%.*e\n", precision, x), ranges)
	println("$str Means:")
	foreach(x -> @printf("%.*e\n", precision, x), means)
	println("$str Sums:")
	foreach(x -> @printf("%.*e\n", precision, x), sums)
	println("$str Variances:")
	foreach(x -> @printf("%.*e\n", precision, x), vars)
	println("$str Standard Deviations:")
	foreach(x -> @printf("%.*e\n", precision, x), stds)
end

function print_basic_stats_e_format(str::String, precision::Int64, cnts, mins, medians, maxs, ranges, means, sums, vars, stds)
	# Display rows or column results
	i = 1
	for x in cnts
		@printf("%s: %d\n", str, i)
		@printf(" Count     : %d\n", x)
		@printf(" Minimum   : %.*e\n", precision, mins[i])
		@printf(" Median    : %.*e\n", precision, medians[i])
		@printf(" Maximum   : %.*e\n", precision, maxs[i])
		@printf(" Range     : %.*e\n", precision, ranges[i])
		@printf(" Mean      : %.*e\n", precision, means[i])
		@printf(" Sum       : %.*e\n", precision, sums[i])
		@printf(" Variance  : %.*e\n", precision, vars[i])
		@printf(" Std. Dev. : %.*e\n", precision, stds[i])
		i += 1
	end
end

function print_basic_stats_g_format(str::String, precision::Int64, cnts, mins, medians, maxs, ranges, means, sums, vars, stds)
	# Display rows or column results
	i = 1
	for x in cnts
		@printf("%s: %d\n", str, i)
		@printf(" Count     : %d\n", x)
		@printf(" Minimum   : %.*g\n", precision, mins[i])
		@printf(" Median    : %.*g\n", precision, medians[i])
		@printf(" Maximum   : %.*g\n", precision, maxs[i])
		@printf(" Range     : %.*g\n", precision, ranges[i])
		@printf(" Mean      : %.*g\n", precision, means[i])
		@printf(" Sum       : %.*g\n", precision, sums[i])
		@printf(" Variance  : %.*g\n", precision, vars[i])
		@printf(" Std. Dev. : %.*g\n", precision, stds[i])
		i += 1
	end
end

function main()
	# Announce bfbs version
	println("bfbs version 0v11 (2025-11-10)")

	# Parse command line arguments
    args = parse_arguments()
	comment_delimiter_string = get(args, "comment_char", nothing)	# --comment_char command line argument
	delimiter_string = get(args, "delimiter_char", nothing)			# --delimiter_char command line argument
	has_header = args["header"]		# --header command line argument
	n_divisor = args["n_divisor"]	# --n_divisor command line argument
	print_digits_string = get(args, "print_digits", nothing)	# --print_digits command line argument
	precision_bits_string = get(args, "precision", nothing)		# --precision command line argument
	skip_lines_string = get(args, "skip", nothing)				# --skip_lines_string command line argument
	verbose = args["verbose"]		# --verbose command line argument
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
		precision = 64			# set default value of output format to effectively "%.64g" or "%.64e"
	else
		precision = parse(Int64, print_digits_string)
		if precision < 0		# Don't allow negetive numbers in the "%.*e" output format
			println("Warning: Unable to set print_digits to \"$precision\" digits - limiting to 0 digits")
			precision = 0
		elseif precision > 256	# Limit the print_digits to 256 digits
			println("Warning: Unable to set print_digits to \"$precision\" digits - limiting to 256 digits")
			precision = 256
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
	else
		println("Julia version $(VERSION)")
	end

	# Report current precision and settings if verbose or debug mode is active
	setprecision(BigFloat, precision_bits)	# Defaults to set BigFloat precision to 256 bits (about 77 decimal digits)
	println("BigFloat precision: $precision_bits bits")
	print("Results output using $precision digits in ")
	if args["scientific"]
		println("scientific number format")
	else
		println("general number format")
	end

	if verbose || args["debug"]
		println("Column delimiter is: '$delimiter'")
		println("Start of Comment delimiter is: '$comment_start'")
		println("Skip lines before starting to read data: $skip_lines")
		println("Use number of samples n as devisor in Standard Deviation: $n_divisor")
	end

	if args["version"]
		return		# terminate the execution (a bit like the help option)
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
		if args["debug"]
			println("Data dimensions are $num_cols columns x $num_rows rows")
			print_bigfloat_matrix(bignum_matrix, precision)
		end

		# Now compute stats with high precision
		if !args["no_row_stats"] && num_cols > 1		# Don't calc row stats unless more than 1 column
			# Calculate row results with high precision
			row_cnts, row_mins, row_medians, row_maxs, row_ranges, row_means, row_sums, row_vars, row_stds = row_stats(bignum_matrix, n_divisor)
			# Display rows results
			if args["scientific"]
				print_basic_stats_e_format("Row", precision, row_cnts, row_mins, row_medians, row_maxs, row_ranges, row_means, row_sums, row_vars, row_stds)
			else
				print_basic_stats_g_format("Row", precision, row_cnts, row_mins, row_medians, row_maxs, row_ranges, row_means, row_sums, row_vars, row_stds)
			end
		end
		if !args["no_column_stats"] && num_rows > 1		# Don't calc column stats unless more than 1 row
			# Calculate column results with high precision
			col_cnts, col_mins, col_medians, col_maxs, col_ranges, col_means, col_sums, col_vars, col_stds = col_stats(bignum_matrix, n_divisor)
			# Display column results
			if args["scientific"]
				print_basic_stats_e_format("Column", precision, col_cnts, col_mins, col_medians, col_maxs, col_ranges, col_means, col_sums, col_vars, col_stds)
			else
				print_basic_stats_g_format("Column", precision, col_cnts, col_mins, col_medians, col_maxs, col_ranges, col_means, col_sums, col_vars, col_stds)
			end
		end
    end
end

# Start the timer at the beginning of the script
start_time = time()

main()

# End the timer at the end of the script
end_time = time()

# Calculate the elapsed time and print it
elapsed_time = end_time - start_time
@printf("bfbs.jl script execution time: %.4g  [sec]\n", elapsed_time )
