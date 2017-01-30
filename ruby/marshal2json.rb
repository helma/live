#!/bin/env ruby
require 'json'
require_relative 'sample.rb'

audio = Dir[File.join(ARGV[0],"**","*.{wav,WAV,aif,aiff,AIF,AIFF}")]
samples = audio.collect{|f| Sample.from_file f}

samples.each do |s|
  ext = File.extname s.file
  mfcc_file = s.file.sub ext, ".mfcc"
  File.open(mfcc_file,"w+"){|f| Marshal.dump s.mfcc, f}
  onsets_file = s.file.sub ext, ".onsets"
  File.open(onsets_file,"w+"){|f| f.puts s.onsets.to_json}
  json_file = s.file.sub ext, ".json"
  File.open(json_file,"w+") do |f|
    meta = {
      :bpm => s.bpm,
      :tags => s.tags,
      :bars => s.bars,
      :max_amplitude => s.max_amplitude
    }
    f.puts meta.to_json
  end
end
