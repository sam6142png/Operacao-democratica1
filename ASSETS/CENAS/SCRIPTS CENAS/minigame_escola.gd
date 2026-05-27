extends Control

# === RECURSOS ===
const FONTE = preload("res://ASSETS/FONTES/determination.ttf")

# === DADOS DO CIRCUITO ===
# 5x5 grid de tipos de fio
const SHAPES = [
	["corner", "straight", "tjunction", "straight", "corner"],
	["straight", "corner", "straight", "corner", "straight"],
	["straight", "tjunction", "cross", "tjunction", "straight"],
	["straight", "corner", "straight", "corner", "straight"],
	["corner", "straight", "tjunction", "straight", "corner"]
]

# === ESTADO DO JOGO ===
var grid_shapes = []
var grid_rotations = []
var grid_connected = []
var finalizado := false

# === UI COMPONENTS ===
var layer: CanvasLayer
var panel_main: PanelContainer
var grid_container: GridContainer
var painel_overlay: PanelContainer
var lbl_status_desc: Label
var indicator_status: Label
var btn_finish: Button

# Referências dos botões
var cell_buttons = []

func _ready() -> void:
	if get_tree().root.has_node("MedidorConfianca"):
		get_tree().root.get_node("MedidorConfianca").visible = false
		
	_inicializar_tabuleiro()
	_construir_ui()
	_mostrar_intro()
	_atualizar_circuito()

# ══════════════════════════════════════════════
#  INICIALIZAÇÃO E EMBARALHAMENTO DO CIRCUITO
# ══════════════════════════════════════════════

func _inicializar_tabuleiro() -> void:
	grid_shapes = SHAPES.duplicate(true)
	
	# Aloca as matrizes de rotação e conectividade
	grid_rotations = []
	grid_connected = []
	for r in range(5):
		var row_rot = []
		var row_con = []
		for c in range(5):
			row_rot.append(0)
			row_con.append(false)
		grid_rotations.append(row_rot)
		grid_connected.append(row_con)
		
	# Embaralha as rotações garantindo que o jogo não comece resolvido
	var resolvido = true
	while resolvido:
		for r in range(5):
			for c in range(5):
				grid_rotations[r][c] = randi() % 4
		
		# Atualiza conectividade temporariamente
		_calcular_DFS()
		
		# O jogo está resolvido se a saída (2, 4) estiver conectada e com abertura à direita (1)
		var vitoria = grid_connected[2][4] and (1 in _obter_aberturas(grid_shapes[2][4], grid_rotations[2][4]))
		if not vitoria:
			resolvido = false

# ══════════════════════════════════════════════
#  CONSTRUÇÃO DA UI DINÂMICA
# ══════════════════════════════════════════════

