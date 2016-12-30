#!/usr/bin/env ruby
#`killall jackd`
#`jackd -dalsa -r44100 -dhw:CODEC -P &`
date = `date +%Y-%m-%dT%H%M%S`.chomp
file = File.join(File.expand_path(ARGV[0]),"#{date}.wav")
p file
cmd = File.join(ENV["HOME"],"music","src","chuck","record","record.ck:#{file}")
p cmd
`chuck #{cmd}`
