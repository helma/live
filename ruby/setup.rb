#!/usr/bin/env ruby
require 'json'
require "unimidi"
require 'ruby-osc'
require_relative 'loop.rb'

@devices = ["UDAC8", "USBStreamer","CODEC","PCH"]

@devices.each do |d|
  if `aplay -l |grep card`.match(d)
    jack = spawn "jackd -d alsa -P hw:#{d} -r 44100"
    Process.detach jack
    sleep 1
    multichannel = 0
    multichannel = 1 if d == "USBStreamer" or d == "UDAC8"
    if multichannel == 1
      chuck = spawn "chuck --channels:8 $HOME/music/src/chuck/clock.ck $HOME/music/src/chuck/clock-send.ck $HOME/music/src/chuck/looper.ck $HOME/music/src/chuck/main.ck:#{multichannel} "
    else
      chuck = spawn "chuck $HOME/music/src/chuck/clock.ck $HOME/music/src/chuck/clock-send.ck $HOME/music/src/chuck/looper.ck $HOME/music/src/chuck/main.ck:#{multichannel} "
      
    end
    Process.detach chuck
    break
  end
end

@bpm = ARGV[0].match(/\d\d\d/).to_s.to_f
@midiin = UniMIDI::Input.find{ |device| device.name.match(/Launchpad/) }.open
@midiout = UniMIDI::Output.find{ |device| device.name.match(/Launchpad/) }.open
@oscclient = OSC::Client.new 9669

@current = [nil,nil,nil,nil]
@bank = 0

at_exit do
  `killall chuck`
  @midiout.puts(176,0,0)
  `killall jackd`
end
