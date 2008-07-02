# ingredient.rb

# Copyright (c) UnaMesa Association 2004-2008
# License: Creative Commons Attribution ShareAlike 3.0 License http://creativecommons.org/licenses/by-sa/3.0/

require 'cgi'
require 'tempfile'

require 'tiddler'
require 'splitter'

class String
	def to_file(file_name) #:nodoc:
		File.open(file_name,"w") { |f| f << self }
	end
end

class Ingredient

	def initialize(line, type, attributes=nil, raw=false)
		@attributes = attributes
		@line = line
		@filename = line
		@type = type
		@raw = raw
	end

	def filename
		@filename
	end

	def type
		@type
	end

	def raw
		@raw
	end

	def Ingredient.stripcomments
		@@stripcomments
	end

	def Ingredient.stripcomments=(stripcomments)
		@@stripcomments = stripcomments
	end

	def Ingredient.compress
		@@compress
	end

	def Ingredient.compress=(compress)
		@@compress = compress
	end
	
	def Ingredient.keepallcomments
		@@keepallcomments
	end

	def Ingredient.keepallcomments=(keepallcomments)
		@@keepallcomments = keepallcomments
	end

	def to_s
		#"to_s_#{@type}".to_sym
		subtype = type.split('.')

		if(@type == "tline")
			return @line
		elsif(@raw == true)
			return @line
		end
			
		dirname = File.dirname(@filename)
		if(dirname =~ /\$TW_ROOT\//)
			c = dirname.index('$TW_ROOT')
			dirname = dirname[(c + 8)...dirname.length].strip
			dirname = Recipe.root + dirname
		end
		@filename = File.join(dirname,File.basename(@filename))

		if(subtype[0] == "list")
		elsif(subtype[0] == "tiddler")
			if(@filename =~ /\.tiddler/)
				return to_s_retiddle(subtype[0])
			elsif(@filename =~/\.html/)
				out = ''
				tiddlers = Splitter.extractTiddlers(@filename,URI.parse(@filename).fragment.split("%20"))
				tiddlers.each do |tiddler|
					out << tiddler.to_div
				end
				return out
			else
				return to_s_tiddler
			end
		elsif(subtype[0] == "shadow")
			if(@filename =~ /\.tiddler/)
				return to_s_retiddle(subtype[0])
			else
				# have a non-tidler in the shadow area, so output it raw
				return to_s_line(subtype[0])
			end
		elsif(subtype[0] == "plugin")
			return to_s_plugin
		else
			if(@filename =~ /\.tiddler/)
				# not in tiddler, shadow or plugin, so output raw content of tiddler
				return to_s_raw(subtype[0])
			else
				return to_s_line(subtype[0])
			end
		end
	end

protected
	def to_s_tiddler
		compress = false
		compress = true if @attributes == "-c"
		tiddler = Tiddler.new
		tiddler.load(@filename)
		tiddler.setAttributes(@attributes)
		return tiddler.to_div("tiddler",true,compress)
	end

	def to_s_plugin
		tiddler = Tiddler.new
		tiddler.load(@filename)
		tiddler.setAttributes(@attributes)
		return tiddler.to_plugin
	end

	def to_s_retiddle(subtype)
		tiddler = Tiddler.new
		tiddler.loadDiv(@filename)
		tiddler.setAttributes(@attributes)
		return tiddler.to_div(subtype)
	end

	def to_s_raw(subtype)
		tiddler = Tiddler.new
		tiddler.loadDiv(@filename)
		tiddler.setAttributes(@attributes)
		return tiddler.to_raw(subtype)
	end

	def to_s_line(subtype)
		open(@filename) do |infile|
			out = ""
			infile.each_line do |line|
				if(@@keepallcomments)
					out << line
				elsif(@@stripcomments)
					out << line unless(line.strip =~ /^\/\//)
				else
					out << line unless(line.strip =~ /^\/\/#/)
				end
			end
			if(@@compress=="f" && subtype == "js" && @filename !~ /\/Lingo/&& @filename !~ /\/locale/)
				out = Ingredient.rhino(out)
			end
			return out
		end
	end

public
	def Ingredient.rhino(input)
		inputfile = Tempfile.new('rhino')
		inputfile.print(input)
		inputfile.close
		outputfile = Tempfile.new('rhino')
		outputfile.close
		done = system("java -jar custom_rhino.jar -c #{inputfile.path} > #{outputfile.path} 2>&1")
		if(done)
			compressed = File.read(outputfile.path)
		else
			compressed = input
			STDERR.puts("Could not compress with custom_rhino.jar.")
			if(@@compress!="")
				STDERR.puts("Cooking failed.")
				exit
			end
		end
		return compressed
	end

	def Ingredient.packr(input)
		begin
			require 'packr'
			compressed = Packr.pack(input, :shrink_vars => true, :base62 => true)
		rescue LoadError
			STDERR.puts("Missing Ruby gem Packr - install using: gem install packr. Cooking failed")
			exit
		end
		return compressed
	end
end
