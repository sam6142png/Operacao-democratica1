extends Control

var time := 0.0
var binary_timer := 0.0
var binaries_top := []
var binaries_bottom := []

var font_mono = preload("res://ASSETS/FONTES/dogicapixel.ttf")

func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(false)
		return
	
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Popula arrays de binários para o estilo Hacker
	for i in range(40):
		binaries_top.append(str(randi() % 2))
		binaries_bottom.append(str(randi() % 2))

func _process(delta: float) -> void:
	time += delta
	binary_timer += delta
	if binary_timer > 0.18:
		binary_timer = 0.0
		# Atualiza binários aleatoriamente para efeito dinâmico
		for i in range(binaries_top.size()):
			if randf() < 0.25:
				binaries_top[i] = str(randi() % 2)
			if randf() < 0.25:
				binaries_bottom[i] = str(randi() % 2)
	queue_redraw()

func _draw() -> void:
	if Engine.is_editor_hint():
		return
		
	var estilo = ""
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		estilo = game_state.estilo_textbox_selecionado
	else:
		return
		
	var style_box: StyleBox = null
	if "XilografiaCariri" in estilo:
		style_box = load("res://ASSETS/DIALOGIC/STYLES/VisualNovelTextbox/xilografia_textbox_panel.tres")
	elif "JangadaRenda" in estilo:
		style_box = load("res://ASSETS/DIALOGIC/STYLES/VisualNovelTextbox/jangada_textbox_panel.tres")
	elif "NeonHacker" in estilo:
		style_box = load("res://ASSETS/DIALOGIC/STYLES/VisualNovelTextbox/neon_textbox_panel.tres")
	elif "PalacioDourado" in estilo:
		style_box = load("res://ASSETS/DIALOGIC/STYLES/VisualNovelTextbox/palacio_textbox_panel.tres")
		
	if style_box:
		draw_style_box(style_box, Rect2(Vector2.ZERO, size))

	if "XilografiaCariri" in estilo:
		_desenhar_xilografia()
	elif "JangadaRenda" in estilo:
		_desenhar_jangada()
	elif "NeonHacker" in estilo:
		_desenhar_neon()
	elif "PalacioDourado" in estilo:
		_desenhar_palacio()

