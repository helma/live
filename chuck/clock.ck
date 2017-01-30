public class Clock {
  132.0 => static float bpm;
  1.0 => static float rate;
  0 => static int pulses;
  new Event @=> static Event @ pulse;
  new Event @=> static Event @ bar;
  static Shred @ ticker;
 
  fun static void tick() {
    0 => pulses;
    while (true) {
      pulse.broadcast();
      pulses + 1 => pulses;
      if ((pulses % 16) == 0) { bar.broadcast(); }
      quant() => now;
    }
  }

  fun static dur bardur() { return 4*minute/(bpm*rate); }

  fun static dur quant() { return bardur()/16; }

  fun static void osc() {
    OscIn oin;
    9669 => oin.port;
    OscMsg msg;
    oin.listenAll();

    spork ~ tick() @=> ticker;

    while ( true ) {
      oin => now;
      while ( oin.recv(msg) ) { 
        if (msg.address == "/bpm") { msg.getFloat(0) => bpm; }
        else if (msg.address == "/restart") {
          ticker.exit();
          spork ~ tick() @=> ticker;
        }
        else if (msg.address == "/rate") {
          pulse => now;
          msg.getFloat(0) => rate;
        }
      }
    }
  }

}
/*
MidiOut mout; 
MidiMsg msg; 

// check if port is open 
if( !mout.open( 0 ) ) me.exit(); 

// fill the message with data 
47 => msg.data1; 
100 => msg.data2; 
100 => msg.data3; 

// bugs after this point can be sent 
// to the manufacturer of your synth 

while( true ) 
{ 
    mout.send( msg ); 
    // allow 2 seconds to pass 
    2::second => now; 
}
*/
