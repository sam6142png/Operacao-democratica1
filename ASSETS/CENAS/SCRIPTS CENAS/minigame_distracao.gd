extends Node2D

const FONTE = preload("res://ASSETS/FONTES/determination.ttf")
const BG_TEX = preload("res://ASSETS/SPRITES/FUNDOS/Rua de noite.png")

var timer_val := 7.0
var finalizado := false
var layer: CanvasLayer
var lbl_timer: Label
var color_panico: ColorRect
var sparks_layer: Control  # Camada de faíscas visuais
var drawing_layer: Control # Camada de desenhos (holofote, trajetórias, ondas)
var crt_overlay: ColorRect  # Overlay CRT nas bordas

# Parâmetros de Gameplay do Farol e Detecção
var detecao: float = 0.0
var bar_detecao: ProgressBar
var lanterna_angulo: float = 0.0
var lanterna_pos := Vector2(100, 80)
var dante_pos := Vector2(1000, 520)

# Parâmetros do Arremesso Parabólico e Ondas
var trajetoria_ativa := false
var trajetoria_t := 0.0
var trajetoria_origem := Vector2.ZERO
var trajetoria_destino := Vector2.ZERO
var trajetoria_escolha := ""
var ondas_impacto := [] # Array de dicionários: {pos, radius, max_radius, alpha}

func _ready() -> void:
	randomize()
	
	# Monta a cena via script para garantir estabilidade e estilos precisos
	layer = CanvasLayer.new()
	add_child(layer)
	
	var v_size = get_viewport_rect().size
	lanterna_pos = Vector2(100, 80)
	dante_pos = Vector2(v_size.x - 150, v_size.y - 120)
	
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
	COLOR = vec4(vec3(gray) * 0.4, color.a);
}
"""
	mat.shader = shader
	bg.material = mat
	layer.add_child(bg)
	
	# Camada de desenho personalizado (abaixo da UI, acima do BG)
	drawing_layer = Control.new()
	drawing_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	drawing_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drawing_layer.draw.connect(_desenhar_drawing_layer)
	layer.add_child(drawing_layer)
	
	# Overlay CRT: vinheta escura + aberração cromática nas bordas
	crt_overlay = ColorRect.new()
	crt_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	crt_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var crt_mat = ShaderMaterial.new()
	var crt_shader = Shader.new()
	crt_shader.code = """
