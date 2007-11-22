# spliter.rb

# Copyright (c) UnaMesa Association 2004-2007
# License: Creative Commons Attribution ShareAlike 3.0 License http://creativecommons.org/licenses/by-sa/3.0/

require 'tiddler'
require 'iconv'

class Splitter
	def initialize(filename, outdir=nil, charset="ISO-8859-1")
		@filename = filename
		@conv = Iconv.new(charset,"UTF-8")
		@shadowNames = ["AdvancedOptions","ColorPalette",
			"DefaultTiddlers","EditTemplate","GettingStarted","ImportTiddlers","MainMenu",
			"MarkupPreBody","MarkupPreHead","MarkupPostBody","MarkupPostHead",
			"OptionsPanel","PageTemplate","PluginManager",
			"SiteSubtitle","SiteTitle","SiteUrl",
			"StyleSheet","StyleSheetColors","StyleSheetLayout","StyleSheetLocale","StyleSheetPrint",
			"TabAll","TabMoreMissing","TabMoreOrphans","TabMoreShadowed","TabTimeline","TabTags",
			"ViewTemplate"]
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

	def Splitter.quiet=(quiet)
		@@quiet = quiet
	end


	def split
		tiddlerCount = 0
		recipe = ""
		shadowsrecipe = ""
		pluginsrecipe = ""
		contentrecipe = ""
		feedsrecipe = ""
		themesrecipe = ""
		File.open(@filename) do |file|
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
					writeTiddler(tiddler, recipe, pluginsrecipe, shadowsrecipe, contentrecipe, feedsrecipe, themesrecipe)
				else
					line = file.gets
				end
			end while(line && line !~ /<!--STORE-AREA-END-->/ && line !~ /<!--POST-BODY-START-->/ && line !~ /<div id="shadowArea">/)
		end
		
		if(@@usesubdirectories)
			toprecipe = ""
			if(shadowsrecipe != "")
				dirname = File.join(@dirname, "shadows")
				File.open(File.join(dirname, "split.recipe"), File::CREAT|File::TRUNC|File::RDWR, 0644) do |recipefile|
					recipefile << shadowsrecipe
				end
				toprecipe << "recipe: shadows/split.recipe\n"
			end
			if(pluginsrecipe != "")
				dirname = File.join(@dirname, "plugins")
				File.open(File.join(dirname, "split.recipe"), File::CREAT|File::TRUNC|File::RDWR, 0644) do |recipefile|
					recipefile << pluginsrecipe
				end
				toprecipe << "recipe: plugins/split.recipe\n"
			end
			if(contentrecipe != "")
				dirname = File.join(@dirname, "content")
				File.open(File.join(dirname, "split.recipe"), File::CREAT|File::TRUNC|File::RDWR, 0644) do |recipefile|
					recipefile << contentrecipe
				end
				toprecipe << "recipe: content/split.recipe\n"
			end
			if(feedsrecipe != "")
				dirname = File.join(@dirname, "feeds")
				File.open(File.join(dirname, "split.recipe"), File::CREAT|File::TRUNC|File::RDWR, 0644) do |recipefile|
					recipefile << feedsrecipe
				end
				toprecipe << "recipe: feeds/split.recipe\n"
			end
			if(themesrecipe != "")
				dirname = File.join(@dirname, "themes")
				File.open(File.join(dirname, "split.recipe"), File::CREAT|File::TRUNC|File::RDWR, 0644) do |recipefile|
					recipefile << feedsrecipe
				end
				toprecipe << "recipe: themes/split.recipe\n"
			end
			recipe = toprecipe
		end
		File.open(File.join(@dirname, "split.recipe"), File::CREAT|File::TRUNC|File::RDWR, 0644) do |recipefile|
			recipefile << recipe
		end
		if(tiddlerCount == 0)
			puts "'#{@filename}' does not contain any tiddlers"
		else
			puts "\n'#{@filename}' processed, #{tiddlerCount.to_s} tiddlers written to '#{@dirname}'"
		end
	end

private
	def writeTiddler(tiddler, recipe, pluginsrecipe, shadowsrecipe, contentrecipe, feedsrecipe, themesrecipe)
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
			pluginsrecipe << "tiddler: #{tiddlerFilename}\n"
		else
			if(tiddler.tags =~ /systemServer/)
				writeTiddlerToSubDir(tiddler, tiddlerFilename, feedsrecipe, "feeds")
			elsif(tiddler.tags =~ /systemTheme/)
				writeTiddlerToSubDir(tiddler, tiddlerFilename, themesrecipe, "themes")
			elsif(@shadowNames.include?(tiddler.title))
				writeTiddlerToSubDir(tiddler, tiddlerFilename, shadowsrecipe, "shadows")
			else
				writeTiddlerToSubDir(tiddler, tiddlerFilename, contentrecipe, "content")
			end
		end
		recipe << "tiddler: #{tiddlerFilename}.tiddler\n"
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
end
