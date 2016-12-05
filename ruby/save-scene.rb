#!/usr/bin/env ruby
require 'json'

dir = File.expand_path(File.read(File.join(File.dirname(__FILE__),"..",".current","dir")).chomp)
scenes_file = File.join dir, "scenes.json"
date = `date +%Y-%m-%dT%H:%M:%S`.chomp
`cp #{scenes_file} #{scenes_file}.#{date}`

scenes = JSON.parse(File.read(scenes_file))
current = (0..3).collect do |t|
  i = File.read(File.join(File.dirname(__FILE__),"..",".current",t.to_s)).chomp.to_i
  scenes[i][t]
end
scenes = scenes.insert ARGV[0].to_i-1, current
File.open(scenes_file,"w+"){|f| f.puts JSON.pretty_generate scenes}
puts `#{File.join(File.dirname(__FILE__),"status.rb")}`
