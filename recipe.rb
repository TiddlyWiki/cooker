require 'ingredient'

class Recipe
  def initialize(filename)
    @filename = filename
    @ingredients = Array.new
    @addons = Hash.new
    File.open(filename) do |file|
      file.each_line {|line| genIngredient(File.dirname(filename), line) }
    end
  end
  
  def cook
    puts "Creating file: " + outfilename
    File.open(outfilename, File::CREAT|File::TRUNC|File::RDWR, 0644) do |out|
      @ingredients.each do |ingredient|
        if ingredient.type == "list"
          if @addons.has_key?(ingredient.filename)
            @addons.fetch(ingredient.filename).each{|ingredient| writeToDish(out, ingredient)}
          end
        else
          writeToDish(out, ingredient)
        end
      end
    end
  end
  
  protected
    def outfilename
      @filename.sub(".recipe", "")
    end
    
    def ingredients
      @ingredients
    end
    
    def addons
      @addons
    end
    
    def genIngredient(dirname, line)
      if line =~ /@.*@/
        @ingredients << Ingredient.new(line.strip.slice(1..-2), "list")
      elsif line =~ /recipe\:/
        loadSubrecipe(dirname + "/" + line.sub(/recipe\:/, "").strip)
      elsif line =~ /\:/
        entry = line.split(':')
        key = entry.shift.strip
        file = dirname + "/" + entry.shift.strip
        addAddOns(key, file, entry)
        loadSubrecipe(file + ".deps") if File.exists?(file + ".deps")
      else
        file = dirname + "/" + line.chomp
        @ingredients << Ingredient.new(file, "line")
        loadSubrecipe(file + ".deps") if File.exists?(file + ".deps")
      end
    end
    
    def loadSubrecipe(subrecipename)
        recipe = Recipe.new(subrecipename)
        @ingredients = @ingredients + recipe.ingredients
        recipe.addons.each{|key, value| addAddOns(key, value)}
    end
    
    def addAddOns(key, value, attributes=nil)
        addonarray = @addons.fetch(key, Array.new)
        if value.class == Array
          addonarray = addonarray + value
        elsif value.class == Ingredient
          addonarray.push(value)
        else
          ingredient = Ingredient.new(value, key, attributes)
          addonarray.push(ingredient)
        end
        @addons.store(key, addonarray)
    end
    
    def writeToDish(outfile, ingredient)
      puts "Writing: " + ingredient.filename
      outfile << ingredient
    end
end
