require 'tiddlywiki'

class Splitter
  def initialize(filename)
    @numprocessed = 0
    @filename = filename
    dirset = false
    dirnum = 0;
    while !dirset do
      if !File.exists?(@filename + "." + dirnum.to_s)
        @dirname = @filename + "." + dirnum.to_s
        Dir.mkdir(@dirname)
        dirset = true
      else
        dirnum += 1
      end
    end
  end
  
  def split
    File.open(@filename) do |file|
      start = false
      File.open(@dirname + "/split.recipe", File::CREAT|File::TRUNC|File::RDWR, 0644) do |recipe|
        file.each_line do |line|
          start = true if line =~ /<div id="storeArea">/
          extractTiddler(line.sub(/.*<div id="storeArea">/, "").strip, recipe) if start
        end
      end
    end
    if @numprocessed == 0
      puts @filename + " Does not contain any tiddlers"
    else
      puts "\n" + @filename + " processed, " + @numprocessed.to_s + " tiddlers written to " + @dirname + "/"
    end
  end
  
  def extractTiddler(line, recipefile)
    @numprocessed += 1
    if line =~ /<div tiddler=.*<\/div>/
      tiddler = Tiddlywiki.untiddle(line)
      newfilename = ""
      if(tiddler["tags"] =~ /systemConfig/)
        newfilename = tiddler["title"].to_s + ".js"
        while newfilename =~ /[\/:?#\* ]/ do
          newfilename = newfilename.sub(/[\/:?#\* ]/, "_")
        end
        File.open(@dirname + "/" + newfilename, File::CREAT|File::TRUNC|File::RDWR, 0644) do |out|
          out << tiddler["contents"]
        end
        File.open(@dirname + "/" + newfilename + ".meta", File::CREAT|File::TRUNC|File::RDWR, 0644) do |out|
          out << Tiddlywiki.metadata(tiddler)
        end
      else
        newfilename = tiddler["title"].to_s + ".tiddler"
        while newfilename =~ /[\/:\?#\* ]/ do
          newfilename = newfilename.sub(/[\/:\?#\* ]/, "_")
        end
        File.open(@dirname + "/" + newfilename, File::CREAT|File::TRUNC|File::RDWR, 0644) do |out|
          out << line
        end
      end
      recipefile << "tiddler: " + newfilename + "\n"
      puts "Writing: " + tiddler["title"].to_s
    end
  end
end