func _construir_ui() -> void:
	layer = CanvasLayer.new()
	add_child(layer)
	
	# Fundo escuro tecnológico (reutiliza painel do rádio como console)
	var bg = TextureRect.new()
	var bg_tex = load("res://ASSETS/SPRITES/FUNDOS/RadioPainel.png")
	if bg_tex:
		bg.texture = bg_tex
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.modulate = Color(0.4, 0.7, 0.5) # Modula verde militar escuro
	else:
		var color_rect = ColorRect.new()
		color_rect.color = Color(0.01, 0.02, 0.01, 1.0)
		bg = color_rect
	bg.set_anchors_preset(PRESET_FULL_RECT)
	layer.add_child(bg)
	
	# Overlay de grid de monitor sutil
	var bg_grid = Control.new()
	bg_grid.set_anchors_preset(PRESET_FULL_RECT)
	bg_grid.modulate = Color(0.0, 1.0, 0.4, 0.02)
	bg_grid.draw.connect(func():
		var step = 30
		var g_size = bg_grid.size
		for x in range(0, int(g_size.x), step):
			bg_grid.draw_line(Vector2(x, 0), Vector2(x, g_size.y), Color.WHITE, 1.0)
		for y in range(0, int(g_size.y), step):
			bg_grid.draw_line(Vector2(0, y), Vector2(g_size.x, y), Color.WHITE, 1.0)
	)
	layer.add_child(bg_grid)

	# Main Panel (Terminal Verde Cibernético)
	panel_main = PanelContainer.new()
	panel_main.custom_minimum_size = Vector2(960, 650)
	panel_main.set_anchors_preset(PRESET_CENTER)
	panel_main.grow_horizontal = GROW_DIRECTION_BOTH
	panel_main.grow_vertical = GROW_DIRECTION_BOTH
	
	var sb_main = StyleBoxFlat.new()
	sb_main.bg_color = Color(0.03, 0.05, 0.03, 0.96)
	sb_main.border_width_left = 3; sb_main.border_width_top = 3
	sb_main.border_width_right = 3; sb_main.border_width_bottom = 3
	sb_main.border_color = Color("#00FF66") # Verde Néon
	sb_main.corner_radius_top_left = 12; sb_main.corner_radius_top_right = 12
	sb_main.corner_radius_bottom_left = 12; sb_main.corner_radius_bottom_right = 12
	sb_main.shadow_size = 20
	sb_main.shadow_color = Color("#00FF66", 0.08)
	panel_main.add_theme_stylebox_override("panel", sb_main)
	layer.add_child(panel_main)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	panel_main.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)
	
	# Cabeçalho
	var lbl_title = Label.new()
	lbl_title.text = "CAIXA DE DISTRIBUIÇÃO E AMPLIFICAÇÃO"
	lbl_title.add_theme_font_override("font", FONTE)
	lbl_title.add_theme_font_size_override("font_size", 34)
	lbl_title.add_theme_color_override("font_color", Color("#00FF66"))
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_title)
	
	# Conteúdo Principal (Transmissor + Grid + Alto-falante)
	var hbox_content = HBoxContainer.new()
	hbox_content.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_content.add_theme_constant_override("separation", 25)
	hbox_content.size_flags_vertical = SIZE_EXPAND_FILL
	vbox.add_child(hbox_content)
	
	# 1. Painel Esquerdo: Entrada do Sinal
	var panel_source = PanelContainer.new()
	panel_source.custom_minimum_size = Vector2(160, 200)
	panel_source.size_flags_vertical = SIZE_SHRINK_CENTER
	var sb_source = StyleBoxFlat.new()
	sb_source.bg_color = Color(0.01, 0.04, 0.01, 0.8)
	sb_source.border_width_left = 2; sb_source.border_width_top = 2
	sb_source.border_width_right = 2; sb_source.border_width_bottom = 2
	sb_source.border_color = Color("#00FF66", 0.4)
	sb_source.corner_radius_top_left = 6; sb_source.corner_radius_top_right = 6
	sb_source.corner_radius_bottom_left = 6; sb_source.corner_radius_bottom_right = 6
	panel_source.add_theme_stylebox_override("panel", sb_source)
	hbox_content.add_child(panel_source)
	
	var vbox_source = VBoxContainer.new()
	vbox_source.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_source.add_theme_constant_override("separation", 10)
	panel_source.add_child(vbox_source)
	
	var lbl_source_title = Label.new()
	lbl_source_title.text = "SINAL ENTRADA"
	lbl_source_title.add_theme_font_override("font", FONTE)
	lbl_source_title.add_theme_font_size_override("font_size", 18)
	lbl_source_title.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
	lbl_source_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_source.add_child(lbl_source_title)
	
	var lbl_source_val = Label.new()
	lbl_source_val.text = "RÁDIO LIVRE\n[ 98.3 MHz ]"
	lbl_source_val.add_theme_font_override("font", FONTE)
	lbl_source_val.add_theme_font_size_override("font_size", 20)
	lbl_source_val.add_theme_color_override("font_color", Color("#00FF66"))
	lbl_source_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_source.add_child(lbl_source_val)
	
	# Terminal esquerdo de conexão visual
	var connector_left = Control.new()
	connector_left.custom_minimum_size = Vector2(30, 20)
	connector_left.draw.connect(func():
		# Desenha linha neon horizontal conectando o painel de entrada à grade
		connector_left.draw_line(Vector2(0, 10), Vector2(30, 10), Color("#00FF66", 0.3), 8.0)
		connector_left.draw_line(Vector2(0, 10), Vector2(30, 10), Color("#00FF66"), 4.0)
		connector_left.draw_line(Vector2(0, 10), Vector2(30, 10), Color.WHITE, 1.5)
	)
	hbox_content.add_child(connector_left)

	# 2. Painel Central: Grade 5x5
	var panel_grid = PanelContainer.new()
	var sb_grid = StyleBoxFlat.new()
	sb_grid.bg_color = Color(0.01, 0.02, 0.01, 0.9)
	sb_grid.border_width_left = 2; sb_grid.border_width_top = 2
	sb_grid.border_width_right = 2; sb_grid.border_width_bottom = 2
	sb_grid.border_color = Color("#00FF66")
	sb_grid.corner_radius_top_left = 8; sb_grid.corner_radius_top_right = 8
	sb_grid.corner_radius_bottom_left = 8; sb_grid.corner_radius_bottom_right = 8
	panel_grid.add_theme_stylebox_override("panel", sb_grid)
	hbox_content.add_child(panel_grid)
	
	var margin_grid = MarginContainer.new()
	margin_grid.add_theme_constant_override("margin_top", 10)
	margin_grid.add_theme_constant_override("margin_bottom", 10)
	margin_grid.add_theme_constant_override("margin_left", 10)
	margin_grid.add_theme_constant_override("margin_right", 10)
	panel_grid.add_child(margin_grid)
	
	grid_container = GridContainer.new()
	grid_container.columns = 5
	grid_container.add_theme_constant_override("h_separation", 6)
	grid_container.add_theme_constant_override("v_separation", 6)
	margin_grid.add_child(grid_container)
	
	# Cria botões da grade
	cell_buttons = []
	for r in range(5):
		var row_btns = []
		for c in range(5):
			var btn = Button.new()
			btn.flat = true
			btn.custom_minimum_size = Vector2(80, 80)
			btn.focus_mode = Control.FOCUS_NONE
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			
			# Configura eventos usando lambdas locais
			btn.pressed.connect(_on_cell_clicked.bind(r, c))
			btn.draw.connect(_draw_cell.bind(btn, r, c))
			
			grid_container.add_child(btn)
			row_btns.append(btn)
		cell_buttons.append(row_btns)
		
	# Terminal direito de conexão visual
	var connector_right = Control.new()
	connector_right.custom_minimum_size = Vector2(30, 20)
	connector_right.draw.connect(func():
		var active = finalizado
		var color = Color("#00FF66") if active else Color("#374151")
		var glow = Color("#00FF66", 0.3) if active else Color(0,0,0,0)
		connector_right.draw_line(Vector2(0, 10), Vector2(30, 10), glow, 8.0)
		connector_right.draw_line(Vector2(0, 10), Vector2(30, 10), color, 4.0)
		if active:
			connector_right.draw_line(Vector2(0, 10), Vector2(30, 10), Color.WHITE, 1.5)
	)
	hbox_content.add_child(connector_right)

	# 3. Painel Direito: Alto-falante de Saída
	var panel_dest = PanelContainer.new()
	panel_dest.custom_minimum_size = Vector2(160, 200)
	panel_dest.size_flags_vertical = SIZE_SHRINK_CENTER
	var sb_dest = StyleBoxFlat.new()
	sb_dest.bg_color = Color(0.01, 0.04, 0.01, 0.8)
	sb_dest.border_width_left = 2; sb_dest.border_width_top = 2
	sb_dest.border_width_right = 2; sb_dest.border_width_bottom = 2
	sb_dest.border_color = Color("#00FF66", 0.4)
	sb_dest.corner_radius_top_left = 6; sb_dest.corner_radius_top_right = 6
	sb_dest.corner_radius_bottom_left = 6; sb_dest.corner_radius_bottom_right = 6
	panel_dest.add_theme_stylebox_override("panel", sb_dest)
	hbox_content.add_child(panel_dest)
	
	var vbox_dest = VBoxContainer.new()
	vbox_dest.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_dest.add_theme_constant_override("separation", 10)
	panel_dest.add_child(vbox_dest)
	
	var lbl_dest_title = Label.new()
	lbl_dest_title.text = "ALTO-FALANTES"
	lbl_dest_title.add_theme_font_override("font", FONTE)
	lbl_dest_title.add_theme_font_size_override("font_size", 18)
	lbl_dest_title.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
	lbl_dest_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_dest.add_child(lbl_dest_title)
	
	indicator_status = Label.new()
	indicator_status.text = "DESCONECTADO"
	indicator_status.add_theme_font_override("font", FONTE)
	indicator_status.add_theme_font_size_override("font_size", 20)
	indicator_status.add_theme_color_override("font_color", Color("#FF4444"))
	indicator_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_dest.add_child(indicator_status)
	
	# Área inferior: Status e Botão
	var vbox_bottom = VBoxContainer.new()
	vbox_bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_bottom.add_theme_constant_override("separation", 10)
	vbox.add_child(vbox_bottom)
	
	lbl_status_desc = Label.new()
	lbl_status_desc.text = "CONECTE O CABO DE ENTRADA (LINHA 3) AO CABO DE SAÍDA"
	lbl_status_desc.add_theme_font_override("font", FONTE)
	lbl_status_desc.add_theme_font_size_override("font_size", 20)
	lbl_status_desc.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
	lbl_status_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_bottom.add_child(lbl_status_desc)
	
	btn_finish = Button.new()
	btn_finish.text = "CONCLUIR CONEXÃO"
	btn_finish.custom_minimum_size = Vector2(350, 50)
	btn_finish.add_theme_font_override("font", FONTE)
	btn_finish.add_theme_font_size_override("font_size", 22)
	btn_finish.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	
	var sb_finish = StyleBoxFlat.new()
	sb_finish.bg_color = Color(0.0, 0.5, 0.2, 0.9)
	sb_finish.border_width_left = 2; sb_finish.border_width_top = 2
	sb_finish.border_width_right = 2; sb_finish.border_width_bottom = 2
	sb_finish.border_color = Color("#00FF66")
	sb_finish.corner_radius_top_left = 6; sb_finish.corner_radius_top_right = 6
	sb_finish.corner_radius_bottom_left = 6; sb_finish.corner_radius_bottom_right = 6
	
	var sb_finish_h = sb_finish.duplicate() as StyleBoxFlat
	sb_finish_h.bg_color = Color(0.0, 0.7, 0.3)
	sb_finish_h.shadow_size = 10
	sb_finish_h.shadow_color = Color("#00FF66", 0.3)
	
	btn_finish.add_theme_stylebox_override("normal", sb_finish)
	btn_finish.add_theme_stylebox_override("hover", sb_finish_h)
	btn_finish.add_theme_stylebox_override("pressed", sb_finish_h)
	btn_finish.pressed.connect(_on_finish_pressed)
	btn_finish.visible = false
	btn_finish.size_flags_horizontal = SIZE_SHRINK_CENTER
	vbox_bottom.add_child(btn_finish)

