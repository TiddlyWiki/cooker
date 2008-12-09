#! /usr/bin/env ruby

#
# generates .meta file from plugin
#
# Usage:
#  metaFileGenerator.rb file [author]
#

require 'ftools'

if(ARGV.empty?)
	$stderr.puts "no arguments specified"
	exit
end

file = ARGV[0]
author = ARGV[1] || "N/A"

unless(File.extname(file) == ".js" && File.exists?(file))
	$stderr.puts "#{file} does not exist or is not a js file"
	exit
end

title = File.basename(file,".js")
meta = "#{file}.meta"
created = Time.now.strftime("%Y%m%d%H%M")
modified = created
modifier = author

class String
	def to_file(file_name) #:nodoc:
		File.open(file_name,"w") { |f| f << self }
	end
end

def updateMeta(meta)
	File.open(meta, 'r+') do |f|
		out = ""
		f.each do |line|
		    if(line =~/^modified/)
		    	out << "modified: #{Time.now.strftime("%Y%m%d%H%M")}\n"
		    else
		    	out << line
		    end
		end
		f.pos = 0
		f.print out
		f.truncate(f.pos)
	end
end

template = <<EOF
title: #{title}
modifier: #{modifier}
created: #{created}
modified: #{modified}
tags: systemConfig excludeLists excludeSearch
EOF

if(File.exists?(meta))
	updateMeta(meta)
else
	template.to_file(meta)
end
