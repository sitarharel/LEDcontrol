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
    int avg_color = 0;
    Bar center_c, b_smooth, h_smooth, saturation, maxv;
    boolean settings_changed = true;
    // TODO: determine smoothness based on beat count
    MusicControl() {
        init();
        center_c = new Bar("main color", 350, new PVector(0, 255), avg_color);
        h_smooth = new Bar("hue smooth", 200, new PVector(1, 150), 50);
        b_smooth = new Bar("beat smooth", 275, new PVector(1, 150), 30);
        saturation = new Bar("sat", 50, new PVector(0, 255), sat);
        maxv = new Bar("max", 125, new PVector(0, 1), maxvel);
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
        boolean same = true;
        same = same && saturation.draw(0, 0, 255);
        sat = saturation.val;
        same = same && maxv.draw(0, 200, 255);
        maxvel = maxv.val;
        same = same && h_smooth.draw(0, 200, 0);
        same = same && b_smooth.draw(200, 0, 200);
        same = same && center_c.draw(255, 200, 0);
        avg_color = (int) center_c.val;
        settings_changed = same;
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
            hue_pusher = hue_pusher + (sample_mean - hue_pusher) * (1.0/h_smooth.val);
            hue_min += Math.pow(hue_pusher - hue_min, 2) * (0.0001) * maxvel;
            hue_max -= Math.pow(hue_max - hue_pusher, 2) * (0.0001) * maxvel;
            if(hue_min > hue_pusher) hue_min = hue_pusher;
            if(hue_max < hue_pusher) hue_max = hue_pusher;

            br_pusher = br_pusher + (samples*0.1 - br_pusher) * (5.0/(5 + b_smooth.val));
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
        return "{\"max\": " + ((int) (maxv.val*100)) + 
            ", \"center\": " + ((int) center_c.val) + 
            ", \"b_smooth\": " + ((int) b_smooth.val) + 
            ", \"h_smooth\": " + ((int) h_smooth.val) + 
            ", \"sat\": " + ((int) saturation.val) + "}";
    }

    public boolean settingsChanged(){
        return settings_changed;
    }

    public void setSettings(int nmaxv, int nsat, int nh_smooth, int nb_smooth, int ncenter){
        saturation.val = (float) nsat;
        h_smooth.val = (float) nh_smooth;
        b_smooth.val = (float) nb_smooth;
        center_c.val = (float) ncenter;
        maxv.val = (float) nmaxv/100;
    }

    int[] musicVis() {
        drawSmartAvg(true);

        colorMode(HSB, 255);
        float c_hue = (map(hue_pusher, hue_min, hue_max, 0, 235) + (avg_color + 127)) % 256;
        color c = color(c_hue, sat, map(br_pusher, 0, br_max, 0, 255));
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