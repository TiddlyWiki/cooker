# spliter.rb

# Copyright (c) UnaMesa Association 2004-2008
# License: Creative Commons Attribution ShareAlike 3.0 License http://creativecommons.org/licenses/by-sa/3.0/

require 'tiddler'
require 'iconv'
#require 'open-uri'
#require 'net/http'

class Splitter
	def initialize(filename, outdir=nil, charset="ISO-8859-1")
		@filename = filename
		@conv = Iconv.new(charset,"UTF-8")
		dirset = false
		dirnum = 0;
		dirname = outdir.nil? || outdir.empty? ? @filename : File.join(outdir, File.basename(@filename))
		while !dirset do
			@dirname = dirname + "." + dirnum.to_s
			if(File.exists?(@dirname))
				dirnum += 1
			else
				Dir.mkdir(@dirname)
				dirset = true
			end
		end
	end

	def Splitter.usesubdirectories=(usesubdirectories)
		@@usesubdirectories = usesubdirectories
	end

	def Splitter.tagsubdirectory=(tagsubdirectory)
		@@tagsubdirectory = tagsubdirectory
	end

	def Splitter.quiet=(quiet)
		@@quiet = quiet
	end


	def split
		recipes = {"main" => "", "shadows" => "", "plugins" => "", "content" => "", "feeds" => "", "themes" => "", "tags" => ""}

		tiddlerCount = readStoreArea(recipes)
		if(tiddlerCount == 0)
			puts "'#{@filename}' does not contain any tiddlers"
			return
		end
		
		if(@@usesubdirectories)
			toprecipe = ""
			recipes.each_key do |k|
				if(k != "tags" && k !="main")
					if(recipes[k] != "")
						dirname = File.join(@dirname, k)
						File.open(File.join(dirname, "split.recipe"), File::CREAT|File::TRUNC|File::RDWR, 0644) do |recipefile|
							recipefile << recipes[k]
						end
						toprecipe << "recipe: " + k + "/split.recipe\n"
					end
				end
			end
			if(recipes["tags"] != "")
				dirname = File.join(@dirname, @@tagsubdirectory)
				File.open(File.join(dirname, "split.recipe"), File::CREAT|File::TRUNC|File::RDWR, 0644) do |recipefile|
					recipefile << recipes["tags"]
				end
				toprecipe << "recipe: #{@@tagsubdirectory}/split.recipe\n"
			end
			recipes["main"] = toprecipe
		end
		File.open(File.join(@dirname, "split.recipe"), File::CREAT|File::TRUNC|File::RDWR, 0644) do |recipefile|
			recipefile << recipes["main"]
		end
		puts "\n'#{@filename}' processed, #{tiddlerCount.to_s} tiddlers written to '#{@dirname}'"
	end

private
	def writeTiddler(tiddler, recipes)
		dirname = @dirname
		tiddlerFilename = tiddler.title.to_s.gsub(/[ <>]/,"_").gsub(/\t/,"%09").gsub(/#/,"%23").gsub(/%/,"%25").gsub(/\*/,"%2a").gsub(/,/,"%2c").gsub(/\//,"%2f").gsub(/:/,"%3a").gsub(/</,"%3c").gsub(/>/,"%3e").gsub(/\?/,"%3f")
		tiddlerFilename = @conv.iconv(tiddlerFilename)
		if(tiddler.tags =~ /systemConfig/)
			dirname = @dirname
			if(@@usesubdirectories)
				dirname = File.join(@dirname, "plugins")
				if(!File.exists?(dirname))
					Dir.mkdir(dirname)
				end
			end
			targetfile = File.join(dirname, tiddlerFilename += ".js")
			File.open(targetfile, File::CREAT|File::TRUNC|File::RDWR, 0644) do |out|
				out << tiddler.contents
			end
			File.open(targetfile + ".meta", File::CREAT|File::TRUNC|File::RDWR, 0644) do |out|
				out << tiddler.to_meta
			end
			recipes["plugins"] << "tiddler: #{tiddlerFilename}\n"
		else
			if(tiddler.tags =~ /systemServer/)
				writeTiddlerToSubDir(tiddler, tiddlerFilename, recipes["feeds"], "feeds")
			elsif(tiddler.tags =~ /systemTheme/)
				writeTiddlerToSubDir(tiddler, tiddlerFilename, recipes["themes"], "themes")
			elsif(@@tagsubdirectory && tiddler.tags =~ Regexp.new(@@tagsubdirectory))
				writeTiddlerToSubDir(tiddler, tiddlerFilename, recipes["tags"], @@tagsubdirectory)
			elsif(Tiddler.isShadow?(tiddler.title))
				writeTiddlerToSubDir(tiddler, tiddlerFilename, recipes["shadows"], "shadows")
			else
				writeTiddlerToSubDir(tiddler, tiddlerFilename, recipes["content"], "content")
			end
		end
		recipes["main"] << "tiddler: #{tiddlerFilename}.tiddler\n"
		if(!@@quiet)
			puts "Writing: #{tiddler.title}"
		end
	end

	def writeTiddlerToSubDir(tiddler, tiddlerFilename, recipe, subdir)
		dirname = @dirname
		if(@@usesubdirectories)
			dirname = File.join(@dirname, subdir)
			if(!File.exists?(dirname))
				Dir.mkdir(dirname)
			end
		end
		targetfile = File.join(dirname, tiddlerFilename += ".tiddler")
		File.open(targetfile, File::CREAT|File::TRUNC|File::RDWR, 0644) do |out|
			out << tiddler.to_div("tiddler",false)
		end
		recipe << "tiddler: #{tiddlerFilename}\n"
	end

	def readStoreArea(recipes)
		open(@filename) do |file|
			tiddlerCount = 0
			start = false
			line = file.gets
			begin
				line = file.gets
			end while(line && line !~ /<div id="storeArea">/)
			line = line.sub(/.*<div id="storeArea">/, "").strip
			begin
				if(line =~ /<div ti.*/)
					tiddlerCount += 1
					tiddler = Tiddler.new
					line = tiddler.read_div(file,line)
					writeTiddler(tiddler, recipes)
				else
					line = file.gets
				end
			end while(line && line !~ /<!--STORE-AREA-END-->/ && line !~ /<!--POST-BODY-START-->/ && line !~ /<div id="shadowArea">/)
			return tiddlerCount
		end
	end

public
	def Splitter.extractTiddlers(filename,titles)
		out = Array.new
		found = Array.new
		open(filename) do |file|
			start = false
			line = file.gets
			begin
				line = file.gets
			end while(line && line !~ /<div id="storeArea">/)
			line = line.sub(/.*<div id="storeArea">/, "").strip
			begin
				if(line =~ /<div ti.*/)
					tiddler = Tiddler.new
					line = tiddler.read_div(file,line)
					if titles.include?(tiddler.title)
						out.push(tiddler)
						found.push(tiddler.title)
					end
				else
					line = file.gets
				end
			end while(line && line !~ /<!--STORE-AREA-END-->/ && line !~ /<!--POST-BODY-START-->/ && line !~ /<div id="shadowArea">/)
		end
		if out.length == titles.length
			return out
		else
			STDERR.puts("Tiddlers #{(titles-found).to_s} not found in #{filename}")
		end
	end
end
