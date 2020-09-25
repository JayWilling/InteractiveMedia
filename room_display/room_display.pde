// Structure of the code is very similar if not the same as the particle system examples included with Processing.

import java.util.LinkedList;
import java.util.Queue;

boolean changing = false;
String[] sensorList = {"PC00.05", "PC00.06", "PC00.07", "PC00.08", "PC00.09", "PC01.11", "PC01.12", "PC01.13", "PC02.14"};
String currentSensor;
Table peopleCounterIn; //http://eif-research.feit.uts.edu.au/api/csv/?rFromDate=2020-09-09T19%3A58%3A06&rToDate=2020-09-13T19%3A58%3A06&rFamily=people&rSensor=+PC00.05+%28In%29
Table peopleCounterOut; //http://eif-research.feit.uts.edu.au/api/csv/?rFromDate=2020-09-09T19%3A58%3A06&rToDate=2020-09-13T19%3A58%3A06&rFamily=people&rSensor=+PC00.05+%28Out%29
String[] dateTime;
String[] initialTime;
int[] clock = {0, 0, 0};
int offset = 0;

Room room;

void setup() {
  size(1000, 1000);
  
  peopleCounterIn = loadTable("http://eif-research.feit.uts.edu.au/api/csv/?rFromDate=2020-09-09T19%3A58%3A06&rToDate=2020-09-13T19%3A58%3A06&rFamily=people&rSensor=+PC00.05+%28In%29", "csv");
  peopleCounterOut = loadTable("http://eif-research.feit.uts.edu.au/api/csv/?rFromDate=2020-09-09T19%3A58%3A06&rToDate=2020-09-13T19%3A58%3A06&rFamily=people&rSensor=+PC00.05+%28Out%29", "csv");
  currentSensor = "PC00.05";
  
  room = new Room();
  for (int i = 0; i < peopleCounterIn.getInt(0, 1); i++) {
    room.addPerson();
  }
  dateTime = peopleCounterIn.getString(0, 0).toString().split(" ");
  initialTime = dateTime[1].split(":"); // now of the form {hh, mm, ss}
  //print(initialTime[0]);
  clock[0] = Integer.parseInt(initialTime[0]);
  clock[1] = Integer.parseInt(initialTime[1]);
  clock[2] = Integer.parseInt(initialTime[2]);
}

// Examining the counter data, the sensors take a reading every 30 minutes
// If we assume the framerate runs at 60fps, then the timer will count each second in 60 second incremenets.
// As a default/baseline, we will pull a new data point from the people coutner data every 10 seconds at
// which point the counter will reset and start again. (when the timer has a value of 600)
int timer = 0;
int counterIndex = 1; // This increments every time the timer goes back to 0. It will track our place in the people counter data
int addPeople = 10; // We will initialise the people count variables with arbitrary values since we can assume there are already people in the 'room'
int removePeople = 0;



void draw() {
  if (changing && offset >= -40 && offset < 0) {
    offset = 0;
    changing = false;
  } else if (changing && offset <= width) {
    translate(offset, 0);
    offset += 20;
  
  } else if (changing && offset > width) {
    offset *= -1;
    translate(offset, 0);
  }
  
  if (clock[0] >= 24) {
    clock[0] = 0;
  }
  if(clock[1] >= 60) {
    clock[1] = 0;
    clock[0]++;
  }
  if(clock[2] >= 60) {
    clock[2] = 0;
    clock[1]++;
  }
  clock[2] += 3;
  background(255, 255, 255);
  fill(50);
  textSize(32);
  text("People: " + room.getSize(), 50, 50);
  text("Time: " + clock[0] + ":" + clock[1] + ":" + clock[2], 50, 100);
  text("Sensor: " + currentSensor, width - 300, 50);
  text("To change sensors, press a number 1 - 9 on your keyboard.", 50, height - 50);
  fill(255);
  if(timer < 600) {
    timer++;
  } else {
    timer = 0;
    int addPeople = peopleCounterIn.getInt(counterIndex, 1);
    int removePeople = peopleCounterOut.getInt(counterIndex, 1);
    System.out.println(addPeople);
    System.out.println(removePeople);
    //int addPeople = 5;
    //int removePeople = 10;
    if (room.getSize() - removePeople <= 0) { // We do not want to have a negative number of people in the room;
      removePeople = room.getSize();
    }
    System.out.println(removePeople);
    System.out.println("");
    
    
    for (int i = 0; i <= addPeople; i++) {
      room.addPerson();
    }
    for (int i = 0; i <= removePeople; i++) {
      room.removePerson();
    }
    System.out.println("");
    counterIndex++;
  }
  room.run();
}

