#!/usr/bin/env ruby
require 'yaml'
require 'json'
require_relative 'sample.rb'

paths = ARGV.collect{|d| Dir["#{File.join d, "**", "*.{wav,WAV,aif,aiff,AIF,AIFF}"}"]}.flatten
paths.each do |f|
  s = Sample.from_file(f)
  `mv -iv #{s.file} /home/ch/music/loops/fix/cut/132/` unless [2.0,4.0,6.0,8.0,12.0,16.0,24.0,32.0,48.0,64.0,96.0,112.0,128.0].include? s.bars.round#(2)
  #puts   s.file + " "+ s.bars.to_s unless [2.0,4.0,6.0,8.0,12.0,16.0,24.0,32.0,48.0,64.0,96.0,128.0].include? s.bars.round#(2)
end
