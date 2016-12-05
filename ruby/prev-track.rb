#!/usr/bin/env ruby
require 'json'

path = File.join(File.dirname(__FILE__),"..",".current","track")
track = (File.read(path).chomp.to_i - 1) % 4
File.open(path,"w+"){|file| file.puts track}
puts `#{File.join(File.dirname(__FILE__),"status.rb")}`
