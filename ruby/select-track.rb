#!/usr/bin/env ruby
require 'json'

path = File.join(File.dirname(__FILE__),"..",".current","track")
File.open(path,"w+"){|file| file.puts ARGV[0]}
puts `#{File.join(File.dirname(__FILE__),"status.rb")}`
