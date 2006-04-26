#!/usr/bin/env ruby
require 'recipe'
require 'optparse'
require 'ostruct'

$VERSION = "0.9.1"
$BUILD = "$Rev$"

class Optparse
  def self.parse(args)
    options = OpenStruct.new
    options.dest = ""
    options.hashid = false
    
    opts = OptionParser.new do |opts|
      opts.banner = "Cooker Build: " + $BUILD + ", Version: " + $VERSION + " Usage: cook.rb recipename [options]"
      opts.separator ""
      opts.separator "Specific options:"
      
      opts.on("-d", "--dest [DESTINATION]", "Destination directory") do |dest|
        if(!File.exist?(dest))
          STDERR.puts("Error: destination directory: " + dest + " does not exist.")
          exit
        end
        options.dest = dest
      end
      
      opts.on("-i", "--hashid", "Add hash id to all tiddlers") do |i|
        options.hashid = i
      end
      
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

Ingredient.hashid = options.hashid

ARGV.each do |file|
  recipe = Recipe.new(file, options.dest)
  recipe.cook
end
