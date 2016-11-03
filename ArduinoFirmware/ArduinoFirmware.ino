const int RED = 6;
const int GREEN = 3;
const int BLUE = 9;
int oldR;
int oldG;
int oldB;
extern const uint8_t gamma8[];

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
                analogWrite(RED, correctGamma(r, offThreshold));
                analogWrite(GREEN, correctGamma(g, offThreshold));
                analogWrite(BLUE, correctGamma(b, offThreshold));
                oldR = r;
                oldG = g;
                oldB = b;
        }
    }
}

int correctGamma(int input, int offThreshold){
    return pgm_read_byte(&gamma8[input > offThreshold ? input : 0]);
}

const uint8_t PROGMEM gamma8[] = {
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  1,  1,  1,  1,
    1,  1,  1,  1,  1,  1,  1,  1,  1,  2,  2,  2,  2,  2,  2,  2,
    2,  3,  3,  3,  3,  3,  3,  3,  4,  4,  4,  4,  4,  5,  5,  5,
    5,  6,  6,  6,  6,  7,  7,  7,  7,  8,  8,  8,  9,  9,  9, 10,
   10, 10, 11, 11, 11, 12, 12, 13, 13, 13, 14, 14, 15, 15, 16, 16,
   17, 17, 18, 18, 19, 19, 20, 20, 21, 21, 22, 22, 23, 24, 24, 25,
   25, 26, 27, 27, 28, 29, 29, 30, 31, 32, 32, 33, 34, 35, 35, 36,
   37, 38, 39, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 50,
   51, 52, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 66, 67, 68,
   69, 70, 72, 73, 74, 75, 77, 78, 79, 81, 82, 83, 85, 86, 87, 89,
   90, 92, 93, 95, 96, 98, 99,101,102,104,105,107,109,110,112,114,
  115,117,119,120,122,124,126,127,129,131,133,135,137,138,140,142,
  144,146,148,150,152,154,156,158,160,162,164,167,169,171,173,175,
  177,180,182,184,186,189,191,193,196,198,200,203,205,208,210,213,
  215,218,220,223,225,228,231,233,236,239,241,244,247,249,252,255 };