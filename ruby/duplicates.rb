#!/usr/bin/env ruby
require 'yaml'
require 'json'

paths = ARGV.collect{|d| Dir["#{File.join d, "**", "*.{wav,WAV,aif,aiff,AIF,AIFF}"}"]}.flatten
files = {}
paths.each do |p|
  name = File.basename p
  files[name] ||= []
  files[name] << p
end
files.select!{|f,paths| paths.size > 1}
#files.select!{|f,paths| paths.size == 1}
#puts files.to_yaml
#puts JSON.pretty_generate files
puts files.collect{|f,p| p.join "\n"}.join "\n"
