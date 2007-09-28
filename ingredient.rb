# ingredient.rb

# Copyright (c) UnaMesa Association 2004-2007
# License: Creative Commons Attribution ShareAlike 3.0 License http://creativecommons.org/licenses/by-sa/3.0/

require 'cgi'
require 'tiddler'

class Ingredient

	def initialize(filename, type, attributes=nil)
		@attributes = attributes
		@filename = filename
		@type = type
	end

	def filename
		@filename
	end

	def type
		@type
	end

	def Ingredient.stripcomments
		@@stripcomments
	end

	def Ingredient.stripcomments=(stripcomments)
		@@stripcomments = stripcomments
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
			if(@filename =~ /\.tiddler/)
				return to_s_raw(subtype[0])
			else
				return to_s_line
			end
		end
	end

protected
	def to_s_tiddler
		tiddler = Tiddler.new
		tiddler.load(@filename)
		tiddler.setAttributes(@attributes)
		return tiddler.to_div
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

	def to_s_line
		File.open(@filename) do |infile|
			out = ""
			infile.each_line do |line|
				if(@@stripcomments)
					out << line unless(line.strip =~ /^\/\//)
				else
					out << line unless(line.strip =~ /^\/\/#/)
				end
			end
			return out
		end
	end

end
