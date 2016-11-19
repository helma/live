#!/usr/bin/env ruby
require 'json'
require 'ruby-osc'

dir = File.expand_path(File.read(File.join(File.dirname(__FILE__),"..",".current","dir")).chomp)
scenes_file = File.join dir, "scenes.json"
client = OSC::Client.new 9669
scenes = JSON.parse(File.read(scenes_file))[ARGV[0].to_i]
scenes.each_with_index do |f,i|
  client.send OSC::Message.new("/#{i}/read" ,f)
end
scenes.each_with_index do |f,i|
  path = File.join(File.dirname(__FILE__),"..",".current",i.to_s)
  File.open(path,"w+"){|file| file.puts f}
end
puts `#{File.join(File.dirname(__FILE__),"status.rb")}`
