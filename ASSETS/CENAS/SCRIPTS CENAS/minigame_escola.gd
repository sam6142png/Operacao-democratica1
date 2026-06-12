extends Control

# ═══════════════════════════════════════════════════════════════
#  MINIGAME ESCOLA — SINTONIZADOR DE ONDAS (ACESSIBILIDADE)
# ═══════════════════════════════════════════════════════════════

const FONTE = preload("res://ASSETS/FONTES/determination.ttf")
const FONTE_MONO = preload("res://ASSETS/FONTES/dogicapixel.ttf")
const BG_TEX = preload("res://ASSETS/SPRITES/FUNDOS/Sala de Aula.png")

# Audio Streams
const CLICK_SOUND = preload("res://ASSETS/SOUNDS/FSX/BotoesClick.mp3")
const HOVER_SOUND = preload("res://ASSETS/SOUNDS/FSX/BotoesHover.mp3")
const ERRO_SOUND  = preload("res://ASSETS/SOUNDS/FSX/SlideMenu.mp3")
const SPEECH_SOUND = preload("res://ASSETS/SOUNDS/Fala minigame escola.mp3")

# Cores do Tema Cívico-Retrô
const COR_BG_OVERLAY  := Color(0.04, 0.04, 0.05, 0.82)
const COR_PANEL_BG    := Color(0.04, 0.04, 0.07, 0.96)
const COR_PANEL_BORDA := Color(0.0,  0.72, 1.0,  0.8) # Azul Cívico
const COR_GREEN_WAVE  := Color(0.0,  1.0,  0.4,  0.9) # Rádio Livre (Verde)
const COR_RED_WAVE    := Color(1.0,  0.22, 0.22, 0.85) # Bloqueio (Vermelho)
const COR_TEXT_PRI    := Color(1.0,  1.0,  1.0,  1.0)
const COR_TEXT_SEC    := Color(0.75, 0.82, 0.95, 1.0)
const COR_TEXT_TER    := Color(0.42, 0.53, 0.68, 1.0)

# ==========================================
# ESTADO DO TRANSMISSOR E SINTONIA
# ==========================================
var canal_atual: int = 0 # 0 = MIC, 1 = TX, 2 = ANT/AMP
var finalizado := false
var dialogo_em_execucao := false
var tempo_restante: float = 45.0
var lock_time: float = 0.0
const LOCK_TARGET: float = 1.5 # Reduzido para acoplamento mais rápido

# Parâmetros da Onda Alvo (Regime)
var target_amp: float = 0.6
var target_freq: float = 6.0
var target_phase: float = 2.0

# Parâmetros da Onda do Jogador (Ajustes)
var val_amp: float = 0.15
var val_freq: float = 3.0
var val_phase: float = 0.0 # Mantido constante para simplificar a sintonização

var wave_time: float = 0.0

# Componentes de Som
var sfx_click: AudioStreamPlayer
var sfx_hover: AudioStreamPlayer
var sfx_erro: AudioStreamPlayer

# Componentes de UI
var layer: CanvasLayer
var panel_main: PanelContainer
var oscilloscope: Control
var progress_lock: ProgressBar
var slider_amp: HSlider
var slider_freq: HSlider
var dial_amp: Control
var dial_freq: Control
var lbl_timer: Label
var lbl_channel_title: Label
var tab_mic: Label
var tab_tx: Label
var tab_ant: Label
var lbl_lock_status: Label

# Labels Auxiliares de Sintonização (Acessibilidade)
var lbl_helper_amp: Label
var lbl_helper_freq: Label

# ==========================================
# INICIALIZAÇÃO
# ==========================================
func _ready() -> void:
	if has_node("/root/MusicManager"):
		get_node("/root/MusicManager").play_default_music()
	if get_tree().root.has_node("MedidorConfianca"):
		get_tree().root.get_node("MedidorConfianca").visible = false

	_configurar_audio()
	_construir_ui()
	_inicializar_canal(0)
	_iniciar_minigame_fluxo()

