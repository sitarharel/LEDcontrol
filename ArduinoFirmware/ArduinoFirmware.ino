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
    int8_t input[3];

  // check if data has been sent from the computer:
  if (Serial.available()) {
      // read the most recent byte (which will be from -128 to 127):
    Serial.readBytes((char*) input, 3);
    // set the brightness of the LEDs:
    int offThreshold = 0;
    int r = ((int) input[0]) + 128;
    int g = ((int) input[1]) + 128;
    int b = ((int) input[2]) + 128;
    analogWrite(RED, r > offThreshold ? r : 0);
    analogWrite(GREEN, g > offThreshold ? g : 0);
    analogWrite(BLUE, b > offThreshold ? b : 0);
  }
}
