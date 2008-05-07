#!/usr/bin/env ruby
# ginsu.rb

# Copyright (c) UnaMesa Association 2004-2008
# License: Creative Commons Attribution ShareAlike 3.0 License http://creativecommons.org/licenses/by-sa/3.0/

require 'splitter'
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
		options.charset = ""
		options.usesubdirectories = false

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

			opts.on("-q", "--[no-]quiet", "Quiet mode, do not output file names") do |quiet|
				options.quiet = quiet
			end

			opts.on("-s", "--[no-]subdirectories", "Split tidders into subdirectories by type") do |usesubdirectories|
				options.usesubdirectories = usesubdirectories
			end
			
			opts.on("-t", "--tag TAGDIRECTORY", "Split tidders into subdirectories by type") do |tagsubdirectory|
				options.tagsubdirectory = tagsubdirectory
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

def remoteFileExists?(url)
	url = URI.parse(url)
	Net::HTTP.start(url.host, url.port) do |http|
		return http.head(url.request_uri).code == "200"
	end
end

def fileExists?(file)
	if file =~ /^https?/
		r = remoteFileExists?(file)	
	else
		r = File.exist?(file)	
	end
	r
end

ARGV.each do |file|
	if(!fileExists?(file))
		STDERR.puts("ERROR - File '#{file}' does not exist.")
		exit
	end
end

Splitter.quiet = options.quiet
Splitter.usesubdirectories = options.usesubdirectories
Splitter.tagsubdirectory = options.tagsubdirectory
Tiddler.ginsu = true

ARGV.each do |file|
	splitter = Splitter.new(file, options.dest, options.charset)
	splitter.split
end
