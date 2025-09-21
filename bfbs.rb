#! /bin/ruby -w
#
# bfbs.rb last edited on Sun Sep 21 23:15:49 2025
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
# 0v2 Added command line options --precision and --headers, plus max, min and range output.
#

require 'optparse'
require 'csv'
require 'bigdecimal'  # For accurate mathematical calculations
require 'bigdecimal/util'  # For to_d method

#
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

BigDecimal.limit(options[:precision])  # Set global precision limit for BigDecimal operations
#
# Output version and environment information
puts "bfbs.rb version 0v2"
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
  #
  # Convert string format Data Columns to BigDecimal format for higher precision calculations
  tmpData = Array.new 
  tmpData = data_no_headers.transpose  # Transpose columns to rows
  tmpData.each  do  |row|
    row.map!(&:to_d)  # Convert all values to bigdecimal
  end
  #
  # Find minimum of each column
  minOfColumns = Array.new
  minOfColumns = tmpData.map { |col| col.min }

  # Find maximum of each column
  maxOfColumns = Array.new
  maxOfColumns = tmpData.map { |col| col.max }

  # Find range of each column
  rangeOfColumns = Array.new
  rangeOfColumns = tmpData.map { |col| col.max.sub(col.min, options[:precision]) }  # Calculate range

  # Calculate sum of each column
  sumOfColumns = Array.new
  sumOfColumns = tmpData.map { |col| col.sum }
  #
  # Calculate the average of each column
  avgOfColumns = Array.new
  avgOfColumns = sumOfColumns.map { |sum| sum.div(rowCount, options[:precision]) }  # Calculate mean
  #
  # Calculate the normalized square of each column
  sqrOfColumns = Array.new
  sqrOfColumns = tmpData.map do |col|
    col.map { |value| (avgOfColumns[tmpData.index(col)] - value.to_d).power(2, options[:precision])}.sum
  end
  #
  # Calculate the sample variance of each column
  varOfColumns = Array.new
  varOfColumns = sqrOfColumns.map do |var|
    if rowCount > 1
      (var.div((rowCount - 1), options[:precision]))  # Calculate variance
    else
      (0.0).to_d
    end
  end
  #
  # Calculate the sample standard deviation of each column
  stddevOfColumns = Array.new
  stddevOfColumns = varOfColumns.map do |var|
    if var > (0.0).to_d
      (var.sqrt(options[:precision]))  # Calculate standard deviation
    else
      (0.0).to_d
    end
  end
  #
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
    print "  Maximum   : ", maxOfColumns[i], "\n"
    print "  Range     : ", rangeOfColumns[i], "\n"
    print "  Sum       : ", sumOfColumns[i], "\n"
    print "  Variance  : ", varOfColumns[i], "\n"
    print "  Std. Dev. : ", stddevOfColumns[i], "\n"
  end
end
