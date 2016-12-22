import ddf.minim.*;
import ddf.minim.analysis.*;

class MusicControl {
    FFT fft;
    Minim  minim;
    AudioInput song;

    // float[][] specs = new float[4][10];

    float br_pusher = 10, brv = 10, br_max = 10;
    float hue_pusher = 10, hue_max = 10, hue_min = 10;
    float max = 0;

    float powV = 3;
    float maxvel = 0.3;
    float ref = 1.15;
    int avgamount = 15;
    Bar smooth, power, refresh, maxv;
    // TODO: spectrum localization (use sample mean and variance)
    // TODO: determine smoothness based on beat count
    // TODO: normalize fft to what people can actually hear (like gamma) DONE
    MusicControl() {
        init();
        smooth = new Bar("smooth", 425, new PVector(1, 100), avgamount);
        power = new Bar("contrast", 200, new PVector(0, 5), powV);
        refresh = new Bar("refresh", 350, new PVector(0, 3), ref);
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
        power.draw(0, 0, 255);
        powV = power.val;
        maxv.draw(0, 200, 255);
        maxvel = maxv.val;
        refresh.draw(0, 255, 0);
        ref = refresh.val;
        smooth.draw(255, 200, 0);
        avgamount = (int) smooth.val;
        return ret;
    }

    void drawSmartAvg(boolean push) {
        // since logarithmically spaced averages are not equally spaced
        // we can't precompute the width for all averages
        int xcount = 0;
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
          rect( xcount, (height - 20) - h, draw_width, h);
          xcount += draw_width;
        }
        float sample_mean = samples > 0 ? sum/samples : fft.avgSize()/2;
        // float standard_dev = 0;
        // for (int i = 0; i < vals.length; i++){
        //     standard_dev += Math.pow(i - sample_mean, 2);
        // }
        // standard_dev = sqrt((float) standard_dev/(vals.length - 1));

        stroke(255,0,0);
        // line(0, (height-samples*0.1), width, (height-samples*0.1));

