extends Node2D

const FONTE = preload("res://ASSETS/FONTES/determination.ttf")
const BG_TEX = preload("res://ASSETS/SPRITES/FUNDOS/Rua de noite.png")

var timer_val := 7.0
var finalizado := false
var layer: CanvasLayer
var lbl_timer: Label
var lbl_inst: Label
var timing_seguro := false
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
	if has_node("/root/MusicManager"):
		get_node("/root/MusicManager").play_default_music()
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
	lbl_inst = Label.new()
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
		timing_seguro = not _check_dante_inside_cone()
		
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
			if lbl_inst:
				lbl_inst.text = "HOLOFOTE FOCADO! NÃO SE MOVE!"
				lbl_inst.add_theme_color_override("font_color", Color("#FF3333"))
		else:
			detecao = max(0.0, detecao - delta * 15.0)
			color_panico.color.a = 0.0
			if lbl_inst:
				lbl_inst.text = "HOLOFOTE LONGE. SEGURO PARA ARREMESSAR!"
				lbl_inst.add_theme_color_override("font_color", Color("#62ff86"))
			
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
	
	if id == "timeout":
		finalizado = true
		_esconder_ui_final()
		var lbl_resultado = _criar_lbl_resultado()
		lbl_resultado.text = "Você foi localizado pelas patrulhas autoritárias.\nEles te capturaram."
		lbl_resultado.add_theme_color_override("font_color", Color("#FF0000"))
		await _game_over()
		return
		
	if timing_seguro:
		finalizado = true
		_esconder_ui_final()
		var lbl_resultado = _criar_lbl_resultado()
		lbl_resultado.add_theme_color_override("font_color", Color("#00FF00"))
		match id:
			"lata":
				lbl_resultado.text = "A lata rola pelo beco, atraindo os guardas.\nVocê passa despercebido."
			"pedra":
				lbl_resultado.text = "A pedra desvia a patrulha temporariamente.\nVocê passa correndo pelos becos!"
			"cano":
				lbl_resultado.text = "O cano cai com um estrondo, atraindo toda a patrulha para o outro lado.\nCaminho livre!"
		await get_tree().create_timer(3.0).timeout
		GameState.fase2_passo = "casa_velho"
		await GameState.retornar_para_game_scene_apos_minigame()
	else:
		# Penalidade de timing incorreto
		var penalidade = 0.0
		var msg_aviso = ""
		match id:
			"lata":
				penalidade = 35.0
				msg_aviso = "A lata fez barulho, mas os guardas viram seu vulto! (+35% Detecção)"
			"pedra":
				penalidade = 40.0
				msg_aviso = "Vidraça quebrada! O barulho quase revelou sua posição (+40% Detecção)"
			"cano":
				penalidade = 60.0
				msg_aviso = "Estrondo metálico sob a luz! Alerta crítico (+60% Detecção)"
				
		detecao = min(100.0, detecao + penalidade)
		bar_detecao.value = detecao
		
		if detecao >= 100.0:
			finalizado = true
			_esconder_ui_final()
			var lbl_resultado = _criar_lbl_resultado()
			lbl_resultado.add_theme_color_override("font_color", Color("#FF0000"))
			match id:
				"lata":
					lbl_resultado.text = "Você arremessou a lata sob o holofote!\nOs guardas te avistaram e capturaram."
				"pedra":
					lbl_resultado.text = "A pedra quebrou a vidraça diretamente na sua frente!\nOs guardas te encurralaram."
				"cano":
					lbl_resultado.text = "Estrondo ensurdecedor sob a luz! Os guardas atiraram na sua direção.\nVocê foi capturado."
			await _game_over()
		else:
			_mostrar_aviso_temporario(msg_aviso)
			_bloquear_botoes(false)

func _esconder_ui_final() -> void:
	for c in layer.get_children():
		if c is VBoxContainer or c == lbl_timer or c is HBoxContainer:
			c.hide()
	color_panico.color.a = 0

func _criar_lbl_resultado() -> Label:
	var lbl_resultado = Label.new()
	lbl_resultado.add_theme_font_override("font", FONTE)
	lbl_resultado.add_theme_font_size_override("font_size", 42)
	lbl_resultado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_resultado.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl_resultado.custom_minimum_size = Vector2(800, 0)
	lbl_resultado.set_anchors_preset(Control.PRESET_CENTER)
	layer.add_child(lbl_resultado)
	return lbl_resultado

func _game_over() -> void:
	await get_tree().create_timer(3.5).timeout
	FadeManager.carregar_cena("res://ASSETS/CENAS/minigame_distracao.tscn")

func _mostrar_aviso_temporario(texto_aviso: String) -> void:
	var l_aviso = Label.new()
	l_aviso.text = texto_aviso
	l_aviso.add_theme_font_override("font", FONTE)
	l_aviso.add_theme_font_size_override("font_size", 28)
	l_aviso.add_theme_color_override("font_color", Color("#FFAA00"))
	l_aviso.add_theme_color_override("font_shadow_color", Color.BLACK)
	l_aviso.add_theme_constant_override("shadow_offset_x", 2)
	l_aviso.add_theme_constant_override("shadow_offset_y", 2)
	l_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_aviso.set_anchors_preset(Control.PRESET_CENTER)
	l_aviso.grow_horizontal = Control.GROW_DIRECTION_BOTH
	l_aviso.grow_vertical = Control.GROW_DIRECTION_BOTH
	l_aviso.position = Vector2(get_viewport_rect().size.x / 2.0 - 400, get_viewport_rect().size.y / 2.0 - 150)
	l_aviso.size = Vector2(800, 50)
	layer.add_child(l_aviso)
	
	var orig_pos = l_aviso.position
	var tw_shake = create_tween()
	for i in range(6):
		var offset = Vector2(randf_range(-6, 6), randf_range(-6, 6))
		tw_shake.tween_property(l_aviso, "position", orig_pos + offset, 0.05)
	tw_shake.tween_property(l_aviso, "position", orig_pos, 0.05)
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(l_aviso, "position:y", l_aviso.position.y - 80.0, 2.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(l_aviso, "modulate:a", 0.0, 2.0).set_delay(0.5)
	tw.chain().tween_callback(func(): l_aviso.queue_free())

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