func _configurar_audio() -> void:
	sfx_click = AudioStreamPlayer.new()
	sfx_click.stream = CLICK_SOUND
	sfx_click.bus = "SFX"
	add_child(sfx_click)
	
	sfx_hover = AudioStreamPlayer.new()
	sfx_hover.stream = HOVER_SOUND
	sfx_hover.bus = "SFX"
	add_child(sfx_hover)
	
	sfx_erro = AudioStreamPlayer.new()
	sfx_erro.stream = ERRO_SOUND
	sfx_erro.bus = "SFX"
	add_child(sfx_erro)

func _play(player: AudioStreamPlayer, pitch: float = 1.0) -> void:
	if player:
		player.pitch_scale = pitch
		player.play()

# ==========================================
# CONSTRUÇÃO DA UI DINÂMICA
# ==========================================
func _construir_ui() -> void:
	layer = CanvasLayer.new()
	add_child(layer)
	
	# Background sala de aula desfocado e escuro
	var bg = TextureRect.new()
	if BG_TEX:
		bg.texture = BG_TEX
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.modulate = Color(0.24, 0.24, 0.28)
	layer.add_child(bg)
	
	# Overlay escurecido do tema
	var overlay = ColorRect.new()
	overlay.color = COR_BG_OVERLAY
	overlay.set_anchors_preset(PRESET_FULL_RECT)
	layer.add_child(overlay)
	
	# Grid de linhas de vetor de fundo
	var bg_grid = Control.new()
	bg_grid.set_anchors_preset(PRESET_FULL_RECT)
	bg_grid.modulate = Color(0.0, 0.6, 1.0, 0.02)
	bg_grid.draw.connect(func():
		var step = 40
		var grid_size = bg_grid.size
		for x in range(0, int(grid_size.x), step):
			bg_grid.draw_line(Vector2(x, 0), Vector2(x, grid_size.y), Color.WHITE, 1.0)
		for y in range(0, int(grid_size.y), step):
			bg_grid.draw_line(Vector2(0, y), Vector2(grid_size.x, y), Color.WHITE, 1.0)
	)
	layer.add_child(bg_grid)
	
	# Shader de Vinheta CRT
	var crt_overlay = ColorRect.new()
	crt_overlay.set_anchors_preset(PRESET_FULL_RECT)
	crt_overlay.mouse_filter = MOUSE_FILTER_IGNORE
	var crt_mat = ShaderMaterial.new()
	var crt_shader = Shader.new()
	crt_shader.code = """
shader_type canvas_item;
uniform float vignette_strength : hint_range(0.0, 2.0) = 1.35;
uniform float scanline_alpha : hint_range(0.0, 0.5) = 0.09;
void fragment() {
	vec2 center = UV - 0.5;
	float dist = length(center) * 1.414;
	float vignette = smoothstep(0.38, 1.0, dist) * vignette_strength;
	float scanline = abs(sin(UV.y * 540.0)) * scanline_alpha;
	COLOR = vec4(0.0, 0.05, 0.1, vignette + scanline);
}
"""
	crt_mat.shader = crt_shader
	crt_overlay.material = crt_mat
	layer.add_child(crt_overlay)
	
	# Painel de Controle Principal
	panel_main = PanelContainer.new()
	panel_main.custom_minimum_size = Vector2(1040, 660)
	panel_main.set_anchors_preset(PRESET_CENTER)
	panel_main.grow_horizontal = GROW_DIRECTION_BOTH
	panel_main.grow_vertical = GROW_DIRECTION_BOTH
	panel_main.add_theme_stylebox_override("panel", _stylebox(COR_PANEL_BG, COR_PANEL_BORDA, 3, 10))
	layer.add_child(panel_main)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	panel_main.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)
	
	# Título do Minigame
	var lbl_title = Label.new()
	lbl_title.text = "SINTONIZADOR DE ONDAS — PA TRANSMITTER"
	lbl_title.add_theme_font_override("font", FONTE)
	lbl_title.add_theme_font_size_override("font_size", 30)
	lbl_title.add_theme_color_override("font_color", COR_PANEL_BORDA)
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_title)
	
	# Abas dos Canais de Sintonização (Tabs HUD)
	var hbox_tabs = HBoxContainer.new()
	hbox_tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_tabs.add_theme_constant_override("separation", 35)
	vbox.add_child(hbox_tabs)
	
	tab_mic = _criar_tab_label("CANAL 1: MIC")
	tab_tx = _criar_tab_label("CANAL 2: TX")
	tab_ant = _criar_tab_label("CANAL 3: ANT/AMP")
	hbox_tabs.add_child(tab_mic)
	hbox_tabs.add_child(tab_tx)
	hbox_tabs.add_child(tab_ant)
	
	# Painel do Osciloscópio Split-Screen
	var split_hbox = HBoxContainer.new()
	split_hbox.size_flags_vertical = SIZE_EXPAND_FILL
	split_hbox.add_theme_constant_override("separation", 24)
	vbox.add_child(split_hbox)
	
	# Lado Esquerdo: Osciloscópio CRT
	var panel_osc = PanelContainer.new()
	panel_osc.size_flags_horizontal = SIZE_EXPAND_FILL
	panel_osc.size_flags_stretch_ratio = 1.6
	var sb_osc = StyleBoxFlat.new()
	sb_osc.bg_color = Color(0.01, 0.02, 0.03, 0.98)
	sb_osc.border_width_left = 2; sb_osc.border_width_right = 2
	sb_osc.border_width_top = 2; sb_osc.border_width_bottom = 2
	sb_osc.border_color = COR_PANEL_BORDA
	sb_osc.corner_radius_top_left = 6; sb_osc.corner_radius_top_right = 6
	sb_osc.corner_radius_bottom_left = 6; sb_osc.corner_radius_bottom_right = 6
	panel_osc.add_theme_stylebox_override("panel", sb_osc)
	split_hbox.add_child(panel_osc)
	
	oscilloscope = Control.new()
	oscilloscope.set_anchors_preset(PRESET_FULL_RECT)
	oscilloscope.draw.connect(_on_oscilloscope_draw)
	panel_osc.add_child(oscilloscope)
	
	# Lado Direito: Status e Lock Indicators
	var col_right = VBoxContainer.new()
	col_right.size_flags_horizontal = SIZE_EXPAND_FILL
	col_right.size_flags_stretch_ratio = 1.0
	col_right.add_theme_constant_override("separation", 12)
	split_hbox.add_child(col_right)
	
	var status_bg = PanelContainer.new()
	status_bg.size_flags_vertical = SIZE_EXPAND_FILL
	status_bg.add_theme_stylebox_override("panel", _stylebox(Color(0.08, 0.09, 0.13, 0.5), Color("#2a2c35", 0.4), 1, 6))
	col_right.add_child(status_bg)
	
	var status_margin = MarginContainer.new()
	status_margin.add_theme_constant_override("margin_left", 16)
	status_margin.add_theme_constant_override("margin_right", 16)
	status_margin.add_theme_constant_override("margin_top", 16)
	status_margin.add_theme_constant_override("margin_bottom", 16)
	status_bg.add_child(status_margin)
	
	var status_vbox = VBoxContainer.new()
	status_vbox.add_theme_constant_override("separation", 14)
	status_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	status_margin.add_child(status_vbox)
	
	lbl_channel_title = _label("MODULAÇÃO DE ENTRADA: MIC", 18, COR_PANEL_BORDA, FONTE)
	lbl_channel_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_vbox.add_child(lbl_channel_title)
	
	var desc_inst = _label("Alinhe os parâmetros de AMPLITUDE e FREQUÊNCIA para sintonizar a rádio nos alto-falantes.", 13, COR_TEXT_SEC, FONTE_MONO)
	desc_inst.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_inst.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_vbox.add_child(desc_inst)
	
	status_vbox.add_child(_label("TEMPO RESTANTE:", 13, COR_TEXT_TER, FONTE_MONO))
	lbl_timer = _label("45.0s", 36, Color("#ffa240"), FONTE)
	lbl_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_vbox.add_child(lbl_timer)
	
	status_vbox.add_child(_label("SINCRONISMO DE SINAL:", 13, COR_TEXT_TER, FONTE_MONO))
	
	progress_lock = ProgressBar.new()
	progress_lock.min_value = 0.0
	progress_lock.max_value = LOCK_TARGET
	progress_lock.value = 0.0
	progress_lock.custom_minimum_size = Vector2(0, 24)
	progress_lock.show_percentage = false
	var sb_lock_bg = StyleBoxFlat.new()
	sb_lock_bg.bg_color = Color(0.05, 0.05, 0.06)
	progress_lock.add_theme_stylebox_override("background", sb_lock_bg)
	var sb_lock_fg = StyleBoxFlat.new()
	sb_lock_fg.bg_color = Color("#62ff86")
	progress_lock.add_theme_stylebox_override("fill", sb_lock_fg)
	status_vbox.add_child(progress_lock)
	
	lbl_lock_status = _label("SINAL DESSINTONIZADO", 15, Color("#ff4b4b"), FONTE_MONO)
	lbl_lock_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_vbox.add_child(lbl_lock_status)
	
	# Painel de Controles e Sliders na base
	var ctrl_panel = PanelContainer.new()
	ctrl_panel.add_theme_stylebox_override("panel", _stylebox(Color(0.06, 0.06, 0.09, 0.65), Color(COR_PANEL_BORDA, 0.22), 1, 8))
	vbox.add_child(ctrl_panel)
	
	var ctrl_margin = MarginContainer.new()
	ctrl_margin.add_theme_constant_override("margin_left", 20)
	ctrl_margin.add_theme_constant_override("margin_right", 20)
	ctrl_margin.add_theme_constant_override("margin_top", 12)
	ctrl_margin.add_theme_constant_override("margin_bottom", 12)
	ctrl_panel.add_child(ctrl_margin)
	
	var ctrl_vbox = VBoxContainer.new()
	ctrl_vbox.add_theme_constant_override("separation", 14)
	ctrl_margin.add_child(ctrl_vbox)
	
	# Slider 1: Amplitude
	slider_amp = _criar_linha_controle(ctrl_vbox, "AMPLITUDE (ALTURA DA ONDA)", 0.1, 1.0, 0.15, func(v):
		val_amp = v
		dial_amp.queue_redraw()
	)
	dial_amp = ctrl_vbox.get_child(ctrl_vbox.get_child_count() - 1).get_child(1)
	lbl_helper_amp = ctrl_vbox.get_child(ctrl_vbox.get_child_count() - 1).get_child(3) as Label
	
	# Slider 2: Frequência
	slider_freq = _criar_linha_controle(ctrl_vbox, "FREQUÊNCIA (QUANTIDADE DE CICLOS)", 2.0, 15.0, 3.0, func(v):
		val_freq = v
		dial_freq.queue_redraw()
	)
	dial_freq = ctrl_vbox.get_child(ctrl_vbox.get_child_count() - 1).get_child(1)
	lbl_helper_freq = ctrl_vbox.get_child(ctrl_vbox.get_child_count() - 1).get_child(3) as Label

