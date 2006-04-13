#!/usr/bin/env ruby
require 'recipe'

recipe = Recipe.new(ARGV[0])
recipe.cook
