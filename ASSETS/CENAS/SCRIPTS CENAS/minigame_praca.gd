extends Control

# ═══════════════════════════════════════════════════════════════
#  MINIGAME PRAÇA — BY-PASS DO CADEADO (ENIGMA DE INTEGRAÇÃO)
# ═══════════════════════════════════════════════════════════════

const FONTE = preload("res://ASSETS/FONTES/determination.ttf")
const FONTE_MONO = preload("res://ASSETS/FONTES/dogicapixel.ttf")
const BG_TEX = preload("res://ASSETS/SPRITES/FUNDOS/Rua com manifestação.jpeg")
const CLICK_SOUND = preload("res://ASSETS/SOUNDS/FSX/BotoesClick.mp3")

const PALACIO_SCENE: String = "res://ASSETS/CENAS/minigame_final_palacio.tscn"

# Cores do Tema Cívico-Retrô
const COR_BG_OVERLAY  := Color(0.04, 0.04, 0.05, 0.82)
const COR_PANEL_BG    := Color(0.04, 0.04, 0.07, 0.96)
const COR_PANEL_BORDA := Color(0.0,  0.72, 1.0,  0.8) # Azul Cívico
const COR_GREEN_WAVE  := Color(0.0,  1.0,  0.4,  0.9) # Rádio Livre (Verde)
const COR_RED_WAVE    := Color(1.0,  0.22, 0.22, 0.85) # Bloqueio (Vermelho)

# Estado do Enigma
var etapa_atual: int = 1 # 1 = Análise, 2 = Decodificação, 3 = Calibração
var finalizado: bool = false

# Componentes de Som
var sfx_click: AudioStreamPlayer

# Componentes de UI
var layer: CanvasLayer
var panel_main: PanelContainer
var step_lbl_1: Label
var step_lbl_2: Label
var step_lbl_3: Label
var container_etapa: PanelContainer
var lbl_feedback: Label

# Elementos Dinâmicos - Etapa 1
var btn_statement_a: Button
var btn_statement_b: Button

# Elementos Dinâmicos - Etapa 2
var slider_cifra: HSlider
var lbl_cifra_result: Label
var current_shift: int = 0

# Elementos Dinâmicos - Etapa 3
var oscilloscope: Control
var slider_amp: HSlider
var slider_freq: HSlider
var target_amp: float = 0.80
var target_freq: float = 14.0
var val_amp: float = 0.20
var val_freq: float = 4.0
var lock_time: float = 0.0
const LOCK_TARGET: float = 1.5
var progress_lock: ProgressBar
var lbl_lock_status: Label
var lbl_helper_amp: Label
var lbl_helper_freq: Label
var wave_time: float = 0.0


# ══════════════════════════════════════════
# INICIALIZAÇÃO
# ══════════════════════════════════════════
func _ready() -> void:
	if has_node("/root/MusicManager"):
		get_node("/root/MusicManager").play_default_music()
	if get_tree().root.has_node("MedidorConfianca"):
		get_tree().root.get_node("MedidorConfianca").visible = false

	_configurar_audio()
	_montar_cena()
	_mostrar_etapa(1)


