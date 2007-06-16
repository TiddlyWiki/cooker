# ingredient.rb

require 'cgi'
require 'tiddler'

class Ingredient

	def initialize(filename, type, attributes=nil)
		@filename = filename
		@type = type
		@extendedAttributes = Hash.new
		@sliceAttributes = Hash.new
		if(type == "tline")
		else
			if(File.exists?(filename + ".meta"))
				File.open(filename + ".meta") do |file|
					file.each_line { |line| attributes.unshift(line.strip) }
				end
			end
		end
		parseAttributes(attributes) if(attributes)
	end

	def Ingredient.format
		@@format
	end

	def Ingredient.format=(format)
		@@format = format
	end

	def filename
		@filename
	end

	def type
		@type
	end

	def to_s
		#"to_s_#{@type}".to_sym
		subtype = type.split('.')

		if(@type == "tline")
			return @filename
		elsif(subtype[0] == "list")
		elsif(subtype[0] == "tiddler")
			if(@filename =~ /\.tiddler/)
				return to_s_retiddle(subtype[0])
			else
				return to_s_tiddler
			end
		elsif(subtype[0] == "shadow")
			return to_s_retiddle(subtype[0])
		elsif(subtype[0] == "plugin")
			return to_s_plugin
		else
			return to_s_line
		end
	end

protected
	def to_s_tiddler
		File.open(@filename) do |infile|
			contents = ""
			tiddler = Tiddler.new
			infile.each_line do |line|
				contents << line unless(line.strip =~ /^\/\/#/)
			end
			tiddler.set(@title, @modifier, created(infile), modified(infile), @tags, @extendedAttributes, contents)
			tiddler.usePre = true;
			return tiddler.to_div
		end
	end

	def to_s_plugin
		File.open(@filename) do |infile|
			tiddler = Tiddler.new
			header = "/***\n"
			keyList = tiddler.sliceAttributeNames
			keyList.each do |key|
				out = key
				value = @sliceAttributes[key]
				if(out == "CoreVersion" || out == "CodeRepository")
					out = "~" + out
				end
				header << "|''#{out}:''|#{value}|\n" if(value)
			end

			header << "***/\n//{{{\n"
			sliceName = @sliceAttributes["Name"]
			if(sliceName)
				header << "if(!version.extensions.#{sliceName}) {\n" 
				header << "version.extensions.#{sliceName} = {installed:true};\n\n"
				footer = "\n}\n//}}}\n"
			else
				footer = "\n//}}}\n"
			end

			contents = header
			infile.each_line do |line|
				contents << line unless(line.strip =~ /^\/\/#/)
			end
			contents << footer
			tiddler.set(@title, @modifier, created(infile), modified(infile), @tags, @extendedAttributes, contents)
			tiddler.usePre = true;
			return tiddler.to_div
		end
	end

	def to_s_retiddle(subtype)
		File.open(@filename) do |infile|
			tiddler = Tiddler.new
			line = infile.gets
			tiddler.read_div(infile, line)
			tiddler.optimizeAttributeStorage = true if(subtype == "shadow")
			tiddler.usePre = true if(subtype == "shadow" && @@format =~ /preshadow/)
			tiddler.usePre = true if(subtype == "tiddler" && @@format =~ /pretiddler/)
			return tiddler.to_div
		end
	end

	def to_s_line
		File.open(@filename) do |infile|
			contents = ""
			infile.each_line do |line|
				contents << line unless(line.strip =~ /^\/\/#/)
			end
			return contents
		end
	end

	def parseAttributes(attributes)
		for i in 0...attributes.length
			line = attributes[i]
			c = line.index(':')
			next if(c == nil)
			key = line[0, c].strip
			value = line[(c + 1)...line.length].strip
			tiddler = Tiddler.new
			key2 = key
			k = key.index('.')
			if(k != nil)
				key2 = key[(k + 1)...key.length]
			end
			sliceAttributeNames = tiddler.sliceAttributeNames
			if(sliceAttributeNames.include?(key2))
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

	def modified(infile)
		@modified ||= infile.ctime.strftime("%Y%m%d%M%S")
	end

	def created(infile)
		@created ||= infile.mtime.strftime("%Y%m%d%M%S")
	end

	def title
		@title ||= @filename
	end

	def modifier
		@modifier ||= ""
	end
end
