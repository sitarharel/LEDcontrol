import processing.serial.*;
import cc.arduino.*;
import http.requests.*;
import java.util.*;

// ~/Programs/processing-3.0.2/processing-java --sketch="LightControl" --run

Serial port;

int state = 1;
boolean webcontrol = false;
int[] interRGB = {0, 0, 0};

JSONObject webstatic = new JSONObject();
JSONObject webfade = new JSONObject();
int webstate = 3;

int[] oldRGBoutput = {0, 0, 0};

boolean debug = false;
boolean networking = false;
boolean fullscreen = true;
String api_key = "";
int serial_offset = 0;

boolean isarduino = true;
float dimness = 1; //scale of 0 to 1
float partswhite = 0; //scale of 0 to 1 for how much is just white (1 is all white, 0 is all music visualization)

Bar rbar, gbar, bbar, dim, white, fadespeed;
Flip stat;
int oldstate = 0;
MusicControl mc;
FadeControl fc;
Toggle webconn;

void settings() {
	size(1500, 800, P3D);
	loadSettings();
	if(!debug && fullscreen) fullScreen();
}

void setup() {
	webstatic.setInt("r", 180);
	webstatic.setInt("g", 0);
	webstatic.setInt("b", 50);
	webstatic.setFloat("dim", 1.0);
	webstatic.setFloat("white", 0.0);

	surface.setResizable(true);
	if(debug){
		for(String port : portList()){
			System.out.println(port);
		}
	}

	String[] ports = portList();
	if (!debug && ports.length > serial_offset) {
		port = new Serial(this, ports[serial_offset], 57600);
	} else {
		isarduino = false;
	}

	mc = new MusicControl();
	fc = new FadeControl();

	white = new Bar("white", 50, new PVector(0, 1), partswhite);
	dim = new Bar("intensity", 125, new PVector(0, 1), dimness);

	rbar = new Bar("red", 350, new PVector(0, 255), 255);
	gbar = new Bar("green", 275, new PVector(0, 255), 255);
	bbar = new Bar("blue", 200, new PVector(0, 255), 255);

	String[] p = {"music", "fade", "static"};
	stat = new Flip("state", (width - 150 ) / 2, 50, p, state - 1);
	String[] ops = {"Web control on", "Web control off"};
	if(networking) webconn = new Toggle(width/2, height/2, 100, 100, ops, true);
}

void draw() {
	background(0);
	if (frameCount % 5 == 0 && networking) {
		thread("requestData");
	}
	int[] output = new int[3];
	// int select = webcontrol ? webstate : state;
	if(webcontrol){
		stat.setVal(webstate - 1);
		dim.setVal(webstatic.getFloat("dim"));
		white.setVal(webstatic.getFloat("white"));
	}

	partswhite = white.val;
	dimness = dim.val;

	state = stat.val + 1;
	if(oldstate != state) mc.stop();

	if (state == 1) {
		if(oldstate != state) mc.init();
		int[] musicval = mc.doMusicControl();
		output = musicval;
	} else if (state == 2) {
		if(webcontrol){
			fc.setFadeSpeed(webfade.getFloat("speed"));
		}
		int[] fadeval = fc.doFadeControl();
		output = fadeval;
	} else if (state == 3) {
		if(webcontrol){
			int[] res = staticRGBArray();
			rbar.setVal((float) res[0]);
			gbar.setVal((float) res[1]);
			bbar.setVal((float) res[2]);
		}
		output[0] = (int) (constrain(rbar.val, 0, 255) * dimness * (1 - partswhite) + 255 * partswhite * dimness);
		output[1] = (int) (constrain(gbar.val, 0, 255) * dimness * (1 - partswhite) + 255 * partswhite * dimness);
		output[2] = (int) (constrain(bbar.val, 0, 255) * dimness * (1 - partswhite) + 255 * partswhite * dimness);
		rbar.draw(255, 0, 0);
		gbar.draw(0, 255, 0);
		bbar.draw(0, 0, 255);
	}

	outputToArduino(output[0], output[1], output[2]);

	white.draw(255, 255, 255);
	dim.draw(255, 0, 255);
	stat.draw(0, 0, 255);
	if(networking){
		webconn.setSelected(webcontrol);
		webconn.draw(true);
	}

	String[] ports = portList();
	if (!debug && !isarduino && ports.length > serial_offset) {
		port = new Serial(this, ports[serial_offset], 57600);
		isarduino = true;
	} 
	if (debug || isarduino && ports.length <= serial_offset) {
		isarduino = false;
	}
	oldstate = state;
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
		byte[] send = {(byte)(r - 128), (byte)(g - 128), (byte)(b - 128)};
		port.write(send);
		int[] nw = {r, g, b};
		oldRGBoutput = nw;
	}
}

void makePost(){
	String s = webconn.selected ? "true" : "false";
	PostRequest post = new PostRequest("http://sitarbucks.com/lightstatus/");
	post.addData("lightstat", s);
	post.send();
}

int[] staticRGBArray() {
	int[] res = {webstatic.getInt("r"), webstatic.getInt("g"), webstatic.getInt("b")};
	return res;
}

void stop() {
	mc.stop();
	super.stop();
}

// This happens as a separate thread and can take as long as it wants
void requestData() {
	// {webcontrol: false, lightmode: "static", music: {}, fade: {speed: 12, dim: 1, white: 0}, static: {r: 180, g: 0, b: 50} };
	JSONObject json = loadJSONObject("http://sitarbucks.com/lightstatus/");
	if(json != null){
		webstatic = json.getJSONObject("static");
		webcontrol = json.getBoolean("webcontrol");
		webstate = json.getInt("lightmode");
		webfade = json.getJSONObject("fade");
	}
}

String[] portList(){
	List<String> res = new ArrayList<String>();
	for(String port : Serial.list()){
		if(port.substring(0, 9).equals("/dev/ttyS")) continue;
		res.add(port);
	}

	String[] arr = new String[res.size()];
	return res.toArray(arr);
}

void loadSettings(){	
	for (String line : loadStrings("config.txt")) {
		line = line.replaceAll("\\s+",""); //remove whitespace
		if(line.length() == 0 || line.charAt(0) == '#') continue; //continue loop if it's a comment
		String[] setting = line.split(":");
		if(setting.length >= 2){
			switch (setting[0]) {
				case "networking":  
					if(setting[1].equals("true")) networking = true;
					break;
				case "api_key":  
					api_key = setting[1];
					break;
				case "serial_offset":  
					serial_offset = Integer.parseInt(setting[1]);
					break;
				case "fullscreen":  
					if(setting[1].equals("false")) fullscreen = false;
					break;
				case "debug":  
					if(setting[1].equals("true")) debug = true;
					break;
				default: break;
			}	
		}
	}
	System.out.println("Loaded settings");
}