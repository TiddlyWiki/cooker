#!/usr/bin/env ruby
# cook.rb

# Copyright (c) UnaMesa Association 2004-2007
# License: Creative Commons Attribution ShareAlike 3.0 License http://creativecommons.org/licenses/by-sa/3.0/

require 'recipe'
require 'optparse'
require 'ostruct'

$VERSION = "1.1.0"
$BUILD = "$Revision$"

class Optparse
	def self.parse(args)
		version = "Version: #{$VERSION} (#{$BUILD.gsub('$', '').strip})"

		options = OpenStruct.new
		options.help = ""
		options.dest = ""

		opts = OptionParser.new do |opts|
			opts.banner = "Cook #{version}\n"
			opts.banner += "Usage: cook.rb recipename [...] [options]"
			opts.separator ""
			opts.separator "Specific options:"

			opts.on("-d", "--dest DESTINATION", "Destination directory") do |dest|
				if(!File.exist?(dest))
					STDERR.puts("ERROR - Destination directory '#{dest}' does not exist.")
					exit
				end
				options.dest = dest
			end

			options.format = ""
			opts.on("-f", "--format FORMAT", "Tiddler format") do |format|
				options.format = format
			end

			options.help = opts
			opts.on_tail("-h", "--help", "Show this message") do
				puts options.help
				exit 64
			end

			opts.on_tail("-v", "--version", "Show version") do
				puts version
				exit 64
			end
		end
		opts.parse!(args)
		options
	end
end

options = Optparse.parse(ARGV)

if(ARGV.empty?)
	puts options.help
	exit
end

ARGV.each do |file|
	if(!File.exist?(file))
		STDERR.puts("ERROR - File '#{file}' does not exist.")
		exit
	end
end

Tiddler.format = options.format

ARGV.each do |file|
	recipe = Recipe.new(file, options.dest)
	recipe.cook
end