func _process(delta: float) -> void:
	if finalizado:
		return
		
	if etapa_atual == 3:
		wave_time += delta * 4.0
		if oscilloscope:
			oscilloscope.queue_redraw()
			
		# Verifica a sintonia das ondas
		var diff_amp = abs(val_amp - target_amp)
		var diff_freq = abs(val_freq - target_freq)
		
		# Atualiza textos de ajuda
		if lbl_helper_amp:
			if diff_amp < 0.15:
				lbl_helper_amp.text = "[ ALINHADO ]"
				lbl_helper_amp.add_theme_color_override("font_color", Color("#62ff86"))
			elif val_amp < target_amp:
				lbl_helper_amp.text = "[ ▲ AUMENTAR ]"
				lbl_helper_amp.add_theme_color_override("font_color", Color("#ffd447"))
			else:
				lbl_helper_amp.text = "[ ▼ DIMINUIR ]"
				lbl_helper_amp.add_theme_color_override("font_color", Color("#ffd447"))
				
		if lbl_helper_freq:
			if diff_freq < 1.0:
				lbl_helper_freq.text = "[ ALINHADO ]"
				lbl_helper_freq.add_theme_color_override("font_color", Color("#62ff86"))
			elif val_freq < target_freq:
				lbl_helper_freq.text = "[ ▲ AUMENTAR ]"
				lbl_helper_freq.add_theme_color_override("font_color", Color("#ffd447"))
			else:
				lbl_helper_freq.text = "[ ▼ DIMINUIR ]"
				lbl_helper_freq.add_theme_color_override("font_color", Color("#ffd447"))
		
		var alinhado = (diff_amp < 0.15) and (diff_freq < 1.0)
		if alinhado:
			lock_time += delta
			if progress_lock: progress_lock.value = lock_time
			if lbl_lock_status:
				lbl_lock_status.text = "SINAL ACOPLADO! TRAVAS DESTRANCANDO..."
				lbl_lock_status.add_theme_color_override("font_color", Color("#62ff86"))
				
			if lock_time >= LOCK_TARGET:
				_concluir_etapa_3()
		else:
			lock_time = max(0.0, lock_time - delta * 1.5)
			if progress_lock: progress_lock.value = lock_time
			if lbl_lock_status:
				lbl_lock_status.text = "BUSCANDO ESTABILIDADE..."
				lbl_lock_status.add_theme_color_override("font_color", Color("#ff4b4b"))


func _configurar_audio() -> void:
	sfx_click = AudioStreamPlayer.new()
	sfx_click.stream = CLICK_SOUND
	sfx_click.bus = "SFX"
	add_child(sfx_click)


func _montar_cena() -> void:
	layer = CanvasLayer.new()
	layer.layer = 20
	add_child(layer)

	# Fundo da praça desfocado
	var bg := TextureRect.new()
	bg.texture = BG_TEX
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.modulate = Color(0.38, 0.38, 0.42)
	layer.add_child(bg)

	var overlay := ColorRect.new()
	overlay.color = COR_BG_OVERLAY
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(overlay)

	# Painel principal
	panel_main = PanelContainer.new()
	panel_main.custom_minimum_size = Vector2(1080, 640)
	panel_main.set_anchors_preset(Control.PRESET_CENTER)
	panel_main.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel_main.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel_main.add_theme_stylebox_override("panel", _stylebox(COR_PANEL_BG, COR_PANEL_BORDA, 2, 12))
	layer.add_child(panel_main)
	call_deferred("_centralizar", panel_main)

	var margin := _margin(24)
	panel_main.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	# Cabeçalho
	var header := HBoxContainer.new()
	root.add_child(header)

	var title := _label("PAINEL DE BY-PASS: PORTÃO DO PALÁCIO", 24, COR_PANEL_BORDA, FONTE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	# Etapas indicadas na UI
	var steps_box := HBoxContainer.new()
	steps_box.add_theme_constant_override("separation", 16)
	header.add_child(steps_box)

	step_lbl_1 = _label("[ 1. ANALISE ]", 13, Color("#888888"), FONTE_MONO)
	step_lbl_2 = _label("[ 2. DECODIFICACAO ]", 13, Color("#888888"), FONTE_MONO)
	step_lbl_3 = _label("[ 3. CALIBRACAO ]", 13, Color("#888888"), FONTE_MONO)
	steps_box.add_child(step_lbl_1)
	steps_box.add_child(step_lbl_2)
	steps_box.add_child(step_lbl_3)

	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 2)
	sep.color = Color("#2a2c35")
	root.add_child(sep)

	# Container da Etapa Ativa
	container_etapa = PanelContainer.new()
	container_etapa.size_flags_vertical = Control.SIZE_EXPAND_FILL
	container_etapa.add_theme_stylebox_override("panel", _stylebox(Color(0,0,0,0), Color(0,0,0,0), 0, 0))
	root.add_child(container_etapa)

	# Feedback de Status Inferior
	lbl_feedback = _label("SISTEMA OPERACIONAL PRONTO PARA SEGURANCA CIVICA.", 13, Color("#a2a8b3"), FONTE_MONO)
	lbl_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(lbl_feedback)


