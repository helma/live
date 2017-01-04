#!/usr/bin/env ruby
require "unimidi"
# Select a MIDI input
@midiin = UniMIDI::Input.gets
tn = 0
while true do
  @midiin.gets.each do |m|
    if m[:data].first == 248
      to = tn
      tn = m[:timestamp]
      p tn-to
    else
      #p m
    end
  end
end
=begin
require "topaz"
class Sequencer

  def step
    @i ||= 0
    puts "step #{@i+=1}"
  end

end
# Select a MIDI input
@input = UniMIDI::Input.gets
sequencer = Sequencer.new

tn = Time.now
@tempo = Topaz::Clock.new(@input, :midi_transport => true) do
  to = tn 
  tn = Time.now
  p tn-to if to
  #sequencer.step
  #puts "tempo: #{@tempo.tempo}"
end

puts "Waiting for MIDI clock..."
puts "Control-C to exit"
puts

@tempo.start
=end
#`killall jackd`
#`jackd -dalsa -r44100 -dhw:CODEC -P &`
# wait for midi start
# start record
# wait for record on
# record start time (quant on bars)
# wait for record off
# record end time
# wait for midi stop
# stop record
# extract recordings
# normalize
# annotate: bpm, type
#date = `date +%Y-%m-%dT%H%M%S`.chomp
#file = File.join(File.expand_path(ARGV[0]),"#{date}.wav")
#p file
#cmd = File.join(ENV["HOME"],"music","src","chuck","record","record.ck:#{file}")
#p cmd
#`chuck #{cmd}`
