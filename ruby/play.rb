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
  (0..3).each do |row|
    (0..7).each do |col|
      if @scenes[row][col]
        if @current[row] == @scenes[row][col]
          if @scenes[row][col].bars.round <= 16
            @midiout.puts(144,row*16+col,28)
          else
            @midiout.puts(144,row*16+col,60)
          end
        else
          if @scenes[row][col].bars.round <= 16
            @midiout.puts(144,row*16+col,29)
          else
            @midiout.puts(144,row*16+col,63)
          end
        end
      else
        @midiout.puts(144,row*16+col,12)
      end
      if @offsets[row] == col
        @midiout.puts(144,(row+4)*16+col,15)
      else
        @midiout.puts(144,(row+4)*16+col,12)
      end
    end
  end
end

at_exit do
  `killall chuck`
  @midiout.puts(176,0,0)
  `killall jackd`
end

jack = spawn "jackd -d alsa -P hw:0 -r 44100 "
#jack = spawn "jackd -d alsa -P hw:2 -r 44100 "
Process.detach jack
sleep 1
#chuck = spawn "chuck $HOME/music/src/chuck/clock.ck $HOME/music/src/chuck/looper.ck $HOME/music/src/chuck/arrange.ck "
chuck = spawn "chuck --channels:8 $HOME/music/src/chuck/clock.ck $HOME/music/src/chuck/looper.ck $HOME/music/src/chuck/multichannel.ck "
Process.detach chuck
status

while true do
  @midiin.gets.each do |m|
    d = m[:data]
    col = d[1] % 16
    row = d[1] / 16
    if d[0] == 144 and d[2] == 127
      if row < 4 and col < 8 # grid
        @oscclient.send OSC::Message.new("/#{row}/read", @scenes[row][col].file)
        @offsets[row] = 0
        @current[row] = @scenes[row][col]
      elsif row < 8 and col < 8 # offsets
        row -= 4
        @oscclient.send OSC::Message.new("/#{row}/offset", col)
        @offsets[row] = col
      elsif row == 4 and col == 8 # E
        @oscclient.send OSC::Message.new("/rate", 1.04) # speedup
      elsif row == 5 and col == 8 # F
        @oscclient.send OSC::Message.new("/rate", 0.96) # slowdown
      elsif row == 6 and col == 8 # G
        @oscclient.send OSC::Message.new("/reset")
        (0..3).each{|t| @offsets[t] = 0 }
      elsif row == 7 and col == 8 # H
        @oscclient.send OSC::Message.new("/restart")
        @offsets[row] = 0
        (0..3).each{|t| @offsets[t] = 0 }
      end
    elsif d[0] == 144 and d[2] == 0 and col == 8 and (row == 4 or row == 5)
        @oscclient.send OSC::Message.new("/rate", 1.0) # reset
    elsif d[0] == 176 # 1-8
      scene = d[1] - 104
      (0..3).each do |row|
        @oscclient.send OSC::Message.new("/#{row}/read", @scenes[row][scene].file)
        @offsets[row] = 0
        @current[row] = @scenes[row][scene]
      end
    end
    status
  end
end
