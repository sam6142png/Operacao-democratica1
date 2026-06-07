shader_type canvas_item;

uniform float pixel_size : hint_range(1.0, 32.0, 1.0) = 6.0;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.08;

void fragment() {
	// Obtém a resolução da textura de entrada
	vec2 size = vec2(textureSize(TEXTURE, 0));
	
	// Arredonda a coordenada UV baseada no pixel_size para criar a pixelização
	vec2 uv = round(UV * size / pixel_size) * pixel_size / size;
	
	// Lê a cor da textura na coordenada pixelizada
	vec4 color = texture(TEXTURE, uv);
	
	// Adiciona efeito sutil de linhas de varredura (scanlines) CRT
	float scanline = sin(uv.y * size.y * 3.14159 / pixel_size) * scanline_strength;
	color.rgb -= scanline;
	
	COLOR = color;
}
