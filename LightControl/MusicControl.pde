import ddf.minim.*;
import ddf.minim.analysis.*;

class MusicControl {
    FFT fft;
    Minim  minim;
    AudioInput song;

    float br_pusher = 10, brv = 10, br_max = 10;
    float hue_pusher = 10, hue_max = 10, hue_min = 10;
    float max = 0;

    float sat = 255;
    float maxvel = 0.3;
    int avgamount = 30;
    Bar smooth, saturation, maxv;
    boolean settings_changed = true;
    // TODO: determine smoothness based on beat count
    MusicControl() {
        init();
        smooth = new Bar("smooth", 350, new PVector(1, 150), avgamount);
        saturation = new Bar("sat", 200, new PVector(0, 255), sat);
        maxv = new Bar("max", 275, new PVector(0, 1), maxvel);
    }

    void init(){
        // stop();
        minim = new Minim(this);
        song = minim.getLineIn();
        song.enableMonitoring();
        song.mute();
        fft = new FFT(song.bufferSize(), 2048);
        fft.logAverages( 12, 12 );
        fft.window( FFT.HANN );
    }

    int[] doMusicControl() {
        fft.forward(song.mix);
        int[] ret = musicVis();
        boolean sat_change = saturation.draw(0, 0, 255);
        sat = saturation.val;
        boolean max_change = maxv.draw(0, 200, 255);
        maxvel = maxv.val;
        boolean smooth_change = smooth.draw(255, 200, 0);
        avgamount = (int) smooth.val;
        settings_changed = sat_change && smooth_change && max_change;
        return ret;
    }

    void drawSmartAvg(boolean push) {
        float centerFrequency = 0;
        float spectrumScale = 8;
        float sum = 0;
        float samples = 0;
        float draw_width = 5;
        float[] vals = new float[fft.avgSize()];
        for(int i = 0; i < fft.avgSize(); i++)
        { 
          float h = (float) Math.pow(fft.getAvg(i),1.1)*spectrumScale;
          vals[i] = h;
          sum += h * i;
          samples += h;
          noStroke();
          fill(255);
          rect(i * draw_width, (height - 20) - h, draw_width, h);
        }
        float sample_mean = samples > 0 ? sum/samples : fft.avgSize()/2;
        // float standard_dev = 0;
        // for (int i = 0; i < vals.length; i++){
        //     standard_dev += Math.pow(i - sample_mean, 2);
        // }
        // standard_dev = sqrt((float) standard_dev/(vals.length - 1));

        if(push){
            hue_pusher = hue_pusher + (sample_mean - hue_pusher) * (1.0/avgamount);
            hue_min += Math.pow(hue_pusher - hue_min, 2) * (0.0001) * maxvel;
            hue_max -= Math.pow(hue_max - hue_pusher, 2) * (0.0001) * maxvel;
            if(hue_min > hue_pusher) hue_min = hue_pusher;
            if(hue_max < hue_pusher) hue_max = hue_pusher;

            br_pusher = br_pusher + (samples*0.1 - br_pusher) * (5.0/max(10.0, avgamount));
            //maybe give this a different speed when it goes down vs up
            if (br_max > 0) br_max -= Math.pow(br_max - br_pusher, 2) * (0.0004) *maxvel; 
            if (br_pusher > br_max) br_max = br_pusher;

            stroke(255, 0, 0);
            line(hue_pusher * draw_width, 0, hue_pusher * draw_width, height);
            line(0, height - br_pusher, width/3.0, height - br_pusher);

            stroke(5,0,255);
            line(hue_max * draw_width, 0, hue_max * draw_width, height);
            line(hue_min * draw_width, 0, hue_min * draw_width, height);
            line(0, height - br_max, width/3.0, height - br_max);
        }
    }

    public String getStringSettings(){
        return "{\"max\": " + ((int) (maxv.val*100)) + ", \"smooth\": " + ((int) smooth.val) + ", \"sat\": " + ((int) saturation.val) + "}";
    }

    public boolean settingsChanged(){
        return settings_changed;
    }

    public void setSettings(int nmaxv, int nsat, int nsmooth){
        saturation.val = (float) nsat;
        smooth.val = (float) nsmooth;
        maxv.val = (float) nmaxv/100;
    }

    int[] musicVis() {
        drawSmartAvg(true);

        colorMode(HSB, 255);
        color c = color(map(hue_pusher, hue_min, hue_max, 0, 230), sat, map(br_pusher, 0, br_max, 0, 255));
        int[] ret = rgbToArr(red(c), green(c), blue(c));
        colorMode(RGB, 255);        
        
        return ret;
    }


    public int[] rgbToArr(float r, float g, float b) {
        return new int[]{(int) constrain(r, 0, 255), (int) constrain(g, 0, 255), (int) constrain(b, 0, 255)};
    }

    void stop() {
        song.disableMonitoring();
        minim.stop();
    }
}