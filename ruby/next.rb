#!/usr/bin/env ruby
require 'json'
require 'ruby-osc'

dir = File.expand_path(File.read(File.join(File.dirname(__FILE__),"..",".current","dir")).chomp)
scenes_file = File.join dir, "scenes.json"
scenes = JSON.parse(File.read(scenes_file))
cur_track = File.read(File.join(File.dirname(__FILE__),"..",".current","track")).chomp.to_i
current = File.read(File.join(File.dirname(__FILE__),"..",".current",cur_track.to_s)).chomp
t = scenes.collect{|s| s[cur_track]}
i = t.index current
client = OSC::Client.new 9669
p current
client.send OSC::Message.new("/#{i}/read" ,current)
File.open(File.join(File.dirname(__FILE__),"..",".current",cur_track.to_s),"w+"){|file| file.puts current}
puts `#{File.join(File.dirname(__FILE__),"status.rb")}`
