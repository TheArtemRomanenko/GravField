ArrayList<Cell> massCoords;

ArrayList<Ball> ballList;
double G = 10;

Cell[][] grid;
int gridWidth;
int gridHeight;
int cellSize;
int massPaint = 4;

class Cell{
  boolean isMassy;
  int mass;
  int X;
  int Y;
  
  Cell(int X, int Y){
    isMassy = false;
    mass = 0;
    
    this.X = X;
    this.Y = Y;
  }
  
  //Cell(boolean isMassy, int mass){
  //  this.isMassy = isMassy;
  //  this.mass = mass;
  //}
  
  void change(){
    if(isMassy){
      mass = 0;
      
    } else{
      mass = massPaint;
    }
    isMassy = !isMassy;
  }
  
  int getMass(){
    return mass;
  }
}

void setup(){
  //frameRate(60);
  size(800,800);
  massCoords = new ArrayList<Cell>();
  ballList = new ArrayList<Ball>();
  cellSize = 20;
  
  gridWidth = width/cellSize;
  gridHeight = height/cellSize;
  
  grid = new Cell[gridHeight][gridWidth];
  for(int i = 0; i < gridHeight; i++){
    for(int j = 0; j < gridWidth; j++){
      grid[i][j] = new Cell(i,j);
    }
  }
}

class Ball{
  float pX; float pY;
  float vX = 0; float vY = 0;
  float aX = 0; float aY = 0;
  
  Ball(float pX, float pY, float vX, float vY){
    this.pX = pX; this.pY = pY;
    this.vX = vX; this.vY = vY;
  }
  
  void update(){
    pX += vX; pY += vY;
    vX -= aX; vY -= aY;
    float[] gravVector = getGravVector((int)pX,(int)pY);
    aX = gravVector[0];
    aY = gravVector[1];
    
    ellipseMode(RADIUS);
    ellipse(pX,pY,30,30);
  }
}

float[] ballStartCoords = new float[] {0,0}; //what's this?
void mouseReleased(){
  if(mouseButton == CENTER){
    float velocityScale = .01;
    ballList.add(new Ball(ballStartCoords[0], ballStartCoords[1], (mouseX - ballStartCoords[0]) * velocityScale, (mouseY - ballStartCoords[1]) * velocityScale));
  }
}

void mousePressed(){
  if(mouseButton == CENTER){
    ballStartCoords[0] = mouseX;
    ballStartCoords[1] = mouseY;
  }
}

void keyPressed(){
  if(key == 'r'){
    sigmoidFactor = 5;
    massPaint = 4;
    massCoords.clear();
    ballList.clear();
    for(int i = 0; i < gridHeight; i++){
      for(int j = 0; j < gridWidth; j++){
        grid[i][j].isMassy = false;
      }
    }
  }
}

void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  if(keyCode == SHIFT){
    if(e == -1){//scroll up
      sigmoidFactor *= 1.1;
    } else if(e == 1){//scroll down
      sigmoidFactor *= .9;
    }
  } else{
    if(e == -1){//add 1 to mass
      massPaint++;
    } else if(e == 1){//subtract 1 from mass
      if(massPaint > 4){
        massPaint--;
      }
    }
  }
}

float[] getGravVector(float startX, float startY){//SOMETHING ABOUT THIS METHOD IS VERY FISHY
  float Xacc = 0;
  float Yacc = 0;
  for(int i = 0 ; i < massCoords.size(); i++){
    float Magnitude;
    float theta;
    Cell currentCell = massCoords.get(i);
    float distX = (currentCell.X*cellSize + cellSize/2) - startX;

    float distY = (currentCell.Y*cellSize + cellSize/2) - startY;
    
    Magnitude = (float) G /sqrt(pow(distX,2) + pow(distY,2))*currentCell.getMass()/4;
    if(distX != 0){
      theta = atan(distY/distX);
      //println(degrees(theta));
      if(distX < 0){ //i chalk it up to trig bs inherent to the Math library
        Xacc += Magnitude*cos(theta);
        Yacc += Magnitude*sin(theta);
      } else{
        Xacc -= Magnitude*cos(theta);
        Yacc -= Magnitude*sin(theta);
      }
    } else{
      if(distY > 0){
        Yacc -= Magnitude;
      } else{
        Yacc += Magnitude;
      }

    }
  }
  return new float[] {Xacc,Yacc};
}