class Room { // Used to draw out the room for a given dataset
  LinkedList<Person> attendanceList; // I have used an array list to represent the attendance list, however a queue may be required instead.
  // We need a data type that allows us to remove the oldest element (without creating empty spaces) whilst also being able to index the elements so each person can be drawn.
  int roomWidth;
  int roomHeight;
  int doorWidth;
  //int[] roomOrigin = {0, 0};
  LinkedList<int[]> walls; // This will be passed to each person of the room, letting them know when they have collided with a wall
  // Providing each person with three goal locations (Entrance doorway, room centre, and exit doorway) saves us requiring a path finding algorithm
  PVector roomCentre;
  PVector entrance;
  PVector exit;
  PVector xRange;
  PVector yRange;
  
  Room() {
    roomWidth = 2 * width / 3;
    roomHeight = 3 * height / 4;
    doorWidth = roomHeight / 4;
    roomCentre = new PVector(width/2, height/2);
    entrance = new PVector((width - roomWidth) / 2,(height - doorWidth) / 2 + (height - roomHeight) / 2 + doorWidth/2);
    exit = new PVector((width - roomWidth) / 2 + roomWidth,(height - doorWidth) / 2 + (height - roomHeight) / 2 + doorWidth/2);
    // Above values have not been set with having multiple rooms in mind yet.
    // Just for the purpose of having something displayed on the screen.
    
    xRange = new PVector((width - roomWidth) / 2, (width - roomWidth) / 2 + roomWidth);
    yRange = new PVector((height - roomHeight) / 2, (height - roomHeight) / 2 + roomHeight);
    
    walls = new LinkedList<int[]>();
    attendanceList = new LinkedList<Person>();
  }
  
  // Imagine this function as checking the attendance. If there are people in the room, we render there position
  // If a person is no longer in the room, we remove them from the list.
  void run() {
    render();
    
    for (int i = attendanceList.size()-1; i >= 0; i--) {
      Person p = attendanceList.get(i);
      p.run(attendanceList);
      if (p.hasLeft()) {
        attendanceList.remove(p);
      }
    }
  }
  
  void render() {
    strokeWeight(3);
    beginShape(LINES);
    // Top Wall
    //int[] topWall = {(width - roomWidth) / 2, (height - roomHeight) / 2, (width - roomWidth) / 2 + roomWidth, (height - roomHeight) / 2};
    //walls.add(topWall);
    vertex(xRange.x, yRange.x); // Upper left
    vertex((width - roomWidth) / 2 + roomWidth, (height - roomHeight) / 2); // Upper right
    // Left Wall
    vertex((width - roomWidth) / 2, (height - roomHeight) / 2);
    vertex((width - roomWidth) / 2, (height - doorWidth) / 2 + (height - roomHeight) / 2);
    vertex((width - roomWidth) / 2, (height - doorWidth) / 2 + (height - roomHeight) / 2 + doorWidth);
    vertex((width - roomWidth) / 2,(height - roomHeight) / 2 + roomHeight);
    // Right Wall
    vertex((width - roomWidth) / 2 + roomWidth, (height - roomHeight) / 2);
    vertex((width - roomWidth) / 2 + roomWidth, (height - doorWidth) / 2 + (height - roomHeight) / 2);
    vertex((width - roomWidth) / 2 + roomWidth, (height - doorWidth) / 2 + (height - roomHeight) / 2 + doorWidth);
    vertex((width - roomWidth) / 2 + roomWidth,(height - roomHeight) / 2 + roomHeight);
    // Bottom Wall
    vertex((width - roomWidth) / 2, (height - roomHeight) / 2 + roomHeight); // Lower left
    vertex(xRange.y, yRange.y); // Lower right
    endShape();
    
    //classroom picture
    if (mouseX >= ((width - roomWidth) / 2) && mouseX <= ((width - roomWidth) / 2 + roomWidth) &&
        mouseY >= ((height - roomHeight) / 2) && mouseY <= ((height - roomHeight) / 2 + roomHeight)){
      PImage img = loadImage("classroom.jpg");
      image(img, (width - roomWidth) / 2, (height - roomHeight) / 2, roomWidth, roomHeight);
    }
    
  }
  
