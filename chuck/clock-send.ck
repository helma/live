public class ClockSend {
  MidiOut mout; 
  MidiMsg msg; 
  float bpm;
  dur interval;

  // check if port is open 

  // fill the message with data 
  47 => msg.data1; 
  100 => msg.data2; 
  100 => msg.data3; 

  // bugs after this point can be sent 
  // to the manufacturer of your synth 

  fun void run(float b, int midiport) {
    b => bpm;
    (120*(1000/48)/bpm)::ms => interval;
    if( mout.open( midiport ) ) {
      while( true ) { 
      //<<< "running" >>>;
          mout.send( msg ); 
          interval => now; 
      }
    }
    else { <<< "Cannot open midi port ", midiport >>>; }
  }
}
