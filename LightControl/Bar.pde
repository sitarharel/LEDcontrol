class Bar {
    float x, val;
    PVector scale;
    String name;
    int w = 70; //42
    int h = 20;
    float distwidth;

    Bar(String n, float x, PVector scale, float def) {
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
        rect(x - 2, 0, 4, height - 20);
        stroke(r, g, b);
        l = color(r * 0.7, g * 0.7, b * 0.7);
        fill(l);
        strokeWeight(2);
        float y = height - 40 - (height - 60) * (val - scale.x) / (scale.y - scale.x);
        rect(x - w / 2, y - h / 2, w, h, 5, 5, 5, 5);
        rect(x - w / 2, height - h - 5, w, h, 5, 5, 5, 5);
        fill(255);
        stroke(0);
        strokeWeight(1);
        textAlign(CENTER, CENTER);
        text(val, x, y);
        text(name, x, height - 7 - h / 2);
    }

    void update() {
        if (mousePressed && mouseX <= x + w / 2 && mouseX >= x - w / 2) {
            val = 0 + (((float)height - 40 - mouseY) / ((float) height - 60) * (scale.y - scale.x)) + scale.x;
            val = constrain(val, scale.x, scale.y);
        }
    }
}