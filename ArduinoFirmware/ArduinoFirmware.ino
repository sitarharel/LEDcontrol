
const int RED = 6;
const int GREEN = 3;
const int BLUE = 9;

void setup() {
  // initialize the serial communication:
  Serial.begin(57600);
  // initialize the ledPin as an output:
  pinMode(RED, OUTPUT);
  pinMode(GREEN, OUTPUT);
  pinMode(BLUE, OUTPUT);
}

void loop() {
    byte input[3];

  // check if data has been sent from the computer:
  if (Serial.available()) {
      // read the most recent byte (which will be from -128 to 127):
    Serial.readBytes(input, 3);
    // set the brightness of the LEDs:
    int offThreshold = -128;
    if(input[0] <= offThreshold && input[1] <= offThreshold && input[2] <= offThreshold){
      analogWrite(RED, 0);
      analogWrite(GREEN, 0);
      analogWrite(BLUE, 0);
    }else{
      analogWrite(RED, input[0] + 128);
      analogWrite(GREEN, input[1] + 128);
      analogWrite(BLUE, input[2] + 128);
    }
  }
}
