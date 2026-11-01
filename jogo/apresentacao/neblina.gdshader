// Neblina: banco baixo, mais denso rente ao chão e à água, desenhado em
// pontilhado (sem semitransparência) e derivando devagar para a direita.
shader_type canvas_item;

uniform float forca = 0.0;     // 0..1
uniform vec3 cor = vec3(0.725, 0.867, 0.863);
uniform float deriva = 0.0;    // deslocamento horizontal em pixels
uniform float altura = 118.0;  // linha mais densa
uniform vec2 origem = vec2(0.0, 16.0);

varying vec2 pos;

void vertex() {
	pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy - origem;
}

float bayer(ivec2 p) {
	int m[16] = int[](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return (float(m[(p.y & 3) * 4 + (p.x & 3)]) + 0.5) / 16.0;
}

void fragment() {
	ivec2 p = ivec2(floor(pos));
	float x = float(p.x) - deriva;
	float perto = 1.0 - clamp(abs(float(p.y) - altura) / 20.0, 0.0, 1.0);
	float bancos = 0.55 + 0.45 * sin(x * 0.041) * sin(x * 0.013 + 1.7);
	float densidade = forca * perto * perto * bancos * 0.6;
	COLOR = vec4(cor, bayer(p) < densidade ? 1.0 : 0.0);
}