# ══════════════════════════════════════════════
#  LÓGICA DO QUEBRA-CABEÇA E DFS
# ══════════════════════════════════════════════

func _on_cell_clicked(r: int, c: int) -> void:
	if finalizado: return
	
	# Gira o bloco 90 graus no sentido horário
	grid_rotations[r][c] = (grid_rotations[r][c] + 1) % 4
	
	# Recalcula o circuito e redesenha as células
	_atualizar_circuito()

func _atualizar_circuito() -> void:
	_calcular_DFS()
	
	# Redesenha todas as células
	for r in range(5):
		for c in range(5):
			cell_buttons[r][c].queue_redraw()
			
	# Redesenha o terminal de saída
	layer.get_child(layer.get_child_count() - 2).queue_redraw()
	
	# O sinal deve chegar a (2, 4) e poder sair pelo lado direito (abertura 1)
	var vitoria = grid_connected[2][4] and (1 in _obter_aberturas(grid_shapes[2][4], grid_rotations[2][4]))
	
	if vitoria and not finalizado:
		_vitoria()

func _calcular_DFS() -> void:
	# Reseta conectividade
	for r in range(5):
		for c in range(5):
			grid_connected[r][c] = false
			
	# Entrada de sinal pelo lado esquerdo (3) na célula (2, 0)
	if 3 in _obter_aberturas(grid_shapes[2][0], grid_rotations[2][0]):
		_dfs_recurse(2, 0)

