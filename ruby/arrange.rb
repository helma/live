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

@pool.each { |p| p.shuffle! }
@pool[0] += @pool[1]
@pool[1] += @pool[0]
@pool[2] += @pool[3]
@pool[3] += @pool[2]

@current = [nil,nil,nil,nil]

def status 
  # scenes
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
    end
  end
  # pool
  (4..7).each do |row|
    row -= 4
    (0..7).each do |col|
      if @pool[row][col]
        if @current[row] == @pool[row][col]
          if @pool[row][col].bars.round <= 16
            @midiout.puts(144,(row+4)*16+col,28)
          else
            @midiout.puts(144,(row+4)*16+col,60)
          end
        else
          if @pool[row][col].bars.round <= 16
            @midiout.puts(144,(row+4)*16+col,29)
          else
            @midiout.puts(144,(row+4)*16+col,63)
          end
        end
      else
        @midiout.puts(144,(row+4)*16+col,12)
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

jack = spawn "jackd -d alsa -P hw:2 -r 44100 "
Process.detach jack
sleep 1
chuck = spawn "chuck $HOME/music/src/chuck/clock.ck $HOME/music/src/chuck/looper.ck $HOME/music/src/chuck/arrange.ck "
Process.detach chuck
status

while true do
  @midiin.gets.each do |m|
    d = m[:data]
    col = d[1] % 16
    row = d[1] / 16
    if d[0] == 144 # notes
      if col < 8 # grid
        if d[2] == 127 # press
          @del_time = Time.now
        elsif d[2] == 0 # release
          if row < 4 # scenes
            if Time.now - @del_time > 1 # long press
              @scenes[row][col].delete # delete
              @scenes[row][col] = nil
              @oscclient.send OSC::Message.new("/#{row}/mute") # stop playback
            else # short press
              # play
              @oscclient.send OSC::Message.new("/#{row}/read", @scenes[row][col].file) if @scenes[row][col] and @scenes[row][col].file
              @current[row] = @scenes[row][col]
            end
          elsif row < 8 # pool
            row -= 4
            if Time.now - @del_time > 1 # long press
              @pool[row][col].delete # delete
              @pool[row].delete_at col
              @oscclient.send OSC::Message.new("/#{row}/mute") # stop playback
            else # short press
              # play
              @oscclient.send OSC::Message.new("/#{row}/read", @pool[row][col].file) if @pool[row][col] and @pool[row][col].file
              @current[row] = @pool[row][col]
            end
          end
        end
      elsif col == 8 # A-H
        if row == 0 # A
        elsif row == 1 # B
        elsif row == 2 # C
        elsif row == 3 # D
        elsif row == 4 # E
        elsif row == 5 # F
        elsif row == 6 # G
        elsif row == 7 # H
        end
      end
    elsif d[0] == 176 # 1-8 scenes
      col = d[1] - 104
      if d[2] == 127 # press
        @save_time = Time.now
        if @last_scene # move scene
          (0..3).each do |row|
            src = @scenes[row].delete_at @last_scene
            @scenes[row].insert col, src
            @oscclient.send OSC::Message.new("/#{row}/read", @scenes[row][col].file) if @scenes[row][col]
            @current[row] = @scenes[row][col]
          end
          @last_scene = nil
        else
          @last_scene = col
        end
      elsif d[2] == 0 # release
        if Time.now - @save_time > 1
          save_scene col
        else
          if @last_scene
            (0..3).each do |row|
              @oscclient.send OSC::Message.new("/#{row}/read", @scenes[row][col].file) if @scenes[row][col]
              @current[row] = @scenes[row][col]
            end
          end
        end
        @last_scene = nil
      end
    end
    status
  end
end
