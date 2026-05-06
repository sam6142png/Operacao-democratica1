extends CanvasLayer

const FONTE = preload("res://ASSETS/FONTES/determination.ttf")

var painel_pausa: Control
var menu_container: PanelContainer
var label_feedback: Label

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_criar_interface()
	painel_pausa.visible = false

func _input(event):
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		alternar_pausa()

func alternar_pausa():
	if not painel_pausa: return
	
	var novo_estado = !get_tree().paused
	get_tree().paused = novo_estado
	painel_pausa.visible = novo_estado
	
	if novo_estado:
		menu_container.modulate.a = 0
		var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(menu_container, "modulate:a", 1.0, 0.15)

func _criar_interface():
	painel_pausa = Control.new()
	painel_pausa.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(painel_pausa)
	
	# Fundo escurecido translúcido
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.85)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	painel_pausa.add_child(bg)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	painel_pausa.add_child(center)
	
	menu_container = PanelContainer.new()
	menu_container.custom_minimum_size = Vector2(400, 420)
	center.add_child(menu_container)
	
	# Estilo do Painel (Neon Cyberpunk)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.02, 0.02, 0.95)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color("#FF8C00") # Neon Laranja
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	sb.shadow_size = 30
	sb.shadow_color = Color("#FF8C00", 0.15)
	menu_container.add_theme_stylebox_override("panel", sb)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	menu_container.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)
	
	# Titulo
	var titulo = Label.new()
	titulo.text = "PAUSA"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_override("font", FONTE)
	titulo.add_theme_font_size_override("font_size", 42)
	titulo.add_theme_color_override("font_color", Color("#FF8C00"))
	vbox.add_child(titulo)
	
	var sep = ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 2)
	sep.color = Color(1, 1, 1, 0.1)
	vbox.add_child(sep)
	
	# Botões
	_criar_botao(vbox, "CONTINUAR", alternar_pausa, Color("#22FF55"))
	_criar_botao(vbox, "SALVAR PROGRESSO", func(): 
		GameState.salvar_jogo()
		_mostrar_feedback_save("Progresso salvo no sistema.")
	, Color("#FF8C00"))
	_criar_botao(vbox, "MENU PRINCIPAL", func():
		painel_pausa.visible = false
		await TimelineManager.parar_tudo()
		FadeManager.carregar_cena("res://title_screen.tscn")
	, Color("#FF8C00"))
	_criar_botao(vbox, "SAIR PARA O DESKTOP", func(): get_tree().quit(), Color("#FF2222"))
	
	# Label de Feedback
	label_feedback = Label.new()
	label_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_feedback.add_theme_font_override("font", FONTE)
	label_feedback.add_theme_font_size_override("font_size", 20)
	label_feedback.add_theme_color_override("font_color", Color("#22FF55"))
	label_feedback.modulate.a = 0
	vbox.add_child(label_feedback)

func _mostrar_feedback_save(txt: String):
	label_feedback.text = txt
	label_feedback.pivot_offset = Vector2(180, 15)
	
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	label_feedback.scale = Vector2(1.5, 1.5)
	label_feedback.modulate.a = 0
	
	tween.set_parallel(true)
	tween.tween_property(label_feedback, "modulate:a", 1.0, 0.1)
	tween.tween_property(label_feedback, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	tween.set_parallel(false)
	tween.tween_interval(1.5)
	tween.tween_property(label_feedback, "modulate:a", 0.0, 0.8)

func _criar_botao(parent, texto, acao, cor_destaque: Color):
	var btn = Button.new()
	btn.text = texto
	btn.custom_minimum_size = Vector2(320, 45)
	btn.add_theme_font_override("font", FONTE)
	btn.add_theme_font_size_override("font_size", 22)
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
	hover.bg_color = cor_destaque
	hover.border_color = cor_destaque
	hover.border_width_left = 2
	hover.border_width_right = 2
	hover.border_width_top = 2
	hover.border_width_bottom = 2
	hover.shadow_color = cor_destaque
	hover.shadow_color.a = 0.5
	hover.shadow_size = 20
	
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("focus", hover)
	
	btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(0.05, 0.05, 0.05, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.05, 0.05, 0.05, 1.0))
	btn.add_theme_color_override("font_focus_color", Color(0.05, 0.05, 0.05, 1.0))
	
	btn.pressed.connect(acao)
	parent.add_child(btn)
