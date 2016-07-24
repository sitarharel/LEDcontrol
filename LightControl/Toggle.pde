class Toggle {
    float x, y;
    boolean selected;
    String[] options;
    float w = 120;
    float h = 120;

    Toggle(float x, float y, float w, float h, String[] options, boolean selected) {
        this.x = x;
        this.y = y;
        this.options = options;
        this.w = w;
        this.h = h;
        this.selected = selected;
    }

    void draw(boolean post) {
        update(post);
        String buttontext = "";
        if(selected){
            fill(0, 200, 0);
            stroke(0, 255, 0);
            buttontext = options[0];
        }else{
            fill(200, 0, 0);
            stroke(255, 0, 0);
            buttontext = options[1];
        }
        strokeWeight(2);
        rect(x - w/2, y - h/2, w, h, 18, 18, 18, 18);
        fill(255);
        textAlign(CENTER, CENTER);
        text(buttontext, x, y);
    }

    void setSelected(boolean s){
        selected = s;
    }

    void update(boolean p) {
        if (mousePressed) {
            if (mouseX >= x - w/2 && mouseX <= x + w/2 && mouseY >= y - h/2 && mouseY <= y + h/2) {
                selected = !selected;
                if(p){
                    thread("makePost");
                }
            }
        }
    }

}