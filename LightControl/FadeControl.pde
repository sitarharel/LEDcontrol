class FadeControl {
    int fadenum = 0;
    int fdelay = 12;

    int[] currentfade = {0, 255, 0};
    boolean settings_changed = true;
    float fadespeed = 12.0;

    FadeControl() {
        fadespeed = (float) fdelay;
    }

    int[] doFadeControl() {
        fdelay = (int) fadespeed;
        return fadeCoded(fdelay);
    }

    void setFadeSpeed(float speed) {
        fadespeed = speed;
    }

    float getFadeSpeed() {
        return fadespeed;
    }

    int[] fadeCoded(int d) {
        //int[][] f = {{1, -1, 0},{-1, 0, 1},{1, 1, -1},{-1, -1, 1},{0, 1, -1},{1, -1, 1},{-1, 1, -1}};
        //this is an encoding of the fade order
        int[][] f = {{0, 1, 0}, {-1, 0, 0}, {0, 0, 1}, {0, -1, 0}, {1, 0, 0}, {0, 0, -1}};
        currentfade = getNextFade(currentfade, f[fadenum][0], f[fadenum][1], f[fadenum][2]);
        int rq = (int) (constrain(currentfade[0], 0, 255) * dim * (1 - white) + 255 * white * dim);
        int gq = (int) (constrain(currentfade[1], 0, 255) * dim * (1 - white) + 255 * white * dim);
        int bq = (int) (constrain(currentfade[2], 0, 255) * dim * (1 - white) + 255 * white * dim);
        int[] ret = {rq, gq, bq};
        delay(d);
        if (currentfade[0] < 0 || currentfade[0] > 255 || currentfade[1] < 0 || currentfade[1] > 255 || currentfade[2] < 0 || currentfade[2] > 255) {
            currentfade[0] = constrain(currentfade[0], 0, 255);
            currentfade[1] = constrain(currentfade[1], 0, 255);
            currentfade[2] = constrain(currentfade[2], 0, 255);
            fadenum = (fadenum + 1) % f.length;
        }
        return ret;
    }
    
    int[] getNextFade(int[] c, int r, int g, int b) {
        //int[] f = {c[0] + r * 5, c[1] + g * 5, c[2] + b * 5};
        float m = 0.0004, space = 1, exp = 2;
        float con = (m*pow(127.5, exp) + space);
        int[] f = {(int)(c[0] + r * (-1*m*pow(c[0] - 127.5, exp) + con)), (int)(c[1] + g * (-1*m*pow(c[1] - 127.5, exp) + con)), (int)(c[2] + b * (-1*m*pow(c[2] - 127.5, exp) + con))}; 


        //float m = 0.0004, space = 1, exp = 2;
        //float con = (m*pow(127.5, exp) + space);
        //con = 4000;
        //int[] f = {(int)(c[0] + r * 0.001 * (-1*0.00001*pow(c[0] - 127.5, 4) -0.0001*pow(c[0] - 127.5, 2)  + con)), 
        //           (int)(c[1] + g * 0.001 * (-1*0.00001*pow(c[0] - 127.5, 4) -0.0001*pow(c[0] - 127.5, 2)  + con)),
        //           (int)(c[2] + b * 0.001 * (-1*0.00001*pow(c[0] - 127.5, 4) -0.0001*pow(c[0] - 127.5, 2)  + con))}; 
        // this is a smoother, quadratic fade compared to the linear, first line of this method
        //TODO make a switch for the fade mode to select fade type
        return f;
    }
}