#!/usr/bin/env ruby
#require_relative 'setup.rb'
require 'json'
require_relative 'loop.rb'
require_relative 'sample.rb'

@scenes = File.open(ARGV[0]){|f| Marshal.load(f)}
@pool = [[],[],[],[]]

Dir[File.join(ARGV[1],"**","*wav")].collect{|f| Sample.from_file File.expand_path(f)}.each do |s|
  l = Loop.from_sample(s)
  unless @scenes.flatten.compact.collect{|f| f.file}.include? l.file
    if s.tags.include? "drums" and s.bars.round > 16
      @pool[0] << l
    elsif s.tags.include? "drums" and s.bars.round <= 16
      @pool[1] << l
    elsif s.tags.include? "music" and s.bars.round > 16
      @pool[2] << l
    elsif s.tags.include? "music" and s.bars.round <= 16
      @pool[3] << l
    end
  end
end

@pool.each do |s|
  p s.collect{|l| l.file }
end
