#!/usr/bin/env ruby
require 'json'

dir = File.expand_path(ARGV[0])
scenes_file = File.join ARGV[0], "scenes.json"

if File.exists? scenes_file
  date = `date +%Y-%m-%dT%H:%M:%S`.chomp
  `cp #{scenes_file} #{scenes_file}.#{date}`
end

scenes ||= []
drums = Dir[File.join(dir,"drums","*[wav|WAV]")].shuffle
(0..drums.size-1).step(2) do |n|
  [0,1].each do |j|
    scenes[n/2] ||= []
    scenes[n/2][j] = drums[n+j] if drums[n+j]
  end
end
music = Dir[File.join(dir,"music","*[wav|WAV]")].shuffle
(0..music.size-1).step(2) do |n|
  [0,1].each do |j|
    scenes[n/2] ||= []
    scenes[n/2][j+2] = music[n+j] if music[n+j]
  end
end
files = scenes.collect{|s| s.collect{|p| File.basename(p) if p}}
File.open(scenes_file,"w+"){|f| f.puts JSON.pretty_generate scenes}