shader_type canvas_item;
uniform float vignette_strength : hint_range(0.0, 2.0) = 1.2;
uniform float scanline_alpha : hint_range(0.0, 0.5) = 0.08;
void fragment() {
	vec2 center = UV - 0.5;
	float dist = length(center) * 1.42;
	float vignette = smoothstep(0.35, 1.0, dist) * vignette_strength;
	float scanline = abs(sin(UV.y * 600.0)) * scanline_alpha;
	COLOR = vec4(0.0, 0.0, 0.0, vignette + scanline);
}
"""
	crt_mat.shader = crt_shader
	crt_overlay.material = crt_mat
	layer.add_child(crt_overlay)
	
	# Efeito de pânico (vermelho pulsante)
	color_panico = ColorRect.new()
	color_panico.color = Color(1, 0, 0, 0)
	color_panico.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_panico.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(color_panico)
	
	# Título / Instrução
	var lbl_inst = Label.new()
	lbl_inst.text = "OS GUARDAS ESTÃO VASCULHANDO O BECO..."
	lbl_inst.add_theme_font_override("font", FONTE)
	lbl_inst.add_theme_font_size_override("font_size", 38)
	lbl_inst.add_theme_color_override("font_color", Color.WHITE)
	lbl_inst.add_theme_color_override("font_shadow_color", Color.BLACK)
	lbl_inst.add_theme_constant_override("shadow_offset_x", 3)
	lbl_inst.add_theme_constant_override("shadow_offset_y", 3)
	lbl_inst.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_inst.set_anchors_preset(Control.PRESET_TOP_WIDE)
	lbl_inst.offset_top = 40
	layer.add_child(lbl_inst)
	
	# Timer Label
	lbl_timer = Label.new()
	lbl_timer.text = "7.0s"
	lbl_timer.add_theme_font_override("font", FONTE)
	lbl_timer.add_theme_font_size_override("font_size", 64)
	lbl_timer.add_theme_color_override("font_color", Color("#FF8C00"))
	lbl_timer.add_theme_color_override("font_shadow_color", Color.BLACK)
	lbl_timer.add_theme_constant_override("shadow_offset_x", 4)
	lbl_timer.add_theme_constant_override("shadow_offset_y", 4)
	lbl_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_timer.set_anchors_preset(Control.PRESET_TOP_WIDE)
	lbl_timer.offset_top = 100
	layer.add_child(lbl_timer)
	
	# Painel de Detecção do Inimigo no topo direito
	var detection_box := HBoxContainer.new()
	detection_box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	detection_box.offset_right = -40
	detection_box.offset_top = 40
	detection_box.add_theme_constant_override("separation", 10)
	layer.add_child(detection_box)
	
	var lbl_det := Label.new()
	lbl_det.text = "DETECCAO INIMIGA:"
	lbl_det.add_theme_font_override("font", FONTE)
	lbl_det.add_theme_font_size_override("font_size", 20)
	lbl_det.add_theme_color_override("font_color", Color("#ff4b4b"))
	detection_box.add_child(lbl_det)
	
	bar_detecao = ProgressBar.new()
	bar_detecao.min_value = 0
	bar_detecao.max_value = 100
	bar_detecao.value = 0
	bar_detecao.custom_minimum_size = Vector2(200, 20)
	bar_detecao.show_percentage = true
	bar_detecao.add_theme_font_override("font", FONTE)
	bar_detecao.add_theme_font_size_override("font_size", 12)
	
	var sb_det_bg = StyleBoxFlat.new()
	sb_det_bg.bg_color = Color(0.08, 0.02, 0.02)
	bar_detecao.add_theme_stylebox_override("background", sb_det_bg)
	var sb_det_fg = StyleBoxFlat.new()
	sb_det_fg.bg_color = Color("#ff4b4b")
	bar_detecao.add_theme_stylebox_override("fill", sb_det_fg)
	detection_box.add_child(bar_detecao)
	
	# Botões táticos centralizados
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.add_theme_constant_override("separation", 20)
	layer.add_child(vbox)
	
	_criar_botao(vbox, "Arremessar Lata de Lixo", "lata")
	_criar_botao(vbox, "Lançar Pedra Solta", "pedra")
	_criar_botao(vbox, "Derrubar Cano de Ferro", "cano")
	
	# Camada de faíscas (partículas de clique)
	sparks_layer = Control.new()
	sparks_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	sparks_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(sparks_layer)
	
	# Fade-in suave na entrada da cena
	var fade_in = ColorRect.new()
	fade_in.color = Color(0, 0, 0, 1.0)
	fade_in.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_in.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(fade_in)
	var tw = create_tween()
	tw.tween_property(fade_in, "color:a", 0.0, 0.6)
	tw.tween_callback(func(): fade_in.queue_free())

func _criar_botao(pai: Control, texto: String, id: String) -> void:
	var btn = Button.new()
	btn.text = texto
	btn.custom_minimum_size = Vector2(420, 64)
	btn.add_theme_font_override("font", FONTE)
	btn.add_theme_font_size_override("font_size", 26)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	# Style normal
	var sb_n = StyleBoxFlat.new()
	sb_n.bg_color = Color(0, 0, 0, 0.76)
	sb_n.border_width_left = 2; sb_n.border_width_right = 2
	sb_n.border_width_top = 2; sb_n.border_width_bottom = 2
	sb_n.border_color = Color("#FF8C00")
	sb_n.corner_radius_top_left = 6; sb_n.corner_radius_bottom_right = 6
	sb_n.corner_radius_top_right = 6; sb_n.corner_radius_bottom_left = 6
	
	# Style hover
	var sb_h = sb_n.duplicate() as StyleBoxFlat
	sb_h.bg_color = Color("#FF8C00", 0.28)
	sb_h.border_color = Color.WHITE
	sb_h.shadow_size = 12
	sb_h.shadow_color = Color("#FF8C00", 0.5)
	
	btn.add_theme_stylebox_override("normal", sb_n)
	btn.add_theme_stylebox_override("hover", sb_h)
	btn.add_theme_stylebox_override("pressed", sb_h)
	
	# Tween hover scale
	btn.pivot_offset = Vector2(210, 32)
	btn.mouse_entered.connect(func():
		var t = btn.create_tween()
		t.tween_property(btn, "scale", Vector2(1.04, 1.04), 0.1).set_ease(Tween.EASE_OUT)
	)
	btn.mouse_exited.connect(func():
		var t = btn.create_tween()
		t.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1).set_ease(Tween.EASE_OUT)
	)
	
	btn.pressed.connect(func():
		_spawn_sparks(btn.global_position + btn.size * 0.5)
		_bloquear_botoes(true)
		
		# Define os pontos da trajetória
		trajetoria_origem = dante_pos
		if id == "lata":
			trajetoria_destino = Vector2(320, 500)
		elif id == "pedra":
			trajetoria_destino = Vector2(200, 390)
		else:
			trajetoria_destino = Vector2(440, 530)
			
		trajetoria_escolha = id
		trajetoria_t = 0.0
		trajetoria_ativa = true
	)
	pai.add_child(btn)

func _bloquear_botoes(bloquear: bool) -> void:
	for c in layer.get_children():
		if c is VBoxContainer:
			for b in c.get_children():
				if b is Button:
					b.disabled = bloquear

func _process(delta: float) -> void:
	# 1. Atualiza o Holofote
	# O ângulo varia senoidalmente simulando busca manual dos guardas
	lanterna_angulo = sin(Time.get_ticks_msec() / 600.0) * 0.4 + 0.7
	
	if not finalizado:
		# Verifica detecção de Dante
		var is_inside = _check_dante_inside_cone()
		if is_inside:
			detecao = min(100.0, detecao + delta * 36.0)
			color_panico.color = Color(1.0, 0.0, 0.0, 0.15 + sin(Time.get_ticks_msec() / 60.0) * 0.1)
		else:
			detecao = max(0.0, detecao - delta * 15.0)
			color_panico.color.a = 0.0
			
		bar_detecao.value = detecao
		
		if detecao >= 100.0:
			_fazer_escolha("timeout")
			return
			
		# Avança o tempo se não estiver na trajetória física
		if not trajetoria_ativa:
			timer_val -= delta
			if timer_val <= 0.0:
				timer_val = 0.0
				_fazer_escolha("timeout")
				return
			
			lbl_timer.text = str(snapped(timer_val, 0.1)) + "s"
			
			if timer_val < 3.0:
				lbl_timer.add_theme_color_override("font_color", Color("#FF0000"))
				var pulse = (sin(Time.get_ticks_msec() / 80.0) + 1.0) / 2.0
				lbl_timer.scale = Vector2.ONE * (1.0 + pulse * 0.18)
				lbl_timer.pivot_offset = lbl_timer.size / 2.0
	
	# 2. Atualiza trajetória
	if trajetoria_ativa:
		trajetoria_t += delta * 1.8
		if trajetoria_t >= 1.0:
			trajetoria_ativa = false
			
			# Cria onda de choque no ponto de impacto
			var nova_onda = {
				"pos": trajetoria_destino,
				"radius": 1.0,
				"max_radius": 160.0,
				"alpha": 1.0,
				"cor": Color("#FF8C00") if trajetoria_escolha == "lata" else Color("#62ff86")
			}
			ondas_impacto.append(nova_onda)
			
			# Pequeno tremor de impacto
			_shake_camera(8.0, 0.25)
			
			_fazer_escolha(trajetoria_escolha)
			
	# 3. Atualiza ondas
	var indices_para_remover = []
	for i in range(ondas_impacto.size()):
		var onda = ondas_impacto[i]
		onda.radius += delta * 250.0
		onda.alpha = 1.0 - (onda.radius / onda.max_radius)
		if onda.radius >= onda.max_radius:
			indices_para_remover.append(i)
			
	indices_para_remover.reverse()
	for idx in indices_para_remover:
		ondas_impacto.remove_at(idx)
		
	if drawing_layer:
		drawing_layer.queue_redraw()

func _check_dante_inside_cone() -> bool:
	var dir_to_dante = (dante_pos - lanterna_pos).angle()
	var diff = abs(_angle_difference(lanterna_angulo, dir_to_dante))
	return diff < 0.13

func _angle_difference(from: float, to: float) -> float:
	var diff = fmod(to - from + PI, TAU)
	if diff < 0:
		diff += TAU
	return diff - PI

func _shake_camera(intensity: float, duration: float) -> void:
	var tw = create_tween()
	var steps = 6
	var step_time = duration / steps
	for i in range(steps):
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tw.tween_property(layer, "offset", offset, step_time)
		intensity *= 0.7
	tw.tween_property(layer, "offset", Vector2.ZERO, step_time)

func _desenhar_drawing_layer() -> void:
	if not drawing_layer: return
	
	# 1. Desenha o farol de busca
	var cone_length = 1300.0
	var cone_width = 0.22
	var target = Vector2(cos(lanterna_angulo), sin(lanterna_angulo)) * cone_length
	var left = Vector2(cos(lanterna_angulo - cone_width), sin(lanterna_angulo - cone_width)) * cone_length
	var right = Vector2(cos(lanterna_angulo + cone_width), sin(lanterna_angulo + cone_width)) * cone_length
	
	var points = PackedVector2Array([
		lanterna_pos,
		lanterna_pos + left,
		lanterna_pos + target,
		lanterna_pos + right
	])
	
	var is_detected = _check_dante_inside_cone()
	var cone_color = Color(1.0, 0.9, 0.35, 0.12 if not is_detected else 0.32)
	
	drawing_layer.draw_polygon(points, PackedColorArray([cone_color, Color(1.0, 0.9, 0.4, 0.0), Color(1.0, 0.9, 0.4, 0.0), Color(1.0, 0.9, 0.4, 0.0)]))
	drawing_layer.draw_line(lanterna_pos, lanterna_pos + target, Color(1.0, 0.9, 0.4, 0.22), 1.5)
	
	# 2. Desenha o esconderijo de Dante
	var hide_rect := Rect2(dante_pos - Vector2(40, 50), Vector2(80, 100))
	var border_color = Color("#ff4b4b") if is_detected else Color("#00A2FF")
	drawing_layer.draw_rect(hide_rect, Color(border_color, 0.1), true)
	drawing_layer.draw_rect(hide_rect, Color(border_color, 0.6), false, 2.0)
	drawing_layer.draw_string(FONTE, dante_pos + Vector2(-30, -58), "DANTE", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, border_color)
	
	# 3. Desenha trajetória
	if trajetoria_ativa:
		var trajectory_points = PackedVector2Array()
		var steps = 24
		for i in range(steps + 1):
			var ratio = float(i) / steps
			var pos = trajetoria_origem.lerp(trajetoria_destino, ratio)
			pos.y -= sin(ratio * PI) * 140.0
			trajectory_points.append(pos)
			
		for i in range(trajectory_points.size() - 1):
			drawing_layer.draw_line(trajectory_points[i], trajectory_points[i+1], Color("#FF8C00", 0.65), 2.0)
			
		# Objeto sendo lançado
		var cur = trajetoria_origem.lerp(trajetoria_destino, trajetoria_t)
		cur.y -= sin(trajetoria_t * PI) * 140.0
		drawing_layer.draw_circle(cur, 5.0, Color.WHITE)
		drawing_layer.draw_circle(cur, 9.0, Color("#FF8C00", 0.5))
		
	# 4. Desenha ondas de impacto
	for onda in ondas_impacto:
		drawing_layer.draw_circle(onda.pos, onda.radius, Color(onda.cor, 0.08), true)
		drawing_layer.draw_circle(onda.pos, onda.radius, Color(onda.cor, onda.alpha), false, 2.5)

func _fazer_escolha(id: String) -> void:
	if finalizado: return
	finalizado = true
	
	# Esconde a UI
	for c in layer.get_children():
		if c is VBoxContainer or c == lbl_timer or c is HBoxContainer:
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
			await GameState.retornar_para_game_scene_apos_minigame()
		"pedra":
			lbl_resultado.text = "A pedra estilhaça uma vidraça! Os guardas entram em alerta máximo.\nVocê foi visto."
			lbl_resultado.add_theme_color_override("font_color", Color("#FF0000"))
			await _game_over()
		"cano":
			lbl_resultado.text = "O cano cai com um estrondo ensurdecedor.\nEles atiraram na mesma hora."
			lbl_resultado.add_theme_color_override("font_color", Color("#FF0000"))
			await _game_over()
		"timeout":
			lbl_resultado.text = "Você foi localizado pelas patrulhas autoritárias.\nEles te capturaram."
			lbl_resultado.add_theme_color_override("font_color", Color("#FF0000"))
			await _game_over()

func _game_over() -> void:
	await get_tree().create_timer(3.5).timeout
	FadeManager.carregar_cena("res://ASSETS/CENAS/minigame_distracao.tscn")

# Efeito de faíscas visuais na posição do clique
func _spawn_sparks(pos: Vector2) -> void:
	if not sparks_layer: return
	var num_sparks = 8
	for i in range(num_sparks):
		var spark = ColorRect.new()
		spark.color = Color("#FF8C00") if i % 2 == 0 else Color("#FFCC44")
		spark.size = Vector2(4, 4)
		spark.position = pos - Vector2(2, 2)
		spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sparks_layer.add_child(spark)
		
		var angle = randf() * TAU
		var dist = randf_range(40.0, 120.0)
		var target = pos + Vector2(cos(angle), sin(angle)) * dist
		
		var tw = create_tween()
		tw.set_parallel(true)
		tw.tween_property(spark, "position", target, randf_range(0.25, 0.5)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
		tw.tween_property(spark, "modulate:a", 0.0, randf_range(0.3, 0.55))
		tw.tween_property(spark, "scale", Vector2(0.3, 0.3), randf_range(0.25, 0.5))
		tw.chain().tween_callback(func(): spark.queue_free())