func _dfs_recurse(r: int, c: int) -> void:
	grid_connected[r][c] = true
	
	var aberturas = _obter_aberturas(grid_shapes[r][c], grid_rotations[r][c])
	
	# Direções: 0: UP, 1: RIGHT, 2: DOWN, 3: LEFT
	for a in aberturas:
		match a:
			0: # UP
				if r > 0 and not grid_connected[r-1][c]:
					# Vizinho deve ter saída DOWN (2)
					if 2 in _obter_aberturas(grid_shapes[r-1][c], grid_rotations[r-1][c]):
						_dfs_recurse(r-1, c)
			1: # RIGHT
				if c < 4 and not grid_connected[r][c+1]:
					# Vizinho deve ter saída LEFT (3)
					if 3 in _obter_aberturas(grid_shapes[r][c+1], grid_rotations[r][c+1]):
						_dfs_recurse(r, c+1)
			2: # DOWN
				if r < 4 and not grid_connected[r+1][c]:
					# Vizinho deve ter saída UP (0)
					if 0 in _obter_aberturas(grid_shapes[r+1][c], grid_rotations[r+1][c]):
						_dfs_recurse(r+1, c)
			3: # LEFT
				if c > 0 and not grid_connected[r][c-1]:
					# Vizinho deve ter saída RIGHT (1)
					if 1 in _obter_aberturas(grid_shapes[r][c-1], grid_rotations[r][c-1]):
						_dfs_recurse(r, c-1)

