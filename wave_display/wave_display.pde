import oscP5.*;
import netP5.*;
import codeanticode.syphon.*;

SyphonServer server;
PGraphics canvas;


OscP5 oscP5;
PImage img;
//String datapath = dataPath("");
int port;
boolean ready_for_data = false;
boolean data_updated = false;
int n_bpbands_total;
int n_steps;
float duration;
float pollrate;
float next_step_time;
int next_step_i;
float[] next_bands;

void setup() {
  //This init has to come before the OSC stuff, or the latter gets initialized twice
  size(1280, 720, P2D);
  server = new SyphonServer(this, "Processing Syphon");
  canvas = createGraphics(1280, 720, P2D);
  /* start oscP5, listening for incoming messages at port 3335 */
  //port = int(random(1024, 20480));
  port = 3334;
  oscP5 = new OscP5(this, port);
  /* spectrograph */
  textureMode(NORMAL);
  img = loadImage("spectrogram.png");
}

void draw_spectrogram (){
  canvas.beginShape();
  canvas.texture(img);
  canvas.vertex(0, 0, 0, 0);
  canvas.vertex(1280, 0, 1, 0);
  canvas.vertex(1280, 720, 1, 1);
  canvas.vertex(0, 720, 0, 1);
  canvas.endShape();
}
void draw() {
  //background(0);
  if (data_updated){
    img.updatePixels();
    draw_spectrogram();
    data_updated = false;
    //image(canvas, 0, 0);
    server.sendImage(canvas);
  }
}

void oscEvent(OscMessage theOscMessage) {
  // print the address pattern and the typetag of the received OscMessage 
  print("### received an osc message.");
  print(" addrpattern: "+theOscMessage.addrPattern());
  println(" typetag: "+theOscMessage.typetag());
  // All other functions are switched by whether we have received the right init info or not:
  if(theOscMessage.checkAddrPattern("/viz/init")==true) {
    // parse theOscMessage and extract the values from the osc message arguments.
    // n_bpbands_total, n_steps, duration, pollrate
    n_bpbands_total = theOscMessage.get(0).intValue(); 
    n_steps = theOscMessage.get(1).intValue();
    duration = theOscMessage.get(2).floatValue();
    pollrate = theOscMessage.get(3).floatValue();
    print("## received an init message .");
    println(" values: "+n_bpbands_total+", "+n_steps+", "+duration+", "+pollrate);
    img.resize(n_steps,n_bpbands_total);
    img.loadPixels();
    ready_for_data=true;
    next_step_time = 0.0;
    next_step_i = -1;
  }  else if(theOscMessage.checkAddrPattern("/viz/stop")==true) {
    print("## received a stop message .");
    ready_for_data=false;
  }
  if(ready_for_data) {
    if(theOscMessage.checkAddrPattern("/viz/step")==true) {
      next_step_time = theOscMessage.get(0).floatValue();
      next_step_i++;
    } else if(theOscMessage.checkAddrPattern("/viz/bands")==true) {
      next_bands = new float[n_bpbands_total];
      for (int i = 0; i < n_bpbands_total; i = i+1) {
        next_bands[i] = theOscMessage.get(i).floatValue();
      }
      for (int i = 0; i < n_bpbands_total; i = i+1) {
        img.pixels[next_step_i+n_steps*i] = color(int(next_bands[i]*256));
      }
      print("## received bands message .");
      print(join(nf(next_bands, 0, 3), ";"));
      data_updated=true;
    }
  }
}
