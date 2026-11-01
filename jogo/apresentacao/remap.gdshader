// Troca de cores por horário, com as tabelas de arte/camadas/tabelas_luz.json.
//
// Todas as peças vêm nas cores de dia. O horário é uma mistura de dois estados
// (A e B: 0 dia, 1 entardecer, 2 noite) com fração t; cada pixel escolhe A ou B
// por pontilhado ordenado (Bayer 4 × 4), sem semitransparência. As regras de
// cada plano seguem montagem/montar.py (noite) e alvo/cena.py (entardecer).
shader_type canvas_item;

// Linhas da textura de tabelas (32 colunas, uma por cor da paleta).
const int DIA = 0;
const int ENTARDECER = 1;
const int NOITE = 2;
const int FOGO_MEDIO = 3;
const int FOGO_PERTO = 4;
const int NOITE_AGUA = 5;
const int HALO_CEU = 6;
const int FRENTE_NOITE = 7;
const int CONTORNO = 8;

// Planos.
const int FUNDO = 0;     // céu, montanhas, mata: textura A + tex_b, halo à noite
const int MUNDO = 1;     // terreno e peças fixas, com etiquetas e superfície
const int PESSOA = 2;    // pessoas: modulate traz (centro x, fogo x, espelho)
const int FRENTE = 3;    // primeiro plano, silhueta à noite
const int AGUA = 4;      // superfície animada da água
const int REFLEXO = 5;   // reflexo: textura A + tex_b, sem troca

uniform int plano = 0;
uniform vec3 paleta[32];
uniform sampler2D tabelas : filter_nearest, repeat_disable;
uniform int estado_a = 0;
uniform int estado_b = 0;
uniform float t = 0.0;
uniform sampler2D tex_b : filter_nearest, repeat_disable;
uniform sampler2D etiquetas : filter_nearest, repeat_disable;  // 480 × 160, R = etiqueta
uniform sampler2D superficie : filter_nearest, repeat_disable; // 480 × 1, R = y da superfície
uniform sampler2D luz : filter_nearest, repeat_disable;        // 128 × 80
uniform sampler2D halo : filter_nearest, repeat_disable;       // 128 × 80
uniform vec2 fogos[4];   // canto do mapa de luz de cada fogueira (já com −56, −32)
uniform int n_fogos = 0;
uniform vec2 origem = vec2(0.0, 16.0);  // onde a vista começa na tela base

varying vec2 pos;
varying vec4 info;

void vertex() {
	pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy - origem;
	info = COLOR;
}

float bayer(ivec2 p) {
	int m[16] = int[](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return (float(m[(p.y & 3) * 4 + (p.x & 3)]) + 0.5) / 16.0;
}

int indice(vec3 c) {
	for (int i = 0; i < 32; i++) {
		if (distance(c, paleta[i]) < 0.01) {
			return i;
		}
	}
	return -1;
}

vec3 trocar(vec3 c, int linha) {
	int i = indice(c);
	if (i < 0 || linha == DIA) {
		return c;
	}
	return texelFetch(tabelas, ivec2(i, linha), 0).rgb;
}

// 0 = escuro, 1 = luz média, 2 = luz perto; o maior entre as fogueiras.
int nivel(sampler2D mapa, ivec2 p) {
	int n = 0;
	for (int i = 0; i < 4; i++) {
		if (i >= n_fogos) {
			break;
		}
		ivec2 l = p - ivec2(fogos[i]);
		if (l.x >= 0 && l.y >= 0 && l.x < 128 && l.y < 80) {
			float v = texelFetch(mapa, l, 0).r;
			n = max(n, v > 0.78 ? 2 : (v > 0.235 ? 1 : 0));
		}
	}
	return n;
}

int etiqueta(ivec2 p) {
	if (p.y < 0 || p.y >= 160 || p.x < 0 || p.x >= 480) {
		return 0;
	}
	return int(round(texelFetch(etiquetas, p, 0).r * 255.0));
}

int linha_de_luz(int n) {
	return n >= 2 ? FOGO_PERTO : (n == 1 ? FOGO_MEDIO : NOITE);
}

void fragment() {
	ivec2 p = ivec2(floor(pos));
	bool usa_b = bayer(p) < t;
	int estado = usa_b ? estado_b : estado_a;
	vec4 cor = texture(TEXTURE, UV);
	if (plano == FUNDO || plano == REFLEXO) {
		if (usa_b) {
			cor = texture(tex_b, UV);
		}
	}
	vec3 c = cor.rgb;

	if (plano == FUNDO) {
		if (estado == NOITE && nivel(halo, p) > 0) {
			c = trocar(c, HALO_CEU);
		}
	} else if (plano == MUNDO) {
		int tag = etiqueta(p);
		if (estado == ENTARDECER) {
			// o tom 15 só fica dourado onde há céu logo acima
			if (indice(c) != 15 || etiqueta(p - ivec2(0, 1)) == 0) {
				c = trocar(c, ENTARDECER);
			}
		} else if (estado == NOITE) {
			if (tag == 4) {
				c = trocar(c, NOITE_AGUA);
			} else {
				float s = round(texelFetch(superficie, ivec2(p.x, 0), 0).r * 255.0);
				c = trocar(c, float(p.y) > s + 3.0 ? NOITE : linha_de_luz(nivel(luz, p)));
			}
		}
	} else if (plano == PESSOA) {
		if (estado == ENTARDECER) {
			// luz de contorno: o sol baixo à esquerda acende a borda esquerda
			float passo = TEXTURE_PIXEL_SIZE.x * (info.b > 0.5 ? 1.0 : -1.0);
			vec2 viz = UV + vec2(passo, 0.0);
			bool borda = viz.x < 0.0 || viz.x > 1.0 || texture(TEXTURE, viz).a == 0.0;
			if (borda) {
				c = trocar(c, CONTORNO);
			}
		} else if (estado == NOITE) {
			int n = nivel(luz, p);
			float centro = info.r * 512.0;
			float fogo = info.g * 512.0;
			float px = float(p.x) + 0.5;
			bool perto = abs(px - fogo) < abs(centro - fogo) || (px - fogo) * (centro - fogo) <= 0.0;
			if (!perto) {
				n -= 1;
			}
			c = trocar(c, linha_de_luz(n));
		}
	} else if (plano == FRENTE) {
		if (estado == NOITE) {
			c = trocar(c, FRENTE_NOITE);
		} else if (estado == ENTARDECER) {
			c = trocar(c, ENTARDECER);
		}
	} else if (plano == AGUA) {
		if (estado == NOITE) {
			c = trocar(c, NOITE_AGUA);
		}
	}
	COLOR = vec4(c, cor.a);
}
