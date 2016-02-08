import processing.serial.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import cc.arduino.*;

    Minim  minim;
    AudioInput song;
    Arduino arduino;
     Serial port;
 
    int GREEN = 3;
    int RED = 6;
    int BLUE = 9;

    float osl = 0, osm = 0, osh = 0;
    int state = 1;

    float kickSize, snareSize, hatSize;
    FFT fft;
    float[][] specs = new float[4][10];
    int index = 0;
    float rpusher = 100, rpv = 0;
    float gpusher = 100, gpv = 0;
    float bpusher = 100, bpv = 0;
    float max = 0;
    int fadenum = 0;
    int[] currentfade = {0, 255, 0};
    int[] oldRGBoutput = {0, 0, 0};
    float[][] fftavgs = new float[3][100];
    int fahindex = -1;
    

    boolean isarduino = true;
    int fadetype;
    float dimness = 1; //scale of 0 to 1
    float partswhite = 0; //scale of 0 to 1 for how much is just white (1 is all white, 0 is all music visualisztion)
    float powV = 3;
    float maxvel = 0.3;
    float ref = 1.15;
    int avgamount = 15;
    int fdelay = 12;
    bar rbar, gbar, bbar, power, dim, white, refresh, maxv, fadespeed, smooth;
    flip stat;

    void settings() {
        size(1500, 800, P3D);
        //fullScreen();
    }

    void setup() {
        //frameRate(60);
        surface.setResizable(true);
        minim = new Minim(this);
        
        if (Arduino.list().length > 0) {
             port = new Serial(this, Serial.list()[0], 57600);
             
        } else {
            isarduino = false;
        }
        
        song = minim.getLineIn();
        song.enableMonitoring();
        song.mute();
        fft = new FFT(song.bufferSize(), 2048);

        for (int j = 0; j < specs.length; j++) {
            for (int i = 0; i < specs[0].length; i++) {
                specs[j][i] = 0;
            }
        }

        power = new bar("contrast", 200, new PVector(0, 5), powV);
        dim = new bar("intensity", 125, new PVector(0, 1), dimness);
        white = new bar("white", 50, new PVector(0, 1), partswhite);
        refresh = new bar("refresh", 350, new PVector(0, 3), ref);
        maxv = new bar("max", 275, new PVector(0, 1), maxvel);
        fadespeed = new bar("speed", 200, new PVector(0, 100), fdelay);
        smooth = new bar("smooth", 425, new PVector(1, 100), avgamount);
        
        rbar = new bar("red", 350, new PVector(0, 255), 255);
        gbar = new bar("green", 275, new PVector(0, 255), 255);
        bbar = new bar("blue", 200, new PVector(0, 255), 255);

        String[] p = {"music", "fade", "static"};
        stat = new flip("state", (width - (p.length * 80)) / 2, 20, p, state);
    }

    void draw() {

        background(0);
        fft.forward(song.mix);
        if (state == 1) {
            musicVis();
            power.draw(0, 0, 255);
            powV = power.val;
            maxv.draw(0, 200, 255);
            maxvel = maxv.val;
            refresh.draw(0, 255, 0);
            ref = refresh.val;
            smooth.draw(255, 200, 0);
            avgamount = (int) smooth.val;
        } else if (state == 2) {
            fadeCoded(fdelay);
            fadespeed.draw(0, 0, 255);
            fdelay = (int) fadespeed.val;
        } else if (state == 3) {
            int rq = (int) (constrain(rbar.val, 0, 255) * dimness * (1 - partswhite) + 255 * partswhite * dimness);
            int gq = (int) (constrain(gbar.val, 0, 255) * dimness * (1 - partswhite) + 255 * partswhite * dimness);
            int bq = (int) (constrain(bbar.val, 0, 255) * dimness * (1 - partswhite) + 255 * partswhite * dimness);
            outputToArduino(rq, gq, bq);
            rbar.draw(255, 0, 0);
            gbar.draw(0, 255, 0);
            bbar.draw(0, 0, 255);

        }
        white.draw(255, 255, 255);
        partswhite = white.val;
        dim.draw(255, 0, 255);
        dimness = dim.val;

        stat.draw(0, 0, 255);
        state = stat.val + 1;
        if (!isarduino && Arduino.list().length > 0) {
             port = new Serial(this, Serial.list()[0], 57600);
            isarduino = true;
        }
        if (isarduino && Arduino.list().length == 0) {
            isarduino = false;
        }

    }

    void drawAvg(int detail, float specpercent, boolean push) {
        stroke(0, 0, 255, 200);
        fill(0, 0, 255, 18);
        float specsize = fft.specSize() * specpercent;
        float[] vals = new float[detail - 1];
        for (int i = 0; i < detail - 1; i++) {
            vals[i] = 0;
        }
        double mult = 1.0 / ((double) vals.length);
        fahindex += 1;
        if(fahindex >= fftavgs[0].length) fahindex = 0;
        for (int i = 0; i < detail - 1; i++) {
            double r = (i + 1) * mult * specsize;
            double l = i * mult * specsize;
            for (int j = (int) (l); j < (int) (r); j++) {
                vals[i] += sqrt(fft.getBand(j)) * 0.001 * detail * detail * 0.5 / specpercent;
            }
            vals[i] *= r - l;
            if (push && i < 3) {
             fftavgs[i][fahindex] = vals[i];
             vals[i] = avglast(fftavgs[i], avgamount);
                if (vals[i] > max) max = vals[i];
                if (i == 0) {
                    if (vals[i] > rpusher) rpv = (vals[i] - rpusher) * 0.3;
                }
                if (i == 1) if (vals[i] > gpusher) gpv = (vals[i] - gpusher) * 0.3;
                if (i == 2) if (vals[i] > bpusher) bpv = (vals[i] - bpusher) * 0.3;
                stroke(255, 0, 0, 200);
            rect((float) l * width / specsize * specpercent, height - vals[i], (float) (r - l) * width / specsize * specpercent, height);
              vals[i] = fftavgs[i][fahindex];
            }
            stroke(0,0,255);
            rect((float) l * width / specsize * specpercent, height - vals[i], (float) (r - l) * width / specsize * specpercent, height);
        }
    }
    
    float avglast(float[] arr, int num){
     float sum = 0;
     for(int i = 0; i < num; i++){
       sum += arr[(fahindex - i >= 0) ? fahindex - i : fahindex + fftavgs[0].length - i];
     }
     return sum/((float)num);
    }

    void musicVis() {
        stroke(255, 0, 0, 128);

        drawAvg(13, 0.3333, true);
        drawAvg(101, 0.333, false);
        if (max > 0) max -= maxvel;
        stroke(255, 255, 255);
        line(0, height - max, width, height - max);

        stroke(255, 0, 0);
        line(0, height - rpusher, width, height - rpusher);
        rpv -= ref;
        if (rpusher >= 0) rpusher += rpv;
        if (rpusher < 0) rpusher = 0;

        stroke(0, 255, 0);
        line(0, height - gpusher, width, height - gpusher);
        gpv -= ref;
        if (gpusher >= 0) gpusher += gpv;
        if (gpusher < 0) gpusher = 0;

        stroke(0, 0, 255);
        line(0, height - bpusher, width, height - bpusher);
        bpv -= ref;
        if (bpusher >= 0) bpusher += bpv;
        if (bpusher < 0) bpusher = 0;


        int ardR = (int) (pow(rpusher, powV) * 255.0 / pow(max, powV) * 0.7 * dimness * (1 - partswhite) + 255 * partswhite * dimness);
        int ardG = (int) (pow(gpusher, powV) * 255.0 / pow(max, powV) * 0.85 * dimness * (1 - partswhite) + 255 * partswhite * dimness);
        int ardB = (int) (pow(bpusher, powV) * 255.0 / pow(max, powV) * 1 * dimness * (1 - partswhite) + 255 * partswhite * dimness);
        outputToArduino(ardR, ardG, ardB);
        stroke(255);
    }

    void fadeCoded(int d) {
        //int[][] f = {{1, -1, 0},{-1, 0, 1},{1, 1, -1},{-1, -1, 1},{0, 1, -1},{1, -1, 1},{-1, 1, -1}};
        int[][] f = {{0, 1, 0}, {-1, 0, 0}, {0, 0, 1}, {0, -1, 0}, {1, 0, 0}, {0, 0, -1}};
        currentfade = getNextFade(currentfade, f[fadenum][0], f[fadenum][1], f[fadenum][2]);
        int rq = (int) (constrain(currentfade[0], 0, 255) * dimness * (1 - partswhite) + 255 * partswhite * dimness);
        int gq = (int) (constrain(currentfade[1], 0, 255) * dimness * (1 - partswhite) + 255 * partswhite * dimness);
        int bq = (int) (constrain(currentfade[2], 0, 255) * dimness * (1 - partswhite) + 255 * partswhite * dimness);
        outputToArduino(rq, gq, bq);
        delay(d);
        if (currentfade[0] < 0 || currentfade[0] > 255 || currentfade[1] < 0 || currentfade[1] > 255 || currentfade[2] < 0 || currentfade[2] > 255) {
            currentfade[0] = constrain(currentfade[0], 0, 255);
            currentfade[1] = constrain(currentfade[1], 0, 255);
            currentfade[2] = constrain(currentfade[2], 0, 255);
            fadenum = (fadenum + 1) % f.length;
        }
    }
    
    void outputToArduino(int r, int g, int b){
        r = constrain(r, 0, 255);
        g = constrain(g, 0, 255);
        b = constrain(b, 0, 255);
        fill(r, g, b);
        noStroke();
        rect(width / 2 - width / 6, 0, width / 3, height);
        strokeWeight(3);
        fill(200, 0, 0);
        stroke(255, 0, 0);
        rect(0, height - (r * height/255) - 5, width / 9, 10, 5, 5, 5, 5);
        fill(0, 200, 0);
        stroke(0, 255, 0);
        rect(width/9, height - (g * height/255) - 5, width / 9, 10, 5, 5, 5, 5);
        fill(0, 0, 200);
        stroke(0, 0, 255);
        rect(2 * width/9, height - (b * height/255) - 5, width / 9, 10, 5, 5, 5, 5);
        int allowedchange = 1;
        if(isarduino && (abs(oldRGBoutput[0] - r) > allowedchange || abs(oldRGBoutput[1] - g) > allowedchange || abs(oldRGBoutput[2] - b) > allowedchange)){
            //arduino.analogWrite(RED, r);
            //arduino.analogWrite(GREEN, g);
            //arduino.analogWrite(BLUE, b);
            byte[] send = {(byte)(r - 128), (byte)(g - 128), (byte)(b - 128)};
            port.write(send);
            
            int[] nw = {r, g, b};
            oldRGBoutput = nw;
        }
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

    void stop() {
        song.disableMonitoring();
        minim.stop();
        super.stop();
    }
    
    class bar {
        float x, val;
        PVector scale;
        String name;
        int w = 42;
        int h = 16;
        float distwidth;

        bar(String n, float x, PVector scale, float def) {
            this.distwidth = x;
            this.scale = scale;
            val = def;
            name = n;
        }

        void draw(float r, float g, float b) {
            update();
            x = width - distwidth;
            color l = color(r * 0.5, g * 0.5, b * 0.5);
            fill(l);
            noStroke();
            rect(x - 2, 0, 4, height);
            stroke(r, g, b);
            l = color(r * 0.7, g * 0.7, b * 0.7);
            fill(l);
            strokeWeight(2);
            float y = height - height * (val - scale.x) / (scale.y - scale.x);
            rect(x - w / 2, y - h / 2, w, h, 5, 5, 5, 5);
            rect(x - (w * 1.5) / 2, height - h - 5, w * 1.5, h, 5, 5, 5, 5);
            fill(255);
            stroke(0);
            strokeWeight(1);
            textAlign(CENTER, CENTER);
            text(val, x, y);
            text(name, x, height - 7 - h / 2);
        }

        void update() {
            if (mousePressed && mouseX <= x + w / 2 && mouseX >= x - w / 2) {
                val = (((float)height - mouseY) / ((float) height) * (scale.y - scale.x)) + scale.x;
                val = constrain(val, scale.x, scale.y);
            }
        }
    }

    class flip {
        float x, y;
        int val;
        String[] options;
        String name;
        int w = 80;
        int h = 30;

        flip(String n, float x, float y, String[] options, int def) {
            this.x = x;
            this.y = y;
            this.options = options;
            val = def;
            name = n;
        }

        void draw(float r, float g, float b) {
            update();
            x = width/2 - w * options.length * 0.5;
            color l = color(r * 0.5, g * 0.5, b * 0.5);
            fill(l);
            //noFill();
            strokeWeight(2);
            if (val == 0) strokeWeight(4);
            stroke(r, g, b);
            rect(x, y, w, h, 18, 0, 0, 18);
            for (int i = 1; i < options.length - 1; i++) {
                strokeWeight(2);
                if (val == i) strokeWeight(4);
                rect(x + w * i, y, w, h, 0, 0, 0, 0);
            }
            strokeWeight(2);
            if (val == options.length - 1) strokeWeight(4);
            rect(x + w * (options.length - 1), y, w, h, 0, 18, 18, 0);
            fill(255);
            textAlign(CENTER, CENTER);
            for (int i = 0; i < options.length; i++) {
                text(options[i], x + w * i + w / 2, y + h / 2);
            }
        }

        void update() {
            if (mousePressed) {
                for (int i = 0; i < options.length; i++) {
                    if (mouseX >= x + w * i && mouseX <= x + w * i + w && mouseY >= y && mouseY <= y + h) {
                        val = i;
                    }
                }
            }
        }

    }