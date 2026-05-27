extends Node2D

const FONTE = preload("res://ASSETS/FONTES/determination.ttf")
const BG_TEX = preload("res://ASSETS/SPRITES/FUNDOS/Rua de noite.png")

var timer_val := 7.0
var finalizado := false
var layer: CanvasLayer
var lbl_timer: Label
var color_panico: ColorRect

func _ready() -> void:
	# Monta a cena via script para garantir estabilidade e estilos precisos
	layer = CanvasLayer.new()
	add_child(layer)
	
	# Fundo com Shader P&B
	var bg = TextureRect.new()
	if BG_TEX:
		bg.texture = BG_TEX
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	var mat = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
	vec4 color = texture(TEXTURE, UV);
	float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(vec3(gray) * 0.4, color.a); // 0.4 escurece o tom P&B
}
"""
	mat.shader = shader
	bg.material = mat
	layer.add_child(bg)
	
	# Efeito de pânico (vermelho pulsante)
	color_panico = ColorRect.new()
	color_panico.color = Color(1, 0, 0, 0)
	color_panico.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_panico.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(color_panico)
	
	# Título / Instrução
	var lbl_inst = Label.new()
	lbl_inst.text = "OS GUARDAS ESTÃO SE APROXIMANDO... FAÇA ALGO!"
	lbl_inst.add_theme_font_override("font", FONTE)
	lbl_inst.add_theme_font_size_override("font_size", 42)
	lbl_inst.add_theme_color_override("font_color", Color.WHITE)
	lbl_inst.add_theme_color_override("font_shadow_color", Color.BLACK)
	lbl_inst.add_theme_constant_override("shadow_offset_x", 3)
	lbl_inst.add_theme_constant_override("shadow_offset_y", 3)
	lbl_inst.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_inst.set_anchors_preset(Control.PRESET_TOP_WIDE)
	lbl_inst.offset_top = 80
	layer.add_child(lbl_inst)
	
	# Timer Label
	lbl_timer = Label.new()
	lbl_timer.text = "7.0s"
	lbl_timer.add_theme_font_override("font", FONTE)
	lbl_timer.add_theme_font_size_override("font_size", 72)
	lbl_timer.add_theme_color_override("font_color", Color("#FF8C00"))
	lbl_timer.add_theme_color_override("font_shadow_color", Color.BLACK)
	lbl_timer.add_theme_constant_override("shadow_offset_x", 4)
	lbl_timer.add_theme_constant_override("shadow_offset_y", 4)
	lbl_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_timer.set_anchors_preset(Control.PRESET_TOP_WIDE)
	lbl_timer.offset_top = 160
	layer.add_child(lbl_timer)
	
	# Botões
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.add_theme_constant_override("separation", 24)
	layer.add_child(vbox)
	
	_criar_botao(vbox, "Lata de Lixo", "lata")
	_criar_botao(vbox, "Pedra Solta", "pedra")
	_criar_botao(vbox, "Cano de Ferro", "cano")

func _criar_botao(pai: Control, texto: String, id: String) -> void:
	var btn = Button.new()
	btn.text = texto
	btn.custom_minimum_size = Vector2(400, 70)
	btn.add_theme_font_override("font", FONTE)
	btn.add_theme_font_size_override("font_size", 32)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	# Style normal
	var sb_n = StyleBoxFlat.new()
	sb_n.bg_color = Color(0, 0, 0, 0.7)
	sb_n.border_width_left = 2; sb_n.border_width_right = 2
	sb_n.border_width_top = 2; sb_n.border_width_bottom = 2
	sb_n.border_color = Color("#FF8C00")
	sb_n.corner_radius_top_left = 8; sb_n.corner_radius_bottom_right = 8
	sb_n.corner_radius_top_right = 8; sb_n.corner_radius_bottom_left = 8
	
	# Style hover
	var sb_h = sb_n.duplicate() as StyleBoxFlat
	sb_h.bg_color = Color("#FF8C00", 0.3)
	sb_h.border_color = Color.WHITE
	sb_h.shadow_size = 15
	sb_h.shadow_color = Color("#FF8C00")
	
	btn.add_theme_stylebox_override("normal", sb_n)
	btn.add_theme_stylebox_override("hover", sb_h)
	btn.add_theme_stylebox_override("pressed", sb_h)
	
	btn.pressed.connect(func(): _fazer_escolha(id))
	pai.add_child(btn)

func _process(delta: float) -> void:
	if finalizado: return
	
	timer_val -= delta
	if timer_val <= 0.0:
		timer_val = 0.0
		_fazer_escolha("timeout")
	
	lbl_timer.text = str(snapped(timer_val, 0.1)) + "s"
	
	# Efeito vermelho pulsante se o tempo for menor que 3s
	if timer_val < 3.0:
		lbl_timer.add_theme_color_override("font_color", Color("#FF0000"))
		
		# Calcula pulso rápido
		var pulse = (sin(Time.get_ticks_msec() / 80.0) + 1.0) / 2.0
		color_panico.color.a = pulse * 0.4 
		
		lbl_timer.scale = Vector2.ONE * (1.0 + pulse * 0.2)
		lbl_timer.pivot_offset = lbl_timer.size / 2.0

func _fazer_escolha(id: String) -> void:
	if finalizado: return
	finalizado = true
	
	# Esconde a UI
	for c in layer.get_children():
		if c is VBoxContainer or c == lbl_timer:
			c.hide()
			
	# Zera pânico visual
	color_panico.color.a = 0
	
	var lbl_resultado = Label.new()
	lbl_resultado.add_theme_font_override("font", FONTE)
	lbl_resultado.add_theme_font_size_override("font_size", 42)
	lbl_resultado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_resultado.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl_resultado.custom_minimum_size = Vector2(800, 0)
	lbl_resultado.set_anchors_preset(Control.PRESET_CENTER)
	layer.add_child(lbl_resultado)
	
	match id:
		"lata":
			lbl_resultado.text = "A lata rola pelo beco, atraindo os guardas.\nVocê passa despercebido."
			lbl_resultado.add_theme_color_override("font_color", Color("#00FF00"))
			await get_tree().create_timer(3.0).timeout
			GameState.fase2_passo = "casa_velho"
			GameState.salvar_jogo()
			FadeManager.carregar_cena("res://ASSETS/CENAS/game_scene.tscn")
		"pedra":
			lbl_resultado.text = "A pedra estilhaça uma vidraça! Os guardas entram em alerta máximo.\nVocê foi visto."
			lbl_resultado.add_theme_color_override("font_color", Color("#FF0000"))
			await _game_over()
		"cano":
			lbl_resultado.text = "O cano cai com um estrondo ensurdecedor.\nEles atiraram na mesma hora."
			lbl_resultado.add_theme_color_override("font_color", Color("#FF0000"))
			await _game_over()
		"timeout":
			lbl_resultado.text = "Você hesitou por tempo demais.\nOs guardas te encontraram."
			lbl_resultado.add_theme_color_override("font_color", Color("#FF0000"))
			await _game_over()

func _game_over() -> void:
	await get_tree().create_timer(3.5).timeout
	FadeManager.carregar_cena("res://ASSETS/CENAS/minigame_distracao.tscn")
