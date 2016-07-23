import ddf.minim.*;
import ddf.minim.analysis.*;

class MusicControl {
    FFT fft;
    Minim  minim;
    AudioInput song;

    float[][] specs = new float[4][10];
    float rpusher = 100, rpv = 0;
    float gpusher = 100, gpv = 0;
    float bpusher = 100, bpv = 0;
    float max = 0;
    float[][] fftavgs = new float[3][100];
    int fahindex = -1;

    float powV = 3;
    float maxvel = 0.3;
    float ref = 1.15;
    int avgamount = 15;
    Bar smooth, power, refresh, maxv;

    MusicControl() {
        minim = new Minim(this);
        song = minim.getLineIn();
        song.enableMonitoring();
        song.mute();
        fft = new FFT(song.bufferSize(), 2048);

        smooth = new Bar("smooth", 425, new PVector(1, 100), avgamount);
        power = new Bar("contrast", 200, new PVector(0, 5), powV);
        refresh = new Bar("refresh", 350, new PVector(0, 3), ref);
        maxv = new Bar("max", 275, new PVector(0, 1), maxvel);
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


    int[] musicVis() {
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

        int[] ret = new int[3];
        ret[0] = (int) (pow(rpusher, powV) * 255.0 / pow(max, powV) * 0.7 * dimness * (1 - partswhite) + 255 * partswhite * dimness);
        ret[1] = (int) (pow(gpusher, powV) * 255.0 / pow(max, powV) * 0.85 * dimness * (1 - partswhite) + 255 * partswhite * dimness);
        ret[2] = (int) (pow(bpusher, powV) * 255.0 / pow(max, powV) * 1 * dimness * (1 - partswhite) + 255 * partswhite * dimness);
        
        stroke(255);
        return ret;
    }


    void stop() {
        song.disableMonitoring();
        minim.stop();
    }
}