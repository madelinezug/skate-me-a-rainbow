
import processing.serial.*;

final static int SERIAL_PORT_NUM = 9;

final static int SERIAL_PORT_BAUD_RATE = 57600;

float accelX = 0.0f;
float accelY = 0.0f;
float accelZ = 0.0f;
float accelMax = 0.0f;

float magX = 0.0f;
float magY = 0.0f;
float magZ = 0.0f;
float magMax = 0.0f;

float gyroX = 0.0f;
float gyroY = 0.0f;
float gyroZ = 0.0f;
float gyroMax = 0.0f;

float[] avgArray;

/***************************************************/
//SPIRAL DRAWING VARIABLES
int x = 0;
int y = 300;
float r = 50;
float theta = 0;
float spiralRate = TWO_PI/128;
float spiralDecay = 0.01;
float spawnRate = 0.01;
ArrayList strokeList;
int spawnLimit = 1;
int yIncrement = 0;
/***************************************************/

//Setup and synch connection with hardware
PFont font;
Serial serial;

boolean synched = false;

// Skip incoming serial stream data until token is found
boolean readToken(Serial serial, String token) {
  // Wait until enough bytes are available
  if (serial.available() < token.length())
    return false;
  
  // Check if incoming bytes match token
  for (int i = 0; i < token.length(); i++) {
    if (serial.read() != token.charAt(i))
      return false;
  }
  
  return true;
}

// Global setup
void setup() {
  // Setup graphics
  size(1000, 700);
  background(20);
  fill(0);
  
  //Update speed, taken from sketch that interfaces with serial connection
  frameRate(100);
  
  // Load font
  font = loadFont("Univers-66.vlw");
  textFont(font);
  
  strokeList = new ArrayList();
  
  //avgArray = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}; //15 values

  // Setup serial port I/O
  println("AVAILABLE SERIAL PORTS:");
  println(Serial.list());
  String portName = Serial.list()[SERIAL_PORT_NUM];
  println();
  println("HAVE A LOOK AT THE LIST ABOVE AND SET THE RIGHT SERIAL PORT NUMBER IN THE CODE!");
  println("  -> Using port " + SERIAL_PORT_NUM + ": " + portName);
  serial = new Serial(this, portName, SERIAL_PORT_BAUD_RATE);
}

void setupRazor() {
  println("Trying to setup and synch Razor...");
  
  // On Mac OSX and Linux (Windows too?) the board will do a reset when we connect, which is really bad.
  // See "Automatic (Software) Reset" on http://www.arduino.cc/en/Main/ArduinoBoardProMini
  // So we have to wait until the bootloader is finished and the Razor firmware can receive commands.
  // To prevent this, disconnect/cut/unplug the DTR line going to the board. This also has the advantage,
  // that the angles you receive are stable right from the beginning. 
  delay(3000);  // 3 seconds should be enough
  
  // Set Razor output parameters
  //serial.write("#ob");  // Turn on binary output
  serial.write("#oscb"); //Turn on binary output of sensor data (Accelerometer, Magnetometer, Gyroscpope)
  serial.write("#o1");  // Turn on continuous streaming output
  serial.write("#oe0"); // Disable error message output
  
  // Synch with Razor
  serial.clear();  // Clear input buffer up to here
  serial.write("#s00");  // Request synch token
  
}

float readFloat(Serial s) {
  // Convert from little endian (Razor) to big endian (Java) and interpret as float
  return Float.intBitsToFloat(s.read() + (s.read() << 8) + (s.read() << 16) + (s.read() << 24));
}

void draw() {
  
  // Sync with Razor 
  if (!synched) {
    println(frameCount, "Not synched");
//    textAlign(CENTER);
//    fill(255);
//    text("Connecting to Razor...", width/2, height/2, -200);
    
    if (frameCount == 2)
      setupRazor();  // Set ouput params and request synch token
    else if (frameCount > 2)
      synched = readToken(serial, "#SYNCH00\r\n");  // Look for synch token
    return;
  }
   
   fill(0, 8);
   stroke(color(0, 0, 0));
   rect(0, 0, width, height); 
   
   // update all the strokes
 for (int i=strokeList.size ()-1; i>=0; i--) {
    skateStroke s = (skateStroke) strokeList.get(i);
    for(int strokeUpdates = 0; strokeUpdates<3; strokeUpdates++){
    s.update();
    }
  if (!s.isActive) {
      strokeList.remove(i);
    }   
 } //end update
 
  // Read angles from serial port
  if (serial.available() >= 36) {
    accelX = readFloat(serial);
    accelY = readFloat(serial);
    accelZ = readFloat(serial);
    
    magX = readFloat(serial);
    magY = readFloat(serial);
    magZ = readFloat(serial);
    
    
    gyroX = readFloat(serial);
    gyroY = readFloat(serial);
    gyroZ = readFloat(serial);

  }
  //accel values when standing straight up: x->-250 y->0 z->0
  float avgAccel = (accelX+accelY+accelZ)/3;
  if(avgAccel>0){
    strokeList.add(new skateStroke(color(accelX, accelY, accelZ)));
  }
 
  
  //Display the accelerometer and gyroscope values
  fill(0);
  rect(0, 0, 150, 275);
  textFont(font, 20);
  fill(255);
  textAlign(LEFT);
  text("AccelX: " + ((int) accelX), 0, 25);
  text("AccelY: " + ((int) accelY), 0, 50);
  text("AccelZ: " + ((int) accelZ), 0, 75);
  
  text("MagX: " + ((int) magX), 0, 100);
  text("MagY: " + ((int) magY), 0, 125);
  text("MagZ: " + ((int) magZ), 0, 150);
  
  text("GyroX: " + ((int) gyroX), 0, 175);
  text("GryoY: " + ((int) gyroY), 0, 200);
  text("GyroZ: " + ((int) gyroZ), 0, 225);
   text("AvgAccel: " + ((int) avgAccel), 0, 250);


 

}

