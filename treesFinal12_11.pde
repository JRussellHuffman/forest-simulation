//note that this code has been tweaked and callibrated on the odroid for the actual installaion. This is basically the same
//but some variables may have slightly different values, like the tilePress variable
//options on load
boolean showSrc = false; // render the video taken from the camera
boolean useMouse = true; //use the mouse to control tree growth instead of the camera
boolean bigScreen = false; //1920 x 1980 if true. 1280 x 720 if false
int tilePress = 20; //larger number means press tile harder

//for arraylists
import java.util.*;

//for arduino
import processing.serial.*;
import cc.arduino.*;
Arduino arduino; //creates arduino object
color back = color(64, 218, 255); //variables for the 2 colors
int sensor= 0; //which sensor from the arduino. 0 on the odroid. 2 on the mac (I think)
int read;
float value;

// open cv material borrowed from HVSColorTracking example by Greg Borenstein and Jordi Tost
// https://github.com/atduskgreg/opencv-processing-book/blob/master/code/hsv_color_tracking/HSVColorTracking/HSVColorTracking.pde
import gab.opencv.*;
import processing.video.*;
import java.awt.Rectangle;

Capture video;
OpenCV opencv;
PImage src, colorFilteredImage;
ArrayList<Contour> contours;

// Set the range of Hue values for our filter
//0 to 10 is red. 100 to 120 (or so) is blue
int rangeLow = 0;
int rangeHigh = 10;

int cameraX = 640; //the camera's default output is 640 x 480.
int cameraY = 480; // these numbers are adjusted to fit a full screen

//check for ball move in opencv
float ballX = 0; //current frame ball x and y
float ballY = 0;
int px = 0; //previous frame ball x and y
int py = 0;
boolean moving = false; // is the ball moving?
//end opencv code

// for large screens
int bigX = 1920;
int bigY = 1080;
// for smaller screens
int littleX = 1280;
int littleY = 720;
int canvasX;
int canvasY;

int pods = 0; //how many groups of seeds have been lain
int clickInterval = 0;

//all images assets, most important is the trees array 
PImage ground; //not currently using this, but the ground assets are still in the data folder
PImage[] trees = new PImage[4]; //tree graphic array. 
PImage explosion;

//water detection
PImage waterImg;
PImage waterColor;
// the water detection works like 95% of the time and not sure why. these ints fill in the gaps to work 100%
int area1;
int area2;
int area3;
int area4;
int area5;

//booleans to see if seeds can grow
boolean canGrow;
boolean mouseDown = false;

//how many seeds to drop per click
int seedsPerPod = 1;

//disaster to reset screen. either from tile or max amount of trees
boolean trigger = false;
int diameter = 0;
int treeLimit = 300; //after 300 trees are rendered, the screen resets. a better computer can handle more trees

//tree arrays
//each tree object needs 2 arraylists because I cannot add an item to the array while iterating
//through it (concurrent modification error). this way they add back and forth to which ever one is not active.
//the exception is the grass becuase it is not being reproduced recursively
private static ArrayList<Seed> grass = new ArrayList();

private static ArrayList<Seed> smallPlants = new ArrayList();
private static ArrayList<Seed> smallPlantsOther = new ArrayList();

private static ArrayList<Seed> biggerPlants = new ArrayList();
private static ArrayList<Seed> biggerPlantsOther = new ArrayList();

private static ArrayList<Seed> largePlants = new ArrayList();
private static ArrayList<Seed> largePlantsOther = new ArrayList();

private static ArrayList<Seed> hardwoods = new ArrayList();
private static ArrayList<Seed> hardwoodsOther = new ArrayList();

void setup() {
  noStroke();
  //change background to match screen size
  if (bigScreen) { //1080 screen
    canvasX = bigX;
    canvasY = bigY;
    ground = loadImage("ground4.jpg");
    waterImg = loadImage("groundBitmapLarge.jpg");
    waterColor = loadImage("groundBitmapLarge.png");
    area1 = 450;
    area2 = 150;
    area3 = 975;
    area4 = 1275;
    area5 = 300;
  } else { //720 screen
    canvasX = littleX;
    canvasY = littleY;
    ground = loadImage("ground3.jpg");
    waterImg = loadImage("groundBitmap.jpg");
    waterColor = loadImage("groundBitmap.png");
    area1 = 300;
    area2 = 100;
    area3 = 650;
    area4 = 850;
    area5 = 200;
  }
  size(canvasX,canvasY);
  
  //load other assets
   explosion = loadImage("explosion.png");
   
  //arduino stuff
  arduino = new Arduino(this, Arduino.list()[2], 57600); //sets up arduino
  arduino.pinMode(sensor, Arduino.INPUT);//setup pins to be input (A0 =0?)
  
  //load tree images
  for ( int i = 0; i< trees.length; i++ ) {
    trees[i] = loadImage( i + ".png" );   //loads 4 images, but only uses 3 (not using 0.jpg)
  }
  
  //start open cv code
  video = new Capture(this, cameraX, cameraY);
  video.start();
  
  opencv = new OpenCV(this, video.width, video.height);
  contours = new ArrayList<Contour>();
  
  //end open cv code
}

