#! /bin/ruby -w
#
# bfbs.rb last edited on Fri Oct 24 23:43:49 2025
#
# This script reads a CSV file, calculates statistics for each column,
# including sum, average, standard deviation, and range, and outputs the results.
#
# Calculations use the  bigdecimal  module which provides
# arbitrary-precision decimal floating-point arithmetic
# to minimize floating-point errors.
# The default precision can be adjusted by changing the 'precision' variable.
# The default precision is currently set to 40 decimal places.
#
# This script is designed to be simple to run in a standard Ruby environment
# and does not require any external libraries beyond the standard library.
#

#
# 0v5 Provide execution time output
# 0v4 Provide median
# 0v3 Substituted bsqrt in-place of 'bigdecimal/math' BigMath.sqrt
# 0v2 Added command line options --precision and --headers, plus max, min and range output.
#

require 'optparse'
require 'csv'
require 'bigdecimal'        # For arbitrary-precision mathematical calculations
require 'bigdecimal/util'   # For to_d method

# Substitute Square Root code to supercede 'bigdecimal/math' BigMath.sqrt
# which produced 0.1e51 instead of the expected  0.1000000000000000000000000000000000000001e51
# result on the following data; -
# 1.000000000000000000000000000000000000001e+50, 4.000000000000000000000000000000000000004e+50, 7.000000000000000000000000000000000000007e+50
# 2.000000000000000000000000000000000000002e+50, 5.000000000000000000000000000000000000005e+50, 8.000000000000000000000000000000000000008e+50
# 3.000000000000000000000000000000000000003e+50, 6.000000000000000000000000000000000000006e+50, 9.000000000000000000000000000000000000009e+50

# This code is a ChatGPT conversion of the bfbs.java square root code.
def bsqrt(value, digits)
  return BigDecimal("0") if value <= 0

  # Set the precision (number of significant digits)
  scale = digits + 5  # extra digits for intermediate precision
  BigDecimal.limit(scale)

  # Initial guess using Float sqrt
  x = Math.sqrt(value.to_f).to_d

  two = BigDecimal("2")

  # Newton-Raphson iteration
  scale.times do
    x = (x + value / x).div(two, scale)
  end

  # Round the result to the desired number of digits
  x.round(digits)
end

# Record start time so execution time can be output
start_time = Time.now

# Read the CSV file name from command line arguments or use a default
options = {}
options[:precision] = 40  # Set default precision for BigDecimal calculations
options[:header] = false  # Set default header processing

OptionParser.new do |opts|
  opts.banner = "Usage: bfbs.rb [options] file1 [file2 ...]"

  opts.on("-H", "--header", "Treat first row as a title for each column of data") do |hdr|
    options[:header] = hdr
  end

  opts.on("-P", "--precision PRECISION", "Set calculation precision to PRECISION decimal digits") do |precision|
    options[:precision] = precision.to_i
  end

  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!(ARGV)

# ARGV now contains only the unparsed arguments (filenames)
filenames = ARGV
if filenames.empty?
  puts "Error: No filenames provided. Use -h for help."
  exit 1
end

# Clamp precision between 2 and 1024
if options[:precision] < 2
  options[:precision] = 2
elsif options[:precision] > 1024
  options[:precision] =1024
end

