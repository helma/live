#!/usr/bin/env ruby
require 'json'
require 'ruby-osc'

dir = File.expand_path(File.read(File.join(File.dirname(__FILE__),"..",".current","dir")).chomp)
scenes_file = File.join dir, "scenes.json"
client = OSC::Client.new 9669
files = JSON.parse(File.read(scenes_file))[ARGV[0].to_i]
#puts JSON.pretty_generate files
files.reverse.each_with_index do |f,i|
  p i
  client.send OSC::Message.new("/#{i}/read" ,f)
  #`oscsend localhost 9669 /#{i}/read s "#{f}"`
  p "oscsend localhost 9669 /#{i}/read s '#{f}'"
end
