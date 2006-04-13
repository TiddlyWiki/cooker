require 'cgi'

class Ingredient
  def initialize(filename, type, attributes=nil)
    @filename = filename
    @type = type
    parseAttributes(attributes) if attributes
  end
  
  def filename
    @filename
  end
  
  def type
    @type
  end
  
  def title
    @title ||= @filename
  end
  
  def tags
    @tags ||= ""
  end
  
  def author
    @author ||= "Cooker"
  end
  
  def to_s
    #"to_s_#{@type}".to_sym
    case type
      when "list"
      when "tiddler"
        return to_s_tiddler
      else
        return File.open(@filename, 'r').readlines.join
    end
  end
  
  protected
    def to_s_tiddler
      File.open(@filename) do |infile|
        out = "<div tiddler=\"" + @title + "\" modifier=\"" + @author
        out += "\" modified=\"" + infile.ctime.strftime("%Y%m%d%M%S")
        out += "\" created=\"" + infile.mtime.strftime("%Y%m%d%M%S")
        out += "\" tags=\"" + @tags + "\">"
        infile.each_line {|line| out << CGI::escapeHTML(line).sub("\n", "\\n") } 
        out +="</div>\n"
      end
    end
    
    def parseAttributes(attributes)
      for i in 0...attributes.length
        enum = attributes[i].split('=')
        case enum[0]
          when "title"
            @title = enum[1]
          when "tags"
            @tags = enum[1]
          when "author"
            @author = enum[1]
          else
            puts "Unknown attribute: " + enum[0] + "=" + enum[1]
        end
      end
    end
end