# ══════════════════════════════════════════
# CONTROLE DE ETAPAS
# ══════════════════════════════════════════
func _mostrar_etapa(etapa: int) -> void:
	etapa_atual = etapa
	
	# Atualiza cores das labels do cabeçalho
	step_lbl_1.add_theme_color_override("font_color", Color("#62ff86") if etapa_atual == 1 else (Color("#54d6ff") if etapa_atual > 1 else Color("#888888")))
	step_lbl_2.add_theme_color_override("font_color", Color("#62ff86") if etapa_atual == 2 else (Color("#54d6ff") if etapa_atual > 2 else Color("#888888")))
	step_lbl_3.add_theme_color_override("font_color", Color("#62ff86") if etapa_atual == 3 else Color("#888888"))

	_limpar(container_etapa)
	lbl_feedback.text = "SISTEMA OPERACIONAL PRONTO."
	lbl_feedback.add_theme_color_override("font_color", Color("#a2a8b3"))

	match etapa_atual:
		1: _construir_etapa_1()
		2: _construir_etapa_2()
		3: _construir_etapa_3()


# ══════════════════════════════════════════
# ETAPA 1 — FILTRAGEM CÍVICA
# ══════════════════════════════════════════
func _construir_etapa_1() -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	container_etapa.add_child(vbox)

	var info := _label("ETAPA 1: ISOLAMENTO E FILTRAGEM DE CENSURA", 18, Color("#54d6ff"), FONTE_MONO)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(info)

	var desc := _label("O ditador bloqueia o portão com um sistema eletrônico de verificação. Para gerar um token de decodificação, identifique e filtre qual das afirmações emitidas pelos alto-falantes representa uma PROPAGANDA AUTORITÁRIA do regime:", 16, Color("#d7c9aa"), FONTE)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc)

	# Botão A (Direito Legítimo)
	btn_statement_a = Button.new()
	btn_statement_a.custom_minimum_size = Vector2(0, 110)
	btn_statement_a.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_statement_a.add_theme_stylebox_override("normal", _stylebox(Color(0.08, 0.09, 0.12, 0.95), Color("#54d6ff", 0.4), 2, 8))
	btn_statement_a.add_theme_stylebox_override("hover", _stylebox(Color(0.12, 0.14, 0.18, 0.95), Color("#54d6ff"), 2, 8))
	btn_statement_a.pressed.connect(_on_click_a)
	vbox.add_child(btn_statement_a)

	var lbl_a := _label("AFIRMAÇÃO DE CANAL A:\n\"A livre manifestação de pensamento e a reunião pacífica dos cidadãos na praça pública constituem garantias cívicas fundamentais, protegidas pela antiga constituição da Usina.\"", 15, Color("#fff4d6"), FONTE)
	lbl_a.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl_a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_a.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_a.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn_statement_a.add_child(lbl_a)

	# Botão B (Propaganda Autoritária)
	btn_statement_b = Button.new()
	btn_statement_b.custom_minimum_size = Vector2(0, 110)
	btn_statement_b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_statement_b.add_theme_stylebox_override("normal", _stylebox(Color(0.08, 0.09, 0.12, 0.95), Color("#54d6ff", 0.4), 2, 8))
	btn_statement_b.add_theme_stylebox_override("hover", _stylebox(Color(0.12, 0.14, 0.18, 0.95), Color("#54d6ff"), 2, 8))
	btn_statement_b.pressed.connect(_on_click_b)
	vbox.add_child(btn_statement_b)

	var lbl_b := _label("AFIRMAÇÃO DE CANAL B:\n\"A censura prévia dos meios de comunicação e a proibição de ajuntamentos civis nas ruas são medidas de segurança necessárias para resguardar a ordem contra a desestabilização.\"", 15, Color("#fff4d6"), FONTE)
	lbl_b.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl_b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_b.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_b.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn_statement_b.add_child(lbl_b)


