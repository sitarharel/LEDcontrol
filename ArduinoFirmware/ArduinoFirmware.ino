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
      // read the most recent byte (which will be from 0 to 255):
    Serial.readBytes(input, 3);
    // set the brightness of the LED:
    analogWrite(RED, input[0] + 128);
    analogWrite(GREEN, input[1] + 128);
    analogWrite(BLUE, input[2] + 128);
  }
}