func _criar_tab_label(texto_tab: String) -> Label:
	var l = Label.new()
	l.text = "[ " + texto_tab + " ]"
	l.add_theme_font_override("font", FONTE_MONO)
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", COR_TEXT_TER)
	return l

func _criar_linha_controle(parent: Control, label_text: String, min_v: float, max_v: float, val: float, callback: Callable) -> HSlider:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	parent.add_child(hbox)
	
	var lbl = _label(label_text, 13, COR_TEXT_SEC, FONTE_MONO)
	lbl.custom_minimum_size = Vector2(250, 0)
	hbox.add_child(lbl)
	
	# Knob Dial Desenhado dinamicamente
	var dial = Control.new()
	dial.custom_minimum_size = Vector2(40, 40)
	dial.draw.connect(func():
		var size = dial.size
		var center = size * 0.5
		var radius = size.x * 0.4
		
		# Fundo do knob
		dial.draw_circle(center, radius, Color("#181b22"))
		dial.draw_circle(center, radius, COR_PANEL_BORDA, false, 1.5)
		
		# Posição angular
		var slider_node = dial.get_parent().get_node("Slider") as HSlider
		var ratio = (slider_node.value - slider_node.min_value) / (slider_node.max_value - slider_node.min_value)
		var angle = lerpf(-deg_to_rad(135.0), deg_to_rad(135.0), ratio) - PI/2.0
		var pointer_dest = center + Vector2(cos(angle), sin(angle)) * (radius - 2.0)
		
		# Marcador do dial
		dial.draw_line(center, pointer_dest, COR_PANEL_BORDA, 2.0)
	)
	hbox.add_child(dial)
	
	var slider = HSlider.new()
	slider.name = "Slider"
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = 0.01
	slider.value = val
	slider.size_flags_horizontal = SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(0, 30)
	slider.value_changed.connect(callback)
	slider.value_changed.connect(func(v): _play(sfx_hover, 1.25))
	
	var sb_bg = StyleBoxFlat.new()
	sb_bg.bg_color = Color(0.09, 0.09, 0.12)
	sb_bg.content_margin_top = 5
	sb_bg.content_margin_bottom = 5
	slider.add_theme_stylebox_override("slider", sb_bg)
	hbox.add_child(slider)
	
	# Helper Label (Acessibilidade)
	var helper_lbl = _label("---", 13, COR_TEXT_TER, FONTE_MONO)
	helper_lbl.custom_minimum_size = Vector2(130, 0)
	helper_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(helper_lbl)
	
	return slider

