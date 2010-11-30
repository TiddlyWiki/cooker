# recipe.rb

# Copyright (c) UnaMesa Association 2004-2008
# License: Creative Commons Attribution ShareAlike 3.0 License http://creativecommons.org/licenses/by-sa/3.0/

require 'ingredient'
require "fileutils"
require 'net/http'
require 'uri'

class Recipe
	def initialize(filename, outdir=nil, isTemplate=false, outputfile=nil)
		@outdir = outdir ||= ""
		@outputfile = outputfile ||= ""
		@ingredients = Array.new
		@addons = Hash.new
		@tiddlers = Hash.new
		@defaultTiddlersFilename = ""
		@filename = Recipe.injectEnv(filename)
		@dirname = File.dirname(@filename)
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
								title << " - " if(@tiddlers["SiteSubtitle"])
							end
							title << @tiddlers["SiteSubtitle"].contents if(@tiddlers["SiteSubtitle"])
							out << title + "\n" if title
						end
						if(@@splash  && ingredient.filename=="posthead")
							writeSplashStyles(out)
						end
						if(@@splash  && ingredient.filename=="prebody")
							writeSplash(out)
						end
						type = ingredient.filename
						block = ""
						if(@addons.has_key?(ingredient.filename))
							@addons.fetch(ingredient.filename).each do |ingredient|
								type = ingredient.type
								b = writeToDish(block, ingredient)
								block += b if(b)
							end
						end
						if((Ingredient.compress=~/[pry]+/ && type == "js") || (Ingredient.compressplugins=~/[pry]+/ && type == "jquery") || (Ingredient.compressdeprecated=~/[pry]+/ && type == "jsdeprecated"))
							if(Ingredient.compress=~/[pry]+/ || Ingredient.compressplugins=~/[pry]+/ || Ingredient.compressdeprecated=~/[pry]+/)
								block = Ingredient.compressor(block)
								if(Ingredient.compress=~/.?p.+/ || Ingredient.compressplugins=~/.?p.+/ || Ingredient.compressdeprecated=~/.?p.+/)
									block = Ingredient.packr(block)
								end
							end
						end
						out << block
					else
						writeToDish(out, ingredient)
					end
				end
			end
		end
		@addons.fetch("copy", Array.new).each { |ingredient| copyFile(ingredient) }
	end

	def Recipe.env(name)
		ENV[name] || ''
	end

	def Recipe.injectEnv(path)
		while path =~ /\$.*?\//
			path = env($&[1...-1]) + '/' + $'
		end
		return path
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

	def Recipe.plugins
		@@plugins
	end

	def Recipe.plugins=(plugins)
		@@plugins = plugins
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
		if(@outputfile == "")
			return outdir + Recipe.env('TW_COOK_OUTPUT_PREFIX') + File.basename(@filename.sub(".recipe", ""))
		else
			return outdir + Recipe.env('TW_COOK_OUTPUT_PREFIX') + @outputfile
		end
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
				if(value =~ /^https?/ || value[0,1]=='/')
					file =  value
				else
					file = File.join(dirname,value)
				end
				loadSubrecipe(file,true)
			elsif(line =~ /recipe\:/)
				value = line.sub(/recipe\:/, "").strip
				if(value =~ /^https?/ || value[0,1]=='/')
					file =  value
				else
					file = File.join(dirname,value)
				end
				loadSubrecipe(file,false)
			elsif(line =~ /\:/)
				c = line.index(':')
				key = line[0, c].strip
				value = line[(c + 1)...line.length].strip
				d = value.index('.')
				if(d != nil)
					c = value[(d + 1)...value.length].strip.index(' ')
					if(c != nil)
						c += d + 1
					end
				else
					c = value.index(' ')
				end
				if(c != nil)
					attributes = value[(c + 1)...value.length].strip
					value = value[0, c].strip
				end
				if(value =~ /^https?/ || value[0,1]=='/')
					file =  value
				else
					file = File.join(dirname,value)
				end
				addAddOns(key, file, attributes)
				loadSubrecipe(file + ".deps",false) if File.exists?(file + ".deps")
			elsif(line =~ /\=/)
				c = line.index('=')
				key = line[0, c].strip
				value = line[(c + 1)...line.length]
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
		recipe.addons.each { |key, value, attributes| addAddOns(key, value, attributes) }
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
			if(!Tiddler.isShadow?(title))
				filename = filename.sub(/shadows/,"content")
			end
			tiddler.loadDiv(filename);
			tiddlers += tiddler.to_html(viewTemplate.contents)
		end

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
		if(!@@ignorecopy)
			puts "Copying: " + ingredient.filename if(!@@quiet)
			if ingredient.filename =~ /^https?/
				downloadFile(ingredient.filename)
			else
				FileUtils.copy(ingredient.filename, File.join(outdir, File.basename(ingredient.filename)))
			end
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
