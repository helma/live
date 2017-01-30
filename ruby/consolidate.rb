#!/bin/env ruby
require 'json'
require 'ruby-osc'
require_relative 'sample.rb'
require 'highline'

jack = spawn "jackd -d alsa -P hw:PCH -r 44100"
Process.detach jack
sleep 1
chuck = spawn "chuck $HOME/music/src/chuck/play.ck"
Process.detach chuck
@oscclient = OSC::Client.new 9669

def play sample
  @oscclient.send OSC::Message.new("/play", sample.file)
end

def stop
  @oscclient.send OSC::Message.new("/stop")
end

at_exit do
  `killall chuck`
  `killall jackd`
end

@cli = HighLine.new
audio = Dir[File.join(ARGV[0],"**","*.{wav,WAV,aif,aiff,AIF,AIFF}")]
samples = audio.collect{|f| Sample.from_file f}

# remove stale metadata files
meta = Dir[File.join(ARGV[0],"**","*.meta")]
meta.each { |f| puts `trash "#{f}"` if Dir[f.sub("meta","*")].size == 1 }

# remove stale metadata files
images = Dir[File.join(ARGV[0],"**","*.png")]
images.each { |f| puts `trash "#{f}"` if Dir[f.sub("png","*")].size == 1 }

# TODO fix file paths

# normalize
samples.each { |s| s.normalize }

# check tags
samples.each do |s|
  unless s.tags and (s.tags.include? "drums" or s.tags.include? "music")
    stay = true
    while stay do
      @cli.say s.name
      @cli.choose do |menu|
        menu.choice("play") { play s }
        menu.choice("stop") { stop }
        menu.choice(:drums) { s.tags << "drums"; s.save; stop; stay = false }
        menu.choice(:music) { s.tags << "music"; s.save; stop; stay = false }
      end
    end
  end
end

# adjust bars
samples.each do |s|
  unless [2.0,4.0,6.0,8.0,12.0,16.0,24.0,32.0,48.0,64.0,96.0,112.0,128.0].include? s.bars.round(2)
    stay = true
    dir = "/home/ch/music/loops/cut/#{s.bpm}/"
    while stay do
      @cli.choose do |menu|
        menu.header = "#{s.file}: #{s.bars} bars"
        menu.choice("play") { play s }
        menu.choice("stop") { stop }
        menu.choice("move to #{dir}") { 
          stop
          `mkdir -p #{dir}` 
          puts `mv -iv "#{s.file}" #{dir}` 
          stay = false
        }
        menu.choice("delete") {
          stop
          puts `trash "#{s.file}"`
          stay = false
        }
        menu.choice("next") {
          stop
          stay = false
        }
      end
    end
  end
end

def display sample
  Process.detach spawn("display '#{sample.png}'")
end


# find/remove duplicates
#threshold=0.95
threshold=0.9
@matrix = []
@cli.say "Calculating similarities ..."
last = samples.size-1
(0..last).each do |i|
  @matrix[i] ||= []
  @matrix[i][i] = true
  (i+1..last).each do |j|
    sim = samples[i].similarity samples[j]
    if sim > threshold
      @matrix[j] ||= []
      @matrix[i][j] = true
      @matrix[j][i] = true
    end
  end
end

# disconnected subgraphs
# http://math.stackexchange.com/questions/277045/easiest-way-to-determine-all-disconnected-sets-from-a-graph

@components = []
@visited = []

def search i
  unless @visited.include? i
    @visited << i
    if @matrix[i].compact.size > 1
      @matrix[i].each_with_index do |v,j|
        if v and !@visited.include? j
          @components.last << j
          search j
        end
      end
    end
  end
end

@matrix.each_with_index do |row,i|
  if row.compact.size > 1 and !@visited.include? i
    @components << [i]
    search i
  end
end

@components.each do |component|
  component = component.collect{|i| samples[i]}
  stay = true
  while stay do
    @cli.choose do |menu|
      menu.header = "\n"+component.collect{|s| "#{s.name}: #{s.bars.round}"}.join(", ")
      component.each do |s|
        menu.choice("play \"#{s.name}\"".to_sym) { play s; menu.prompt = "#{s.name} playing" }
      end
      # TODO: single display
      component.each do |s|
        menu.choice("display \"#{s.name}\"".to_sym) { display s }
      end
      component.each do |s|
        menu.choice("delete \"#{s.name}\"".to_sym) { stop; s.delete; component.delete s }
      end
      menu.choice("stop") { stop }
      menu.choice("next") { stop; stay = false }
    end
  end
end

=begin
#p matrix
p del#.join "\n"
puts
p del.uniq#.join "\n"
p del.size
p del.uniq.size
    end
  end
end

p del
#del.each{|s| puts `trash "#{s.file}"`}
=end
