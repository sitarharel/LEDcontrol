// Generate an LED gamma-correction table for Arduino sketches.

float gamma   = 2.2; // Correction factor
int   max_in  = 255, // Top end of INPUT range
      max_out = 255; // Top end of OUTPUT range
 
void setup() {
  print("const uint8_t PROGMEM gamma[] = {");
  for(int i=0; i<=max_in; i++) {
    if(i > 0) print(',');
    if((i & 15) == 0) print("\n  ");
    System.out.format("%3d",
      (int)(pow((float)i / (float)max_in, gamma) * max_out + 0.5));
  }
  println(" };");
  exit();
}