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

        // for pins 5 & 6:
    TCCR0B = TCCR0B & B11111000 | B00000010;
    // set timer 0 divisor to 8 for PWM frequency of  7812.50 Hz
        // for pins 9 & 10:
    TCCR1B = TCCR1B & B11111000 | B00000010;
    // set timer 1 divisor to     8 for PWM frequency of  3921.16 Hz
        // for pins 3 & 11:
    TCCR2B = TCCR2B & B11111000 | B00000010;
    // set timer 2 divisor to     8 for PWM frequency of  3921.16 Hz

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
            }
        }
    }
