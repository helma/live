Clock c;
132.0 => c.bpm;
spork ~ c.osc();

Looper loopers[4];
for (0 => int i; i < 4; i++) {
  Looper l;
  l.init(i,1);
  spork ~ l.osc();
}

while(true) { minute => now; }
