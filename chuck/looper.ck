public class Looper {

  int chan;
  string file;
  SndBuf2 buffer; 
  int bars;

  fun void init(int c) {
    c => chan;
    1 => buffer.loop;
    0 => buffer.play;
    buffer => dac; // TODO multichannel
  }

  fun void read(string f) {
    Clock.next_bar();
    f => file;
    file => buffer.read;
    0 => buffer.pos;
    1 => buffer.play;
  }

  fun void osc() {
    OscIn oin;
    9669 => oin.port;
    OscMsg msg;
    oin.listenAll();

    while ( true ) {
      oin => now;
      while ( oin.recv(msg) != 0 ) { 
        if (msg.address == "/"+chan+"/read") { spork ~ read(msg.getString(0)); }
        else if (msg.address == "/start") { 1 => buffer.play; }
        else if (msg.address == "/stop") { 0 => buffer.play; }
        else if (msg.address == "/"+chan+"/restart" || msg.address == "/restart") { 0 => buffer.pos; }
        else {
          // print
        }
      }
    }
  }

}
