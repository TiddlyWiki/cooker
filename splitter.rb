class Splitter
  def initialize(filename)
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
      file.each_line do |line|
        start = true if line =~ /<div id="storeArea">/
        extractTiddler(line.sub(/<div id="storeArea">/, "").strip) if start
      end
    end
  end
  
  def extractTiddler(line)
    if line =~ /<div tiddler=.*<\/div>/
      line =~ /tiddler="([^"]+)"/
      if $1
        title = $1
        title = title.sub(/[\/: ]/, "_")
        File.open(@dirname + "/" + title + ".tiddler", File::CREAT|File::TRUNC|File::RDWR, 0644) do |out|
          out << line
        end
      end
    end
  end
end