func _obter_aberturas(shape: String, rot: int) -> Array:
	var padrao = []
	match shape:
		"straight": padrao = [3, 1] # Horizontal
		"corner": padrao = [3, 2] # Canto inferior esquerdo
		"tjunction": padrao = [3, 2, 1] # T apontando para baixo
		"cross": padrao = [0, 1, 2, 3] # Todos
		"empty": padrao = []
		
	var aberturas = []
	for d in padrao:
		aberturas.append((d + rot) % 4)
	return aberturas

# ══════════════════════════════════════════════
#  DESENHO DOS FIOS (NEON GLOW)
# ══════════════════════════════════════════════

func _draw_cell(btn: Button, r: int, c: int) -> void:
	var size_rect = btn.size
	var is_connected = grid_connected[r][c]
	
	# Fundo da célula
	var bg_color = Color(0.01, 0.05, 0.02) if is_connected else Color(0.02, 0.02, 0.03)
	var border_color = Color("#00FF66", 0.4) if is_connected else Color(0.12, 0.16, 0.22)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_width_left = 1; sb.border_width_top = 1
	sb.border_width_right = 1; sb.border_width_bottom = 1
	sb.border_color = border_color
	sb.corner_radius_top_left = 4; sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4; sb.corner_radius_bottom_right = 4
	
	# Destaque de hover
	if btn.is_hovered() and not finalizado:
		sb.bg_color = sb.bg_color.lightened(0.06)
		sb.border_color = Color("#00FF66", 0.7)
		
	btn.draw_style_box(sb, Rect2(Vector2.ZERO, size_rect))
	
	var shape = grid_shapes[r][c]
	var rot = grid_rotations[r][c]
	if shape == "empty": return
	
	var aberturas = _obter_aberturas(shape, rot)
	var center = size_rect / 2.0
	
	# Plota cada segmento do fio
	for a in aberturas:
		var target_pos = Vector2.ZERO
		match a:
			0: target_pos = Vector2(center.x, 0) # UP
			1: target_pos = Vector2(size_rect.x, center.y) # RIGHT
			2: target_pos = Vector2(center.x, size_rect.y) # DOWN
			3: target_pos = Vector2(0, center.y) # LEFT
			
		_draw_neon_segment(btn, center, target_pos, is_connected)
		
	# Desenha terminal central
	var term_color = Color("#00FF66") if is_connected else Color(0.25, 0.35, 0.45)
	btn.draw_circle(center, 4.0, term_color)
	if is_connected:
		btn.draw_circle(center, 1.5, Color.WHITE)

func _draw_neon_segment(btn: Button, from: Vector2, to: Vector2, active: bool) -> void:
	var color = Color("#00FF66") if active else Color(0.2, 0.25, 0.3)
	var glow = Color("#00FF66", 0.22) if active else Color(0, 0, 0, 0)
	
	if active:
		# Camada de glow
		btn.draw_line(from, to, glow, 8.0)
		btn.draw_line(from, to, color, 4.0)
		btn.draw_line(from, to, Color.WHITE, 1.5)
	else:
		btn.draw_line(from, to, color, 3.0)

# ══════════════════════════════════════════════
#  VÍTÓRIA E ENCERRAMENTO
# ══════════════════════════════════════════════

func _vitoria() -> void:
	finalizado = true
	
	lbl_status_desc.text = "SINAL ATIVO! CAIXAS DE SOM REDIRECIONADAS COM SUCESSO."
	lbl_status_desc.add_theme_color_override("font_color", Color("#00FF66"))
	
	indicator_status.text = "ATENÇÃO:\nRÁDIO LIVRE"
	indicator_status.add_theme_color_override("font_color", Color("#00FF66"))
	
	# Efeito visual de piscar
	var tween = create_tween()
	var original_mod = panel_main.modulate
	tween.tween_property(panel_main, "modulate", Color(0.5, 2.0, 0.8, 1.0), 0.1)
	tween.tween_property(panel_main, "modulate", original_mod, 0.4)
	
	btn_finish.visible = true

