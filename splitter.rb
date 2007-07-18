# spliter.rb

# Copyright (c) UnaMesa Association 2004-2007
# License: Creative Commons Attribution ShareAlike 3.0 License http://creativecommons.org/licenses/by-sa/3.0/

require 'tiddler'
require 'iconv'

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

	def split
		tiddlerCount = 0
		File.open(@filename) do |file|
			start = false
			File.open(File.join(@dirname, "split.recipe"), File::CREAT|File::TRUNC|File::RDWR, 0644) do |recipefile|
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
						writeTiddler(tiddler, recipefile)
					else
						line = file.gets
					end
				end while(line && line !~ /<!--STORE-AREA-END-->/ && line !~ /<!--POST-BODY-START-->/ && line !~ /<div id="shadowArea">/)
			end
		end
		if(tiddlerCount == 0)
			puts "'#{@filename}' does not contain any tiddlers"
		else
			puts "\n'#{@filename}' processed, #{tiddlerCount.to_s} tiddlers written to '#{@dirname}'"
		end
	end

private
	def writeTiddler(tiddler, recipefile)
		tiddlerFilename = tiddler.title.to_s.gsub(/[\/:\?#\*<> ]/, "_")
		tiddlerFilename = @conv.iconv(tiddlerFilename)
		if(tiddler.tags =~ /systemConfig/)
			targetfile = File.join(@dirname, tiddlerFilename += ".js")
			File.open(targetfile, File::CREAT|File::TRUNC|File::RDWR, 0644) do |out|
				out << tiddler.contents
			end
			File.open(targetfile + ".meta", File::CREAT|File::TRUNC|File::RDWR, 0644) do |out|
				out << tiddler.to_meta
			end
		else
			targetfile = File.join(@dirname, tiddlerFilename += ".tiddler")
			File.open(targetfile, File::CREAT|File::TRUNC|File::RDWR, 0644) do |out|
				out << tiddler.to_div
			end
		end
		recipefile << "tiddler: #{tiddlerFilename}\n"
		puts "Writing: #{tiddler.title}"
	end
end
