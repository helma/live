#!/usr/bin/env ruby
require 'json'

dir = File.expand_path(File.read(File.join(File.dirname(__FILE__),"..",".current","dir")).chomp)
scenes_file = File.join dir, "scenes.json"

if File.exists? scenes_file
  date = `date +%Y-%m-%dT%H:%M:%S`.chomp
  `cp #{scenes_file} #{scenes_file}.#{date}`
end

scenes = JSON.parse(File.read(scenes_file))
t0 = scenes.collect{|s| s[0] if s[0] and File.exists?(s[0])}.compact.uniq
t1 = scenes.collect{|s| s[1] if s[1] and File.exists?(s[1])}.compact.uniq
t2 = scenes.collect{|s| s[2] if s[2] and File.exists?(s[2])}.compact.uniq
t3 = scenes.collect{|s| s[3] if s[3] and File.exists?(s[3])}.compact.uniq
size = [t0.size,t1.size,t2.size,t3.size].max
(0..size-1).each do |i|
  scenes[i] = [t0[i],t1[i],t2[i],t3[i]]
end
#puts JSON.pretty_generate scenes
File.open(scenes_file,"w+"){|f| f.puts JSON.pretty_generate scenes}