# ==========================================
# CICLO E ESTADOS DE SINTONIA
# ==========================================
func _process(delta: float) -> void:
	if finalizado or dialogo_em_execucao:
		return
		
	wave_time += delta * 15.0
	if oscilloscope:
		oscilloscope.queue_redraw()
		
	# Atualiza o tempo regressivo
	tempo_restante -= delta
	if tempo_restante <= 0.0:
		tempo_restante = 0.0
		_trigger_defeat()
		return
		
	lbl_timer.text = str(snapped(tempo_restante, 0.1)) + "s"
	lbl_timer.add_theme_color_override("font_color", Color("#ff4b4b") if tempo_restante < 10.0 else Color("#ffa240"))
	
	# Verifica o alinhamento com tolerâncias amplas para acessibilidade
	# Amplitude: diferença < 0.15 é aceitável
	# Frequência: diferença < 1.0 é aceitável
	var diff_amp = abs(val_amp - target_amp)
	var diff_freq = abs(val_freq - target_freq)
	
	var amp_aligned = diff_amp < 0.15
	var freq_aligned = diff_freq < 1.0
	
	# Atualiza Helpers de Feedback
	if lbl_helper_amp:
		if val_amp < target_amp - 0.15:
			lbl_helper_amp.text = "▲ AUMENTAR"
			lbl_helper_amp.add_theme_color_override("font_color", Color("#ffa240"))
		elif val_amp > target_amp + 0.15:
			lbl_helper_amp.text = "▼ DIMINUIR"
			lbl_helper_amp.add_theme_color_override("font_color", Color("#ffa240"))
		else:
			lbl_helper_amp.text = "ALINHADO"
			lbl_helper_amp.add_theme_color_override("font_color", Color("#62ff86"))
			
	if lbl_helper_freq:
		if val_freq < target_freq - 1.0:
			lbl_helper_freq.text = "▲ AUMENTAR"
			lbl_helper_freq.add_theme_color_override("font_color", Color("#ffa240"))
		elif val_freq > target_freq + 1.0:
			lbl_helper_freq.text = "▼ DIMINUIR"
			lbl_helper_freq.add_theme_color_override("font_color", Color("#ffa240"))
		else:
			lbl_helper_freq.text = "ALINHADO"
			lbl_helper_freq.add_theme_color_override("font_color", Color("#62ff86"))
	
	var sintonizado = amp_aligned and freq_aligned
	
	if sintonizado:
		lock_time = min(LOCK_TARGET, lock_time + delta)
		progress_lock.value = lock_time
		lbl_lock_status.text = "SINAL ACOPLADO [LOCK %d%%]" % int(lock_time / LOCK_TARGET * 100.0)
		lbl_lock_status.add_theme_color_override("font_color", Color("#62ff86"))
		
		# Som suave de sintonia acoplada
		if sfx_hover and not sfx_hover.playing:
			sfx_hover.pitch_scale = 1.0 + sin(Time.get_ticks_msec() * 0.015) * 0.05
			sfx_hover.play()
			
		if lock_time >= LOCK_TARGET:
			_concluir_canal_atual()
	else:
		lock_time = max(0.0, lock_time - delta * 1.5)
		progress_lock.value = lock_time
		lbl_lock_status.text = "BUSCANDO FREQUÊNCIA..."
		lbl_lock_status.add_theme_color_override("font_color", Color("#ff4b4b"))

