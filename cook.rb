#!/usr/bin/env ruby
# cook.rb

# Copyright (c) UnaMesa Association 2004-2008
# License: Creative Commons Attribution ShareAlike 3.0 License http://creativecommons.org/licenses/by-sa/3.0/

require 'recipe'
require 'optparse'
require 'ostruct'

$VERSION = "1.1.10001"
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
		options.compresstype = "rhino"
		options.compressplugins = ""
		options.compressdeprecated = ""
		options.compresshead = ""
		options.outputfile = ""
		options.plugins = ""
		options.splash = false
		options.section = ""
		options.ignorecopy = false
		options.usefiletime = false

		opts = OptionParser.new do |opts|
			opts.banner = "Cook #{version}\n"
			opts.banner += "Usage: cook.rb recipename [...] [options]"
			opts.separator ""
			opts.separator "Specific options:"

			opts.on("-r", "--root ROOT", "Root path") do |root|
				options.root = root
			end

			#opts.on("-p", "--plugins PLUGINS", "jQuery plugin path") do |plugins|
			#	options.plugins = plugins
			#end

			opts.on("-c", "--compress COMPRESS", "Compress javascript, use -c, -cr, -cy or -crp") do |compress|
				# three options available
				# F - compress each .js file individually using rhino
				# R - compress .js files as a single block
				# P - compress .js files as a single block using packr (not yet available)
				# P and R may be combined, eg -c PR
				# only P implies PR, Packr compression is not performed without Rhino compression first
				options.compress = compress.downcase.strip
				if options.compress=~/y/
					options.compresstype = "yui"
				end
			end

			opts.on("-C", "--cplugins CPLUGINS", "Compress javascript plugins, use -C, -Cr, -Cy or -Crp") do |compressplugins|
				# three options available
				# R - compress .js files as a single block using rhino
				# Y - compress .js files as a single block using yuicompressor
				# P - compress .js files as a single block using packr (not yet available)
				# P and R may be combined, eg -c PR
				# only P implies PR, Packr compression is not performed without Rhino compression first
				options.compressplugins = compressplugins.strip
				if options.compressplugins=~/y/
					options.compresstype = "yui"
				end
			end

			opts.on("-D", "--deprecated DEPRECATED", "Compress deprecated javascript, use -D, -Dr or -Drp") do |compressdeprecated|
				# three options available
				# R - compress .js files as a single block using rhino
				# Y - compress .js files as a single block using yuicompressor
				# P - compress .js files as a single block using packr (not yet available)
				# P and R may be combined, eg -c PR
				# only P implies PR, Packr compression is not performed without Rhino compression first
				options.compressdeprecated = compressdeprecated.strip
				if options.compressdeprecated=~/y/
					options.compresstype = "yui"
				end
			end

			opts.on("-H", "--[no-]HEAD", "Compress jshead, use -H") do |compresshead|
				options.compresshead = compresshead
			end

			opts.on("-d", "--dest DESTINATION", "Destination directory") do |dest|
				if(!File.exist?(dest))
					STDERR.puts("ERROR - Destination directory '#{dest}' does not exist.")
					exit
				end
				options.dest = dest
			end

			opts.on("-o", "--outputfile OUTPUTFILE", "Output file") do |outputfile|
				options.outputfile = outputfile
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
			
			opts.on("-t","--time", "Time modified from file system") do |usefiletime|
				options.usefiletime = usefiletime
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
ENV['TW_ROOT'] = options.root || ENV['TW_ROOT'] || ENV['TW_TRUNKDIR']
Recipe.plugins = options.plugins
Recipe.splash = options.splash
Recipe.ignorecopy = options.ignorecopy
Ingredient.compress = options.compress
Ingredient.compresstype = options.compresstype
Ingredient.compressplugins = options.compressplugins
Ingredient.compressdeprecated = options.compressdeprecated
Ingredient.compresshead = options.compresshead
Ingredient.keepallcomments = options.keepallcomments
Ingredient.stripcomments = options.stripcomments
Tiddler.ginsu = false
Tiddler.usefiletime = options.usefiletime

ARGV.each do |file|
	recipe = Recipe.new(file, options.dest, false, options.outputfile)
	recipe.scanrecipe
	recipe.cook
end
