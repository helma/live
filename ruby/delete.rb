#!/usr/bin/env ruby
require 'json'

dir = File.expand_path(File.read(File.join(File.dirname(__FILE__),"..",".current","dir")).chomp)
scenes_file = File.join dir, "scenes.json"
scenes = JSON.parse(File.read(scenes_file))
cur_track = File.read(File.join(File.dirname(__FILE__),"..",".current","track")).chomp.to_i
t = scenes.collect{|s| s[cur_track]}.compact
nr = File.read(File.join(File.dirname(__FILE__),"..",".current",cur_track.to_s)).chomp.to_i
sample = t[nr]
`mkdir -p #{dir}/delete`
`mv #{sample} #{dir}/delete/`
#TODO adjust scenes