func _iniciar_minigame_fluxo() -> void:
	dialogo_em_execucao = true
	_set_interacao(false)
	await TimelineManager.tocar_dialogo("fase3_escola_minigame_inicio", false)
	dialogo_em_execucao = false
	_set_interacao(true)

func _inicializar_canal(idx: int) -> void:
	canal_atual = idx
	tempo_restante = 45.0
	lock_time = 0.0
	if progress_lock: progress_lock.value = 0.0
	
	# Define parâmetros alvo aleatórios baseados no canal atual
	var r = RandomNumberGenerator.new()
	r.randomize()
	
	target_amp = r.randf_range(0.38, 0.85)
	target_freq = r.randf_range(4.5, 12.5)
	target_phase = r.randf_range(0.5, 5.8)
	
	# Sincroniza a HUD de Abas
	if tab_mic and tab_tx and tab_ant:
		tab_mic.add_theme_color_override("font_color", COR_PANEL_BORDA if canal_atual == 0 else (Color("#62ff86") if canal_atual > 0 else COR_TEXT_TER))
		tab_tx.add_theme_color_override("font_color", COR_PANEL_BORDA if canal_atual == 1 else (Color("#62ff86") if canal_atual > 1 else COR_TEXT_TER))
		tab_ant.add_theme_color_override("font_color", COR_PANEL_BORDA if canal_atual == 2 else COR_TEXT_TER)
		
	if lbl_channel_title:
		match canal_atual:
			0: lbl_channel_title.text = "MODULAÇÃO DE ENTRADA: MIC"
			1: lbl_channel_title.text = "CALIBRAÇÃO DE SAÍDA: TX"
			2: lbl_channel_title.text = "SINTONIZAÇÃO GERAL: ANTENA / AMP"
			
	# Redefine controles para valores iniciais afastados
	if slider_amp and slider_freq:
		slider_amp.value = 0.15
		slider_freq.value = 3.0
		
	if dial_amp: dial_amp.queue_redraw()
	if dial_freq: dial_freq.queue_redraw()