func _on_click_a() -> void:
	_play_click()
	lbl_feedback.text = "FILTRAGEM FALHOU. ESSA AFIRMAÇÃO EXPRESSA UM DIREITO CÍVICO LEGÍTIMO."
	lbl_feedback.add_theme_color_override("font_color", Color("#ff4b4b"))
	
	var tw = create_tween()
	btn_statement_a.modulate = Color(1.5, 0.4, 0.4)
	tw.tween_property(btn_statement_a, "modulate", Color.WHITE, 0.4)


func _on_click_b() -> void:
	_play_click()
	lbl_feedback.text = "CENSURA DETECTADA E FILTRADA! CRIPTOGRAMA OBTIDO: K-Q-W-T"
	lbl_feedback.add_theme_color_override("font_color", Color("#62ff86"))
	
	var tw = create_tween()
	btn_statement_b.modulate = Color(0.4, 1.5, 0.4)
	tw.tween_property(btn_statement_b, "modulate", Color.WHITE, 0.4)
	await tw.finished
	_mostrar_etapa(2)


# ══════════════════════════════════════════
# ETAPA 2 — DECODIFICAÇÃO (CIFRA DE CÉSAR)
# ══════════════════════════════════════════
func _construir_etapa_2() -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	container_etapa.add_child(vbox)

	var info := _label("ETAPA 2: DECODIFICACAO DE CHAVE CRIPTOGRAFICA", 18, Color("#54d6ff"), FONTE_MONO)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(info)

	# Bloco de Anotações/Dica
	var hint_panel := PanelContainer.new()
	hint_panel.add_theme_stylebox_override("panel", _stylebox(Color(0.12, 0.11, 0.08, 0.95), Color("#ffd447", 0.6), 1, 8))
	vbox.add_child(hint_panel)

	var hint_margin := _margin(10)
	hint_panel.add_child(hint_margin)

	var hint_lbl := _label("ANOTAÇÕES DO DIÁRIO (Dantas):\n\"O Coronel Antônio criptografa a senha de acesso usando a Cifra de César. A chave de deslocamento é a diferença exata entre o ano de promulgação da nossa antiga Constituição Democrática (1988) e o ano em que a intervenção militar de Antônio foi instaurada (1985). Desloque o sinal negativamente por essa diferença.\"", 14, Color("#ffd447"), FONTE)
	hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	hint_margin.add_child(hint_lbl)

	# Criptograma
	var cipher_box := HBoxContainer.new()
	cipher_box.alignment = BoxContainer.ALIGNMENT_CENTER
	cipher_box.add_theme_constant_override("separation", 12)
	vbox.add_child(cipher_box)

	cipher_box.add_child(_label("TOKEN CRIPTOGRAFADO:", 16, Color("#a2a8b3"), FONTE_MONO))
	var cipher_val := _label("K - Q - W - T", 24, Color("#54d6ff"), FONTE)
	cipher_box.add_child(cipher_val)

	# Ajuste do Shift
	var control_box := HBoxContainer.new()
	control_box.alignment = BoxContainer.ALIGNMENT_CENTER
	control_box.add_theme_constant_override("separation", 16)
	vbox.add_child(control_box)

	control_box.add_child(_label("Ajustar Deslocamento:", 15, Color("#fff4d6"), FONTE))

	slider_cifra = HSlider.new()
	slider_cifra.min_value = -10
	slider_cifra.max_value = 10
	slider_cifra.step = 1
	slider_cifra.value = 0
	slider_cifra.custom_minimum_size = Vector2(250, 20)
	slider_cifra.value_changed.connect(_on_cifra_changed)
	control_box.add_child(slider_cifra)

	lbl_cifra_result = _label("Deslocamento: 0  ->  [ K Q W T ]", 18, Color("#62ff86"), FONTE_MONO)
	lbl_cifra_result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_cifra_result)

	# Botão de Ação
	var btn_submit := Button.new()
	btn_submit.text = "APLICAR DESCRIPTOGRAFIA"
	btn_submit.custom_minimum_size = Vector2(260, 45)
	btn_submit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_submit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_submit.add_theme_font_override("font", FONTE)
	btn_submit.add_theme_font_size_override("font_size", 18)
	btn_submit.add_theme_color_override("font_color", Color.BLACK)
	btn_submit.add_theme_stylebox_override("normal", _stylebox(Color("#54d6ff"), Color("#2b2118"), 2, 6))
	btn_submit.add_theme_stylebox_override("hover", _stylebox(Color("#62ff86"), Color("#54d6ff"), 2, 6))
	btn_submit.pressed.connect(_verificar_cifra)
	vbox.add_child(btn_submit)


