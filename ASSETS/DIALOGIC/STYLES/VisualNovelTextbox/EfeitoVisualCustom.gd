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
	var estilo = GameState.estilo_textbox_selecionado
	if "XilografiaCariri" in estilo:
		_desenhar_xilografia()
	elif "JangadaRenda" in estilo:
		_desenhar_jangada()
	elif "NeonHacker" in estilo:
		_desenhar_neon()
	elif "PalacioDourado" in estilo:
		_desenhar_palacio()

func _desenhar_neon() -> void:
	# Fundo verde-escuro quase preto de terminal
	draw_rect(Rect2(Vector2.ZERO, size), Color("#010603", 0.96))
	
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

	# Borda verde neon com glow (dupla)
	draw_rect(Rect2(Vector2.ZERO, size), Color("#00ff66", 0.85), false, 2.0)
	draw_rect(Rect2(Vector2(-1, -1), size + Vector2(2, 2)), Color("#00ff66", 0.22), false, 4.0)

	# Fluxo de binários nas bordas superior e inferior
	var bin_color = Color("#00ff66", 0.7)
	var step_x = size.x / binaries_top.size()
	for i in range(binaries_top.size()):
		draw_string(font_mono, Vector2(i * step_x + 6, 16), binaries_top[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, bin_color)
		draw_string(font_mono, Vector2(i * step_x + 6, size.y - 7), binaries_bottom[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, bin_color)

func _desenhar_xilografia() -> void:
	# Fundo papel antigo amarelado
	draw_rect(Rect2(Vector2.ZERO, size), Color("#f5ebd8"))
	
	# Borda grossa rústica imitando corte de madeira
	var border_color = Color("#1d1813")
	draw_rect(Rect2(Vector2(4, 4), size - Vector2(8, 8)), border_color, false, 5.0)
	# Segunda linha fina interna irregular
	draw_rect(Rect2(Vector2(12, 12), size - Vector2(24, 24)), border_color, false, 1.5)
	
	# Hachuras de madeira entalhada nos cantos
	var wood_color = Color("#1d1813", 0.8)
	for i in range(6):
		var d = i * 8
		# Superior Esquerdo
		draw_line(Vector2(16 + d, 16), Vector2(16, 16 + d), wood_color, 2.0)
		# Superior Direito
		draw_line(Vector2(size.x - 16 - d, 16), Vector2(size.x - 16, 16 + d), wood_color, 2.0)
		# Inferior Esquerdo
		draw_line(Vector2(16 + d, size.y - 16), Vector2(16, size.y - 16 - d), wood_color, 2.0)
		# Inferior Direito
		draw_line(Vector2(size.x - 16 - d, size.y - 16), Vector2(size.x - 16, size.y - 16 - d), wood_color, 2.0)

func _desenhar_jangada() -> void:
	# Fundo azul-celeste claro litorâneo
	draw_rect(Rect2(Vector2.ZERO, size), Color("#ebf6ff", 0.97))
	
	# Ondas animadas no fundo inferior
	var wave_color = Color("#2d92d4", 0.15)
	var points = PackedVector2Array()
	for x in range(0, int(size.x) + 12, 12):
		var wave_y = size.y - 22 + sin(x * 0.025 + time * 2.5) * 6.0
		points.append(Vector2(x, wave_y))
	for i in range(points.size() - 1):
		draw_line(points[i], points[i+1], wave_color, 3.5)

	# Borda azul-jangada
	draw_rect(Rect2(Vector2.ZERO, size), Color("#2d92d4"), false, 3.0)

	# Detalhe de renda de bilro (semi-círculos no topo)
	var lace_color = Color("#2d92d4", 0.45)
	var r = 12.0
	var step = r * 2.0
	var cx = r
	while cx < size.x:
		draw_arc(Vector2(cx, 16), r, 0, PI, 16, lace_color, 2.0)
		cx += step

func _desenhar_palacio() -> void:
	# Fundo azul-marinho nobre
	draw_rect(Rect2(Vector2.ZERO, size), Color("#0a0f1d", 0.98))
	
	var gold_color = Color("#ffd700")
	var gold_shadow = Color("#b8860b")

	# Bordas duplas de ouro
	draw_rect(Rect2(Vector2.ZERO, size), gold_color, false, 3.0)
	draw_rect(Rect2(Vector2(5, 5), size - Vector2(10, 10)), gold_shadow, false, 1.5)

	# Cantoneiras clássicas douradas (Laureados)
	var offset = 14.0
	var length = 40.0
	# Superior Esquerda
	draw_line(Vector2(offset, offset), Vector2(offset + length, offset), gold_color, 2.5)
	draw_line(Vector2(offset, offset), Vector2(offset, offset + length), gold_color, 2.5)
	# Superior Direita
	draw_line(Vector2(size.x - offset, offset), Vector2(size.x - offset - length, offset), gold_color, 2.5)
	draw_line(Vector2(size.x - offset, offset), Vector2(size.x - offset, offset + length), gold_color, 2.5)
	# Inferior Esquerda
	draw_line(Vector2(offset, size.y - offset), Vector2(offset + length, size.y - offset), gold_color, 2.5)
	draw_line(Vector2(offset, size.y - offset), Vector2(offset, size.y - offset - length), gold_color, 2.5)
	# Inferior Direita
	draw_line(Vector2(size.x - offset, size.y - offset), Vector2(size.x - offset - length, size.y - offset), gold_color, 2.5)
	draw_line(Vector2(size.x - offset, size.y - offset), Vector2(size.x - offset, size.y - offset - length), gold_color, 2.5)