float getGravMag(int startX, int startY){
  float[] gravVector = getGravVector(startX,startY);
  return (pow(gravVector[0],2) + pow(gravVector[1],2));
}

void drawGravLine(float startX, float startY){
  float posX = startX;
  float posY = startY;
  
  int steps = 0;
  while(posX > 0 && posX < width && posY > 0 && posY < height && abs(getGravVector((float)posX,(float)posY)[0]) > .0001 && abs(getGravVector((float)posX,(float)posY)[1]) > .0001 && steps < 500){
    strokeWeight(1);
    stroke(color(0));
    float[] gravVector = getGravVector((int)posX,(int)posY);
    float gravMag = sqrt(pow(gravVector[0],2)+pow(gravVector[1],2));
    
    float gravLineStep = cellSize;
    float newPosX = posX+gravVector[0]*gravLineStep;
    float newPosY = posY+gravVector[1]*gravLineStep;
    
    line(posX,posY,newPosX,newPosY);
    
    posX = newPosX;
    posY = newPosY;
    steps++;
  }
}

float sigmoidFactor = 1;
void draw(){
  background(color(150));
  
  if(mouseX < gridWidth * cellSize && mouseX > 0 && mouseY < gridHeight * cellSize && mouseY > 0  && mousePressed){
    Cell cell = grid[mouseX/cellSize][mouseY/cellSize];
    if(!cell.isMassy && mouseButton == LEFT){
      massCoords.add(grid[mouseX/cellSize][mouseY/cellSize]);
      cell.change();
    }
    
    //if(mouseButton == RIGHT){
    //  drawGravLine(mouseX,mouseY);
    //}
  }

  //DRAW THE GRID, THIS SHOULD BE CLOSE TO THE BOTTOM !!!
  strokeWeight(1);
  stroke(color(0));
  for(int i = 0; i < gridHeight; i++){
    for(int j = 0; j < gridWidth; j++){
      if(grid[i][j].isMassy == false){//light cells
        strokeWeight(1);
        float shade = 255/PI * atan(sigmoidFactor*getGravMag(i*cellSize + cellSize/2,j*cellSize + cellSize/2));
        fill(color(255-shade,255-shade/2,255-shade));
        rect(i*cellSize,j*cellSize,cellSize,cellSize);
      }
    }
  }
  for(int i = 0; i < gridHeight; i++){
    for(int j = 0; j < gridWidth; j++){
      if(grid[i][j].isMassy == true){//dark cells with mass
        fill(color(50));
        rect(i*cellSize,j*cellSize,cellSize,cellSize);
        strokeWeight(1);
        if(keyPressed && key == ' '){
          int sub = grid[i][j].getMass();
          for(int k = 0; k < sub; k++){
            float theta = (k*2 + 1)*PI/sub;
            drawGravLine(cellSize*(i+.5) + cellSize/2*cos(theta), cellSize*(j+.5) + cellSize/2*sin(theta));
          }
        }
      }
    }
  }

  for(int i = 0; i < ballList.size(); i++){
    Ball ball = ballList.get(i);
    if(ball.pX >= height || ball.pX <= 0 || ball.pY >= width || ball.pY <= 0 ||grid[(int)ball.pX/cellSize][(int)ball.pY/cellSize].isMassy){
      ballList.remove(i);
      i--;
    }
    ball.update();
  }
  drawGravLine(mouseX,mouseY); //UN-COMMENT THIS WHEN YOU'RE DONE
  strokeWeight(15);
  stroke(color(0,50,0));
  if(!mousePressed){
    float[] gravVector = getGravVector(mouseX,mouseY);
    float scale = sigmoidFactor*30;
    line(mouseX,mouseY,mouseX-gravVector[0]*scale,mouseY-gravVector[1]*scale);
    strokeWeight(10);
    stroke(color(200,20,20));
    line(mouseX,mouseY,mouseX,mouseY);
  }
  
  textSize(cellSize);
  fill(0, 0, 0);
  text("sigmoid factor: "+sigmoidFactor,0,cellSize);
  text("mass paint: "+massPaint,0,2*cellSize);
  text("hold space to draw gravity lines",0,3*cellSize);
  text("press r to reset",0,4*cellSize);
}