        if(push){
            // float hv = (sample_mean - hue_pusher) * 0.1;
            // hue_max -= 0.001;
            hue_pusher = hue_pusher + (sample_mean - hue_pusher) * (1.0/avgamount);
            hue_min += Math.pow(hue_pusher - hue_min, 2) * (0.00005);
            hue_max -= Math.pow(hue_max - hue_pusher, 2) * (0.00005);

            if(hue_min + 1 > hue_pusher) hue_min = hue_pusher - 1;
            if(hue_max - 1 < hue_pusher) hue_max = hue_pusher + 1;


            // if (samples*0.1 > br_pusher) brv = (samples*0.1 - br_pusher) * 0.3;
            br_pusher = br_pusher + (samples*0.1 - br_pusher) * (5.0/avgamount);

            stroke(255, 0, 0);

            if (br_max > 0) br_max -= maxvel;
            if (br_pusher > br_max) br_max = br_pusher;

            line(hue_pusher * draw_width, 0, hue_pusher * draw_width, height);
            line(0, height - br_pusher, width, height - br_pusher);

            stroke(5,0,255);
            line(hue_max * draw_width, 0, hue_max * draw_width, height);
            line(hue_min * draw_width, 0, hue_min * draw_width, height);

            line(0, height - br_max, width, height - br_max);

            // stroke(255, 255, 255);
        }
    }


    // void drawAvg(int detail, float specpercent, boolean push) {
    //     stroke(0, 0, 255, 200);
    //     fill(0, 0, 255, 18);
    //     float specsize = fft.specSize() * specpercent;
    //     float[] vals = new float[detail - 1];
    //     for (int i = 0; i < detail - 1; i++) {
    //         vals[i] = 0;
    //     }
    //     double mult = 1.0 / ((double) vals.length);
    //     fahindex += 1;
    //     if(fahindex >= fftavgs[0].length) fahindex = 0;
    //     for (int i = 0; i < detail - 1; i++) {
    //         double r = (i + 1) * mult * specsize;
    //         double l = i * mult * specsize;
    //         for (int j = (int) (l); j < (int) (r); j++) {
    //             vals[i] += sqrt(fft.getBand(j)) * 0.001 * detail * detail * 0.5 / specpercent;
    //         }
    //         vals[i] *= r - l;
    //         if (push && i < 3) {
    //             fftavgs[i][fahindex] = vals[i];
    //             vals[i] = avglast(fftavgs[i], avgamount);
    //             if (vals[i] > max) max = vals[i];
    //             if (i == 0) {
    //                 if (vals[i] > rpusher) rpv = (vals[i] - rpusher) * 0.3;
    //             }
    //             if (i == 1) if (vals[i] > gpusher) gpv = (vals[i] - gpusher) * 0.3;
    //             if (i == 2) if (vals[i] > bpusher) bpv = (vals[i] - bpusher) * 0.3;
    //             stroke(255, 0, 0, 200);
    //             // rect((float) l * width / specsize * specpercent, height - vals[i], (float) (r - l) * width / specsize * specpercent, height);
    //             // vals[i] = fftavgs[i][fahindex];
    //         }
    //         // stroke(0,0,255);
    //         // rect((float) l * width / specsize * specpercent, height - vals[i], (float) (r - l) * width / specsize * specpercent, height);
    //     }
    // }

    // float avglast(float[] arr, int num){
    //     float sum = 0;
    //     for(int i = 0; i < num; i++){
    //         sum += arr[(fahindex - i >= 0) ? fahindex - i : fahindex + fftavgs[0].length - i];
    //     }
    //     return sum/((float)num);
    // }


    // int[] musicVis() {
    //     stroke(255, 0, 0, 128);

    //     // drawAvg(13, 0.3333, true);
    //     // drawAvg(101, 0.333, false);
    //     // drawSmartAvg(201, 1, false);
    //     drawSmartAvg(true);
    //     if (max > 0) max -= maxvel;
    //     stroke(255, 255, 255);
    //     line(0, height - max, width, height - max);

    //     stroke(255, 0, 0);
    //     line(0, height - rpusher, width, height - rpusher);
    //     rpv -= ref;
    //     if (rpusher >= 0) rpusher += rpv;
    //     if (rpusher < 0) rpusher = 0;

    //     stroke(0, 255, 0);
    //     line(0, height - gpusher, width, height - gpusher);
    //     gpv -= ref;
    //     if (gpusher >= 0) gpusher += gpv;
    //     if (gpusher < 0) gpusher = 0;

    //     stroke(0, 0, 255);
    //     line(0, height - bpusher, width, height - bpusher);
    //     bpv -= ref;
    //     if (bpusher >= 0) bpusher += bpv;
    //     if (bpusher < 0) bpusher = 0;

    //     // int[] ret = new int[3];
    //     // ret[0] = (int) (pow(rpusher, powV) * 255.0 / pow(max, powV) * 0.7 * dimness * (1 - partswhite) + 255 * partswhite * dimness);
    //     // ret[1] = (int) (pow(gpusher, powV) * 255.0 / pow(max, powV) * 0.85 * dimness * (1 - partswhite) + 255 * partswhite * dimness);
    //     // ret[2] = (int) (pow(bpusher, powV) * 255.0 / pow(max, powV) * 1 * dimness * (1 - partswhite) + 255 * partswhite * dimness);
        
    //     stroke(255);

    //     colorMode(HSB, 100);
    //     color c = color(hue_pusher*5, 50, 50);
    //     System.out.println(hue_pusher);

    //     // System.out.println(ret[0] + "," + ret[1] + "," + ret[2]);
    //     int[] ret = rgbToArr(red(c), green(c), blue(c));
    //     colorMode(RGB, 255);        
    //     return ret;
    // }



    int[] musicVis() {
        stroke(255, 0, 0, 128);

        drawSmartAvg(true);

        stroke(255);

        colorMode(HSB, 255);
        color c = color(map(hue_pusher, hue_min, hue_max, 0, 255), 255, map(br_pusher, 0, br_max, 0, 255));
        // System.out.println(hue_pusher*3.5);

        // System.out.println(ret[0] + "," + ret[1] + "," + ret[2]);
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