func _on_cifra_changed(val: float) -> void:
	_play_click()
	current_shift = int(val)
	var dec = _decriptar("KQWT", current_shift)
	lbl_cifra_result.text = "Deslocamento: %d  ->  [ %s ]" % [current_shift, dec]


func _decriptar(texto: String, shift: int) -> String:
	var alfabeto := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	var res := ""
	for i in range(texto.length()):
		var c = texto[i]
		var idx = alfabeto.find(c.to_upper())
		if idx != -1:
			var novo_idx = (idx + shift) % 26
			if novo_idx < 0: novo_idx += 26
			res += alfabeto[novo_idx]
		else:
			res += c
	return res


func _verificar_cifra() -> void:
	_play_click()
	if current_shift == -3:
		lbl_feedback.text = "DESCRIPTOGRAFADO COM SUCESSO: [ H N T Q ]"
		lbl_feedback.add_theme_color_override("font_color", Color("#62ff86"))
		var tw = create_tween()
		tw.tween_interval(0.8)
		tw.tween_callback(func(): _mostrar_etapa(3))
	else:
		lbl_feedback.text = "CHAVE INCORRETA. A DIFERENCA DE ANOS NAO CORRESPONDE AO DESLOCAMENTO."
		lbl_feedback.add_theme_color_override("font_color", Color("#ff4b4b"))
		var tw = create_tween()
		lbl_cifra_result.add_theme_color_override("font_color", Color("#ff4b4b"))
		tw.tween_property(lbl_cifra_result, "modulate", Color(1.5, 0.4, 0.4), 0.1)
		tw.tween_property(lbl_cifra_result, "modulate", Color.WHITE, 0.3)
		tw.tween_callback(func(): lbl_cifra_result.add_theme_color_override("font_color", Color("#62ff86")))