func _desenhar_neon() -> void:
	# Grade verde futurista sutil
	var grid_color = Color("#00ff66", 0.07)
	var grid_size = 40
	for x in range(0, int(size.x), grid_size):
		draw_line(Vector2(x, 0), Vector2(x, size.y), grid_color, 1.0)
	for y in range(0, int(size.y), grid_size):
		draw_line(Vector2(0, y), Vector2(size.x, y), grid_color, 1.0)
		
	# Linhas de scanline (CRT antigo) em movimento
	var scan_color = Color("#00ff66", 0.04)
	var scan_spacing = 10.0
	var offset = fmod(time * 30.0, scan_spacing)
	var y = offset
	while y < size.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), scan_color, 1.5)
		y += scan_spacing

	# Fluxo de binários nas bordas superior e inferior
	var bin_color = Color("#00ff66", 0.7)
	var step_x = size.x / binaries_top.size()
	for i in range(binaries_top.size()):
		draw_string(font_mono, Vector2(i * step_x + 6, 16), binaries_top[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, bin_color)
		draw_string(font_mono, Vector2(i * step_x + 6, size.y - 7), binaries_bottom[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, bin_color)

func _desenhar_xilografia() -> void:
	var dark_color = Color("#1d1813")
	var light_color = Color("#f5ebd8")
	
	# Margem onde as estrelas e a linha interna do quadro serão desenhadas
	var margin = 26.0
	
	# Desenha linhas internas rústicas conectando as estrelas (quadro)
	draw_line(Vector2(margin, margin), Vector2(size.x - margin, margin), dark_color, 2.0)
	draw_line(Vector2(margin, size.y - margin), Vector2(size.x - margin, size.y - margin), dark_color, 2.0)
	draw_line(Vector2(margin, margin), Vector2(margin, size.y - margin), dark_color, 2.0)
	draw_line(Vector2(size.x - margin, margin), Vector2(size.x - margin, size.y - margin), dark_color, 2.0)

	# Desenha as estrelas procedurais de 8 pontas nos 4 cantos
	_desenhar_estrela_xilo(Vector2(margin, margin), 15.0, dark_color, light_color)
	_desenhar_estrela_xilo(Vector2(size.x - margin, margin), 15.0, dark_color, light_color)
	_desenhar_estrela_xilo(Vector2(margin, size.y - margin), 15.0, dark_color, light_color)
	_desenhar_estrela_xilo(Vector2(size.x - margin, size.y - margin), 15.0, dark_color, light_color)

func _desenhar_estrela_xilo(center: Vector2, radius: float, color: Color, bg_color: Color) -> void:
	# Estrela 1 (quadrado reto)
	var points1 = PackedVector2Array()
	# Estrela 2 (quadrado rotacionado 45 graus)
	var points2 = PackedVector2Array()
	
	for i in range(4):
		var a1 = i * PI / 2.0
		var a2 = a1 + PI / 4.0
		points1.append(center + Vector2(cos(a1), sin(a1)) * radius)
		points2.append(center + Vector2(cos(a2), sin(a2)) * radius)
		
	draw_colored_polygon(points1, color)
	draw_colored_polygon(points2, color)
	
	# Estrela interna menor para o efeito de entalhe (vazado)
	var points_in1 = PackedVector2Array()
	var points_in2 = PackedVector2Array()
	for i in range(4):
		var a1 = i * PI / 2.0
		var a2 = a1 + PI / 4.0
		points_in1.append(center + Vector2(cos(a1), sin(a1)) * (radius * 0.65))
		points_in2.append(center + Vector2(cos(a2), sin(a2)) * (radius * 0.65))
		
	draw_colored_polygon(points_in1, bg_color)
	draw_colored_polygon(points_in2, bg_color)
	
	# Núcleo da estrela
	draw_circle(center, radius * 0.22, color)


func _desenhar_jangada() -> void:
	# Ondas animadas no fundo inferior
	var wave_color = Color("#2d92d4", 0.15)
	var points = PackedVector2Array()
	for x in range(0, int(size.x) + 12, 12):
		var wave_y = size.y - 22 + sin(x * 0.025 + time * 2.5) * 6.0
		points.append(Vector2(x, wave_y))
	for i in range(points.size() - 1):
		draw_line(points[i], points[i+1], wave_color, 3.5)

	# Detalhe de renda de bilro (semi-círculos no topo)
	var lace_color = Color("#2d92d4", 0.45)
	var r = 12.0
	var step = r * 2.0
	var cx = r
	while cx < size.x:
		draw_arc(Vector2(cx, 16), r, 0, PI, 16, lace_color, 2.0)
		cx += step

func _desenhar_palacio() -> void:
	var gold_color = Color("#dfc17b")
	var gold_trans = Color("#dfc17b", 0.6)
	var bg_color = Color("#0b0f19")
	
	var m_out = 14.0
	var m_in = 22.0
	
	# 1. Moldura Externa Sólida (Espessura 2.0)
	draw_line(Vector2(m_out, m_out), Vector2(size.x - m_out, m_out), gold_color, 2.0)
	draw_line(Vector2(m_out, size.y - m_out), Vector2(size.x - m_out, size.y - m_out), gold_color, 2.0)
	draw_line(Vector2(m_out, m_out), Vector2(m_out, size.y - m_out), gold_color, 2.0)
	draw_line(Vector2(size.x - m_out, m_out), Vector2(size.x - m_out, size.y - m_out), gold_color, 2.0)

	# 2. Moldura Interna Delicada (Espessura 1.0, Transparente)
	draw_line(Vector2(m_in, m_in), Vector2(size.x - m_in, m_in), gold_trans, 1.0)
	draw_line(Vector2(m_in, size.y - m_in), Vector2(size.x - m_in, size.y - m_in), gold_trans, 1.0)
	draw_line(Vector2(m_in, m_in), Vector2(m_in, size.y - m_in), gold_trans, 1.0)
	draw_line(Vector2(size.x - m_in, m_in), Vector2(size.x - m_in, size.y - m_in), gold_trans, 1.0)

	# 3. Insígnias Imperiais de Canto (Círculo + Diamante + Núcleo Vazado)
	var cantos = [
		Vector2(m_in, m_in),
		Vector2(size.x - m_in, m_in),
		Vector2(m_in, size.y - m_in),
		Vector2(size.x - m_in, size.y - m_in)
	]
	
	for c in cantos:
		# Círculo Externo
		draw_arc(c, 10.0, 0, TAU, 32, gold_color, 1.5)
		
		# Diamante Interno Preenchido
		var points = PackedVector2Array([
			c + Vector2(0, -5),
			c + Vector2(5, 0),
			c + Vector2(0, 5),
			c + Vector2(-5, 0)
		])
		draw_colored_polygon(points, gold_color)
		
		# Núcleo do fundo (vazado)
		draw_circle(c, 1.5, bg_color)

	# 4. Ornamentos Centrais Estilizados (Losango e Asas)
	var centros = [
		Vector2(size.x / 2.0, (m_out + m_in) / 2.0), # Centro Superior
		Vector2(size.x / 2.0, size.y - (m_out + m_in) / 2.0) # Centro Inferior
	]
	
	for c in centros:
		# Losango Central
		var points = PackedVector2Array([
			c + Vector2(0, -3.5),
			c + Vector2(3.5, 0),
			c + Vector2(0, 3.5),
			c + Vector2(-3.5, 0)
		])
		draw_colored_polygon(points, gold_color)
		
		# Asas Horizontais
		draw_line(c + Vector2(-3.5, 0), c + Vector2(-18.5, 0), gold_color, 1.0)
		draw_line(c + Vector2(3.5, 0), c + Vector2(18.5, 0), gold_color, 1.0)

