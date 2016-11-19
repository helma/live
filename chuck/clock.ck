public class Clock {
  132.0 => static float bpm;
  static time start;

  fun static void next_bar() {
    bar() - ((now - start) % bar()) => now;
  }

  fun static dur bar() { return 4*minute/bpm; }

  fun static void osc() {
    OscIn oin;
    9669 => oin.port;
    OscMsg msg;
    oin.addAddress( "/bpm, f" );
    oin.addAddress( "/restart" );

    while ( true ) {
      oin => now;
      while ( oin.recv(msg) ) { 
        if (msg.address == "/bpm") { msg.getFloat(0) => bpm; <<< bpm >>>; }
        else if (msg.address == "/restart") { now => start; <<< "Restart ..." >>>; }
      }
    }
  }

}

