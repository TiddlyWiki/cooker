# ingredient.rb

require 'cgi'
require 'tiddler'

class Ingredient
	@@hashid = false

	def initialize(filename, type, attributes=nil)
		@filename = filename
		@type = type
		@extendedAttributes = Hash.new
		if(File.exists?(filename + ".meta"))
			File.open(filename + ".meta") do |file|
				file.each_line { |line| attributes.unshift(line.strip) }
			end
		end
		parseAttributes(attributes) if(attributes)
	end

	def Ingredient.hashid
		@@hashid
	end

	def Ingredient.hashid=(hashid)
		@@hashid = hashid
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
		if(subtype[0] == "list")
		elsif(subtype[0] == "tiddler")
			if(@filename =~ /\.tiddler/)
				return to_s_retiddle(subtype[0])
			else
				return to_s_tiddler
			end
		elsif(subtype[0] == "shadow")
			return to_s_retiddle(subtype[0])
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
			case key
				when "title"
					@title = value
				when "tiddler"
					@title = value
				when "tags"
					@tags = value
				when "modifier"
					@modifier = value
				when "tiddle"
					@tiddle = true
				when "modified"
					@modified = value
				when "created"
					@created = value
				else
					@extendedAttributes[key] = value
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
