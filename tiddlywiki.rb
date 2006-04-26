require 'digest/sha1'

class Tiddlywiki
  def Tiddlywiki.tiddle(title, author, modified, created, tags, contents, hashid=nil)
    out = "<div tiddler=\"" + title
    out += "\" id=\"" + hashid if hashid
    out += "\" modifier=\"" + author
    out += "\" modified=\"" + modified
    out += "\" created=\"" + created
    out += "\" tags=\"" + tags + "\">"
    contents.each {|line| out << CGI::escapeHTML(line).sub("\n", "\\n") }
    out +="</div>\n"
  end
  
  def Tiddlywiki.untiddle(tiddler)
    rethash = Hash.new()
    rethash["title"] = Tiddlywiki.getTiddlerAttribute(tiddler, "tiddler")
    rethash["modifier"] = Tiddlywiki.getTiddlerAttribute(tiddler, "modifier")
    rethash["modified"] = Tiddlywiki.getTiddlerAttribute(tiddler, "modified")
    rethash["created"] = Tiddlywiki.getTiddlerAttribute(tiddler, "created")
    rethash["tags"] = Tiddlywiki.getTiddlerAttribute(tiddler, "tags")
    content = CGI::unescapeHTML(tiddler.sub("</div>", "").sub(/<div.*?>/, ""))
    while content =~ /\\n/ do
      content = content.sub("\\n", "\n" )
    end
    rethash["contents"] = content
    return rethash
  end
  
  def Tiddlywiki.metadata(tiddler)
    if(tiddler.class == hash)
      tiddler = Tiddlywiki.untiddle(tiddler)
    end
    out = "title: " + tiddler["title"] + "\n"
    out << "modifier: " + tiddler["modifier"] + "\n"
    out << "modified: " + tiddler["modified"] + "\n"
    out << "created: " + tiddler["created"] + "\n"
    out << "tags: " + tiddler["tags"] + "\n"
  end
  
  def Tiddlywiki.hashid(contents, path)
    contenthash = Digest::SHA1.hexdigest(contents ||= "")
    pathhash = Digest::SHA1.hexdigest(path)
    return "0x" + pathhash.slice(0..9) + ".0x" + contenthash.slice(0..9)
  end
  
  protected
    def Tiddlywiki.getTiddlerAttribute(tiddler, attribute)
      exp = Regexp.new(Regexp.escape(attribute) + '="([^"]+)"')
      if(exp.match(tiddler))
        returnval = $1
      end
    end
end
