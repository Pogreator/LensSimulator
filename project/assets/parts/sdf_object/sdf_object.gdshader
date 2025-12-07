shader_type canvas_item;

uniform int type = 0;
uniform vec4 color : source_color;

float circle(vec2 position, float r){
	return length(position-vec2(0.5,0.5)) - r;
}

float box(vec2 position, float r){
	vec2 d = abs(position) - r;
	return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float concave(vec2 position, float r){
	return max(-circle(position+vec2(0.5,0),r),box(position,r*2.0));
}

void fragment() {
	float dist = 0.0;
	switch (type){
		case 0: dist = circle(UV,0.5); break;
		case 1: dist = box(UV,1.0); break;
		case 2: dist = circle(UV,0.5); break;
		case 3: dist = concave(UV,0.5); break;
	}
	if (dist > 0.0){
		COLOR = vec4(0.0,0.0,0.0,0.0);
	}
	else{
		COLOR = color;
	}
}
