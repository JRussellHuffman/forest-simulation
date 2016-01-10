// all seeds (mostly) play by the same rules, both grass and trees
class Seed { 
  float xpos;
  float ypos;
  int id;
  float growth;
  boolean colorBool = true;
  boolean continueGrow = true;
  int img;
  
  boolean switchID = false;
  boolean finished = false;
  boolean grow = true;
  
  boolean collided = false;
  
  float maxSize;
  boolean reproduce;
  float reproSpeed;
  boolean canCollide = false;
  
  float randomGrowth = random(50);
  
  //baby tree variables
  boolean fertile = true;
  boolean isChild;
  float seedAmount = 0;
  
  final ArrayList<Seed> others;
 
  //not a part of the constructor
  float seedSize = 0;
  //boolean colorBool = true;

  // The Constructor is defined with arguments.
  Seed (float tempXpos, float tempYpos, float tempGrowth, int tempId, int tempImg, ArrayList<Seed> tempOthers, float tempMax, boolean tempRepro, float tempReproSpeed, boolean tempChild) { 
    xpos = tempXpos;
    ypos = tempYpos;
    //seedGrowth = tempGrowth;
    id = tempId;
    others = tempOthers;
    growth = tempGrowth;
    //canGrow = true;
    img = tempImg;
    maxSize = tempMax;
    reproduce = tempRepro;
    reproSpeed = tempReproSpeed;
    //canCollide = tempCollide;
    isChild = tempChild;
  }
  
  
  void run () {
    collide ();
    display ();
    grow ();
    spawn ();
    detectWater ();
  }

  void display() {
    if (colorBool) {
      //stroke(#79582C);
      fill(126, 160, 106, 255);
    } else {
      fill(142, 157, 135, 255);
    }

    float centerTree = seedSize/2;
    if (img == 0) { //the first image should be the grass
    ellipse(xpos,ypos,seedSize,seedSize); //draw the green circle instead of an image here. this could be replaced with an image mask of a 'lush' ground
    } else {
      image(trees[img], xpos-(centerTree*1.1), ypos-(centerTree*1.1), seedSize*1.1, seedSize*1.1); //otherwise draw a tree
    }
  }
  
  void detectWater() {
    float waterLocation = xpos + ypos*waterImg.width;
    int i = (int) (waterLocation);
    if (i > 921599) { //this value is the bottom right of the image, from the pixel array (1279 x 719)
      i = 921599;
    } else if (i < 0) {
      i = 1;
    }
    float location = blue(waterImg.pixels[i]);
    if (xpos > area1 && ypos > height-area2) {
      grow = false;
    } else if (xpos > area3 && xpos < area4 && ypos > height-area5) { // the float "location" works like 95%, maybe less. some areas of just water are boxed off here to help 
      grow = false;
    } else if (xpos > width-area5 && ypos > height-area5) {
      grow = false;
    } else if (location <= 254) {
      grow = false;
    } else if (location == 255) {
      grow = true;
    }
  }

  void grow() {
    if (seedSize < maxSize && continueGrow && grow) {
      seedSize += growth;
      if (seedSize > maxSize/ reproSpeed) { //let tree its own seeds after it grows above a certain size
        makeChild();
      }
    }
  }
  
  void collide() {
    if (canCollide) {
     for (int i = 0; i < pods*seedsPerPod; i++) {
       float dx = others.get(i).xpos - xpos;
       float dy = others.get(i).ypos - ypos;
       float distance = sqrt(dx*dx + dy*dy);
       float minDist = others.get(i).seedSize/2 + seedSize/2;
       
       if (distance < minDist) { 
         if (others.get(i).seedSize > seedSize) { // do something if the trees collide, like make the smaller tree die, but this isn't being used any more. might still be useful though.
           collided = true;
         } 
       } 
     }   
    }
  }
  
  
  void makeChild () { //create next level seeds after a bit of growing has happened
      if (reproduce && !finished && img < trees.length) {
        //grow within 50 pixels of origin
         float randomX = random(xpos-50, xpos+50);
         float randomY = random(ypos-50, ypos+50);
         float randomSize = random(0.5, 1);
         float randomGrowth = random(0, 50);
         //60% chance it can grow
          if (randomGrowth > 20) {
            canGrow = true;
          } else {
            canGrow = false;
          }
          //if the object is grass, grow small shrubs. if shrubs, grow larger trees, etc
         if (img == 0) {
           smallPlants.add( new Seed(randomX, randomY, 1, 1, img+1, grass, 25, canGrow, 1.001, false) );
         } else if (img == 1) {
           biggerPlants.add( new Seed(randomX, randomY, 1, 1, img+1, grass, maxSize*1.5, canGrow, 1.001, false) );
         } else if (img == 2) {
           largePlants.add( new Seed(randomX, randomY, 1, 1, img+1, grass, maxSize*2, canGrow, 1.001, false) );
         }


         finished = true;
      }
  }
  
  void spawn () { //trees can also create clones of themselves, very similar to makeChild() accept it creates itself, not the next level
    if (seedSize > maxSize-10 && fertile && reproduce) {
      float newX = xpos + random(-50, 50);
      float newY = ypos + random (-50, 50);
      float randomSize = random(0, 0.3);
      float randomGrowth = random(0, 50);
      int max = 5;
      //60% chance of the seed growing
          if (randomGrowth > 20) {
            canGrow = true;
          } else {
            canGrow = false;
          }
      if (!isChild) { //switch between arraylists to avoid concurrent modification exception
        if (img == 1) {
          biggerPlants.add(new Seed(newX, newY, 0.5, id+1, img, grass, maxSize, false, 1.001, true) );
        } else if (img == 2) {
          largePlants.add(new Seed(newX, newY, 0.5, id+1, img, grass, maxSize, false, 1.001, true) );
        } else if (img == 3) {
          hardwoods.add(new Seed(newX, newY, 0.5, id+1, img, grass, maxSize, canGrow, 1.001, true) );
        }
      } else { //switch between arraylists to avoid concurrent modification exception
        if (img == 1 && id < max) {
          biggerPlantsOther.add(new Seed(newX, newY, 0.5, id+1, img, grass, maxSize, true, 1.001, false) );
        } else if (img == 2 && id < max) {
          largePlantsOther.add(new Seed(newX, newY, 0.5, id+1, img, grass, maxSize, true, 1.001, false) );
        } else if (img == 3 && id < max) {
          hardwoodsOther.add(new Seed(newX, newY, 0.5, id+1, img, grass, maxSize, canGrow, 1.001, false) );
        }
      }
      seedAmount ++;
      if (seedAmount > 1) { //only create children once. otherwise we get into a recursive loop with, like, tons of trees, and the whole thing crashes
        fertile = false;
      }
    }
  }
}