func _concluir_canal_atual() -> void:
	_play(sfx_click, 0.9)
	dialogo_em_execucao = true
	_set_interacao(false)
	
	# Efeito visual de brilho verde
	var tween = create_tween()
	var original_mod = oscilloscope.modulate
	tween.tween_property(oscilloscope, "modulate", Color(0, 2.0, 0.5, 1.0), 0.1)
	tween.tween_property(oscilloscope, "modulate", original_mod, 0.35)
	await tween.finished
	
	if canal_atual == 0:
		await TimelineManager.tocar_dialogo("fase3_escola_minigame_fios_ok", false)
		_inicializar_canal(1)
		dialogo_em_execucao = false
		_set_interacao(true)
	elif canal_atual == 1:
		await TimelineManager.tocar_dialogo("fase3_escola_minigame_disjuntores_ok", false)
		_inicializar_canal(2)
		dialogo_em_execucao = false
		_set_interacao(true)
	else:
		finalizado = true
		
		# Toca a fala do rádio nos alto-falantes de forma persistente
		var speech_player = AudioStreamPlayer.new()
		speech_player.stream = SPEECH_SOUND
		speech_player.bus = "SFX"
		get_tree().root.add_child(speech_player)
		speech_player.play()
		speech_player.finished.connect(func(): speech_player.queue_free())
		
		await TimelineManager.tocar_dialogo("fase3_escola_minigame_sintonia_ok", false)
		await _mostrar_card_transmissao()
		_finalizar_sucesso()

func _trigger_defeat() -> void:
	_play(sfx_erro, 0.9)
	dialogo_em_execucao = true
	_set_interacao(false)
	await TimelineManager.tocar_dialogo("fase3_escola_minigame_derrota", false)
	FadeManager.carregar_cena("res://ASSETS/CENAS/minigame_escola.tscn")

func _finalizar_sucesso() -> void:
	if get_tree().root.has_node("MedidorConfianca"):
		get_tree().root.get_node("MedidorConfianca").visible = true
		
	GameState.fase_atual = 3
	GameState.fase3_passo = "escola_concluida"
	GameState.desbloquear_conquista("escola_ok")
	await GameState.retornar_para_game_scene_apos_minigame()

