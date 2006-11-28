require 'cgi'
require 'tiddlywiki'

class Ingredient
  @@hashid = false
  
  def initialize(filename, type, attributes=nil)
    @filename = filename
    @type = type
    if(File.exists?(filename + ".meta"))
      File.open(filename+ ".meta") do |file|
        file.each_line {|line| attributes.unshift(line.strip) }
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
        infile.each_line {|line| contents << line } 
        id = nil
        id = Tiddlywiki.hashid(contents, File.expand_path(@filename)) if @@hashid
        Tiddlywiki.tiddle(@title, @author, modified(infile), created(infile), @tags, contents, id)
      end
    end
    
    def to_s_retiddle
      File.open(@filename) do |infile|
        contents = ""
        infile.each_line do |line|
          tiddler = Tiddlywiki.untiddle(line)
          id = nil
          id = Tiddlywiki.hashid(tiddler["contents"], File.expand_path(@filename)) if @@hashid
          contents << Tiddlywiki.tiddle(tiddler["title"] ||= @title,
                                        tiddler["modifier"],
                                        tiddler["modified"],
                                        tiddler["created"],
                                        tiddler["tags"] ||= "",
                                        tiddler["contents"] ||= "",
                                        id)
        end
        return contents
      end
    end
    
    def to_s_line
      File.open(@filename, 'r').readlines.join
    end
    
    def parseAttributes(attributes)
      for i in 0...attributes.length
        enum = attributes[i].split(':')
        case enum[0]
          when "title"
            @title = enum[1]
          when "tiddler"
            @title = enum[1]
          when "tags"
            @tags = enum[1]
          when "author"
            @author = enum[1]
          when "modifier"
            @author = enum[1]
          when "tiddle"
            @tiddle = true
          when "modified"
            @modified = enum[1]
          when "created"
            @created = enum[1]
          else
            puts "Unknown attribute: " + enum[0] != nil ? enum[0] : "" + "=" + enum[1] != nil ? enum[1] : "" 
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
