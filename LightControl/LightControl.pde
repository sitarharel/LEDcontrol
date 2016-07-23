import processing.serial.*;
// import ddf.minim.*;
// import ddf.minim.analysis.*;
import cc.arduino.*;

// Minim  minim;
// AudioInput song;
Arduino arduino;
Serial port;

int state = 1;

// FFT fft;
// float[][] specs = new float[4][10];
// float rpusher = 100, rpv = 0;
// float gpusher = 100, gpv = 0;
// float bpusher = 100, bpv = 0;
// float max = 0;
int fadenum = 0;
// float[][] fftavgs = new float[3][100];
// int fahindex = -1;

boolean webcontrol = false;
int[] interRGB = {0, 0, 0};
boolean useConnection = true;
JSONObject webstatic = new JSONObject();

int[] currentfade = {0, 255, 0};
int[] oldRGBoutput = {0, 0, 0};

boolean isarduino = true;
int fadetype;
float dimness = 1; //scale of 0 to 1
float partswhite = 0; //scale of 0 to 1 for how much is just white (1 is all white, 0 is all music visualisztion)

// float powV = 3;
// float maxvel = 0.3;
// float ref = 1.15;
// int avgamount = 15;

int fdelay = 12;
// Bar rbar, gbar, bbar, power, dim, white, refresh, maxv, fadespeed, smooth;
Bar rbar, gbar, bbar, dim, white, fadespeed;
Flip stat;
MusicControl mc;

void settings() {
	size(1500, 800, P3D);
	fullScreen();
}

void setup() {
	webstatic.setInt("r", 180);
	webstatic.setInt("g", 0);
	webstatic.setInt("b", 50);

	surface.setResizable(true);
	// minim = new Minim(this);


	if (Arduino.list().length > 1) {
		port = new Serial(this, Arduino.list()[1], 57600);
	} else {
		isarduino = false;
	}

	mc = new MusicControl();
	// song = minim.getLineIn();
	// song.enableMonitoring();
	// song.mute();
	// fft = new FFT(song.bufferSize(), 2048);

	// for (int j = 0; j < specs.length; j++) {
	// 	for (int i = 0; i < specs[0].length; i++) {
	// 		specs[j][i] = 0;
	// 	}
	// }

	// smooth = new Bar("smooth", 425, new PVector(1, 100), avgamount);
	// power = new Bar("contrast", 200, new PVector(0, 5), powV);
	// refresh = new Bar("refresh", 350, new PVector(0, 3), ref);
	// maxv = new Bar("max", 275, new PVector(0, 1), maxvel);

	white = new Bar("white", 50, new PVector(0, 1), partswhite);
	dim = new Bar("intensity", 125, new PVector(0, 1), dimness);
	
	fadespeed = new Bar("speed", 200, new PVector(0, 100), fdelay);

	rbar = new Bar("red", 350, new PVector(0, 255), 255);
	gbar = new Bar("green", 275, new PVector(0, 255), 255);
	bbar = new Bar("blue", 200, new PVector(0, 255), 255);

	String[] p = {"music", "fade", "static"};
	stat = new Flip("state", (width - 150 ) / 2, 50, p, state);
}