# ══════════════════════════════════════════
# ETAPA 3 — CALIBRAÇÃO DO OSCILOSCÓPIO
# ══════════════════════════════════════════
func _construir_etapa_3() -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	container_etapa.add_child(vbox)

	var info := _label("ETAPA 3: CALIBRACAO E ACOPLAMENTO DE ONDAS", 18, Color("#54d6ff"), FONTE_MONO)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(info)

	var sub := _label("O sinal revelado (H N T Q) mapeia os valores de segurança no circuito: H é a 8ª letra (Amplitude 0.8) e N é a 14ª letra (Frequência 14.0). Alinhe a onda do oscilador eletrônico para liberar as travas físicas:", 14, Color("#d7c9aa"), FONTE)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(sub)

	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 20)
	vbox.add_child(split)

	# Lado Esquerdo: CRT Screen
	var osc_panel := PanelContainer.new()
	osc_panel.custom_minimum_size = Vector2(460, 240)
	osc_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	osc_panel.add_theme_stylebox_override("panel", _stylebox(Color(0.02, 0.02, 0.03, 0.98), COR_PANEL_BORDA, 2, 8))
	split.add_child(osc_panel)

	oscilloscope = Control.new()
	oscilloscope.set_anchors_preset(Control.PRESET_FULL_RECT)
	oscilloscope.draw.connect(_on_oscilloscope_draw)
	osc_panel.add_child(oscilloscope)

	# Lado Direito: Sliders
	var ctrl_box := VBoxContainer.new()
	ctrl_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ctrl_box.add_theme_constant_override("separation", 10)
	split.add_child(ctrl_box)

	# Amplitude
	ctrl_box.add_child(_label("AMPLITUDE (Alvo: H = 0.80)", 12, Color("#54d6ff"), FONTE_MONO))
	var amp_hbox := HBoxContainer.new()
	amp_hbox.add_theme_constant_override("separation", 10)
	ctrl_box.add_child(amp_hbox)

	slider_amp = HSlider.new()
	slider_amp.min_value = 0.1
	slider_amp.max_value = 1.0
	slider_amp.step = 0.02
	slider_amp.value = 0.2
	slider_amp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider_amp.custom_minimum_size = Vector2(0, 40)
	slider_amp.value_changed.connect(func(v): val_amp = v; _play_click())
	amp_hbox.add_child(slider_amp)

	lbl_helper_amp = _label("[ AJUSTANDO ]", 11, Color("#ffd447"), FONTE_MONO)
	lbl_helper_amp.custom_minimum_size = Vector2(110, 0)
	amp_hbox.add_child(lbl_helper_amp)

	# Frequência
	ctrl_box.add_child(_label("FREQUENCIA (Alvo: N = 14.0)", 12, Color("#54d6ff"), FONTE_MONO))
	var freq_hbox := HBoxContainer.new()
	freq_hbox.add_theme_constant_override("separation", 10)
	ctrl_box.add_child(freq_hbox)

	slider_freq = HSlider.new()
	slider_freq.min_value = 2.0
	slider_freq.max_value = 20.0
	slider_freq.step = 0.5
	slider_freq.value = 4.0
	slider_freq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider_freq.custom_minimum_size = Vector2(0, 40)
	slider_freq.value_changed.connect(func(v): val_freq = v; _play_click())
	freq_hbox.add_child(slider_freq)

	lbl_helper_freq = _label("[ AJUSTANDO ]", 11, Color("#ffd447"), FONTE_MONO)
	lbl_helper_freq.custom_minimum_size = Vector2(110, 0)
	freq_hbox.add_child(lbl_helper_freq)

	# Lock Progress Bar
	progress_lock = ProgressBar.new()
	progress_lock.min_value = 0.0
	progress_lock.max_value = LOCK_TARGET
	progress_lock.value = 0.0
	progress_lock.show_percentage = false
	progress_lock.custom_minimum_size = Vector2(0, 16)
	ctrl_box.add_child(progress_lock)

	lbl_lock_status = _label("BUSCANDO ESTABILIDADE...", 12, Color("#ff4b4b"), FONTE_MONO)
	lbl_lock_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ctrl_box.add_child(lbl_lock_status)


func _on_oscilloscope_draw() -> void:
	if not oscilloscope: return
	var size := oscilloscope.size
	var center_y := size.y / 2.0

	# 1. Desenha a grade
	var grid_color := Color(0.0, 0.45, 0.72, 0.15)
	for x in range(0, int(size.x), 25):
		oscilloscope.draw_line(Vector2(x, 0), Vector2(x, size.y), grid_color, 1.0)
	for y in range(0, int(size.y), 25):
		oscilloscope.draw_line(Vector2(0, y), Vector2(size.x, y), grid_color, 1.0)

	# 2. Gera pontos das ondas
	var pts_target := PackedVector2Array()
	var pts_player := PackedVector2Array()

	for x in range(0, int(size.x)):
		var t = float(x) / size.x * TAU
		
		# Onda Vermelha (Alvo)
		var y_target = center_y + (target_amp * 90.0) * sin(t * target_freq + wave_time)
		pts_target.append(Vector2(x, y_target))

		# Onda Verde (Jogador)
		var y_player = center_y + (val_amp * 90.0) * sin(t * val_freq + wave_time)
		pts_player.append(Vector2(x, y_player))

	oscilloscope.draw_polyline(pts_target, COR_RED_WAVE, 2.0)
	oscilloscope.draw_polyline(pts_player, COR_GREEN_WAVE, 2.5)


