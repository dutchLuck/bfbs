#! /bin/ruby -w
#
# stddevcsv.rb last edited on Sun Aug 31 23:41:49 2025
#
# This script reads a CSV file, calculates statistics for each column,
# including sum, average, standard deviation, and range, and outputs the results.
#
# Calculations use the  bigdecimal  module which provides
# arbitrary-precision decimal floating-point arithmetic
# to minimize floating-point errors.
# The precision can be adjusted by changing the 'precision' variable.
# The default precision is set to 40 decimal places.
#
# This script is designed to be simple to run in a standard Ruby environment
# and does not require any external libraries beyond the standard library.
#


require 'csv'
require 'bigdecimal'  # For accurate mathematical calculations
require 'bigdecimal/util'  # For to_d method

#
# Read the CSV file name from command line arguments or use a default
# If the file does not exist or is malformed, handle the error gracefully.
precision = 40  # Set precision for BigDecimal calculations
BigDecimal.limit(precision)  # Set global precision limit for BigDecimal operations
#
# Output version and environment information
puts "bfbs.rb 0v1"
puts "ruby version: #{RUBY_VERSION}"
puts "csv module version: #{CSV::VERSION}"
puts "bigdecimal module version: #{BigDecimal::VERSION}"
puts "Using #{precision} digits of bigdecimal precision."
#
# Get the filename from command line arguments or use "tmp.csv" as default
name = if ARGV.size > 0 then ARGV.shift else "tmp.csv" end
puts "\nProcessing file: \"#{name}\""
#
# Read CSV data without headers, skipping blank lines
data_no_headers = Array.new
begin
  data_no_headers = CSV.read( name, skip_blanks:true, headers:false )
rescue Errno::ENOENT
  puts "Error: File named '#{name}' not found."
  exit 1
rescue CSV::MalformedCSVError => e
  puts "Error: Malformed CSV file '#{name}': #{e.message}"
  exit 1
end
rowCount = data_no_headers.size
#
# Convert string format Data Columns to BigDecimal format for higher precision calculations
tmpData = Array.new 
tmpData = data_no_headers.transpose  # Transpose columns to rows
tmpData.each  do  |row|
  row.map!(&:to_d)  # Convert all values to bigdecimal
end
#
# Calculate sum of each column
sumOfColumns = Array.new
sumOfColumns = tmpData.map { |col| col.sum }
#
# Calculate the average of each column
avgOfColumns = Array.new
avgOfColumns = sumOfColumns.map { |sum| sum.div(rowCount, precision) }  # Calculate average of each column
#
# Calculate the normalized square of each column
sqrOfColumns = Array.new
sqrOfColumns = tmpData.map do |col|
  col.map { |value| (avgOfColumns[tmpData.index(col)] - value.to_d).power(2, precision)}.sum
end
#
# Calculate the variance of each column
varOfColumns = Array.new
varOfColumns = sqrOfColumns.map do |var|
  (var.div((rowCount - 1), precision))  # Calculate variance of each column
end
#
# Calculate the standard deviation of each column
stddevOfColumns = Array.new
stddevOfColumns = varOfColumns.map do |var|
  if var > (0.0).to_d
    (var.sqrt(precision))  # Calculate standard deviation of each column
  else
    (0.0).to_d
  end
end
#
# Output the results in column blocks
lastColNum = sumOfColumns.size - 1
0.upto(lastColNum) do |i|
  print "Column: ", i + 1, "\n"
  print "  Count     : ", rowCount, "\n"
  print "  Sum       : ", sumOfColumns[i], "\n"
  print "  Mean      : ", avgOfColumns[i], "\n"
  print "  Variance  : ", varOfColumns[i], "\n"
  print "  Std. Dev. : ", stddevOfColumns[i], "\n"
end
