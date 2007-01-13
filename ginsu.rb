#!/usr/bin/env ruby
# ginsu.rb

require 'splitter'
require 'optparse'
require 'ostruct'

$VERSION = "0.9.4"
$BUILD = "$Revision$"

class Optparse
	def self.parse(args)
		version = "Version: #{$VERSION} (#{$BUILD.gsub('$', '').strip})"

		options = OpenStruct.new
		options.help = ""
		options.dest = ""
		options.charset = ""

		opts = OptionParser.new do |opts|
			opts.banner = "Ginsu #{version}\n"
			opts.banner += "Usage: ginsu.rb tiddlywikiname [...] [options]"
			opts.separator ""
			opts.separator "Specific options:"

			opts.on("-d", "--dest DESTINATION", "Destination directory") do |dest|
				if(!File.exist?(dest))
					STDERR.puts("ERROR - Destination directory '#{dest}' does not exist.")
					exit
				end
				options.dest = dest
			end

			opts.on_tail("-c", "--charset CHARSET", "Character set of filesystem.") do |charset|
				options.charset = charset
			end
			
			options.help = opts

			opts.on_tail("-h", "--help", "Show this message") do
				puts options.help
				exit 64
			end

			opts.on_tail("--version", "Show version") do
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

ARGV.each do |file|
	splitter = Splitter.new(file, options.dest, options.charset)
	splitter.split
end