func _concluir_etapa_3() -> void:
	finalizado = true
	_play_click()

	if slider_amp: slider_amp.editable = false
	if slider_freq: slider_freq.editable = false

	# Efeito visual de brilho verde
	var tween := create_tween()
	var original_mod = oscilloscope.modulate
	tween.tween_property(oscilloscope, "modulate", Color(0.1, 2.0, 0.6, 1.0), 0.12)
	tween.tween_property(oscilloscope, "modulate", original_mod, 0.4)
	await tween.finished

	_concluir_simulacao()


# ══════════════════════════════════════════
# CONCLUSÃO DO MINIJOGO
# ══════════════════════════════════════════
func _concluir_simulacao() -> void:
	# Transiciona e atualiza os estados do jogo
	await _ir_para_palacio()


func _ir_para_palacio() -> void:
	GameState.fase4_passo = "palacio"
	GameState.pontuacao_final = {
		"bonus_praca": 35,
		"escolhas_praca": ["BY-PASS DO CADEADO"]
	}
	await GameState.mostrar_registro_democratico({
		"fase": "Fase 4 - Praca",
		"conceito": "Integração cívica, raciocínio lógico e desobediência civil",
		"evidencia": "O jogador superou o bloqueio eletrônico do Palácio unindo e aplicando todos os aprendizados de fases passadas.",
		"impacto": "A infiltração tática foi bem-sucedida, abrindo a entrada secreta para o Palácio sem confrontos ou violência.",
		"reflexao": "A inteligência cívica e a persistência são as chaves para desarmar as defesas do autoritarismo."
	})
	GameState.registrar_escolha("Desarmou a segurança do Palácio através de by-pass cívico", 3)
	
	if GameState.is_minigame_mode:
		await GameState.retornar_para_game_scene_apos_minigame()
	else:
		GameState.cena_atual = PALACIO_SCENE
		GameState.salvar_jogo(false)
		await TimelineManager.parar_tudo()
		await FadeManager.carregar_cena(PALACIO_SCENE)


# ══════════════════════════════════════════
# AUXILIARES
# ══════════════════════════════════════════
func _play_click() -> void:
	if sfx_click:
		sfx_click.play()


func _limpar(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()


func _centralizar(node: Control) -> void:
	if not node: return
	node.pivot_offset = node.size * 0.5


func _label(texto_lbl: String, tamanho: int, cor: Color, fonte: Font) -> Label:
	var lbl := Label.new()
	lbl.text = texto_lbl
	lbl.add_theme_font_override("font", fonte)
	lbl.add_theme_font_size_override("font_size", tamanho)
	lbl.add_theme_color_override("font_color", cor)
	lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	# Corrige o overlap de linhas devido a métricas de fontes retro
	if fonte == FONTE:
		lbl.add_theme_constant_override("line_spacing", 4)
	else:
		lbl.add_theme_constant_override("line_spacing", 2)
	return lbl


func _margin(valor: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", valor)
	margin.add_theme_constant_override("margin_right", valor)
	margin.add_theme_constant_override("margin_top", valor)
	margin.add_theme_constant_override("margin_bottom", valor)
	return margin


func _ca(code: String, alpha: float) -> Color:
	var color := Color(code)
	color.a = alpha
	return color


func _stylebox(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_left = border_width
	sb.border_width_top = border_width
	sb.border_width_right = border_width
	sb.border_width_bottom = border_width
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	return sb
