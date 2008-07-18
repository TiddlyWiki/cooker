# recipe.rb

# Copyright (c) UnaMesa Association 2004-2008
# License: Creative Commons Attribution ShareAlike 3.0 License http://creativecommons.org/licenses/by-sa/3.0/

require 'ingredient'
require "ftools"
require 'net/http'
require 'uri'

class Recipe
	def initialize(filename, outdir=nil, isTemplate=false)
		@filename = filename
		@outdir = outdir ||= ""
		@ingredients = Array.new
		@addons = Hash.new
		@tiddlers = Hash.new
		@defaultTiddlersFilename = ""
		@dirname = File.dirname(filename)
		if(@dirname =~ /\$TW_ROOT\//)
			c = @dirname.index('$TW_ROOT')
			@dirname = @dirname[(c + 8)...@dirname.length].strip
			@dirname = @@root + @dirname
		end
		@filename = File.join(@dirname,File.basename(filename))
		open(@filename) do |file|
			file.each_line { |line| genIngredient(@dirname, line, isTemplate) }
		end
	end

	def scanrecipe
		if(@ingredients.length > 0)
			@ingredients.each do |ingredient|
				if(ingredient.type == "list")
					if(@addons.has_key?(ingredient.filename))
						@addons.fetch(ingredient.filename).each{ |ingredient| writeToDishScan(ingredient) }
					end
				else
					writeToDishScan(ingredient)
				end
			end
		end
	end

	def cook
		puts "Creating file: " + outfilename
		if(@ingredients.length > 0)
			File.open(outfilename, File::CREAT|File::TRUNC|File::RDWR, 0644) do |out|
				@ingredients.each do |ingredient|
					if(ingredient.type == "list")
						if(ingredient.filename=="title")
							# write the title from the shadow tiddlers if available
							title = ""
							if(@tiddlers["SiteTitle"])
								title << @tiddlers["SiteTitle"].contents
								if(@tiddlers["SiteSubtitle"])
									title << " - "
								end
							end
							if(@tiddlers["SiteSubtitle"])
								title << @tiddlers["SiteSubtitle"].contents
							end
							out << title + "\n" if title
						end
						if(@@splash  && ingredient.filename=="posthead")
							writeSplashStyles(out)
						end
						if(@@splash  && ingredient.filename=="prebody")
							writeSplash(out)
						end
						if(Ingredient.compress=~/[pr]+/ && ingredient.filename == "js")
							block = ""
							if(@addons.has_key?(ingredient.filename))
								@addons.fetch(ingredient.filename).each do |ingredient| 
									b = writeToDish(block, ingredient)
									block += b if(b)
								end
							end
							if(Ingredient.compress=~/[pr]+/)
								block = Ingredient.rhino(block)
								if(Ingredient.compress=~/.?p.?/)
									block = Ingredient.packr(block)
								end
							end
							out << block
						else
							if(@addons.has_key?(ingredient.filename))
								@addons.fetch(ingredient.filename).each{ |ingredient| writeToDish(out, ingredient) }
							end
						end
					else
						writeToDish(out, ingredient)
					end
				end
			end
		end
		@addons.fetch("copy", Array.new).each { |ingredient| copyFile(ingredient) }
	end

	def Recipe.quiet
		@@quiet
	end

	def Recipe.quiet=(quiet)
		@@quiet = quiet
	end

	def Recipe.ignorecopy
		@@ignorecopy
	end

	def Recipe.ignorecopy=(ignorecopy)
		@@ignorecopy = ignorecopy
	end

	def Recipe.root
		@@root
	end

	def Recipe.root=(root)
		@@root = root
	end

	def Recipe.splash
		@@splash
	end

	def Recipe.splash=(splash)
		@@splash = splash
	end

	def Recipe.section
		@@section
	end

	def Recipe.section=(section)
		@@section = section
	end

protected
	def outdir
		@outdir.empty? ? "" : File.join(@outdir, "")
	end

	def outfilename
		outdir + File.basename(@filename.sub(".recipe", ""))
	end

	def ingredients
		@ingredients
	end

	def addons
		@addons
	end

	def genIngredient(dirname, line, isTemplate=false)
		if(isTemplate)
			if(line =~ /<!--@@.*@@-->/)
				@ingredients << Ingredient.new(line.strip.slice(6..-6), "list")
			elsif(line =~ /&lt;!--@@.*@@--&gt;/)
				@ingredients << Ingredient.new(line.strip.slice(9..-9), "list")
			elsif(line =~ /<!--<<.*>>-->/)
				item = line.strip.slice(6..-6)
				c = item.index(' ')
				if(c != nil)
					item = item[(c + 1)...item.length].strip
				end
				@ingredients << Ingredient.new(item, "list")
			else
				@ingredients << Ingredient.new(line.sub("\r", ""), "tline")
			end
		else
			if(line.strip == "" || line[0, 1]=='#')
				return
			end
			if(line =~ /@.*@/)
				@ingredients << Ingredient.new(line.strip.slice(1..-2), "list")
			elsif(line =~ /template\:/)
				value = line.sub(/template\:/, "").strip
				path = value =~ /^https?/ ? "" : dirname
				loadSubrecipe(File.join(path, value),true)
			elsif(line =~ /recipe\:/)
				value = line.sub(/recipe\:/, "").strip
				unless value =~ /^https?/
					loadSubrecipe(File.join(dirname, value),false)
				else
					loadSubrecipe(value,false)
				end
			elsif(line =~ /\:/)
				c = line.index(':')
				key = line[0, c].strip
				value = line[(c + 1)...line.length].strip
				c = value.index(' ')
				if(c != nil)
					attributes = value[(c + 1)...value.length].strip
					value = value[0, c].strip
				end
				file = value =~ /^https?/ ? value : File.join(dirname,value)
				addAddOns(key, file, attributes)
				loadSubrecipe(file + ".deps",false) if File.exists?(file + ".deps")
			elsif(line =~ /\=/)
			#puts "line:"+ line
				c = line.index('=')
				key = line[0, c].strip
				value = line[(c + 1)...line.length]
			#puts "value:"+ value
				addAddOns(key, value, nil, true)
				#@ingredients << Ingredient.new(value, "text")
			else
				file = File.join(dirname, line.chomp)
				@ingredients << Ingredient.new(file, "line")
				loadSubrecipe(file + ".deps",false) if(File.exists?(file + ".deps"))
			end
		end
	end

	def loadSubrecipe(subrecipename, isTemplate)
		recipe = Recipe.new(subrecipename, @outdir, isTemplate)
		@ingredients = @ingredients + recipe.ingredients
		recipe.addons.each { |key, value| addAddOns(key, value) }
	end

	def addAddOns(key, value, attributes=nil, raw=false)
		addonarray = @addons.fetch(key, Array.new)
		if(value.class == Array)
			addonarray = addonarray + value
		elsif(value.class == Ingredient)
			addonarray.push(value)
		else
			ingredient = Ingredient.new(value, key, attributes, raw)
			addonarray.push(ingredient)
		end
		@addons.store(key, addonarray)
	end

	def writeToDishScan(ingredient)
		if (!ingredient.is_a? String)
			if(ingredient.type=="shadow" || ingredient.type=="tiddler")
				# save copies of all the shadow tiddlers in scan pass
				name = File.basename(ingredient.filename,".tiddler")
				if(Tiddler.looksLikeShadow?(ingredient.filename))
					tiddler = Tiddler.new
					tiddler.loadDiv(ingredient.filename)
					if(Tiddler.isShadow?(tiddler.title))
						@tiddlers[tiddler.title] = tiddler
						if(tiddler.title=="DefaultTiddlers")
							@defaultTiddlersFilename = ingredient.filename
						end
					end
				end
			end
		end
	end

	def writeToDish(outfile, ingredient)
		if (!ingredient.is_a? String)
			if(ingredient.type == "title")
				return if(@tiddlers["SiteTitle"]||@tiddlers["SiteSubtitle"]) # don't write the title if it is available from the tiddlers
			end
		end
		return if(@@section!="" && @@section!=ingredient.type)
		if(outfile.is_a? String)
			outfile = ingredient.to_s
		else
			puts "Writing: " + ingredient.filename if !@@quiet && ingredient.type!="tline" && ingredient.raw==false
			outfile << ingredient
		end
	end

	def writeSplashStyles(out)
		out << "<style type=\"text/css\">\n"
		out << "#contentWrapper {display:none;}\n"
		out << "#splashScreen {display:block;}\n"
		out << ".title {color:#841;}\n"
		out << ".subtitle {color:#666;}\n"
		out << ".header {background:#04b;}\n"
		out << ".headerShadow {color:#000;}\n"
		out << ".headerShadow a {font-weight:normal; color:#000;}\n"
		out << ".headerForeground {color:#fff;}\n"
		out << ".headerForeground a {font-weight:normal; color:#8cf;}\n"
		out << ".shadow .title {color:#666;}\n"
		out << "</style>\n"
	end

	def writeSplash(out)
		pageTemplate = @tiddlers["PageTemplate"]
		viewTemplate = @tiddlers["ViewTemplate"]
		return if !pageTemplate || !viewTemplate

		sitetitle = @tiddlers["SiteTitle"]
		sitetitle = sitetitle.contents if sitetitle
		sitesubtitle = @tiddlers["SiteSubtitle"]
		sitesubtitle = sitesubtitle.contents if sitesubtitle

		defaultTiddlers = Array.new
		if(@tiddlers["DefaultTiddlers"])
			list = @tiddlers["DefaultTiddlers"].contents
			items = list.split(" ")
			count = items.length
			i = 0
			while(i<count)
				x = items[i].sub("[[","").sub("]]","");
				defaultTiddlers.push(x)
				i = i+1
			end
		end

		splash = pageTemplate.contents
		#puts "pageTemplate:"+splash
		tiddlers = ""
		defaultTiddlers.each do |title|
			tiddler = Tiddler.new
			filename = @defaultTiddlersFilename.sub(/DefaultTiddlers/,title)
			tiddler.loadDiv(filename);
			tiddlers += tiddler.to_html(viewTemplate.contents)
		end
		#puts "tiddlers:"+tiddlers

		splash = splash.gsub(/<!--\{\{\{-->/,"");
		splash = splash.gsub(/<!--\}\}\}-->/,"");
		#splash = splash.gsub(/<div id='/,"<div id='s_")
		splash = splash.gsub(/<span class='siteTitle' refresh='content' tiddler='SiteTitle'><\/span>/,"<span class=\"siteTitle\">#{sitetitle}</span>")
		splash = splash.gsub(/<span class='siteSubtitle' refresh='content' tiddler='SiteSubtitle'><\/span>/,"<span class=\"siteSubtitle\">#{sitesubtitle}</span>")
		splash = splash.sub(/<div id='tiddlerDisplay'><\/div>/,"<div id=\"s_tiddlerDisplay\">#{tiddlers}</div>")
		splash = splash.gsub(/ macro='[\w \.\[\]:]*'/,"")
		splash = splash.gsub(/<div class='(\w*)'/,"<div class=\"\\1\"")
		splash = splash.gsub(/<div id='(\w*)'/,"<div id=\"\\1\"")
		#puts "splash:"+splash
		out << "<div id=\"splashScreen\">\n"
		out << splash
		out << "</div>\n"
	end

	def copyFile(ingredient)
		puts "Copying: " + ingredient.filename if(!@@quiet && !@@ignorecopy)
		if ingredient.filename =~ /^https?/
			downloadFile(ingredient.filename)
		else
			File.copy(ingredient.filename, File.join(outdir, File.basename(ingredient.filename))) if(!@@ignorecopy)
		end
	end
	
private
	def downloadFile(url)
		uri = URI.parse(url)
		Net::HTTP.start(uri.host) { |http|
			resp = http.get(uri.path)
			open(File.join(outdir, File.basename(url)), "wb") { |file|
				file.write(resp.body)
			}
		}
	end
end
