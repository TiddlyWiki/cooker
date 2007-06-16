# recipe.rb

require 'ingredient'
require "ftools"

class Recipe
	def initialize(filename, outdir=nil, isTemplate=false)
		@filename = filename
		@outdir = outdir ||= ""
		@ingredients = Array.new
		@addons = Hash.new
		File.open(filename) do |file|
			file.each_line { |line| genIngredient(File.dirname(filename), line, isTemplate) }
		end
	end

	def cook
		puts "Creating file: " + outfilename
		if(@ingredients.length > 0)
			File.open(outfilename, File::CREAT|File::TRUNC|File::RDWR, 0644) do |out|
				@ingredients.each do |ingredient|
					if(ingredient.type == "list")
						if(@addons.has_key?(ingredient.filename))
							@addons.fetch(ingredient.filename).each{ |ingredient| writeToDish(out, ingredient) }
						end
					else
						writeToDish(out, ingredient)
					end
				end
			end
		end
		@addons.fetch("copy", Array.new).each { |ingredient| copyFile(ingredient) }
	end

protected
	def outdir
		@outdir.empty? ? "" : File.join(@outdir, "")
	end

	def outfilename
		outdir + File.basename(@filename.sub(".recipe", ""))
	end

	def ingredients
		@ingredients
	end

	def addons
		@addons
	end

	def genIngredient(dirname, line, isTemplate)
		if(isTemplate)
			if(line =~ /<!--@@.*@@-->/)
				@ingredients << Ingredient.new(line.strip.slice(6..-6), "list")
			else
				@ingredients << Ingredient.new(line, "tline")
			end
		else
			if(line.strip == "")
				return
			end
			if(line =~ /@.*@/)
				@ingredients << Ingredient.new(line.strip.slice(1..-2), "list")
			elsif(line =~ /template\:/)
				loadSubrecipe(File.join(dirname, line.sub(/template\:/, "").strip),true)
			elsif(line =~ /recipe\:/)
				loadSubrecipe(File.join(dirname, line.sub(/recipe\:/, "").strip),false)
			elsif(line =~ /\:/)
				entry = line.split(':')
				key = entry.shift.strip
				file = File.join(dirname, entry.shift.strip)
				addAddOns(key, file, entry)
				loadSubrecipe(file + ".deps",false) if File.exists?(file + ".deps")
			else
				file = File.join(dirname, line.chomp)
				@ingredients << Ingredient.new(file, "line")
				loadSubrecipe(file + ".deps",false) if(File.exists?(file + ".deps"))
			end
		end
	end

	def loadSubrecipe(subrecipename, isTemplate)
		recipe = Recipe.new(subrecipename, @outdir, isTemplate)
		@ingredients = @ingredients + recipe.ingredients
		recipe.addons.each { |key, value| addAddOns(key, value) }
	end

	def addAddOns(key, value, attributes=nil)
		addonarray = @addons.fetch(key, Array.new)
		if(value.class == Array)
			addonarray = addonarray + value
		elsif(value.class == Ingredient)
			addonarray.push(value)
		else
			ingredient = Ingredient.new(value, key, attributes)
			addonarray.push(ingredient)
		end
		@addons.store(key, addonarray)
	end

	def writeToDish(outfile, ingredient)
		if(ingredient.type != "tline")
			puts "Writing: " + ingredient.filename
		end
		outfile << ingredient
	end

	def copyFile(ingredient)
		puts "Copying: " + ingredient.filename
		File.copy(ingredient.filename, File.join(outdir, File.basename(ingredient.filename)))
	end
end
