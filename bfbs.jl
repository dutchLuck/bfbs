#! /usr/bin/env julia

#
# B F B S . J L
#
# Big Float Basic Stats
#
# bfbs.jl last updated on Tue Jun  3 21:39:38 2025 by O.H. as 0v6
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
# bfbs version 0v3 (2025-06-01)
##

#
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

        "--header", "-H"
        action = :store_true
        help = "The first row is treated as a header."

        "--n_divisor", "-n"
        action = :store_true
        help = "Use the actual number of samples n as the Standard Deviation divisor, rather than n-1."

        "--output", "-o"
        arg_type = String
        help = "Write output to a file named \"OUTPUT\". If not provided, output goes to stdout."

        "--print_digits", "-p"
        arg_type = String
        help = "Write output with \"PRINT-DIGITS\" digits. If not provided, 25 output digits are used."

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

function main()
    args = parse_arguments()
	comment_delimiter_string = get(args, "comment_char", nothing)	# --comment_char command line argument
	delimiter_string = get(args, "delimiter_char", nothing)			# --delimiter_char command line argument
	has_header = args["header"]		# --header command line argument
	n_divisor = args["n_divisor"]	# --n_divisor command line argument
	output_file = get(args, "output", nothing)				# --output command line argument
	print_digits_string = get(args, "print_digits", nothing)		# --print_digits command line argument
	skip_lines_string = get(args, "skip", nothing)			# --skip_lines_string command line argument
	verbose = args["verbose"]		# --verbose command line argument
	files = args["files"]			# names of data files 

	if args["version"] || args["debug"]
		println("bfbs version 0v5 (2025-06-03)")
	end

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
		precision = 25			# set default value of output format to effectively "%.25e"
	else
		precision = parse(Int64, print_digits_string)
		if precision < 0		# Don't allow negetive numbers in the "%.*e" output format
			println("Warning: Unable to set print_digits to \"$precision\" digits - limiting to 0 digits")
			precision = 0
		elseif precision > 50	# Limit the print_digits to 50 digits
			println("Warning: Unable to set print_digits to \"$precision\" digits - limiting to 50 digits")
			precision = 50
		end
	end

	if verbose || args["debug"]
		println("Column delimiter is: '$delimiter'")
		println("Start of Comment delimiter is: '$comment_start'")
		println("Skip lines before starting to read data: $skip_lines")
		println("Use number of samples n as devisor in Standard Deviation: $n_divisor")
		if isnothing(output_file)
			println("No output file is defined")
		else
			println("Outputting statistics information to file: $output_file")
		end
	end

	if args["version"]
		return		# terminate the execution (a bit like the help option)
	end

    for filepath in files
		if !isfile(filepath)
			println("\nWarning: file \"$filepath\" not found?!")
			continue	# if there are more files on the command line then try to process them
		end

		if verbose
			println("Basic Statistics for Data from file: \"$filepath\"")
		end
	
		bignum_matrix = read_bignum_matrix(filepath, delimiter, has_header, verbose, skip_lines, comment_start)
		num_rows, num_cols = size(bignum_matrix)

		# Show matrix with full BigFloat precision
		if args["debug"]
			println("Data dimensions are $num_cols columns x $num_rows rows")
			print_bigfloat_matrix(bignum_matrix, precision)
		end

		# Now compute stats with high precision
		if !args["no_row_stats"] && num_cols > 1		# Don't calc row stats unless more than 1 column
			# Calculate row results with high precision
			row_cnts, row_mins, row_medians, row_maxs, row_ranges, row_means, row_sums, row_vars, row_stds = row_stats(bignum_matrix, n_divisor)
			# Display rows results
			println("Row Counts:")
			foreach(x -> @printf("%d\n", x), row_cnts)
			# Display row results with precision
			println("Row Minimums:")
			foreach(x -> @printf("%.*e\n", precision, x), row_mins)
			println("Row Medians:")
			foreach(x -> @printf("%.*e\n", precision, x), row_medians)
			println("Row Maximums:")
			foreach(x -> @printf("%.*e\n", precision, x), row_maxs)
			println("Row Ranges:")
			foreach(x -> @printf("%.*e\n", precision, x), row_ranges)
			println("Row Means:")
			foreach(x -> @printf("%.*e\n", precision, x), row_means)
			println("Row Sums:")
			foreach(x -> @printf("%.*e\n", precision, x), row_sums)
			println("Row Variances:")
			foreach(x -> @printf("%.*e\n", precision, x), row_vars)
			println("Row Standard Deviations:")
			foreach(x -> @printf("%.*e\n", precision, x), row_stds)
		end
		if !args["no_column_stats"] && num_rows > 1		# Don't calc column stats unless more than 1 row
			# Calculate column results with high precision
			col_cnts, col_mins, col_medians, col_maxs, col_ranges, col_means, col_sums, col_vars, col_stds = col_stats(bignum_matrix, n_divisor)
			# Display column results
			println("Column Counts:")
			foreach(x -> @printf("%d\n", x), col_cnts)
			# Display column results with high precision
			println("Column Minimums:")
			foreach(x -> @printf("%.*e\n", precision, x), col_mins)
			println("Column Medians:")
			foreach(x -> @printf("%.*e\n", precision, x), col_medians)
			println("Column Maximums:")
			foreach(x -> @printf("%.*e\n", precision, x), col_maxs)
			println("Column Ranges:")
			foreach(x -> @printf("%.*e\n", precision, x), col_ranges)
			println("Column Means:")
			foreach(x -> @printf("%.*e\n", precision, x), col_means)
			println("Column Sums:")
			foreach(x -> @printf("%.*e\n", precision, x), col_sums)
			println("Column Variances:")
			foreach(x -> @printf("%.*e\n", precision, x), col_vars)
			println("Column Standard Deviations:")
			foreach(x -> @printf("%.*e\n", precision, x), col_stds)
		end
    end
end

main()
