#!/bin/env ruby
require 'fileutils'
require 'matrix'
require 'digest/md5'
require 'yaml'

class Sample 

  attr_accessor :file, :bpm, :mfcc, :dir, :channels, :samplerate, :seconds, :frames, :max_amplitude, :slices, :stat, :bpm, :tags

  def initialize file
    metadata = file.sub "wav","meta"
    @file = file
    @dir = File.dirname(@file)
    @stat = Hash[`sox "#{@file}" -n stat 2>&1|sed '/Try/,$d'`.split("\n")[0..14].collect{|l| l.split(":").collect{|i| i.strip}}]
    @seconds = @stat["Length (seconds)"].to_f
    @max_amplitude = [@stat["Maximum amplitude"].to_f,stat["Minimum amplitude"].to_f.abs].max
    # remove first column with timestamps
    # remove second column with energy
    @mfcc = Vector.elements(`aubiomfcc "#{@file}"`.split("\n").collect{|l| l.split(" ")[2,12].collect{|i| i.to_f}}.flatten)
    @onsets = `aubioonset "#{@file}"`.split("\n").collect{|t| t.to_f}
    @bpm = @file.match(/\d\d\d/).to_s.to_i
    if @file.match /drum/
      @tags = ["drums"]
    elsif @file.match /music/
      @tags = ["music"]
    end
    @bars = bars
    save
  end

  def save
    metadata = @file.sub "wav","meta"
    File.open(metadata,"w+"){|f| Marshal.dump self, f}
  end

  def self.from_file file
    metadata = file.sub "wav","meta"
    if File.exists? metadata
      File.open(metadata){|f| return Marshal.load f}
    else
      Sample.new(file)
    end
  end

  def play
    `play #{@file} 2>&1 >/dev/null`
  end

  def show
    pid = fork {`sox #{@file} /tmp/gnuplot.dat; gnuplot -e "title='#{@file}'; set term X11" -p ./plot`}
    Process.detach pid
  end

  def backup 
    bakdir = File.join "/tmp/ot", @dir, "bak"
    date = `date +\"%Y%m%d_%H%M%S\"`.chomp
    bakfile = File.join bakdir, name+"."+date
    FileUtils.mkdir_p bakdir
    FileUtils.cp @file, bakfile
    bakfile
  end

  def name
    File.basename(@file)
  end

  def md5
    Digest::MD5.file(@file).to_s
  end

  def pitch
    input = `aubionotes -v -u midi  -i #{@file} 2>&1 |grep "^[0-9][0-9].000000"|sed 's/read.*$//'`.split("\n")
    input.empty? ? nil : input.first.split("\t").first.to_i  # only onset pitch
  end

  def bars
    @seconds*@bpm/60/4
  end

  def normalized?
    @max_amplitude > 0.95
  end

  def normalize
    unless normalized?
      `sox -G --norm "#{backup}" "#{@file}"`
      @stat = Hash[`sox "#{@file}" -n stat 2>&1|sed '/Try/,$d'`.split("\n")[0..14].collect{|l| l.split(":").collect{|i| i.strip}}]
      @max_amplitude = [@stat["Maximum amplitude"].to_f,stat["Minimum amplitude"].to_f.abs].max
    end
  end

  def zerocrossings
    snd = RubyAudio::Sound.open @file
    snd.seek 0
    buf = snd.read(:float, snd.info.frames)
    i = buf.size-2
    while i >= 0 and (buf[i][0]*buf[i+1][0] < 0 or buf[i][1]*buf[i+1][1] < 0) # get first zero crossing of both channels
      i-=1
    end
    puts i
  end

  def similarity sample # cosine
    last = [@mfcc.size, sample.mfcc.size].min - 1
    v1 = Vector.elements(@mfcc[0..last])
    v2 = Vector.elements(sample.mfcc[0..last])
    #p v1.angle_with(v2)/Math::PI
    #p v1.inner_product(v2)/(v1.magnitude*v2.magnitude)
    #puts
    
    v1.inner_product(v2)/(v1.magnitude*v2.magnitude)

    #begin
    #rescue
      #puts $!
      #p self.name, sample.name
      #0
    #end
  end

end
