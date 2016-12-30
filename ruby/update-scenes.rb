#!/usr/bin/env ruby
require 'json'

dir = File.expand_path(File.read(File.join(File.dirname(__FILE__),"..",".current","dir")).chomp)
scenes_file = File.join dir, "scenes.json"
#dir = File.expand_path(ARGV[0])
#scenes_file = File.join ARGV[0], "scenes.json"

if File.exists? scenes_file
  date = `date +%Y-%m-%dT%H:%M:%S`.chomp
  `cp #{scenes_file} #{scenes_file}.#{date}`
end

scenes = JSON.parse(File.read(scenes_file))
drums = Dir[File.join(dir,"drums","*[wav|WAV]")].shuffle
music = Dir[File.join(dir,"music","*[wav|WAV]")].shuffle
t0 = scenes.collect{|s| s[0]} | drums
t1 = scenes.collect{|s| s[1]} | drums
t2 = scenes.collect{|s| s[2]} | music
t3 = scenes.collect{|s| s[3]} | music
size = [t0.size,t1.size,t2.size,t3.size].max
(0..size-1).each do |i|
  scenes[i] = [t0[i],t1[i],t2[i],t3[i]]
end
File.open(scenes_file,"w+"){|f| f.puts JSON.pretty_generate scenes}