void keyPressed() {
  switch (key) {
    case 'q':
      exit(); // Stops the program
  }
}
class spiral {
  PVector location;
  PVector previousLocation;
  PVector direction;
  PVector center;
  float clockWise;
  float radius;
  float angle;
  boolean dead;
  color clr;
  spiral(PVector loc, PVector dir, float rad, float clock, color spiralColor) {
    location = loc;
    direction = dir;
    radius = rad;
    clockWise = clock;
    angle = atan2(direction.y, direction.x)-clockWise*PI/2;
    PVector arm = new PVector(cos(angle), sin(angle));
    arm.mult(radius);
    center = PVector.sub(location, arm);
    clr = spiralColor;
    //clr = color(0, (int) (random(180, 255)), 200);
    //clr = color((int) (random(0, 255)), (int) (random(0, 255)), (int) (random(0, 255)));
  }
  spiral(spiral parent) {
    location = parent.location.get();
    direction = parent.direction.get();
    angle = parent.angle + PI;
    clockWise = -1*parent.clockWise;
    radius = random(0, width/8);
    PVector arm = new PVector(cos(angle), sin(angle));
    arm.mult(radius);
    center = PVector.sub(location, arm);
//    float mutation = 32;
//    float r = constrain(red(parent.clr)+random(-mutation,mutation),0,255);
//    float g = constrain(green(parent.clr)+random(-mutation,mutation),0,255);
//    float b = constrain(blue(parent.clr)+random(-mutation,mutation),0,255);
//    clr = color(r,g,b);
  }
  void setRadius(int r){
    radius = r;
  }
  void setColor(color c){
   clr = c; 
  }
  color getColor(){
    return clr;
  }
  void update() {
    previousLocation = location.get();
    angle += spiralRate*clockWise;
    radius *= 1-spiralDecay;
    dead = radius<2;
    PVector arm = new PVector(cos(angle), sin(angle));
    arm.mult(radius);
    location = PVector.add(center, arm);
    direction = PVector.sub(location, previousLocation);
    stroke(clr);
    line(previousLocation.x, previousLocation.y,
    location.x, location.y);
  }
}

class skateStroke{
  int myX;
  int myY;
  int prevX;
  int prevY;
  int mySpeed;
  int mySlope;
  color myColor;
  boolean isActive;
  ArrayList mySpirals;
  skateStroke(){
    myX = 0;
    myY = (int) random(0, height);
    prevX = 0;
    prevY = myY;
    mySpeed = 2;
    mySlope = (int) (random(-3, 3));
    myColor = color(0, (int) (random(100, 255)), (int) (random(100, 255)));
    isActive = true;
    mySpirals = new ArrayList();
    //mySpirals.add(new spiral(new PVector(myX, myY),
     //new PVector(mySpeed, mySlope), random(width/50, width/16), 1));
    
  }
  skateStroke(color newColor){
    myColor = newColor;
    myX = 0;
    myY = (int) random(0, height);
    prevX = 0;
    prevY = myY;
    mySpeed = 2;
    mySlope = (int) (random(-3, 3));
    isActive = true;
    mySpirals = new ArrayList();
  }
  void update(){
    /*
    if(mySpirals.size()>0){
     spiral s = (spiral)mySpirals.get(0);
   stroke(s.getColor()); 
    }
    else{
      stroke(myColor);
    }
    */
    stroke(myColor);
   //update stroke position and draw
   prevX = myX;
   prevY = myY;
   myX = myX+mySpeed;
   myY = myY+mySlope;
   
   line(prevX, prevY, myX, myY);
   
   //add a new spiral
   if(myX%50 == 0){
     int rand = (int) random(0, 2);
       if(rand ==0){
          rand = -1; 
         }
     mySpirals.add(new spiral(new PVector(myX, myY),
     new PVector(mySpeed, mySlope), random(width/50, width/16), rand, myColor));
  }
  
  //update all existing spirals
   for (int i=mySpirals.size ()-1; i>=0; i--) {
    spiral s = (spiral) mySpirals.get(i);
    for(int spiralUpdates = 0; spiralUpdates<3; spiralUpdates++){
    s.update();
    }
   
    if (s.dead) {
      mySpirals.remove(i);
    } 
  }
  
  //Decide if still active
  if(myX>width || myY>height){
    isActive = false;
    
  }
  
  }//end of update method
}//end of stroke class

