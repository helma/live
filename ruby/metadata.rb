#!/bin/env ruby
require 'json'
require_relative 'sample.rb'

dir = File.expand_path(File.read(File.join(File.dirname(__FILE__),"..",".current","dir")).chomp)
bpm = ARGV[0].match(/\d\d\d/).to_s.to_i
@samples = Dir["#{File.join(ARGV[0],'*[wav|WAV]')}"].collect{|f| Sample.from_file(f)}
p @samples.collect{|s| s.name}
