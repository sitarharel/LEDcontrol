class Flip {
    float x, y;
    int val;
    String[] options;
    String name;
    int w = 120;
    int h = 50;

    Flip(String n, float x, float y, String[] options, int def) {
        this.x = x;
        this.y = y;
        this.options = options;
        val = def;
        name = n;
    }

    boolean draw(float r, float g, float b) {
        int oldval = val;
        boolean updated = update();
        x = width/2 - w * 0.5;
        color l = color(r * 0.5, g * 0.5, b * 0.5);
        fill(l);
        //noFill();
        strokeWeight(2);
        if (val == 0) strokeWeight(4);
        stroke(r, g, b);
        rect(x, y, w, h, 18, 18, 0, 0);
        for (int i = 1; i < options.length - 1; i++) {
            strokeWeight(2);
            if (val == i) strokeWeight(4);
            rect(x, y + h * i, w, h, 0, 0, 0, 0);
        }
        strokeWeight(2);
        if (val == options.length - 1) strokeWeight(4);
        rect(x, y + h * (options.length - 1), w, h, 0, 0, 18, 18);
        fill(255);
        textAlign(CENTER, CENTER);
        for (int i = 0; i < options.length; i++) {
            text(options[i], x + w / 2, y + h * i + h / 2);
        }
        return val == oldval && !updated;
    }

    boolean update() {
        if (mousePressed) {
            for (int i = 0; i < options.length; i++) {
                if (mouseX >= x && mouseX <= x + w && mouseY >= y + h * i && mouseY <= y + h + h * i) {
                    val = i;
                    return true;
                }
            }
        }
        return false;
    }

    void setVal(int v){
        this.val = v;
    }
}