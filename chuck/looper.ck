public class Looper {

  int chan;
  string file;
  SndBuf2 buffer; 
  int bars;
  int multichannel;

  fun void init(int c, int m) {
    c => chan;
    m => multichannel;
    1 => buffer.loop;
    0 => buffer.play;
  }

  fun void connect() {
    if (multichannel) { 
      0 => buffer.channel;
      buffer => dac.chan(chan*2);
      1 => buffer.channel;
      buffer => dac.chan(chan*2+1);
    }
    else { buffer => dac; }
    1 => buffer.play;
  }

  fun void disconnect() {
    0 => buffer.play;
    if (multichannel) { 
      0 => buffer.channel;
      buffer =< dac.chan(chan*2);
      1 => buffer.channel;
      buffer =< dac.chan(chan*2+1);
    }
    else { buffer =< dac; }
  }

  fun void read(string f) {
    f => file;
    <<< file >>>;
    Clock.next_bar();
    disconnect();
    file => buffer.read;
    0 => buffer.pos;
    connect();
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
        else if (msg.address == "/"+chan+"/mute") { disconnect(); }
        else if (msg.address == "/"+chan+"/unmute") { connect(); }
        else {
          // print
        }
      }
    }
  }

}
