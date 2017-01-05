Clock c;
132.0 => c.bpm;
spork ~ c.osc();
Std.atoi(me.arg(0)) => int multichannel;

Looper loopers[4];
for (0 => int i; i < 4; i++) {
  Looper l;
  l.init(i,multichannel);
  spork ~ l.osc();
}

while(true) { minute => now; }