func _on_finish_pressed() -> void:
	# Reabilita medidor de confiança
	if get_tree().root.has_node("MedidorConfianca"):
		get_tree().root.get_node("MedidorConfianca").visible = true
		
	# Avança o estado de Fase 3
	GameState.fase3_passo = "escola_concluida"
	GameState.salvar_jogo()
	
	# Volta para a cena principal
	FadeManager.carregar_cena("res://ASSETS/CENAS/game_scene.tscn")

# ══════════════════════════════════════════════
#  TUTORIAL POPUP INICIAL
# ══════════════════════════════════════════════

func _mostrar_intro() -> void:
	panel_main.visible = false
	
	painel_overlay = PanelContainer.new()
	painel_overlay.custom_minimum_size = Vector2(800, 500)
	painel_overlay.set_anchors_preset(PRESET_CENTER)
	painel_overlay.grow_horizontal = GROW_DIRECTION_BOTH
	painel_overlay.grow_vertical = GROW_DIRECTION_BOTH
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.01, 0.03, 0.01, 0.98)
	sb.border_width_left = 3; sb.border_width_top = 3
	sb.border_width_right = 3; sb.border_width_bottom = 3
	sb.border_color = Color("#00FF66")
	sb.corner_radius_top_left = 12; sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12; sb.corner_radius_bottom_right = 12
	sb.shadow_size = 25
	sb.shadow_color = Color("#00FF66", 0.1)
	painel_overlay.add_theme_stylebox_override("panel", sb)
	layer.add_child(painel_overlay)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	painel_overlay.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	var lbl_title = Label.new()
	lbl_title.text = "CAIXA DE SOM: BYPASS DE SINAL"
	lbl_title.add_theme_font_override("font", FONTE)
	lbl_title.add_theme_font_size_override("font_size", 30)
	lbl_title.add_theme_color_override("font_color", Color("#00FF66"))
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_title)
	
	var sep = ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 2)
	sep.color = Color("#00FF66", 0.4)
	vbox.add_child(sep)
	
	var desc = RichTextLabel.new()
	desc.bbcode_enabled = true
	desc.add_theme_font_override("normal_font", FONTE)
	desc.add_theme_font_size_override("normal_font_size", 20)
	desc.custom_minimum_size = Vector2(0, 260)
	desc.text = "[center]" + \
		"[color=#00FF66]1. ROTACIONAR CABOS:[/color] Clique em qualquer bloco da grade de circuitos para girá-lo em 90 graus no sentido horário.\n\n" + \
		"[color=#00FF66]2. PROPAGAÇÃO DO SINAL:[/color] O sinal da Rádio Livre (painel esquerdo) entra pela [color=#FFAA00]Linha 3 (célula central esquerda)[/color]. Os cabos energizados se acenderão em verde fluorescente.\n\n" + \
		"[color=#00FF66]3. OBJETIVO:[/color] Conecte as trilhas elétricas para fazer o sinal chegar com sucesso até a saída (painel direito, [color=#FFAA00]Linha 3, saída direita[/color]), interceptando os alto-falantes da escola para expor a verdade aos alunos." + \
		"[/center]"
	vbox.add_child(desc)
	
	var btn_start = Button.new()
	btn_start.text = "INICIAR HACKING"
	btn_start.custom_minimum_size = Vector2(300, 50)
	btn_start.size_flags_horizontal = SIZE_SHRINK_CENTER
	btn_start.add_theme_font_override("font", FONTE)
	btn_start.add_theme_font_size_override("font_size", 22)
	btn_start.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	
	var sb_btn = StyleBoxFlat.new()
	sb_btn.bg_color = Color(0.0, 0.4, 0.1, 0.8)
	sb_btn.border_width_left = 2; sb_btn.border_width_top = 2
	sb_btn.border_width_right = 2; sb_btn.border_width_bottom = 2
	sb_btn.border_color = Color("#00FF66")
	sb_btn.corner_radius_top_left = 6; sb_btn.corner_radius_top_right = 6
	sb_btn.corner_radius_bottom_left = 6; sb_btn.corner_radius_bottom_right = 6
	
	var sb_btn_h = sb_btn.duplicate() as StyleBoxFlat
	sb_btn_h.bg_color = Color(0.0, 0.6, 0.2)
	
	btn_start.add_theme_stylebox_override("normal", sb_btn)
	btn_start.add_theme_stylebox_override("hover", sb_btn_h)
	btn_start.pressed.connect(func():
		painel_overlay.queue_free()
		panel_main.visible = true
	)
	vbox.add_child(btn_start)