func _mostrar_card_transmissao() -> void:
	# Painel de escurecimento de fundo
	var overlay_dim = ColorRect.new()
	overlay_dim.color = Color(0.02, 0.02, 0.03, 0.85)
	overlay_dim.set_anchors_preset(PRESET_FULL_RECT)
	layer.add_child(overlay_dim)
	
	# Painel do Card
	var card_panel = PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(720, 460)
	card_panel.set_anchors_preset(PRESET_CENTER)
	card_panel.grow_horizontal = GROW_DIRECTION_BOTH
	card_panel.grow_vertical = GROW_DIRECTION_BOTH
	card_panel.add_theme_stylebox_override("panel", _stylebox(COR_PANEL_BG, COR_GREEN_WAVE, 4, 12))
	overlay_dim.add_child(card_panel)
	
	# Container vertical
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	
	var margin = _margin(28)
	card_panel.add_child(margin)
	margin.add_child(vbox)
	
	# Ícone ou Detalhe Estético (ex: Ondas de Rádio)
	var lbl_status = _label("— TRANSMISSÃO RECEBIDA —", 22, COR_GREEN_WAVE, FONTE)
	lbl_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_status)
	
	# Texto da Mensagem
	var lbl_mensagem = Label.new()
	lbl_mensagem.text = "Você está ouvindo a transmissão Voz Livre — em uma frequência que eles não conseguem captar. Se esta mensagem chQegou até você, é porque alguém conseguiu libertar um de nossos canais. Amanhã, Praça do Palácio, ao meio-dia. Não venha com medo — venha com verdade. Nos encontramos lá! Câmbio e desligo."
	lbl_mensagem.add_theme_font_override("font", FONTE)
	lbl_mensagem.add_theme_font_size_override("font_size", 22)
	lbl_mensagem.add_theme_color_override("font_color", COR_TEXT_PRI)
	lbl_mensagem.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl_mensagem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_mensagem.custom_minimum_size = Vector2(620, 0)
	vbox.add_child(lbl_mensagem)
	
	# Divisor estético
	var div = ColorRect.new()
	div.custom_minimum_size = Vector2(400, 2)
	div.color = Color(COR_GREEN_WAVE.r, COR_GREEN_WAVE.g, COR_GREEN_WAVE.b, 0.3)
	div.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(div)
	
	# Botão de Sair/Seguir
	var btn_seguir = Button.new()
	btn_seguir.text = "SEGUIR"
	btn_seguir.custom_minimum_size = Vector2(200, 50)
	btn_seguir.add_theme_font_override("font", FONTE)
	btn_seguir.add_theme_font_size_override("font_size", 22)
	btn_seguir.add_theme_stylebox_override("normal", _stylebox(Color("#142d20"), COR_GREEN_WAVE, 2, 6))
	btn_seguir.add_theme_stylebox_override("hover", _stylebox(COR_GREEN_WAVE, COR_GREEN_WAVE, 2, 6))
	btn_seguir.add_theme_stylebox_override("pressed", _stylebox(COR_GREEN_WAVE.darkened(0.2), COR_GREEN_WAVE, 2, 6))
	btn_seguir.add_theme_color_override("font_color", Color("#fff4dd"))
	btn_seguir.add_theme_color_override("font_hover_color", Color("#0b0b0d"))
	btn_seguir.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_seguir.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(btn_seguir)
	
	# Efeito de Entrada Suave (Tween)
	card_panel.modulate.a = 0.0
	card_panel.scale = Vector2(0.9, 0.9)
	var tw = create_tween().set_parallel(true)
	tw.tween_property(card_panel, "modulate:a", 1.0, 0.3)
	tw.tween_property(card_panel, "scale", Vector2.ONE, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	btn_seguir.mouse_entered.connect(func():
		if sfx_hover: sfx_hover.play()
		btn_seguir.add_theme_color_override("font_color", Color("#0b0b0d"))
	)
	btn_seguir.mouse_exited.connect(func():
		btn_seguir.add_theme_color_override("font_color", Color("#fff4dd"))
	)
	
	await btn_seguir.pressed
	if sfx_click: sfx_click.play()
	
	# Efeito de Saída Suave (Tween)
	var tw_out = create_tween().set_parallel(true)
	tw_out.tween_property(card_panel, "modulate:a", 0.0, 0.2)
	tw_out.tween_property(overlay_dim, "color:a", 0.0, 0.2)
	await tw_out.finished
	overlay_dim.queue_free()

func _set_interacao(ativo: bool) -> void:
	if slider_amp: slider_amp.editable = ativo
	if slider_freq: slider_freq.editable = ativo

# ==========================================
# DESENHO DO OSCILOSCÓPIO CRT (RETRO VECTOR)
# ==========================================
func _on_oscilloscope_draw() -> void:
	if not oscilloscope: return
	var size = oscilloscope.size
	var center_y = size.y / 2.0
	
	# 1. Desenha a grade (grid) verde/azulada tática
	var grid_color = Color(0.0, 0.45, 0.72, 0.15)
	var step = 25
	for x in range(0, int(size.x), step):
		oscilloscope.draw_line(Vector2(x, 0), Vector2(x, size.y), grid_color, 1.0)
	for y in range(0, int(size.y), step):
		oscilloscope.draw_line(Vector2(0, y), Vector2(size.x, y), grid_color, 1.0)
		
	# Eixo central mais grosso
	oscilloscope.draw_line(Vector2(0, center_y), Vector2(size.x, center_y), Color(0.0, 0.6, 1.0, 0.28), 1.5)
	
	# 2. Desenha a Onda Vermelha Alvo (Bloqueio militar com ruído)
	var target_points = PackedVector2Array()
	var num_points = 120
	var amp_pixels = size.y * 0.35
	
	for i in range(num_points):
		var t = float(i) / (num_points - 1)
		var x = t * size.x
		
		# Equação senoidal portadora
		var clean_y = sin(t * target_freq * PI - wave_time * 0.05 + target_phase) * target_amp * amp_pixels
		
		# Ruído de jammer militar (reduz quando acoplado)
		var noise = randf_range(-4.0, 4.0) * sin(Time.get_ticks_msec() * 0.15) * (1.0 - (lock_time / LOCK_TARGET))
		
		target_points.append(Vector2(x, center_y + clean_y + noise))
		
	# Brilho da onda vermelha
	for i in range(target_points.size() - 1):
		oscilloscope.draw_line(target_points[i], target_points[i+1], Color(COR_RED_WAVE, 0.15), 5.0)
	for i in range(target_points.size() - 1):
		oscilloscope.draw_line(target_points[i], target_points[i+1], COR_RED_WAVE, 2.0)
		
	# 3. Desenha a Onda Verde (Jogador - Rádio Livre)
	var player_points = PackedVector2Array()
	for i in range(num_points):
		var t = float(i) / (num_points - 1)
		var x = t * size.x
		# A fase é mantida fixa para simplificar a sintonização do jogador
		var clean_y = sin(t * val_freq * PI - wave_time * 0.05) * val_amp * amp_pixels
		player_points.append(Vector2(x, center_y + clean_y))
		
	# Brilho neon da onda verde
	var pulse_glow = 0.2 + 0.1 * sin(Time.get_ticks_msec() * 0.02)
	for i in range(player_points.size() - 1):
		oscilloscope.draw_line(player_points[i], player_points[i+1], Color(COR_GREEN_WAVE, pulse_glow), 6.5)
	for i in range(player_points.size() - 1):
		oscilloscope.draw_line(player_points[i], player_points[i+1], COR_GREEN_WAVE, 2.0)
		
	# 4. Scanlines internas analógicas sobre a grade
	var scanline_color = Color(0.0, 0.02, 0.04, 0.25)
	for y in range(0, int(size.y), 4):
		oscilloscope.draw_line(Vector2(0, y), Vector2(size.x, y), scanline_color, 1.5)

# ==========================================
# AUXILIARES E LAYOUT
# ==========================================
func _label(texto_lbl: String, tamanho: int, cor: Color, fonte: Font) -> Label:
	var lbl := Label.new()
	lbl.text = texto_lbl
	lbl.add_theme_font_override("font", fonte)
	lbl.add_theme_font_size_override("font_size", tamanho)
	lbl.add_theme_color_override("font_color", cor)
	lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 2)
	return lbl

func _margin(valor: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", valor)
	margin.add_theme_constant_override("margin_right", valor)
	margin.add_theme_constant_override("margin_top", valor)
	margin.add_theme_constant_override("margin_bottom", valor)
	return margin

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
	return sb
