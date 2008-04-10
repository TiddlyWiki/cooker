# tiddler.rb

# Copyright (c) UnaMesa Association 2004-2008
# License: Creative Commons Attribution ShareAlike 3.0 License http://creativecommons.org/licenses/by-sa/3.0/

require 'cgi'
require 'open-uri'
require 'time'
require 'date'
require 'date/format'

# Tiddler line in recipe file:
#	tiddler:TiddlerName.[js|tiddler]
#	can append tags="tag1 tag2..." to set tiddler tags
#	or append tags+="tag1 tag2..." to add tags to tiddler
#	note, no space around '=' or '+='
# eg:
#	tiddler:LegacyStrikeThroughPlugin.js tags+="excludeLists"

class Tiddler
	def initialize
		@@format = ""
		@usePre = true
		@extendedAttributes = Hash.new
		@sliceAttributes = Hash.new
		@standardAttributeNames = [ "tiddler", "title", "modifier", "modified", "created", "tags" ]
		@sliceAttributeNames = ["Name","Description","Version","Requires","CoreVersion","Date","Source","Author","License","Browsers","CodeRepository"]
		@@shadowNames = ["AdvancedOptions","ColorPalette",
			"DefaultTiddlers","EditTemplate","GettingStarted","ImportTiddlers","MainMenu",
			"MarkupPreBody","MarkupPreHead","MarkupPostBody","MarkupPostHead",
			"OptionsPanel","PageTemplate","PluginManager",
			"SiteSubtitle","SiteTitle","SiteUrl",
			"StyleSheet","StyleSheetColors","StyleSheetLayout","StyleSheetLocale","StyleSheetPrint",
			"TabAll","TabMoreMissing","TabMoreOrphans","TabMoreShadowed","TabTimeline","TabTags",
			"ViewTemplate"]
	end

	def Tiddler.format
		@@format
	end

	def Tiddler.format=(format)
		@@format = format
	end

	def Tiddler.isShadow?(title)
		return @@shadowNames.include?(title)
	end

	def Tiddler.looksLikeShadow?(filename)
		if(filename =~ /SiteTitle.*/ || filename =~ /SiteSubtitle.*/ || filename =~ /DefaultTiddlers.*/ || filename =~ /PageTemplate.*/ || filename =~ /ViewTemplate.*/)
			return true
		end
		return false
	end

	def title
		@title ||= @filename
	end

	attr_reader :modifier
	attr_reader :tags
	attr_reader :contents

	def setAttributes(attributes)
		title = parseAttribute(attributes,"title")
		if(title)
			title = title.strip
			@title = title
		end
		tags = parseAddAttribute(attributes,"tags")
		if(tags)
			@tags = @tags + " " + tags
			@tags = @tags.strip
		end
		tags = parseAttribute(attributes,"tags")
		if(tags)
			@tags = tags
			@tags = @tags.strip
		end
		desc = parseAttribute(attributes,"Description")
		if(desc)
			desc = desc.strip
			@sliceAttributes["Description"] = desc
		end
	end

	def load(filename)
		# read in a tiddler from a .js and a .js.meta pair of files
		begin #use begin rescue block since there may not be a .meta file if the attributes are obtained from the .recipe file
			open(filename + ".meta") do |infile|
				infile.each_line do |line|
					c = line.index(':')
					if(c != nil)
						key = line[0, c].strip
						value = line[(c + 1)...line.length].strip
						key2 = key
						k = key.index('.')
						if(k != nil)
							key2 = key[(k + 1)...key.length]
						end
						if(@sliceAttributeNames.include?(key2))
							@sliceAttributes[key2] = value
						else
							case key
							when "title"
								@title = value
							when "tiddler"
								@title = value
							when "modifier"
								@modifier = value
							when "created"
								@created = value
							when "modified"
								@modified = value
							when "tags"
								@tags = value
							else
								@extendedAttributes[key] = value
							end
						end
					end
				end
			end
		rescue
		end
		open(filename) do |infile|
			@contents = ""
			infile.each_line do |line|
				@contents << line unless(line.strip =~ /^\/\/#/)
			end
			unless filename =~ /^https?/
				@created ||= infile.mtime.strftime("%Y%m%d%M%S")
			end
			#@modified ||= infile.ctime.strftime("%Y%m%d%M%S")
		end
		@title ||= File.basename(filename,".js")
	end

	def loadDiv(filename)
		# read in tiddler from a .tiddler file
		open(filename) do |file|
			line = file.gets
			divText = ""
			if(line =~ /<div tiddler=.*<\/div>/)
				divText = line
				line = file.gets
			elsif(line =~ /<div title=.*/)
				begin
					divText << line
					line = file.gets
				end while line
			end
			from_div(divText)
		end
	end

	def read_div(file, line)
		divText = ""
		if(line =~ /<div tiddler=.*<\/div>/)
			divText = line
			line = file.gets
		elsif(line =~ /<div title=.*/)
			begin
				divText << line
				line = file.gets
			end while line && line !~ /<div ti/ && line !~ /<\/div>/
		end
		from_div(divText)
		return line
	end

	def to_div(subtype="tiddler",escapeHTML=true)
		optimizeAttributeStorage = true if(subtype == "shadow")
		@usePre = true if(subtype == "shadow" && @@format =~ /preshadow/)
		@usePre = true if(subtype == "tiddler" && @@format =~ /pretiddler/)
		out = "<div "
		out << (@usePre ? "title=\"#{@title}\"" : "tiddler=\"#{@title}\"")
		out << " modifier=\"#{@modifier}\"" if(@modifier)
		if(@usePre || optimizeAttributeStorage)
			out << " created=\"#{@created}\"" if(@created)
			out << " modified=\"#{@modified}\"" if(@modified && @modified != @created)
			out << " tags=\"#{@tags}\"" if(@tags)
		else
			out << " modified=\"#{@modified}\"" if(@modified)
			out << " created=\"#{@created}\"" if(@created)
			out << " tags=\"#{@tags}\""
		end
		@extendedAttributes.each_pair { |key, value| out << " #{key}=\"#{value}\"" }
		out << ">"
		if(@usePre)
			out << "\n<pre>"
			lines = @contents
			if(escapeHTML)
				lines = CGI::escapeHTML(lines)
			end
			lines = (lines.gsub("\r", "")).split("\n")
			last = lines.pop
			lines.each { |line| out << line << "\n" }
			out << last if(last)
			out << "</pre>\n"
		else
			@contents.each { |line| out << CGI::escapeHTML(line).gsub("\\", "\\s").sub("\n", "\\n").sub("\r", "") }
		end
		out << "</div>\n"
	end

	def to_raw(subtype="tiddler")
		return "" if(@contents=="")
		contents = @contents
		if(subtype!="tiddler" && subtype!="shadow" && subtype!="plugin")
			pos = contents.rindex("</pre>");
			contents = contents[0,pos] if(pos)
			contents = contents.sub(/[\n\r]*<pre>/, "")
		end
		out = ""
		contents.each { |line| out << line.sub("\r", "") }
		return out
	end

	def to_plugin
		header = ""
		sliceName = @sliceAttributes["Name"]
		if(!sliceName)
			# if no name specified then use @title
			sliceName = @title
			if(sliceName)
				header = "/***\n"
				header << "|''Name:''|#{sliceName}|\n"
			end
		end
		@sliceAttributeNames.each do |key|
			out = key
			value = @sliceAttributes[key]
			if(out == "CoreVersion" || out == "CodeRepository")
				out = "~" + out
			end
			header = "/***\n" if(header=="" && value)
			header << "|''#{out}:''|#{value}|\n" if(value)
		end

		header << "***/\n" if(header!="")
		header << "//{{{\n"
		if(sliceName)
			header << "if(!version.extensions.#{sliceName}) {\n" 
			header << "version.extensions.#{sliceName} = {installed:true};\n\n"
			footer = "\n}\n//}}}\n"
		else
			footer = "\n//}}}\n"
		end

		@contents = header + @contents + footer
		return to_div
	end

	def to_meta
		out = "title: #{@title}\n"
		out << "modifier: #{@modifier}\n"
		out << "created: #{@created}\n"
		out << "modified: #{@modified}\n"
		out << "tags: #{@tags}\n"
		@extendedAttributes.each_pair do |key, value|
			out << "#{key}: #{value}\n"
		end
		return out
	end

	def to_html(template)
		contents = @contents # need to wikify this
		t = Time.local(@created[0,4],@created[4,2],@created[6,2])
		created = t.strftime("created %d %B %Y")
		t = Time.local(@modified[0,4],@modified[4,2],@modified[6,2])
		modified = t.strftime("%d %B %Y")

		out = template
		out = out.sub(/<!--\{\{\{-->/,"");
		out = out.sub(/<!--\}\}\}-->/,"");
		out = out.sub(/<div class='title' macro='view title'><\/div>/,"<div class=\"title\">#{@title}</div>")
		out = out.sub(/<span macro='view modifier link'><\/span>/,"<span>#{@modifier}</span>")
		out = out.sub(/<span macro='view modified date(?: "[\w\-\:\/ ]*")?'><\/span>/,"<span>#{modified}</span>")
		out = out.sub(/<span macro='view created date(?: "[\w\-\:\/ ]*")?'><\/span>/,"<span>#{created}</span>")
		out = out.sub(/<div class='viewer' macro='view text wikified'><\/div>/,"<div class=\"viewer\">#{contents}</div>")
		out = out.gsub(/ macro='[\w \.\[\]:]*'/,"")
		out = out.gsub(/<div class='(\w*)'/,"<div class=\"\\1\"")
		out = out.gsub(/<div id='(\w*)'/,"<div id=\"\\1\"")
		return out
	end

protected
	def from_div(divText)
		parseAllAttributes(divText)
		parseContent(divText)
	end

	def parseContent(divText)
		@contents = ""
		return if(divText=="")
		if(@usePre)
			pos = divText.rindex("</pre>");
			divText = divText[0,pos] if(pos)
			@contents = divText.sub(/<div.*?>[\n\r]*<pre>/, "")
		else
			@contents = divText.sub(/<div.*?>/, "").sub(/<\/div>[\n\r]*/, "").gsub("\\n", "\n").gsub("\\s", "\\")
		end
		@contents = CGI::unescapeHTML(@contents.gsub("\r", ""))
	end

	def parseAllAttributes(divText)
		@usePre = false
		@title = parseAttribute(divText, "tiddler")
		if(!@title)
			@usePre = true;
			@title = parseAttribute(divText, "title")
		end
		@modifier = parseAttribute(divText, "modifier")
		@created = parseAttribute(divText, "created")
		@modified = parseAttribute(divText, "modified")
		@tags = parseAttribute(divText, "tags")
		parseExtendedAttributes(divText)
	end

	def parseAttribute(divText, attribute)
		exp = Regexp.new(Regexp.escape(attribute) + '="([^"]+)"')
		if(exp.match(divText))
			returnval = $1
		end
	end

	def parseAddAttribute(divText, attribute)
		return if(!divText || !attribute)

		exp = Regexp.new(Regexp.escape(attribute) + '\+="([^"]+)"')
		if(exp.match(divText))
			returnval = $1
		end
	end

	def parseExtendedAttributes(divText)
		return if(!divText)
		match = /<div (.*)>/.match(divText)
		return if(!match)
		attributes = match[1].to_s.split(/([^\s\t]*)="([^"]*)"/)
		0.step(attributes.size - 1, 3) do |i|
			key, value = attributes[i + 1], attributes[i + 2]
			@extendedAttributes.store(key, value) if(key && !@standardAttributeNames.include?(key))
		end
	end

	def modified(infile)
		@modified ||= infile.ctime.strftime("%Y%m%d%M%S")
	end

	def created(infile)
		@created ||= infile.mtime.strftime("%Y%m%d%M%S")
	end

	def modifier
		@modifier ||= ""
	end
end