  void addPerson() {
    //int[][] goals = {entrance, roomCentre, exit}
    LinkedList<PVector> goals = new LinkedList<PVector>();
    PVector roomGoal = new PVector(random(xRange.x, xRange.y), random(yRange.x, yRange.y));
    goals.add(entrance);
    goals.add(roomGoal);
    goals.add(exit);
    goals.add(new PVector(width + 100, random(0, height)));
    attendanceList.add(new Person(goals));
    // Should not need more done if the Person constructor is set correctly
  }
  
  // This function essentially tells the person to leave the room
  void removePerson() {
    for (int i = 0; i <= attendanceList.size(); i++) {
      // Finding the next person in the list to be removed from the room
      Person p = attendanceList.get(i);
      if (p.goalState != 2) {
        p.goalState = 2;
        System.out.println("leaving");
        break;
      } else if(p.hasLeft) {
        attendanceList.remove(i);
      }
    }
  }
  
  // Self explanatory
  int getSize() {
    return attendanceList.size();
  }
  
}

public class Person { // Person has a goal location, current location, and time to live (ttl). ttl is a default count value to prevent people from getting stuck on objects.
// ttl should count down when people don't move for a time and 'isLeaving' is true. The boolean "isLeaving" changes when the person has been kicked from the room.
  LinkedList<PVector> goal;
  
  int goalState = 0; // potential values are 0, 1 and 2, denoting which goal in the 'goal' array we are approaching.
  PVector location;
  int ttl;
  int personWidth;
  float m;
  boolean isLeaving;
  boolean hasLeft;
  
  PVector velocity;
  PVector acceleration;
  
  float maxforce; // Maximum steering force
  float maxspeed; // Maximum speed
  
  // Variables for interactive features
  boolean clicked;
  
  Person(LinkedList<PVector> goals) {
    goal = goals;
    location = new PVector(-personWidth, random(0, 1000));
    isLeaving = false;
    hasLeft = false;
    personWidth = 30;
    m = personWidth*.5;
    
    velocity = new PVector(0, 0);
    acceleration = new PVector(0, 0);
    
    maxspeed = 1;
    maxforce = 0.03;
  }
  
  void run(LinkedList<Person> attendanceList) {
    if (!clicked) {
      crowd(attendanceList);
      update();
    } else if (!mousePressed){
      clicked = false;
    } else {
      location.x = mouseX;
      location.y = mouseY;
    }
    render();
  }
  
  // Here we check the persons motion and update their position
  // This would also be used when changing colours, size, or other parameters depending on more data if we add it in.
  void update() {
    if (location.x > width) {hasLeft = true;}
    if (!clicked) {
      velocity.add(acceleration);
      velocity.limit(maxspeed);
      location.add(velocity);
      acceleration.mult(0);
    }
    
    
    
  }
  
  // For ease of reference this function is called 'crowd', and is in essence the same as a 'flock' function.
  // This way from the update function we can look at interactions the person has with the 'crowd' or surrounding environment
  void crowd(LinkedList<Person> attendanceList) {
    PVector col = new PVector(0, 0);
    PVector pat = new PVector(0, 0);
    
    // goalState 3 is used to signify that the person has reached the exit and no longer needs to make it's way towards a goal
    // We just make goalState 3 a goal off-screen.
    pat = pathFinding(attendanceList);
    pat.mult(2.0);
    
    col = collisions(attendanceList);
    col.mult(2.0);
    
    applyForce(col);
    applyForce(pat);
  }
  