void draw() {
	background(0);
	if (frameCount % 10 == 0 && useConnection) {
		thread("requestData");
	}
	// fft.forward(song.mix);
	if (state == 1) {
		int[] musicval = mc.doMusicControl();
		outputToArduino(musicval[0], musicval[1], musicval[2]);
		// musicVis();
		// power.draw(0, 0, 255);
		// powV = power.val;
		// maxv.draw(0, 200, 255);
		// maxvel = maxv.val;
		// refresh.draw(0, 255, 0);
		// ref = refresh.val;
		// smooth.draw(255, 200, 0);
		// avgamount = (int) smooth.val;
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
	if (!isarduino && Arduino.list().length > 1) {
		port = new Serial(this, Arduino.list()[1], 57600);
		isarduino = true;
	}
	if (isarduino && Arduino.list().length <= 1) {
		isarduino = false;
	}

}

// void drawAvg(int detail, float specpercent, boolean push) {
// 	stroke(0, 0, 255, 200);
// 	fill(0, 0, 255, 18);
// 	float specsize = fft.specSize() * specpercent;
// 	float[] vals = new float[detail - 1];
// 	for (int i = 0; i < detail - 1; i++) {
// 		vals[i] = 0;
// 	}
// 	double mult = 1.0 / ((double) vals.length);
// 	fahindex += 1;
// 	if(fahindex >= fftavgs[0].length) fahindex = 0;
// 	for (int i = 0; i < detail - 1; i++) {
// 		double r = (i + 1) * mult * specsize;
// 		double l = i * mult * specsize;
// 		for (int j = (int) (l); j < (int) (r); j++) {
// 			vals[i] += sqrt(fft.getBand(j)) * 0.001 * detail * detail * 0.5 / specpercent;
// 		}
// 		vals[i] *= r - l;
// 		if (push && i < 3) {
// 			fftavgs[i][fahindex] = vals[i];
// 			vals[i] = avglast(fftavgs[i], avgamount);
// 			if (vals[i] > max) max = vals[i];
// 			if (i == 0) {
// 				if (vals[i] > rpusher) rpv = (vals[i] - rpusher) * 0.3;
// 			}
// 			if (i == 1) if (vals[i] > gpusher) gpv = (vals[i] - gpusher) * 0.3;
// 			if (i == 2) if (vals[i] > bpusher) bpv = (vals[i] - bpusher) * 0.3;
// 			stroke(255, 0, 0, 200);
// 			rect((float) l * width / specsize * specpercent, height - vals[i], (float) (r - l) * width / specsize * specpercent, height);
// 			vals[i] = fftavgs[i][fahindex];
// 		}
// 		stroke(0,0,255);
// 		rect((float) l * width / specsize * specpercent, height - vals[i], (float) (r - l) * width / specsize * specpercent, height);
// 	}
// }

// float avglast(float[] arr, int num){
// 	float sum = 0;
// 	for(int i = 0; i < num; i++){
// 		sum += arr[(fahindex - i >= 0) ? fahindex - i : fahindex + fftavgs[0].length - i];
// 	}
// 	return sum/((float)num);
// }

// void musicVis() {
// 	stroke(255, 0, 0, 128);

// 	drawAvg(13, 0.3333, true);
// 	drawAvg(101, 0.333, false);
// 	if (max > 0) max -= maxvel;
// 	stroke(255, 255, 255);
// 	line(0, height - max, width, height - max);

// 	stroke(255, 0, 0);
// 	line(0, height - rpusher, width, height - rpusher);
// 	rpv -= ref;
// 	if (rpusher >= 0) rpusher += rpv;
// 	if (rpusher < 0) rpusher = 0;

// 	stroke(0, 255, 0);
// 	line(0, height - gpusher, width, height - gpusher);
// 	gpv -= ref;
// 	if (gpusher >= 0) gpusher += gpv;
// 	if (gpusher < 0) gpusher = 0;

// 	stroke(0, 0, 255);
// 	line(0, height - bpusher, width, height - bpusher);
// 	bpv -= ref;
// 	if (bpusher >= 0) bpusher += bpv;
// 	if (bpusher < 0) bpusher = 0;


// 	int ardR = (int) (pow(rpusher, powV) * 255.0 / pow(max, powV) * 0.7 * dimness * (1 - partswhite) + 255 * partswhite * dimness);
// 	int ardG = (int) (pow(gpusher, powV) * 255.0 / pow(max, powV) * 0.85 * dimness * (1 - partswhite) + 255 * partswhite * dimness);
// 	int ardB = (int) (pow(bpusher, powV) * 255.0 / pow(max, powV) * 1 * dimness * (1 - partswhite) + 255 * partswhite * dimness);
// 	outputToArduino(ardR, ardG, ardB);
// 	stroke(255);
// }

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
	if(webcontrol){
		int[] w = webcontrolResult();
		r = w[0];
		g = w[1];
		b = w[2];
	}
	fill(r, g, b);
	noStroke();
	rect(width / 2 - width / 6, 0, width / 3, height);
	strokeWeight(3);
	if(webcontrol){
		fill(0, 200, 0);
		stroke(0, 255, 0);
		strokeWeight(2);
		rect(width/2 - 50, height/2 - 50, 100, 100, 18, 18, 18, 18);
		fill(255);
		textAlign(CENTER, CENTER);
		text("Web Control On", width/2, height/2);
	}else{
		fill(200, 0, 0);
		stroke(255, 0, 0);
		strokeWeight(2);
		rect(width/2 - 50, height/2 - 50, 100, 100, 18, 18, 18, 18);
		fill(255);
		textAlign(CENTER, CENTER);
		text("Web Control Off", width/2, height/2);
	}
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
		byte[] send = {(byte)(r - 128), (byte)(g - 128), (byte)(b - 128)};
		port.write(send);

		int[] nw = {r, g, b};
		oldRGBoutput = nw;
	}
}

int[] webcontrolResult() {
	int[] res = new int[3];
	res[0] = webstatic.getInt("r");
	res[1] = webstatic.getInt("g");
	res[2] = webstatic.getInt("b");
	return res;
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
	// song.disableMonitoring();
	// minim.stop();
	mc.stop();
	super.stop();
}


// This happens as a separate thread and can take as long as it wants
void requestData() {
	// {webcontrol: false, lightmode: "static", music: {}, fade: {speed: 12, dim: 1, white: 0}, static: {r: 180, g: 0, b: 50} };

	JSONObject json = loadJSONObject("http://sitarbucks.com/lightstatus/");
	webstatic = json.getJSONObject("static");
	webcontrol = json.getBoolean("webcontrol");

	// String[] txt = loadStrings("http://192.241.154.171/lightstatus/");
	// interOnOff = txt[0].equals("ON");
	// String[] c = txt[1].split(",");

	// interRGB[0] = Integer.parseInt(c[0]);
	// interRGB[1] = Integer.parseInt(c[1]);
	// interRGB[2] = Integer.parseInt(c[2]);
}