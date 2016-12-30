#!/usr/bin/env ruby
require 'json'
require "unimidi"
require 'ruby-osc'
require_relative 'sample.rb'
require_relative 'loop.rb'

@bpm = ARGV[0].match(/\d\d\d/).to_s.to_f
@midiin = UniMIDI::Input.find{ |device| device.name.match(/Launchpad/) }.open
@midiout = UniMIDI::Output.find{ |device| device.name.match(/Launchpad/) }.open
@oscclient = OSC::Client.new 9669

if File.exists? ARGV[0]
  @scenes = File.open(ARGV[0]){|f| Marshal.load(f)}
else
  @scenes = [[nil, nil, nil, nil, nil, nil, nil, nil], [nil, nil, nil, nil, nil, nil, nil, nil], [nil, nil, nil, nil, nil, nil, nil, nil], [nil, nil, nil, nil, nil, nil, nil, nil]]
end

@pool = [[],[],[],[]]

Dir[File.join(ARGV[1],"**","*wav")].collect{|f| Sample.from_file f}.each do |s|
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

@pool[0] += @pool[1]
@pool[1] += @pool[0]
@pool[2] += @pool[3]
@pool[3] += @pool[2]

@current = [nil,nil,nil,nil]

def status 
  # scenes
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
    end
  end
  # pool
  (4..7).each do |track|
    track -= 4
    (0..7).each do |scene|
      if @pool[track][scene]
        if @current[track] == @pool[track][scene]
          if @pool[track][scene].bars.round <= 16
            @midiout.puts(144,(track+4)*16+scene,28)
          else
            @midiout.puts(144,(track+4)*16+scene,60)
          end
        else
          if @pool[track][scene].bars.round <= 16
            @midiout.puts(144,(track+4)*16+scene,29)
          else
            @midiout.puts(144,(track+4)*16+scene,63)
          end
        end
      else
        @midiout.puts(144,(track+4)*16+scene,12)
      end
    end
  end
end

def save_scene i
  (0..3).each do |track|
    @scenes[track][i] = @current[track]
    (0..3).each do |t|
      @pool[t].delete @current[track]
    end
  end
  File.open(ARGV[0],"w+"){|f| Marshal.dump @scenes, f}
end

at_exit do
  `killall chuck`
  @midiout.puts(176,0,0)
  `killall jackd`
end

jack = spawn "jackd -d alsa -P hw:0 -r 44100 "
Process.detach jack
sleep 1
chuck = spawn "chuck $HOME/music/src/chuck/clock.ck $HOME/music/src/chuck/looper.ck $HOME/music/src/chuck/arrange.ck "
Process.detach chuck
status

while true do
  @midiin.gets.each do |m|
    d = m[:data]
    sample = d[1] % 16
    track = d[1] / 16
    if d[0] == 144 and d[2] == 127
      if track < 4 and sample < 8 # samples
        @oscclient.send OSC::Message.new("/#{track}/read", @scenes[sample][track]) if @scenes[track][sample] and @scenes[track][sample].file
        @current[track] = sample
      elsif track < 8 and sample < 8 # pool
        track -= 4
        @oscclient.send OSC::Message.new("/#{track}/read", @pool[track][sample].file) if @pool[track][sample] and @pool[track][sample].file
        @current[track] = @pool[track][sample]
      elsif track == 0 and sample == 8 # A
      elsif track == 1 and sample == 8 # B
      elsif track == 2 and sample == 8 # C
      elsif track == 3 and sample == 8 # D
      elsif track == 4 and sample == 8 # E
      elsif track == 5 and sample == 8 # F
      elsif track == 6 and sample == 8 # G
      elsif track == 7 and sample == 8 # H
      end
    elsif d[0] == 144 and d[2] == 0 and sample == 8 and (track == 4 or track == 5)
        @oscclient.send OSC::Message.new("/rate", 1.0) # reset
    elsif d[0] == 176 # 1-8
      scene = d[1] - 104
      if d[2] == 127
        @save_time = Time.now
      elsif d[2] == 0
        if Time.now - @save_time > 1
          save_scene scene
        else
          (0..3).each do |track|
            @oscclient.send OSC::Message.new("/#{track}/read", @scenes[track][scene].file) if @scenes[track][scene]
            @current[track] = @scenes[track][scene]
          end
        end
      end
    end
    status
  end
end