BigDecimal.mode(BigDecimal::ROUND_MODE, :half_up)   # Explicitly set rounding mode
BigDecimal.limit(options[:precision])  # Set global precision limit for BigDecimal operations
#
# Output version and environment information
puts "bfbs.rb version 0v5"
puts "ruby version: #{RUBY_VERSION}"
puts "csv module version: #{CSV::VERSION}"
puts "bigdecimal module version: #{BigDecimal::VERSION}"
puts "Using #{options[:precision]} digits of bigdecimal precision."
# puts "Options: #{options}"
#
# Get the filename from command line arguments
# If the file does not exist or is malformed, handle the error gracefully.
filenames.each do |name|
  puts "\nProcessing file: \"#{name}\""
  #
  # Read CSV data without headers, skipping blank lines
  data_no_headers = Array.new
  headers = Array.new
  begin
  #  data_no_headers = CSV.readlines( name, skip_blanks:true, headers:options[:header]).reject { |row| row.to_hash.values.all?(&:nil?) }
    filtered_lines = File.readlines(name).reject do |line|
      line.strip.empty? || line.start_with?('#') # Skips blank lines and lines starting with '#'
    end
  rescue Errno::ENOENT
    puts "Error: File named '#{name}' not found."
    next
  end
  begin
    count = 1
    CSV.parse(filtered_lines.join, headers:false) do |row|
      if count == 1 && options[:header]
        headers.push(row)
      else
        data_no_headers.push(row)
      end
      # puts "#{count}: #{row.inspect}"
      count += 1
    end
  rescue CSV::MalformedCSVError => e
    puts "Error: Malformed CSV in file '#{name}': #{e.message}"
    next
  end
  rowCount = data_no_headers.size

  # Convert string format Data Columns to BigDecimal format for higher precision calculations
  tmpData = Array.new 
  tmpData = data_no_headers.transpose  # Transpose columns to rows
  tmpData.each  do  |row|
    row.map!(&:to_d)  # Convert all values to bigdecimal
    row.sort!   # sort each row (in-place) needed later to find median
  end

  # Find minimum of each column
  minOfColumns = Array.new
  minOfColumns = tmpData.map { |col| col.min }

  # Find maximum of each column
  maxOfColumns = Array.new
  maxOfColumns = tmpData.map { |col| col.max }

  # Find range of each column without finding max and min again
  rangeOfColumns = Array.new
  0.upto(minOfColumns.size - 1) do |i|
    rangeOfColumns[i] = maxOfColumns[i].sub( minOfColumns[i], options[:precision])
  end

  # Find median of each column
  medianOfColumns = Array.new
  if (rowCount & 1) == 1    # odd number of rows
    0.upto(minOfColumns.size - 1) do |i|
      medianOfColumns[i] = tmpData[i][rowCount / 2]
    end
  else  # even number of rows
    0.upto(minOfColumns.size - 1) do |i|
      medianOfColumns[i] = (tmpData[i][rowCount / 2] + tmpData[i][(rowCount / 2) - 1]).div(2, options[:precision]) 
    end
  end

  # Calculate sum of each column
  sumOfColumns = Array.new
  sumOfColumns = tmpData.map { |col| col.sum }

  # Calculate the average of each column
  avgOfColumns = Array.new
  avgOfColumns = sumOfColumns.map { |sum| sum.div(rowCount, options[:precision]) }  # Calculate mean

  # Calculate the normalized square of each column
  sqrOfColumns = Array.new
  sqrOfColumns = tmpData.map do |col|
    col.map { |value| (avgOfColumns[tmpData.index(col)] - value.to_d).power(2, options[:precision])}.sum
  end

  # Calculate the sample variance of each column
  varOfColumns = Array.new
  varOfColumns = sqrOfColumns.map do |var|
    if rowCount > 1
      (var.div((rowCount - 1), options[:precision]))  # Calculate variance
    else
      (0.0).to_d
    end
  end

  # Calculate the sample standard deviation of each column
  stddevOfColumns = Array.new
  stddevOfColumns = varOfColumns.map do |var|
    if var > (0.0).to_d
      (bsqrt(var, options[:precision]))  # Calculate standard deviation
    else
      (0.0).to_d
    end
  end

  # Ensure global precision limit was't permanently changed by bsqrt() code
  BigDecimal.limit(options[:precision])

  # Output the results in column blocks
  lastColNum = sumOfColumns.size - 1
  0.upto(lastColNum) do |i|
    if options[:header]
      print "Column: ", headers[0][i], "\n"
    else
      print "Column: ", i + 1, "\n"
    end
    print "  Count     : ", rowCount, "\n"
    print "  Minimum   : ", minOfColumns[i], "\n"
    print "  Mean      : ", avgOfColumns[i], "\n"
    print "  Median    : ", medianOfColumns[i], "\n"
    print "  Maximum   : ", maxOfColumns[i], "\n"
    print "  Range     : ", rangeOfColumns[i], "\n"
    print "  Sum       : ", sumOfColumns[i], "\n"
    print "  Variance  : ", varOfColumns[i], "\n"
    print "  Std. Dev. : ", stddevOfColumns[i], "\n"
  end

  print "bfbs.rb execution time was ", Time.now - start_time, " [sec]\n"
end
