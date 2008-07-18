#!/usr/bin/env ruby
# cook.rb

# Copyright (c) UnaMesa Association 2004-2008
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
		options.format = ""
		options.quiet = false
		options.stripcomments = false
		options.compress = ""
		options.root = ""
		options.splash = false
		options.section = ""
		options.ignorecopy = false

		opts = OptionParser.new do |opts|
			opts.banner = "Cook #{version}\n"
			opts.banner += "Usage: cook.rb recipename [...] [options]"
			opts.separator ""
			opts.separator "Specific options:"

			opts.on("-r", "--root ROOT", "Root path") do |root|
				options.root = root
			end

			opts.on("-c", "--compress COMPRESS", "Compress javascript, use -c, -cr or -crp") do |compress|
				# three options available
				# F - compress each .js file individually using rhino
				# R - compress .js files as a single block
				# P - compress .js files as a single block using packr (not yet available)
				# P and R may be combined, eg -c PR
				# only P implies PR, Packr compression is not performed without Rhino compression first
				options.compress = compress.downcase
			end
			
			opts.on("-d", "--dest DESTINATION", "Destination directory") do |dest|
				if(!File.exist?(dest))
					STDERR.puts("ERROR - Destination directory '#{dest}' does not exist.")
					exit
				end
				options.dest = dest
			end

			opts.on("-f", "--format FORMAT", "Tiddler format") do |format|
				options.format = format
			end

			#opts.on("-g", "--[no-]splash", "Generate splash screen") do |splash|
			#	options.splash = splash
			#end

			opts.on("-j", "--javascriptonly", "Generate a file that only contains the javascript") do |javascriptonly|
				options.section = "js"
			end

			opts.on("-k", "--keepallcomments", "Keep all javascript comments") do |keepallcomments|
				options.keepallcomments = keepallcomments
			end

			opts.on("-i", "--[no-]ignorecopy", "Ingnore copy command in recipes") do |ignorecopy|
				options.ignorecopy = ignorecopy
			end

			opts.on("-q", "--[no-]quiet", "Quiet mode, do not output file names") do |quiet|
				options.quiet = quiet
			end

			opts.on("-s", "--[no-]stripcommets", "Strip comments") do |stripcomments|
				options.stripcomments = stripcomments
			end

			options.help = opts
			opts.on_tail("-h", "--help", "Show this message") do
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

Tiddler.format = options.format
Recipe.quiet = options.quiet
Recipe.section = options.section
Recipe.root = options.root
Recipe.splash = options.splash
Recipe.ignorecopy = options.ignorecopy
Ingredient.compress = options.compress.strip
Ingredient.keepallcomments = options.keepallcomments
Ingredient.stripcomments = options.stripcomments
Tiddler.ginsu = false

ARGV.each do |file|
	recipe = Recipe.new(file, options.dest)
	recipe.scanrecipe
	recipe.cook
end
