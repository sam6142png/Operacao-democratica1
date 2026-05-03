extends Control

const FONTE = preload("res://ASSETS/FONTES/determination.ttf")

func _ready():
	# Fade in suave
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.5)
	
	_criar_interface()

func _get_ranking() -> Dictionary:
	var conf = GameState.confianca
	if conf >= 12:
		return {"titulo": "CIDADÃO ATIVO", "cor": Color("#22FF55"), "desc": "Você não apenas observou, mas agiu para mudar a realidade. Sua coragem inspira outros."}
	elif conf >= 6:
		return {"titulo": "RESISTÊNCIA CONSCIENTE", "cor": Color("#FF8C00"), "desc": "Você entende os riscos e agiu com cautela, mas sem perder seus princípios."}
	else:
		return {"titulo": "CIDADÃO OBSERVADOR", "cor": Color("#FF2222"), "desc": "A prudência guiou seus passos. Às vezes, sobreviver para lutar outro dia é a única escolha."}

func _criar_interface():
	# Fundo Escuro
	var bg = ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.02, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 25)
	center.add_child(vbox)
	
	# Header
	var titulo_demonstracao = Label.new()
	titulo_demonstracao.text = "DEMONSTRAÇÃO CONCLUÍDA"
	titulo_demonstracao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo_demonstracao.add_theme_font_override("font", FONTE)
	titulo_demonstracao.add_theme_font_size_override("font_size", 48)
	titulo_demonstracao.add_theme_color_override("font_color", Color("#FF8C00"))
	vbox.add_child(titulo_demonstracao)
	
	var sep = ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 3)
	sep.color = Color(1, 1, 1, 0.1)
	vbox.add_child(sep)
	
	# Stats Section
	var stats_hbox = HBoxContainer.new()
	stats_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_hbox.add_theme_constant_override("separation", 50)
	vbox.add_child(stats_hbox)
	
	_criar_stat(stats_hbox, "Missão", "Vila do Açude")
	_criar_stat(stats_hbox, "Páginas", str(GameState.acertos_paginas_fase1) + "/10")
	_criar_stat(stats_hbox, "Confiança", str(GameState.confianca))
	
	# Ranking Section
	var rank_data = _get_ranking()
	
	var rank_label = Label.new()
	rank_label.text = "SEU RANKING:"
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_label.add_theme_font_override("font", FONTE)
	rank_label.add_theme_font_size_override("font_size", 24)
	rank_label.modulate = Color(0.6, 0.6, 0.6)
	vbox.add_child(rank_label)
	
	var rank_titulo = Label.new()
	rank_titulo.text = rank_data["titulo"]
	rank_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_titulo.add_theme_font_override("font", FONTE)
	rank_titulo.add_theme_font_size_override("font_size", 56)
	rank_titulo.add_theme_color_override("font_color", rank_data["cor"])
	vbox.add_child(rank_titulo)
	
	var rank_desc = Label.new()
	rank_desc.text = rank_data["desc"]
	rank_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rank_desc.custom_minimum_size = Vector2(600, 0)
	rank_desc.add_theme_font_override("font", FONTE)
	rank_desc.add_theme_font_size_override("font_size", 22)
	vbox.add_child(rank_desc)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(spacer)
	
	# Botão de Voltar
	_criar_botao(vbox, "VOLTAR AO MENU PRINCIPAL", func():
		FadeManager.carregar_cena("res://title_screen.tscn")
	)

func _criar_stat(parent, label_txt, valor_txt):
	var stat_vbox = VBoxContainer.new()
	parent.add_child(stat_vbox)
	
	var lbl = Label.new()
	lbl.text = label_txt
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", FONTE)
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.modulate = Color(0.5, 0.5, 0.5)
	stat_vbox.add_child(lbl)
	
	var val = Label.new()
	val.text = valor_txt
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val.add_theme_font_override("font", FONTE)
	val.add_theme_font_size_override("font_size", 32)
	stat_vbox.add_child(val)

func _criar_botao(parent, texto, acao):
	var btn = Button.new()
	btn.text = texto
	btn.custom_minimum_size = Vector2(380, 60)
	btn.add_theme_font_override("font", FONTE)
	btn.add_theme_font_size_override("font_size", 24)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(1.0, 1.0, 1.0, 0.06)
	normal.border_width_left = 1
	normal.border_width_right = 1
	normal.border_width_top = 1
	normal.border_width_bottom = 1
	normal.border_color = Color(1.0, 1.0, 1.0, 0.15)
	normal.corner_radius_top_left = 6
	normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_right = 6
	normal.corner_radius_bottom_left = 6
	
	var hover = normal.duplicate()
	hover.bg_color = Color("#FF8C00")
	hover.border_color = Color("#FF8C00")
	hover.border_width_left = 2
	hover.border_width_right = 2
	hover.border_width_top = 2
	hover.border_width_bottom = 2
	hover.shadow_color = Color("#FF8C00", 0.5)
	hover.shadow_size = 20
	
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("focus", hover)
	
	btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(0.05, 0.05, 0.05, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.05, 0.05, 0.05, 1.0))
	
	btn.pressed.connect(acao)
	parent.add_child(btn)
