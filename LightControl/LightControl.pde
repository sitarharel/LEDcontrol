import processing.serial.*;
import java.util.*;

// ~/Programs/processing-3.0.2/processing-java --sketch="LightControl" --run

Serial port;

int state = 1;
int[] interRGB = {0, 0, 0};

String base_url = "http://sitarbucks.com";
// String base_url = "http://localhost:8000";

int[] oldRGBoutput = {0, 0, 0};

boolean debug = false;
boolean networking = false;
boolean fullscreen = true;
String api_key = "";
int serial_offset = 0;

boolean isarduino = true;

float red_v, green_v, blue_v, dim, white, fadespeed;

int oldstate = 0;
MusicControl mc;
FadeControl fc;
int[] output = new int[3];
int race_buffer = 0;

void settings() {
	// size(1500, 800, P3D);
	loadSettings();
	// if(!debug && fullscreen) fullScreen();
}

void setup() {
	surface.setResizable(true);
	if(debug){
		for(String port : portList()){
			System.out.println(port);
		}
	}

	String[] ports = portList();
	if (!debug && ports.length > serial_offset) {
		port = new Serial(this, ports[serial_offset], 57600);
		System.out.println("Connected to port: " + ports[serial_offset]);
	} else {
		isarduino = false;
		System.out.println("No connection initially found.");
	}

	mc = new MusicControl();
	fc = new FadeControl();

	white = 0;
	dim = 1;
	red_v = 255;
	green_v = 255;
	blue_v = 255;
}

void draw() {
	background(0);

	if(oldstate != state) mc.stop();
	boolean same = true;
	if (state == 1) {
		if(oldstate != state) mc.init();
		int[] musicval = mc.doMusicControl();
		output = musicval;
	} else if (state == 2) {
		int[] fadeval = fc.doFadeControl();
		output = fadeval;
	} else if (state == 3) {
		output[0] = (int) (constrain(red_v, 0, 255) * dim * (1 - white) + 255 * white * dim);
		output[1] = (int) (constrain(green_v, 0, 255) * dim * (1 - white) + 255 * white * dim);
		output[2] = (int) (constrain(blue_v, 0, 255) * dim * (1 - white) + 255 * white * dim);
	}

	outputToArduino(output[0], output[1], output[2]);

	if(networking && frameCount % 30 == 0){
		thread("requestData");
	}

	String[] ports = portList();
	if (!debug && !isarduino && ports.length > serial_offset) {
		port = new Serial(this, ports[serial_offset], 57600);
		System.out.println("Connected to port: " + ports[serial_offset]);
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

	int allowedchange = 1;

	if(isarduino && (abs(oldRGBoutput[0] - r) > allowedchange || abs(oldRGBoutput[1] - g) > allowedchange || abs(oldRGBoutput[2] - b) > allowedchange)){
		byte[] send = {(byte)(r - 128), (byte)(g - 128), (byte)(b - 128)};
		port.write(send);
		int[] nw = {r, g, b};
		oldRGBoutput = nw;
	}
}

void stop() {
	mc.stop();
	super.stop();
}

// This happens as a separate thread and can take as long as it wants
void requestData() {
	JSONObject json = loadJSONObject(base_url + "/api/" + api_key + "/get_state");
	// GetRequest get = new GetRequest(base_url + "/api/" + api_key + "/get_state");
	// get.send();
	// println(" " + get.getContent());

	if(json != null){
		int[] res = hexToRGB(json.getString("static"));
		red_v = (float) res[0];
		green_v = (float) res[1];
		blue_v = (float) res[2];
		white = json.getFloat("white");
		dim = json.getFloat("bright");
		JSONObject nu_mus = json.getJSONObject("music");
		mc.setSettings(nu_mus.getInt("max"), nu_mus.getInt("sat"), nu_mus.getInt("h_smooth"), nu_mus.getInt("b_smooth"), nu_mus.getInt("center"));
		fc.setFadeSpeed((float) json.getInt("fade_speed"));
		state = json.getInt("lightmode");
	}
}

int[] hexToRGB(String hex){
	int[] out = new int[3];
	out[0] = unhex(hex.substring(1,3));
	out[1] = unhex(hex.substring(3,5));
	out[2] = unhex(hex.substring(5,7));
	return out;
}

String[] portList(){
	List<String> res = new ArrayList<String>();
	for(String port : Serial.list()){
		if(port.length() >= 9 && port.substring(0, 9).equals("/dev/ttyS")) continue;
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
				case "debug":  
					if(setting[1].equals("true")) debug = true;
					break;
				default: break;
			}	
		}
	}
	System.out.println("Loaded settings");
}