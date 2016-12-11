#!/usr/bin/env ruby
require 'json'
require "unimidi"
require 'ruby-osc'

@bpm = 132
@midiin = UniMIDI::Input.find{ |device| device.name.match(/Launchpad/) }.open
@midiout = UniMIDI::Output.find{ |device| device.name.match(/Launchpad/) }.open
@oscclient = OSC::Client.new 9669

dir = ARGV[0]
scenes_file = File.join ARGV[0], "scenes.json"
@scenes = JSON.parse(File.read(scenes_file))
@bars = []
@offsets = [0,0,0,0]
@current = [nil,nil,nil,nil]

(0..7).each do |i|
  @bars[i] = []
  (0..3).each do |j|
    seconds = Hash[`sox "#{@scenes[i][j]}" -n stat 2>&1|sed '/Try/,$d'`.split("\n")[0..14].collect{|l| l.split(":").collect{|i| i.strip}}]["Length (seconds)"].to_f
    @bars[i][j] = seconds*@bpm/60/4
  end
end

def status 
  # grid
  (0..3).each do |r|
    (0..7).each do |c|
      if @current[r] == c 
        if @bars[c][r] < 17
          @midiout.puts(144,r*16+c,28)
        else
          @midiout.puts(144,r*16+c,60)
        end
      else
        if @bars[c][r] < 17
          @midiout.puts(144,r*16+c,29)
        else
          @midiout.puts(144,r*16+c,63)
        end
      end
      @offsets[r] == c ? @midiout.puts(144,(r+4)*16+c,15) : @midiout.puts(144,(r+4)*16+c,12)
    end
  end
end

at_exit do
  `killall chuck`
  @midiout.puts(176,0,0)
end

status
while true do
  @midiin.gets.each do |m|
    d = m[:data]
    sample = d[1] % 16
    track = d[1] / 16
    if d[0] == 144 and d[2] == 127
      if track < 4 and sample < 8 # grid
        @oscclient.send OSC::Message.new("/#{track}/read", @scenes[sample][track])
        @current[track] = sample
        @offsets[track] = 0
      elsif track < 8 and sample < 8 # offsets
        track -= 4
        @oscclient.send OSC::Message.new("/#{track}/offset", sample)
        @offsets[track] = sample
      elsif track == 4 and sample == 8 # E
        @oscclient.send OSC::Message.new("/rate", 1.04) # speedup
      elsif track == 5 and sample == 8 # F
        @oscclient.send OSC::Message.new("/rate", 0.96) # slowdown
      elsif track == 6 and sample == 8 # G
        @oscclient.send OSC::Message.new("/reset")
        @offsets = [0,0,0,0]
      elsif track == 7 and sample == 8 # H
        @oscclient.send OSC::Message.new("/restart")
        @offsets = [0,0,0,0]
      end
    elsif d[0] == 144 and d[2] == 0 and sample == 8 and (track == 4 or track == 5)
        @oscclient.send OSC::Message.new("/rate", 1.0) # reset
    elsif d[0] == 176 # 1-8
      scene = d[1] - 104
      (0..3).each do |track|
        @oscclient.send OSC::Message.new("/#{track}/read", @scenes[scene][track])
        @current[track] = scene
        @offsets = [0,0,0,0]
      end
    end
    status
  end
end
