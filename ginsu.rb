#!/usr/bin/env ruby
require 'splitter'
require 'optparse'
require 'ostruct'

$VERSION = "0.9.1"
$BUILD = "$Rev$"

class Optparse
  def self.parse(args)
    options = OpenStruct.new
    options.dest = ""
    
    opts = OptionParser.new do |opts|
      opts.banner = "Ginsu Build: " + $BUILD + ", Version: " + $VERSION + "\nUsage: ginsu.rb [tiddlywikiname]"
      opts.separator ""
      opts.separator "Specific options:"
      
      # No argument, shows at tail.  This will print an options summary.
      # Try it and see!
      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit 64
      end
    end
    opts.parse!(args)
    options
  end
end

options = Optparse.parse(ARGV)

ARGV.each do |file|
  if(!File.exist?(file))
    STDERR.puts("ERROR: File: " + file + " Does not exist.")
    exit
  end
end

ARGV.each do |file|
  splitter = Splitter.new(file)
  splitter.split
end

