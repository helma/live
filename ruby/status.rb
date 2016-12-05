#!/usr/bin/env ruby
require 'json'
require 'colorize'

dir = File.expand_path(File.read(File.join(File.dirname(__FILE__),"..",".current","dir")).chomp)
scenes_file = File.join dir, "scenes.json"
scenes = JSON.parse(File.read(scenes_file))
out = []
cur_track = File.read(File.join(File.dirname(__FILE__),"..",".current","track")).chomp.to_i
scenes.each_with_index do |s,i|
  str = i.to_s.rjust(2)+" "
  (0..3).each do |j|
    if s[j] 
      name = File.basename(s[j])
      path = File.join(File.dirname(__FILE__),"..",".current",j.to_s)
      name = name.ljust(30) 
      name = name.yellow if j == cur_track
      name = name.green if i == File.read(path).chomp.to_i
      str += name#.center(30) 
    else
      str += " "*30
    end
  end
  str += " "+i.to_s.rjust(2)
  out << str
end
puts out.join "\n"
