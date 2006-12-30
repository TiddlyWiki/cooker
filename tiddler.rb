# tiddler.rb
require 'cgi'

class Tiddler
	def initialize
		@usePre = false
		@optimizeAttributeStorage = false
		@extendedAttributes = Hash.new
	end

	attr_accessor :usePre
	attr_reader :title
	attr_reader :modifier
	attr_reader :created
	attr_reader :modified
	attr_reader :tags
	attr_reader :contents
	attr_accessor :optimizeAttributeStorage

	def extendedAttribute(name)
		return @extendedAttributes[name]
	end

	def set(title, modifier, created, modified, tags, extendedAttributes, contents)
		@title = title.strip
		@modifier = modifier.strip
		@created = created.strip
		@modified = modified.strip
		@tags = tags.strip
		@extendedAttributes = extendedAttributes
		@contents = contents
	end

	def read_div(file, line)
		divText = ""
		if(line =~ /<div tiddler=.*<\/div>/)
			@usePre = false
			divText = line
			line = file.gets
		elsif(line =~ /<div title=.*/)
			@usePre = true
			begin
				divText << line
				line = file.gets
			end while line && line !~ /<div ti/ && line !~ /<\/div>/
		end
		from_div(divText)
		return line
	end

	def from_div(divText)
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
		if(@usePre)
			@contents = divText.sub(/<div.*?>\n*<pre>/, "").sub(/<\/pre>\n*/, "").sub(/<\/div>\n*/, "")
		else
			@contents = divText.sub(/<div.*?>/, "").sub(/<\/div>\n*/, "").gsub("\\n", "\n").gsub("\\s", "\\")
		end
		@contents = CGI::unescapeHTML(@contents.gsub("\r", ""))
	end

	def to_div
		out = "<div "
		out << (@usePre ? "title=\"#{@title}\"" : "tiddler=\"#{@title}\"")
		out << " modifier=\"#{@modifier}\"" if(@modifier)
		if(@usePre || @optimizeAttributeStorage)
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
			lines = (CGI::escapeHTML(@contents).gsub("\r", "")).split("\n")
			last = lines.pop
			lines.each { |line| out << line << "\n" }
			out << last if(last)
			out << "</pre>\n"
		else
			@contents.each { |line| out << CGI::escapeHTML(line).gsub("\\", "\\s").sub("\n", "\\n").sub("\r", "") }
		end
		out << "</div>\n"
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

protected
	def parseAttribute(divText, attribute)
		exp = Regexp.new(Regexp.escape(attribute) + '="([^"]+)"')
		if(exp.match(divText))
			returnval = $1
		end
	end

	def parseExtendedAttributes(divText)
		return if(!divText)
		standardAttributes = [ "tiddler", "title", "modifier", "modified", "created", "tags" ]
		match = /<div (.*)>/.match(divText)
		return if(!match)
		attributes = match[1].to_s.split(/([^\s\t]*)="([^"]*)"/)
		0.step(attributes.size - 1, 3) do |i|
			key, value = attributes[i + 1], attributes[i + 2]
			@extendedAttributes.store(key, value) if(key && !standardAttributes.include?(key))
		end
	end
end
