import ddf.minim.*;
import ddf.minim.analysis.*;
import javax.sound.sampled.*;

class MusicControl {
    FFT fft;
    Minim  minim;
    AudioInput song;

    float br_pusher = 10, brv = 10, br_max = 10;
    float hue_pusher = 10, hue_max = 10, hue_min = 10;
    float max = 0;

    float center_c, b_smooth, h_smooth, saturation, maxv;
    
    boolean settings_changed = true;
    // TODO: determine smoothness based on beat count
    MusicControl() {
        init();
        center_c = 0;
        h_smooth = 50;
        b_smooth = 30;
        saturation = 255;
        maxv = 0.3;
    }

    void init(){
        // stop();
        minim = new Minim(this);
        if(raspberry_pi){
            Mixer.Info mixer_info = AudioSystem.getMixerInfo()[0];
            minim.setInputMixer(AudioSystem.getMixer(mixer_info));
            song = minim.getLineIn(Minim.MONO, 2048, 48000.0f, 16);
        }else{   
            song = minim.getLineIn();
        }
        song.enableMonitoring();
        song.mute();
        fft = new FFT(song.bufferSize(), 2048);
        fft.logAverages( 12, 12 );
        fft.window( FFT.HANN );
    }

    int[] doMusicControl() {
        fft.forward(song.mix);
        int[] ret = musicVis();
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
        }
        float sample_mean = samples > 0 ? sum/samples : fft.avgSize()/2;
        // float standard_dev = 0;
        // for (int i = 0; i < vals.length; i++){
        //     standard_dev += Math.pow(i - sample_mean, 2);
        // }
        // standard_dev = sqrt((float) standard_dev/(vals.length - 1));

        if(push){
            hue_pusher = hue_pusher + (sample_mean - hue_pusher) * (1.0/h_smooth);
            hue_min += Math.pow(hue_pusher - hue_min, 2) * (0.0001) * maxv;
            hue_max -= Math.pow(hue_max - hue_pusher, 2) * (0.0001) * maxv;
            if(hue_min > hue_pusher) hue_min = hue_pusher;
            if(hue_max < hue_pusher) hue_max = hue_pusher;

            br_pusher = br_pusher + (samples*0.1 - br_pusher) * (5.0/(5 + b_smooth));
            //maybe give this a different speed when it goes down vs up
            if (br_max > 0) br_max -= Math.pow(br_max - br_pusher, 2) * (0.0004) *maxv; 
            if (br_pusher > br_max) br_max = br_pusher;
        }
    }

    public String getStringSettings(){
        return "{\"max\": " + ((int) (maxv*100)) + 
            ", \"center\": " + ((int) center_c) + 
            ", \"b_smooth\": " + ((int) b_smooth) + 
            ", \"h_smooth\": " + ((int) h_smooth) + 
            ", \"sat\": " + ((int) saturation) + "}";
    }

    public boolean settingsChanged(){
        return settings_changed;
    }

    public void setSettings(int nmaxv, int nsat, int nh_smooth, int nb_smooth, int ncenter){
        saturation = (float) nsat;
        h_smooth = (float) nh_smooth;
        b_smooth = (float) nb_smooth;
        center_c = (float) ncenter;
        maxv = (float) nmaxv/100;
    }

    int[] musicVis() {
        drawSmartAvg(true);

        colorMode(HSB, 255);
        float c_hue = (map(hue_pusher, hue_min, hue_max, 0, 235) + (center_c + 127)) % 256;
        color c = color(c_hue, saturation, map(br_pusher, 0, br_max, 0, 255));
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