void draw() {
  background(#a49e84); //using this instead of a background image currently, which would be pimage ground

  drawTrees();
  disaster();
  constructTrees();
  countTrees();
  openCV();
  arduinoRead();
  
}

void arduinoRead() {
  read=arduino.analogRead(sensor); //reads as 0 if not connected
  println (read);
  value=map(read, 0, 680, 0, width); //use to callibrate 

  
  if (read > tilePress) { //if signal from tile is great than the limit established
    trigger = true; //then trigger the distruction sequence
  }
}

void foundWater () { //check for pixels that contain water
    float waterLocation = mouseX + mouseY*waterImg.width;
    int i = (int) (waterLocation);
    float location = blue(waterImg.pixels[i]);
}

void drawTrees() {
  //loop through each tree arraylist every frame to render on screen
  //biggest trees are rendered last so they appear on top
  for (Seed s: grass)   s.run();
  
  image(waterColor, 0,0); //render the water above the grass so the grass doesn't interupt the water. all other plants grow over the water
  
  for (Seed s: smallPlants)   s.run();
  for (Seed s: smallPlantsOther)   s.run();
  
  for (Seed s: biggerPlants)   s.run();
  for (Seed s: biggerPlantsOther)   s.run();
  
  for (Seed s: largePlants)   s.run();
  for (Seed s: largePlantsOther)   s.run();
  
  for (Seed s: hardwoods)   s.run();
  for (Seed s: hardwoodsOther)   s.run();
}

void mousePressed () {
  clickInterval = 0;
  mouseDown = true;

}

void mouseReleased() {
  mouseDown = false;
}

void keyPressed() {
  trigger = true; //reset the screen with a mousepress to simulate stepping on the tile 
}

//the first layer. grows grass so that trees can grow
void constructTrees () {
  if (useMouse) {
    moving = mouseDown;
  }
  if (moving) {
    clickInterval ++; //used to regulate tree growth based on framerate
    
    if (clickInterval % 2 == 1 ) { // only draw trees every other frame
      pods ++;
    
    for (int i = 0; i < seedsPerPod; i ++) {
      float randomX;
      float randomY;
      int displacement = 100; //distance a seed (of grass) can grow from starting point. smaller number would make a patch. larger is more spread out.
      if (useMouse) {
        //seeds can grow within 100 pixels of mouse position
        randomX = random(mouseX-displacement, mouseX+displacement); 
        randomY = random(mouseY-displacement, mouseY+displacement);
      } else {
        //seeds can grow within 100 pixels of ball position
        randomX = random(ballX-displacement, ballX+displacement);
        randomY = random(ballY-displacement, ballY+displacement);
      }
      float randomGrowth = random(0, 50);
      if (randomGrowth > 20) { //there is only a 60% chance the seed will grow
        canGrow = true;
      } else {
        canGrow = false;
      }
      for (int j = 0; j < 1; j ++) {
        //create grass
        grass.add( new Seed(randomX, randomY, 1, j*pods, 0, grass, 300, canGrow, 3, false) );
      }
    }
    }
  }
}

void disaster() {
  
  //start in the middle of the screen
  float centerX = width/2;
  float centerY = height/2;
  
  // start exploding
  if (trigger && diameter < width+50) {
    
    image(explosion, centerX-(diameter/2), centerY-(diameter/2), diameter, diameter);
    diameter += 1; //becuase anything times 0 is still 0
    diameter *= 1.2;
  } else if (trigger && diameter < width+1000) { // clear screen when the explosion fills the whole screen
    diameter += 1;
    diameter *= 1.2;
    grass.clear();
    smallPlants.clear();
    biggerPlants.clear();
    largePlants.clear();
    hardwoods.clear();
    smallPlantsOther.clear();
    biggerPlantsOther.clear();
    largePlantsOther.clear();
    hardwoodsOther.clear();
  } else { //reset explosion
    diameter = 0;
    trigger = false;
  }
}

void countTrees() { //count trees currently active. this includes grass objects
  int total = grass.size() + smallPlants.size() + biggerPlants.size() + largePlants.size() + hardwoods.size() + smallPlantsOther.size() + biggerPlantsOther.size() + largePlantsOther.size() + hardwoodsOther.size();
  //println(total);
  if (total > treeLimit) {
    trigger = true; // if there are more than 300, trigger explosion
  }
}

//resize camera to fit screen
public float convertOldX (int oldX) {
  float convertX = oldX;
  float resizedX = convertX*canvasX/cameraX; 
  return resizedX;
}

public float convertOldY (int oldY) {
  float convertY = oldY;
  float resizedY = convertY*canvasY/cameraY;
  return resizedY;
}

//check ball's current position and prior position and decide if the ball actually moved during the frame change
//this is basically a quick and dirty solution instead of a velocity vector and needs to be fixed
public boolean checkMove (int x, int y, int px, int py) {
   boolean ballMoved;
   int range = 15; // if the ball has moved less than 15 pixels from last frame, then don't count it as movement
   int jump = 150; // if the ball has moved more than 150 pixels, the camera probably jumped. don't count these either
   int priorX = px;
   int priorY = py;
   
   //this seems to work for checking if the ball is sitting still, but doesn't work if the ball jumped
   if (x > priorX+range || x < priorX-range && x < priorX+jump || x > priorX-jump) {
     ballMoved = true;
   } else if (y > priorY+range || y < priorY-range && y < priorY+jump || y > priorY-jump){
     ballMoved = true;
   } else {
     ballMoved = false;
   }
   
   priorX = x;
   priorY = y;
   
   return ballMoved;
}

void openCV () {
  //start open cv code
  // Read last captured frame
  if (video.available()) {
    video.read();
  }

  // <2> Load the new frame of our movie in to OpenCV
  opencv.loadImage(video);
  
  // Tell OpenCV to use color information
  opencv.useColor();
  src = opencv.getSnapshot();
  
  // <3> Tell OpenCV to work in HSV color space.
  opencv.useColor(HSB);
  
  // <4> Copy the Hue channel of our image into 
  //     the gray channel, which we process.
  opencv.setGray(opencv.getH().clone());
  
  // <5> Filter the image based on the range of 
  //     hue values that match the object we want to track.
  opencv.inRange(rangeLow, rangeHigh);
  
  // <6> Get the processed image for reference.
  colorFilteredImage = opencv.getSnapshot();
  
  ///////////////////////////////////////////
  // We could process our image here!
  // See ImageFiltering.pde
  ///////////////////////////////////////////
  
  // <7> Find contours in our range image.
  //     Passing 'true' sorts them by descending area.
  contours = opencv.findContours(true, true);
  
  // <8> Display background images
  if (showSrc) { //only render the video on screen if the boolean at the very top is true
    image(src, 0, 0, canvasX, canvasY);
  }
  
  // <9> Check to make sure we've found any contours
  if (contours.size() > 0) {
    // <9> Get the first contour, which will be the largest one
    Contour biggestContour = contours.get(0);
    
    // <10> Find the bounding box of the largest contour,
    //      and hence our object.
    Rectangle r = biggestContour.getBoundingBox();
    for (int i=0;i<contours.size();i++){
      Contour tempContour = contours.get(i);
      r = tempContour.getBoundingBox();
      if (r.width<30 && r.height<30){ //because we roughly know the size of the ball, we can tell it what to look for
        break;
      }
    }

    moving = checkMove(r.x, r.y, px, py); //check if the ball moved
    px = r.x; //update the "previous" variables for next frame
    py = r.y;
    
    // <11> Draw the bounding box of our object

    noFill(); 
    strokeWeight(2); 
    stroke(125, 125, 125);
    if (showSrc) {
      ellipse(convertOldX(r.x) + convertOldX(r.width)/2, convertOldY(r.y) + convertOldY(r.height)/2, convertOldX(r.width), convertOldY(r.height));
    }
    ballX = convertOldX(r.x) + convertOldX(r.width)/2; //update for screen size
    ballY = convertOldY(r.y) + convertOldY(r.height)/2;
    
    // <12> Draw a dot in the middle of the bounding box, on the object.
      noStroke(); 
    if (!useMouse) {
      fill(125, 125, 125);
      ellipse(convertOldX(r.x) + convertOldX(r.width)/2, convertOldY(r.y) + convertOldY(r.height)/2, 30, 30);
    }
  }
  
  //end open cv code
}
