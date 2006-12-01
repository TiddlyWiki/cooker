require 'cgi'

class Tiddler
	def initialize
		@usePre = false
	end
	attr_accessor :usePre
	attr_reader :title
	attr_reader :modifier
	attr_reader :created
	attr_reader :modified
	attr_reader :tags
	attr_reader :contents

	def attribute(name)
		return @attributes[name]
	end

	def set(title, modifier, created, modified, tags, attributes, contents)
		@title = title.strip
		@modifier = modifier.strip
		@created = created.strip
		@modified = modified.strip
		@tags = tags.strip
		@attributes = attributes
		@contents = contents
	end

	def read_div(file,line)
		if line =~ /<div tiddler=.*<\/div>/
			this.from_div(line)
		elsif(line =~ /<div title=.*/)
			text = line
			while line !~ /<div ti/
				line = file.gets
				text += line
			end
			this.from_div(text)
		end
		line = file.gets
	end

	def from_div(divText)
		@usePre = false
		@title = parseAttribute(divText, "tiddler")
		@modifier = parseAttribute(divText, "modifier")
		@created = parseAttribute(divText, "created")
		@modified = parseAttribute(divText, "modified")
		@tags = parseAttribute(divText, "tags")
		parseExtendedAttributes(divText)
		if(@usePre)
			@contents = CGI::unescapeHTML(divText.sub(/<div.*?><pre>/,"").sub("</pre></div>","").sub("\r",""))
		else
			@contents = CGI::unescapeHTML(divText.sub(/<div.*?>/,"").sub("</div>","").gsub("\\n","\n").gsub("\\s","\\").sub("\r",""))
		end
	end
	
	def to_div
		@usePre = false
		out = "<div "
		out << (@usePre ? "title=\"#{@title}\"" : "tiddler=\"#{@title}\"")
		out << " modifier=\"#{@modifier}\"" if @modifier
		out << " created=\"#{@created}\"" if @created
		out << " modified=\"#{@modified}\"" if @modified && @modified != @created
		out << " tags=\"#{@tags}\"" if @tags
		@attributes.each_pair { |key, value| out << " #{key}=\"#{value}\"" } if @attributes
		out << ">"
		if(@usePre)
			out << "\n<pre>"
			@contents.each { |line| out << CGI::escapeHTML(line).sub("\r", "") }
			out << "</pre>\n</div>\n"
		else
			@contents.each { |line| out << CGI::escapeHTML(line).gsub("\\", "\\s").sub("\n", "\\n").sub("\r", "") }
			out <<"</div>"
		end
	end
	
	def to_meta
		out = "title: #{@title}\n"
		out << "modifier: #{@modifier}\n"
		out << "created: #{@created}\n"
		out << "modified: #{@modified}\n"
		out << "tags: #{@tags}\n"
		@attributes.each_pair do |key, value|
			out << "#{key}: #{value}\n"
		end
		return out
	end
	
protected
	def parseAttribute(divText, attribute)
		exp = Regexp.new(Regexp.escape(attribute) + '="([^"]+)"')
		if(exp.match(divText))
			returnval = $1
		end
	end

	def parseExtendedAttributes(divText)
		attributesRE = Regexp.new('<div (.*)>.*</div>')
		attributeRE = Regexp.new('([^\s\t]*)="([^"]*)"')
		attributes = attributesRE.match(divText)[1].to_s.split(attributeRE)
		0.step(attributes.size - 1, 3) do |i|
			key, value = attributes[i + 1], attributes[i + 2]
			@attributes.store(key, value) unless key =~ /\Atiddler\Z|\Atitle\Z|\Amodifier\Z|\Aauthor\Z|\Amodified\Z|\Acreated\Z|\Atags\Z/
		end
	end
end
