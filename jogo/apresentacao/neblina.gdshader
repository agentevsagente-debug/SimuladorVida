// Neblina da manhã: fiapos horizontais esparsos na base das montanhas, atrás da vila, num
// tom vizinho do fundo, derivando devagar para a direita. O padrão vem de um
// ruído fixo por pixel, nunca de uma grade, e não há semitransparência.
shader_type canvas_item;

uniform float forca = 0.0;     // 0..1
uniform vec3 cor = vec3(0.725, 0.867, 0.863);
uniform float deriva = 0.0;    // deslocamento horizontal em pixels
uniform float altura = 104.0;  // linha mais densa: a base das montanhas
uniform vec2 origem = vec2(0.0, 18.0);
uniform float zoom = 1.0;

varying vec2 pos;

void vertex() {
	pos = ((MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy - origem) / zoom;
}

float ruido(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	ivec2 p = ivec2(floor(pos));
	float x = float(p.x) - deriva;
	float perto = 1.0 - clamp(abs(float(p.y) - altura) / 8.0, 0.0, 1.0);
	float bancos = clamp(sin(x * 0.041) * sin(x * 0.013 + 1.7), 0.0, 1.0);
	float densidade = forca * perto * bancos * 0.25;
	// fiapos horizontais de 4 a 7 px (não pontos soltos, que liam como chuvisco):
	// o ruído é por trecho da linha, e anda junto com a deriva
	float trecho = floor((x + ruido(vec2(float(p.y), 3.0)) * 7.0) / (4.0 + floor(ruido(vec2(float(p.y), 9.0)) * 4.0)));
	COLOR = vec4(cor, ruido(vec2(trecho, float(p.y))) < densidade ? 1.0 : 0.0);
}