  // This function determines where the person needs to go to avoid colliding with the walls of the room
  // It will not consider the positions of other people however. (If we do want it to consider avoiding
  // other people, we just implement the flocking code provided in other examples).
  // I have added the attendanceList as a parameter in-case we do want some people avoidance going on too.
  PVector pathFinding(LinkedList<Person> attendanceList) {
    if (location.y <= goal.get(goalState).y + 20 && location.y >= goal.get(goalState).y - 20 && goalState < 1) {
      goalState++;
    } else if (goalState == 2 && location.y <= goal.get(goalState).y + 20 && location.y >= goal.get(goalState).y - 20) {
      goalState = 3;
    }
    PVector desired = PVector.sub(goal.get(goalState), location);  // A vector pointing from the position to the target
    // Scale to maximum speed
    desired.normalize();
    desired.mult(maxspeed);

    // Above two lines of code below could be condensed with new PVector setMag() method
    // Not using this method until Processing.js catches up
    // desired.setMag(maxspeed);

    // Steering = Desired minus Velocity
    PVector steer = PVector.sub(desired, velocity);
    steer.limit(maxforce);  // Limit to maximum steering force
    return steer;
  }
  
  void applyForce(PVector force) {
    // We could add mass here if we want A = F / M
    acceleration.add(force);
  }
  
  
  PVector collisions(LinkedList<Person> attendanceList) {
    // Check if a person is colliding with another. If they are 'turn' them away slightly.
    // This will not [should not] override the main velocity towards the goal location.
    float desiredseparation = 5.0f;
    PVector steer = new PVector(0, 0, 0);
    int count = 0;
    
    for (Person p : attendanceList) {
      checkCollisionWall();
      checkCollisionPerson(p);
      float d = PVector.dist(location, p.location);
      // If the distance is greater than 0 and less than an arbitrary amount (0 when you are yourself)
      if ((d > 0) && (d < desiredseparation)) {
        // Calculate vector pointing away from neighbor
        PVector diff = PVector.sub(location, p.location);
        diff.normalize();
        diff.div(d);        // Weight by distance
        steer.add(diff);
        count++;            // Keep track of how many
      }
    }
    // Average -- divide by how many
    if (count > 0) {
      steer.div((float)count);
    }

    // As long as the vector is greater than 0
    if (steer.mag() > 0) {
      // First two lines of code below could be condensed with new PVector setMag() method
      // Not using this method until Processing.js catches up
      // steer.setMag(maxspeed);

      // Implement Reynolds: Steering = Desired - Velocity
      steer.normalize();
      steer.mult(maxspeed);
      steer.sub(velocity);
      steer.limit(maxforce);
    }
    return steer;
  }
  
  // Much simpler than checking for a collision with another person.
  // The velocity just needs to be multiplied by minus 1
  void checkCollisionWall() {
    // Check if the person has collided with the upper wall
    //if (location.x ) {
    //}
  }
  
