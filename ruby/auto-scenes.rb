#!/usr/bin/env ruby
require 'json'
require_relative 'sample.rb'

dir = ARGV[0]
bpm = File.basename(dir).to_f
#scenes_file = File.join dir, "scenes.json"
#dir = File.expand_path(ARGV[0])
#scenes_file = File.join ARGV[0], "scenes.json"

#if File.exists? scenes_file
  #date = `date +%Y-%m-%dT%H:%M:%S`.chomp
  #`cp #{scenes_file} #{scenes_file}.#{date}`
#end

#scenes = JSON.parse(File.read(scenes_file))
drums = `ls -t1 #{File.join(dir,"drums","*wav")}`.split("\n").collect{|f| Sample.new f}
#drums = Dir[File.join(dir,"drums","*[wav|WAV]")].collect{|f| Sample.new f, bpm}.shuffle
long_drums = drums.select{|f| f.bars.round > 16}#[0..7].shuffle
short_drums = drums.select{|f| f.bars.round <= 16}#[0..7].shuffle
#music = Dir[File.join(dir,"music","*[wav|WAV]")].collect{|f| Sample.new f, bpm}.shuffle
music = `ls -t1 #{File.join(dir,"music","*wav")}`.split("\n").collect{|f| Sample.new f}
long_music = music.select{|f| f.bars.round > 16}#[0..7].shuffle
short_music = music.select{|f| f.bars.round <= 16}#[0..7].shuffle
p long_drums.size, short_drums.size, long_music.size, short_music.size
short_music[7] = music.last
scenes = []
(0..7).each do |i|
  scenes << [long_drums[i].file,short_drums[i].file,long_music[i].file,short_music[i].file]
end
#puts JSON.pretty_generate scenes
#File.open(scenes_file,"w+"){|f| f.puts JSON.pretty_generate scenes}
#t0 = scenes.collect{|s| s[0]} | drums
#t1 = scenes.collect{|s| s[1]} | drums
#t2 = scenes.collect{|s| s[2]} | music
#t3 = scenes.collect{|s| s[3]} | music
#size = [t0.size,t1.size,t2.size,t3.size].max
#(0..size-1).each do |i|
  #scenes[i] = [t0[i],t1[i],t2[i],t3[i]]
#end
#File.open(scenes_file,"w+"){|f| f.puts JSON.pretty_generate scenes}
