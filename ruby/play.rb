#!/usr/bin/env ruby
require 'json'
require "unimidi"
require 'ruby-osc'
require_relative 'loop.rb'

@bpm = ARGV[0].match(/\d\d\d/).to_s.to_f
@midiin = UniMIDI::Input.find{ |device| device.name.match(/Launchpad/) }.open
@midiout = UniMIDI::Output.find{ |device| device.name.match(/Launchpad/) }.open
@oscclient = OSC::Client.new 9669

@scenes = File.open(ARGV[0]){|f| Marshal.load(f)}
@current = [nil,nil,nil,nil]
@offsets = [0,0,0,0]

def status 
  # grid
  (0..3).each do |track|
    (0..7).each do |scene|
      if @scenes[track][scene]
        if @current[track] == @scenes[track][scene]
          if @scenes[track][scene].bars.round <= 16
            @midiout.puts(144,track*16+scene,28)
          else
            @midiout.puts(144,track*16+scene,60)
          end
        else
          if @scenes[track][scene].bars.round <= 16
            @midiout.puts(144,track*16+scene,29)
          else
            @midiout.puts(144,track*16+scene,63)
          end
        end

      else
        @midiout.puts(144,track*16+scene,12)
      end
      if @offsets[track] == scene
        #puts
        #p [@current[track].file, @current[track].offset, scene]
        @midiout.puts(144,(track+4)*16+scene,15)
      else
        @midiout.puts(144,(track+4)*16+scene,12)
      end
        #@scenes[track][scene].offset == scene ? @midiout.puts(144,(track+4)*16+scene,15) : @midiout.puts(144,(track+4)*16+scene,12)
      #@current[track] and @current[track].offset == scene ? @midiout.puts(144,(track+4)*16+scene,15) : @midiout.puts(144,(track+4)*16+scene,12)
    end
  end
end

at_exit do
  `killall chuck`
  @midiout.puts(176,0,0)
  `killall jackd`
end

#jack = spawn "jackd -d alsa -P hw:0 -r 44100 "
jack = spawn "jackd -d alsa -P hw:2 -r 44100 "
Process.detach jack
sleep 1
#chuck = spawn "chuck $HOME/music/src/chuck/clock.ck $HOME/music/src/chuck/looper.ck $HOME/music/src/chuck/arrange.ck "
chuck = spawn "chuck --channels:8 $HOME/music/src/chuck/clock.ck $HOME/music/src/chuck/looper.ck $HOME/music/src/chuck/multichannel.ck "
Process.detach chuck
status

while true do
  @midiin.gets.each do |m|
    d = m[:data]
    sample = d[1] % 16
    track = d[1] / 16
    if d[0] == 144 and d[2] == 127
      if track < 4 and sample < 8 # grid
        @oscclient.send OSC::Message.new("/#{track}/read", @scenes[track][sample].file)
        @offsets[track] = 0
        @current[track] = @scenes[track][sample]
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
        (0..3).each{|t| @offsets[t] = 0 }
      elsif track == 7 and sample == 8 # H
        @oscclient.send OSC::Message.new("/restart")
        @offsets[track] = 0
        (0..3).each{|t| @offsets[t] = 0 }
      end
    elsif d[0] == 144 and d[2] == 0 and sample == 8 and (track == 4 or track == 5)
        @oscclient.send OSC::Message.new("/rate", 1.0) # reset
    elsif d[0] == 176 # 1-8
      scene = d[1] - 104
      (0..3).each do |track|
        @oscclient.send OSC::Message.new("/#{track}/read", @scenes[track][scene].file)
        @offsets[track] = 0
        #@scenes[track][scene].offset = 0
        @current[track] = @scenes[track][scene]
      end
    end
    status
  end
end