  void checkCollisionPerson(Person other) {

    // Get distances between the balls components
    PVector distanceVect = PVector.sub(other.location, location);

    // Calculate magnitude of the vector separating the balls
    float distanceVectMag = distanceVect.mag();

    // Minimum distance before they are touching
    float minDistance = personWidth/2 + other.personWidth/2;

    if (distanceVectMag < minDistance) {
      float distanceCorrection = (minDistance-distanceVectMag)/2.0;
      PVector d = distanceVect.copy();
      PVector correctionVector = d.normalize().mult(distanceCorrection);
      other.location.add(correctionVector);
      location.sub(correctionVector);

      // get angle of distanceVect
      float theta  = distanceVect.heading();
      // precalculate trig values
      float sine = sin(theta);
      float cosine = cos(theta);

      /* bTemp will hold rotated ball positions. You 
       just need to worry about bTemp[1] position*/
      PVector[] bTemp = {
        new PVector(), new PVector()
      };

      /* this ball's position is relative to the other
       so you can use the vector between them (bVect) as the 
       reference point in the rotation expressions.
       bTemp[0].position.x and bTemp[0].position.y will initialize
       automatically to 0.0, which is what you want
       since b[1] will rotate around b[0] */
      bTemp[1].x  = cosine * distanceVect.x + sine * distanceVect.y;
      bTemp[1].y  = cosine * distanceVect.y - sine * distanceVect.x;

      // rotate Temporary velocities
      PVector[] vTemp = {
        new PVector(), new PVector()
      };

      vTemp[0].x  = cosine * velocity.x + sine * velocity.y;
      vTemp[0].y  = cosine * velocity.y - sine * velocity.x;
      vTemp[1].x  = cosine * other.velocity.x + sine * other.velocity.y;
      vTemp[1].y  = cosine * other.velocity.y - sine * other.velocity.x;

      /* Now that velocities are rotated, you can use 1D
       conservation of momentum equations to calculate 
       the final velocity along the x-axis. */
      PVector[] vFinal = {  
        new PVector(), new PVector()
      };

      // final rotated velocity for b[0]
      vFinal[0].x = ((m - other.m) * vTemp[0].x + 2 * other.m * vTemp[1].x) / (m + other.m);
      vFinal[0].y = vTemp[0].y;

      // final rotated velocity for b[1]
      vFinal[1].x = ((other.m - m) * vTemp[1].x + 2 * m * vTemp[0].x) / (m + other.m);
      vFinal[1].y = vTemp[1].y;

      // hack to avoid clumping
      bTemp[0].x += vFinal[0].x;
      bTemp[1].x += vFinal[1].x;

      /* Rotate ball positions and velocities back
       Reverse signs in trig expressions to rotate 
       in the opposite direction */
      // rotate balls
      PVector[] bFinal = { 
        new PVector(), new PVector()
      };
      
      bFinal[0].x = cosine * bTemp[0].x - sine * bTemp[0].y;
      bFinal[0].y = cosine * bTemp[0].y + sine * bTemp[0].x;
      bFinal[1].x = cosine * bTemp[1].x - sine * bTemp[1].y;
      bFinal[1].y = cosine * bTemp[1].y + sine * bTemp[1].x;
      
      // update balls to screen position
      other.location.x = location.x + bFinal[1].x;
      other.location.y = location.y + bFinal[1].y;
      

      location.add(bFinal[0]);

      // update velocities
      if (velocity.x < maxspeed) {
        velocity.x = cosine * vFinal[0].x - sine * vFinal[0].y;
      } else {velocity.x = maxspeed;}
      if (velocity.y < maxspeed) {
        velocity.y = cosine * vFinal[0].y + sine * vFinal[0].x;
      } else {velocity.y = maxspeed;}
      
      if (other.velocity.x < maxspeed) {
        other.velocity.x = cosine * vFinal[1].x - sine * vFinal[1].y;
      } else {velocity.x = maxspeed;}
      if (other.velocity.y < maxspeed) {
        other.velocity.y = cosine * vFinal[1].y + sine * vFinal[1].x;
      } else {velocity.y = maxspeed;}
    }
  }
  
  // Where we draw the circle to represent the person
  void render() {
    circle(location.x, location.y, personWidth);
  }
  
  void setIsLeaving() {
    goalState = 2;
  }
  
  void setHasLeft() {
    hasLeft = true;
  }
  
  boolean hasLeft() {
    return hasLeft;
  }
}

void mousePressed() {
  for (Person p: room.attendanceList) {
    if (mouseX <= p.location.x + p.personWidth && mouseX >= p.location.x - p.personWidth && mouseY <= p.location.y + p.personWidth && mouseY >= p.location.y - p.personWidth) {
      p.clicked = true;
    }
  }
}

void keyPressed() {
  if (key == '1' || key == '2' || key == '3' || key == '4' || key == '5' || key == '6' || key == '7' || key == '8' || key == '9') {
    changing = true;
    currentSensor = sensorList[Character.getNumericValue(key) - 1];
    peopleCounterIn = loadTable("http://eif-research.feit.uts.edu.au/api/csv/?rFromDate=2020-09-09T19%3A58%3A06&rToDate=2020-09-13T19%3A58%3A06&rFamily=people&rSensor=+" + currentSensor + "+%28In%29", "csv");
    peopleCounterOut = loadTable("http://eif-research.feit.uts.edu.au/api/csv/?rFromDate=2020-09-09T19%3A58%3A06&rToDate=2020-09-13T19%3A58%3A06&rFamily=people&rSensor=+" + currentSensor + "+%28Out%29", "csv");
  }
}
