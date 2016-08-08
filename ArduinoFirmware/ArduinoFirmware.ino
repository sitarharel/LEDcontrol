const int RED = 6;
const int GREEN = 3;
const int BLUE = 9;
int oldR;
int oldG;
int oldB;


void setup() {
  // initialize the serial communication:
  Serial.begin(57600);
  // initialize the ledPin as an output:
  pinMode(RED, OUTPUT);
  pinMode(GREEN, OUTPUT);
  pinMode(BLUE, OUTPUT);
  oldR = 0;
  oldG = 0;
  oldB = 0;
}

void loop() {
    int8_t input[3];

  // check if data has been sent from the computer:
  if (Serial.available()) {
      // read the most recent byte (which will be from -128 to 127):
    Serial.readBytes((char*) input, 3);
    // set the brightness of the LEDs:
    int offThreshold = 0;
    int changeThreshold = 1;
    int r = ((int) input[0]) + 128;
    int g = ((int) input[1]) + 128;
    int b = ((int) input[2]) + 128;
    if(r > oldR + changeThreshold || r < oldR - changeThreshold ||
        g > oldG + changeThreshold || g < oldG - changeThreshold ||
        b > oldB + changeThreshold || b < oldB - changeThreshold ){
        analogWrite(RED, r > offThreshold ? r : 0);
        analogWrite(GREEN, g > offThreshold ? g : 0);
        analogWrite(BLUE, b > offThreshold ? b : 0);
        oldR = r;
        oldG = g;
        oldB = b;
    }else{
        analogWrite(RED, 0);
        analogWrite(GREEN, 0);
        analogWrite(BLUE, 0);
    }
    // Serial.print("r: ");
    //  Serial.print(r);
    //  Serial.print(" old r: ");
    //  Serial.println(oldR);
    // Serial.print("g: ");
    //  Serial.print(g);
    //  Serial.print(" old g: ");
    //  Serial.println(oldG);
    // Serial.print("b: ");
    //  Serial.print(b);
    //  Serial.print(" old b: ");
    //  Serial.println(oldB);
  }
}
