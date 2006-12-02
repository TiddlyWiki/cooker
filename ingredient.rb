require 'cgi'
require 'tiddler'

class Ingredient
	@@hashid = false
	
	def initialize(filename, type, attributes=nil)
		@filename = filename
		@type = type
		@extendedAttributes = Hash.new
		if(File.exists?(filename + ".meta"))
			File.open(filename+ ".meta") do |file|
				file.each_line { |line| attributes.unshift(line.strip) }
			end
		end
		parseAttributes(attributes) if attributes
	end
	
	def Ingredient.hashid
		@@hashid
	end
	
	def Ingredient.hashid=(hashid)
		@@hashid = hashid
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
		if subtype[0] == "list"
		elsif (subtype[0] == "tiddler")
			if(@filename =~ /\.tiddler/)
				return to_s_retiddle
			else
				return to_s_tiddler
			end
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
				contents << line unless line.strip =~ /^\/\/#/
			end
			tiddler.set(@title, @author, created(infile), modified(infile), @tags, @extendedAttributes, contents)
			return tiddler.to_div + "\n"
		end
	end
	
	def to_s_retiddle
		File.open(@filename) do |infile|
			tiddler= Tiddler.new
			infile.each_line do |line|
				tiddler.from_div(line)
			end
			return tiddler.to_div + "\n"
		end
	end
	
	def to_s_line
		File.open(@filename) do |infile|
			contents = ""
			infile.each_line do |line|
				contents << line unless line.strip =~ /^\/\/#/
			end
			return contents
		end
	end

	def parseAttributes(attributes)
		for i in 0...attributes.length
			line = attributes[i]
			key = line[0, line.index(':')].strip
			value = line[(line.index(':') + 1)...line.length].strip
			case key
				when "title"
					@title = value
				when "tiddler"
					@title = value
				when "tags"
					@tags = value
				when "author"
					@author = value
				when "modifier"
					@author = value
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

	def author
		@author ||= ""
	end
end
