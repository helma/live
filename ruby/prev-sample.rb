#!/usr/bin/env ruby
require 'json'
require 'ruby-osc'

dir = File.expand_path(File.read(File.join(File.dirname(__FILE__),"..",".current","dir")).chomp)
scenes_file = File.join dir, "scenes.json"
scenes = JSON.parse(File.read(scenes_file))
cur_track = File.read(File.join(File.dirname(__FILE__),"..",".current","track")).chomp.to_i
t = scenes.collect{|s| s[cur_track]}.compact
nr = File.read(File.join(File.dirname(__FILE__),"..",".current",cur_track.to_s)).chomp.to_i
nr = (nr -1) % t.size
next_sample = t[nr]
p nr, next_sample
if next_sample then
  client = OSC::Client.new 9669
  client.send OSC::Message.new("/#{cur_track}/read" ,next_sample)
  File.open(File.join(File.dirname(__FILE__),"..",".current",cur_track.to_s),"w+"){|file| file.puts nr}
end
puts `#{File.join(File.dirname(__FILE__),"status.rb")}`
