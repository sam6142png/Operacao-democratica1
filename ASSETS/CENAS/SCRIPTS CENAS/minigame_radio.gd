extends Control

# === RECURSOS ===
const FONTE = preload("res://ASSETS/FONTES/determination.ttf")

# === DADOS DO MINIGAME ===
const TARGET_FREQS = [91.5, 98.3, 104.7]
const ENCRYPTED_MSGS = [
	"YHQGD GH SDPRQKD QR EDLUUR 3",
	"UHXQLDR VHFUXWD PDUFDGD",
	"HVFROD FRQWUROD PHQWHV"
]
const DECRYPTED_MSGS = [
	"VENDA DE PAMONHA NO BAIRRO 3",
	"REUNIAO SECRETA MARCADA",
	"OPERAÇÃO CONTROLE EDUCACIONAL"
]
const DISCOVERY_TIMELINES = [
	"fase2_reacao_mensagem_1",
	"fase2_reacao_mensagem_2",
	"fase2_reacao_final"
]

# === ESTADO ===
var frequencia_atual: float = 88.0
var shift_atual: int = 0
var decrypted_states = [false, false, false]
var captured_index: int = -1 # -1 se nenhum sinal próximo, 0, 1, 2 se capturado
var signal_strength: float = 0.0 # 0.0 a 1.0
var wave_time: float = 0.0
var finalizado := false
var dialogo_descoberta_em_execucao := false

# === COMPONENTES DE UI ===
var layer: CanvasLayer
var panel_main: PanelContainer
var lbl_freq_display: Label
var slider_tuner: HSlider
var progress_signal: ProgressBar

# Status das Frequências
var lbl_status_1: Label
var lbl_status_2: Label
var lbl_status_3: Label

# Painel de Decodificação
var panel_decode: PanelContainer
var lbl_captured_title: Label
var lbl_raw_text: Label
var lbl_shift_value: Label
var lbl_preview_text: Label
var btn_save_signal: Button
var btn_finish: Button

# Visualizador (Osciloscópio)
var oscilloscope: Control

func _ready() -> void:
	if get_tree().root.has_node("MedidorConfianca"):
		get_tree().root.get_node("MedidorConfianca").visible = false
	
	# Garante que as escolhas salvas não interfiram
	_construir_ui()
	_atualizar_ui_estado()

# ══════════════════════════════════════════════
#  CONSTRUÇÃO DA UI DINÂMICA
# ══════════════════════════════════════════════

func _construir_ui() -> void:
	layer = CanvasLayer.new()
	add_child(layer)
	
	# Fundo: RadioPainel.png
	var bg: Control
	var bg_tex = load("res://ASSETS/SPRITES/FUNDOS/RadioPainel.png")
	if bg_tex:
		var tex_rect = TextureRect.new()
		tex_rect.texture = bg_tex
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.modulate = Color(0.6, 0.6, 0.65) # Escurece levemente o painel para maior contraste
		bg = tex_rect
	else:
		var color_rect = ColorRect.new()
		color_rect.color = Color(0.02, 0.02, 0.03, 1.0)
		bg = color_rect
	bg.set_anchors_preset(PRESET_FULL_RECT)
	layer.add_child(bg)
	
	# Grid de efeito tecnológico de fundo (linhas azuis sutis)
	var bg_grid = Control.new()
	bg_grid.set_anchors_preset(PRESET_FULL_RECT)
	bg_grid.modulate = Color(0.0, 0.5, 1.0, 0.03)
	bg_grid.draw.connect(func():
		var step = 40
		var grid_size = bg_grid.size
		for x in range(0, int(grid_size.x), step):
			bg_grid.draw_line(Vector2(x, 0), Vector2(x, grid_size.y), Color.WHITE, 1.0)
		for y in range(0, int(grid_size.y), step):
			bg_grid.draw_line(Vector2(0, y), Vector2(grid_size.x, y), Color.WHITE, 1.0)
	)
	layer.add_child(bg_grid)
	
	# Painel principal
	panel_main = PanelContainer.new()
	panel_main.custom_minimum_size = Vector2(960, 650)
	panel_main.set_anchors_preset(PRESET_CENTER)
	panel_main.grow_horizontal = GROW_DIRECTION_BOTH
	panel_main.grow_vertical = GROW_DIRECTION_BOTH
	
	var sb_main = StyleBoxFlat.new()
	sb_main.bg_color = Color(0.04, 0.04, 0.07, 0.96)
	sb_main.border_width_left = 3
	sb_main.border_width_top = 3
	sb_main.border_width_right = 3
	sb_main.border_width_bottom = 3
	sb_main.border_color = Color("#FF8C00") # Borda Laranja
	sb_main.corner_radius_top_left = 12
	sb_main.corner_radius_top_right = 12
	sb_main.corner_radius_bottom_left = 12
	sb_main.corner_radius_bottom_right = 12
	sb_main.shadow_size = 25
	sb_main.shadow_color = Color("#FF8C00", 0.1)
	panel_main.add_theme_stylebox_override("panel", sb_main)
	layer.add_child(panel_main)
	
	# Margens internas
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_bottom", 25)
	margin.add_theme_constant_override("margin_left", 35)
	margin.add_theme_constant_override("margin_right", 35)
	panel_main.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	margin.add_child(vbox)
	
	# Título
	var lbl_title = Label.new()
	lbl_title.text = "SINTONIZADOR DE COMUNICAÇÕES MILITARES"
	lbl_title.add_theme_font_override("font", FONTE)
	lbl_title.add_theme_font_size_override("font_size", 34)
	lbl_title.add_theme_color_override("font_color", Color("#FF8C00"))
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_title)
	
	# Grid de status dos 3 canais
	var hbox_status = HBoxContainer.new()
	hbox_status.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_status.add_theme_constant_override("separation", 40)
	vbox.add_child(hbox_status)
	
	lbl_status_1 = _criar_lbl_status("Freq 1: 91.5 MHz", Color("#FF3333"))
	lbl_status_2 = _criar_lbl_status("Freq 2: 98.3 MHz", Color("#FF3333"))
	lbl_status_3 = _criar_lbl_status("Freq 3: 104.7 MHz", Color("#FF3333"))
	hbox_status.add_child(lbl_status_1)
	hbox_status.add_child(lbl_status_2)
	hbox_status.add_child(lbl_status_3)
	
	# Osciloscópio (Visualizador)
	var panel_osc = PanelContainer.new()
	panel_osc.custom_minimum_size = Vector2(0, 160)
	var sb_osc = StyleBoxFlat.new()
	sb_osc.bg_color = Color(0.01, 0.02, 0.01, 1.0) # Verde escuro de CRT
	sb_osc.border_width_left = 2; sb_osc.border_width_right = 2
	sb_osc.border_width_top = 2; sb_osc.border_width_bottom = 2
	sb_osc.border_color = Color(0.0, 0.6, 0.2)
	sb_osc.corner_radius_top_left = 6; sb_osc.corner_radius_top_right = 6
	sb_osc.corner_radius_bottom_left = 6; sb_osc.corner_radius_bottom_right = 6
	panel_osc.add_theme_stylebox_override("panel", sb_osc)
	vbox.add_child(panel_osc)
	
	oscilloscope = Control.new()
	oscilloscope.set_anchors_preset(PRESET_FULL_RECT)
	oscilloscope.draw.connect(_on_oscilloscope_draw)
	panel_osc.add_child(oscilloscope)
	
	# Controle do Tuner
	var vbox_tuner = VBoxContainer.new()
	vbox_tuner.add_theme_constant_override("separation", 6)
	vbox.add_child(vbox_tuner)
	
	var hbox_freq = HBoxContainer.new()
	hbox_freq.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_tuner.add_child(hbox_freq)
	
	lbl_freq_display = Label.new()
	lbl_freq_display.text = "FREQUÊNCIA: 88.0 MHz"
	lbl_freq_display.add_theme_font_override("font", FONTE)
	lbl_freq_display.add_theme_font_size_override("font_size", 24)
	lbl_freq_display.add_theme_color_override("font_color", Color.WHITE)
	hbox_freq.add_child(lbl_freq_display)
	
	# Tuner Slider
	slider_tuner = HSlider.new()
	slider_tuner.min_value = 88.0
	slider_tuner.max_value = 108.0
	slider_tuner.step = 0.1
	slider_tuner.value = 88.0
	slider_tuner.custom_minimum_size = Vector2(600, 30)
	slider_tuner.size_flags_horizontal = SIZE_SHRINK_CENTER
	slider_tuner.value_changed.connect(_on_freq_changed)
	
	# Customizar slider
	var sb_slider_bg = StyleBoxFlat.new()
	sb_slider_bg.bg_color = Color(0.1, 0.1, 0.15)
	sb_slider_bg.content_margin_top = 6
	sb_slider_bg.content_margin_bottom = 6
	sb_slider_bg.corner_radius_top_left = 3; sb_slider_bg.corner_radius_top_right = 3
	sb_slider_bg.corner_radius_bottom_left = 3; sb_slider_bg.corner_radius_bottom_right = 3
	slider_tuner.add_theme_stylebox_override("slider", sb_slider_bg)
	vbox_tuner.add_child(slider_tuner)
	
	# Barra de Força do Sinal
	var hbox_signal = HBoxContainer.new()
	hbox_signal.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_signal.add_theme_constant_override("separation", 10)
	vbox_tuner.add_child(hbox_signal)
	
	var lbl_sig_title = Label.new()
	lbl_sig_title.text = "FORÇA DO SINAL:"
	lbl_sig_title.add_theme_font_override("font", FONTE)
	lbl_sig_title.add_theme_font_size_override("font_size", 18)
	lbl_sig_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	hbox_signal.add_child(lbl_sig_title)
	
	progress_signal = ProgressBar.new()
	progress_signal.min_value = 0.0
	progress_signal.max_value = 100.0
	progress_signal.value = 0.0
	progress_signal.custom_minimum_size = Vector2(250, 16)
	progress_signal.show_percentage = false
	
	# ProgressBar styling
	var sb_sig_bg = StyleBoxFlat.new()
	sb_sig_bg.bg_color = Color(0.05, 0.05, 0.05)
	progress_signal.add_theme_stylebox_override("background", sb_sig_bg)
	var sb_sig_fg = StyleBoxFlat.new()
	sb_sig_fg.bg_color = Color(0.0, 0.9, 0.3)
	progress_signal.add_theme_stylebox_override("fill", sb_sig_fg)
	
	hbox_signal.add_child(progress_signal)
	
	# Painel de Decodificação
	panel_decode = PanelContainer.new()
	panel_decode.custom_minimum_size = Vector2(0, 190)
	var sb_decode = StyleBoxFlat.new()
	sb_decode.bg_color = Color(0.05, 0.05, 0.08, 0.9)
	sb_decode.border_width_left = 2; sb_decode.border_width_top = 2
	sb_decode.border_width_right = 2; sb_decode.border_width_bottom = 2
	sb_decode.border_color = Color(0.3, 0.3, 0.4)
	sb_decode.corner_radius_top_left = 8; sb_decode.corner_radius_top_right = 8
	sb_decode.corner_radius_bottom_left = 8; sb_decode.corner_radius_bottom_right = 8
	panel_decode.add_theme_stylebox_override("panel", sb_decode)
	vbox.add_child(panel_decode)
	
	var margin_decode = MarginContainer.new()
	margin_decode.add_theme_constant_override("margin_top", 15)
	margin_decode.add_theme_constant_override("margin_bottom", 15)
	margin_decode.add_theme_constant_override("margin_left", 20)
	margin_decode.add_theme_constant_override("margin_right", 20)
	panel_decode.add_child(margin_decode)
	
	var vbox_decode = VBoxContainer.new()
	vbox_decode.add_theme_constant_override("separation", 10)
	margin_decode.add_child(vbox_decode)
	
	lbl_captured_title = Label.new()
	lbl_captured_title.text = "BUSCANDO TRANSMISSÕES..."
	lbl_captured_title.add_theme_font_override("font", FONTE)
	lbl_captured_title.add_theme_font_size_override("font_size", 20)
	lbl_captured_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	lbl_captured_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_decode.add_child(lbl_captured_title)
	
	# Texto capturado/original
	lbl_raw_text = Label.new()
	lbl_raw_text.text = "???"
	lbl_raw_text.add_theme_font_override("font", FONTE)
	lbl_raw_text.add_theme_font_size_override("font_size", 26)
	lbl_raw_text.add_theme_color_override("font_color", Color("#888899"))
	lbl_raw_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_decode.add_child(lbl_raw_text)
	
	# Controles de Cifra
	var hbox_cipher = HBoxContainer.new()
	hbox_cipher.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_cipher.add_theme_constant_override("separation", 20)
	vbox_decode.add_child(hbox_cipher)
	
	var btn_left = Button.new()
	btn_left.text = "  -  "
	btn_left.custom_minimum_size = Vector2(50, 40)
	btn_left.add_theme_font_override("font", FONTE)
	btn_left.add_theme_font_size_override("font_size", 22)
	btn_left.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	btn_left.pressed.connect(func(): _ajustar_shift(-1))
	hbox_cipher.add_child(btn_left)
	
	lbl_shift_value = Label.new()
	lbl_shift_value.text = "DESLOCAMENTO: 0"
	lbl_shift_value.add_theme_font_override("font", FONTE)
	lbl_shift_value.add_theme_font_size_override("font_size", 22)
	lbl_shift_value.add_theme_color_override("font_color", Color("#FF8C00"))
	hbox_cipher.add_child(lbl_shift_value)
	
	var btn_right = Button.new()
	btn_right.text = "  +  "
	btn_right.custom_minimum_size = Vector2(50, 40)
	btn_right.add_theme_font_override("font", FONTE)
	btn_right.add_theme_font_size_override("font_size", 22)
	btn_right.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	btn_right.pressed.connect(func(): _ajustar_shift(1))
	hbox_cipher.add_child(btn_right)
	
	# Botão Cifra Info para auxílio pedagógico
	var btn_cifra_info = Button.new()
	btn_cifra_info.text = " CIFRA INFO "
	btn_cifra_info.custom_minimum_size = Vector2(120, 40)
	btn_cifra_info.add_theme_font_override("font", FONTE)
	btn_cifra_info.add_theme_font_size_override("font_size", 18)
	btn_cifra_info.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	
	var sb_info = StyleBoxFlat.new()
	sb_info.bg_color = Color(0.05, 0.2, 0.45, 0.85)
	sb_info.border_width_left = 2; sb_info.border_width_top = 2
	sb_info.border_width_right = 2; sb_info.border_width_bottom = 2
	sb_info.border_color = Color("#00A2FF")
	sb_info.corner_radius_top_left = 6; sb_info.corner_radius_top_right = 6
	sb_info.corner_radius_bottom_left = 6; sb_info.corner_radius_bottom_right = 6
	
	var sb_info_h = sb_info.duplicate() as StyleBoxFlat
	sb_info_h.bg_color = Color(0.1, 0.3, 0.65, 0.95)
	sb_info_h.shadow_size = 8
	sb_info_h.shadow_color = Color("#00A2FF", 0.3)
	
	btn_cifra_info.add_theme_stylebox_override("normal", sb_info)
	btn_cifra_info.add_theme_stylebox_override("hover", sb_info_h)
	btn_cifra_info.add_theme_stylebox_override("pressed", sb_info_h)
	btn_cifra_info.pressed.connect(_on_cifra_info_pressed)
	hbox_cipher.add_child(btn_cifra_info)
	
	# Preview Decifrado
	lbl_preview_text = Label.new()
	lbl_preview_text.text = "---"
	lbl_preview_text.add_theme_font_override("font", FONTE)
	lbl_preview_text.add_theme_font_size_override("font_size", 28)
	lbl_preview_text.add_theme_color_override("font_color", Color("#555566"))
	lbl_preview_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_decode.add_child(lbl_preview_text)
	
	# Botão de Registrar Sinal Decifrado
	btn_save_signal = Button.new()
	btn_save_signal.text = "REGISTRAR SINAL DECODIFICADO"
	btn_save_signal.custom_minimum_size = Vector2(320, 50)
	btn_save_signal.size_flags_horizontal = SIZE_SHRINK_CENTER
	btn_save_signal.add_theme_font_override("font", FONTE)
	btn_save_signal.add_theme_font_size_override("font_size", 22)
	btn_save_signal.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	
	var sb_btn = StyleBoxFlat.new()
	sb_btn.bg_color = Color(0.0, 0.4, 0.1, 0.8)
	sb_btn.border_width_left = 2; sb_btn.border_width_top = 2
	sb_btn.border_width_right = 2; sb_btn.border_width_bottom = 2
	sb_btn.border_color = Color("#00FF66")
	sb_btn.corner_radius_top_left = 6; sb_btn.corner_radius_top_right = 6
	sb_btn.corner_radius_bottom_left = 6; sb_btn.corner_radius_bottom_right = 6
	btn_save_signal.add_theme_stylebox_override("normal", sb_btn)
	btn_save_signal.pressed.connect(_on_save_signal_pressed)
	vbox_decode.add_child(btn_save_signal)
	
	# Botão de Concluir Missão (Rodapé)
	btn_finish = Button.new()
	btn_finish.text = "CONCLUIR SINTONIZAÇÃO"
	btn_finish.custom_minimum_size = Vector2(400, 60)
	btn_finish.size_flags_horizontal = SIZE_SHRINK_CENTER
	btn_finish.add_theme_font_override("font", FONTE)
	btn_finish.add_theme_font_size_override("font_size", 24)
	btn_finish.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	
	var sb_finish = StyleBoxFlat.new()
	sb_finish.bg_color = Color(0.6, 0.3, 0.0, 0.9)
	sb_finish.border_width_left = 2; sb_finish.border_width_top = 2
	sb_finish.border_width_right = 2; sb_finish.border_width_bottom = 2
	sb_finish.border_color = Color("#FF8C00")
	sb_finish.corner_radius_top_left = 8; sb_finish.corner_radius_top_right = 8
	sb_finish.corner_radius_bottom_left = 8; sb_finish.corner_radius_bottom_right = 8
	
	var sb_finish_h = sb_finish.duplicate() as StyleBoxFlat
	sb_finish_h.bg_color = Color(0.9, 0.45, 0.0)
	sb_finish_h.shadow_size = 15
	sb_finish_h.shadow_color = Color("#FF8C00", 0.3)
	
	btn_finish.add_theme_stylebox_override("normal", sb_finish)
	btn_finish.add_theme_stylebox_override("hover", sb_finish_h)
	btn_finish.add_theme_stylebox_override("pressed", sb_finish_h)
	btn_finish.pressed.connect(_on_finish_pressed)
	btn_finish.visible = false
	vbox.add_child(btn_finish)

func _criar_lbl_status(txt: String, cor: Color) -> Label:
	var l = Label.new()
	l.text = txt + " [🔴]"
	l.add_theme_font_override("font", FONTE)
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", cor)
	return l

# ══════════════════════════════════════════════
#  LÓGICA DE PROCESSAMENTO E SINTONIA
# ══════════════════════════════════════════════

func _process(delta: float) -> void:
	wave_time += delta * 15.0
	oscilloscope.queue_redraw()

func _on_freq_changed(value: float) -> void:
	frequencia_atual = value
	lbl_freq_display.text = "FREQUÊNCIA: " + str(snapped(frequencia_atual, 0.1)) + " MHz"
	
	# Calcular força do sinal em relação às 3 frequências alvo
	var max_strength = 0.0
	var closest_idx = -1
	
	for i in range(TARGET_FREQS.size()):
		var dist = abs(frequencia_atual - TARGET_FREQS[i])
		# Sinal forte num raio de 0.8 MHz
		var strength = 1.0 - clamp(dist / 0.8, 0.0, 1.0)
		if strength > max_strength:
			max_strength = strength
			closest_idx = i
	
	# Se a força do sinal for menor que 10%, consideramos sem sinal
	if max_strength < 0.1:
		max_strength = 0.0
		closest_idx = -1
		
	signal_strength = max_strength
	progress_signal.value = signal_strength * 100.0
	
	# Atualiza o tema da barra com base no sinal
	var sb_fill = progress_signal.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
	if signal_strength > 0.8:
		sb_fill.bg_color = Color("#00FF66") # Verde: excelente
	elif signal_strength > 0.4:
		sb_fill.bg_color = Color("#FFAA00") # Amarelo/Laranja: razoável
	else:
		sb_fill.bg_color = Color("#FF3333") # Vermelho: fraco
	progress_signal.add_theme_stylebox_override("fill", sb_fill)
	
	# Atualiza estado de captura
	if signal_strength > 0.8:
		if captured_index != closest_idx:
			captured_index = closest_idx
			# Randomiza o shift inicial para forçar o jogador a decifrar (evita começar em 0 ou -3)
			shift_atual = [1, 2, 3, -1, -2, -4, -5, 4, 5].pick_random()
			_atualizar_ui_estado()
	else:
		if captured_index != -1:
			captured_index = -1
			_atualizar_ui_estado()

func _ajustar_shift(delta: int) -> void:
	if captured_index == -1 or decrypted_states[captured_index]: return
	
	shift_atual = clamp(shift_atual + delta, -13, 13)
	_atualizar_ui_estado()

func _atualizar_ui_estado() -> void:
	# Atualiza os labels superiores de status
	lbl_status_1.text = "Freq 1: 91.5 MHz " + ("[🟢 OK]" if decrypted_states[0] else "[🔴 DESCONHECIDO]")
	lbl_status_1.add_theme_color_override("font_color", Color("#00FF66") if decrypted_states[0] else Color("#FF4444"))
	
	lbl_status_2.text = "Freq 2: 98.3 MHz " + ("[🟢 OK]" if decrypted_states[1] else "[🔴 DESCONHECIDO]")
	lbl_status_2.add_theme_color_override("font_color", Color("#00FF66") if decrypted_states[1] else Color("#FF4444"))
	
	lbl_status_3.text = "Freq 3: 104.7 MHz " + ("[🟢 OK]" if decrypted_states[2] else "[🔴 DESCONHECIDO]")
	lbl_status_3.add_theme_color_override("font_color", Color("#00FF66") if decrypted_states[2] else Color("#FF4444"))
	
	# Verifica se todos foram decodificados para mostrar botão concluir
	var total_dec = 0
	for state in decrypted_states:
		if state: total_dec += 1
	
	if total_dec == 3:
		btn_finish.visible = true
	
	# Painel de Decodificação dinâmico
	if captured_index == -1:
		lbl_captured_title.text = "BUSCANDO TRANSMISSÕES..."
		lbl_captured_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		lbl_raw_text.text = "???"
		lbl_raw_text.add_theme_color_override("font_color", Color("#555566"))
		lbl_shift_value.text = "DESLOCAMENTO: --"
		lbl_preview_text.text = "---"
		lbl_preview_text.add_theme_color_override("font_color", Color("#555566"))
		btn_save_signal.visible = false
	else:
		var freq = TARGET_FREQS[captured_index]
		var is_decrypted = decrypted_states[captured_index]
		
		if is_decrypted:
			lbl_captured_title.text = "SINAL REGISTRADO E SALVO EM " + str(freq) + " MHz"
			lbl_captured_title.add_theme_color_override("font_color", Color("#00FF66"))
			lbl_raw_text.text = ENCRYPTED_MSGS[captured_index]
			lbl_raw_text.add_theme_color_override("font_color", Color("#88AA88"))
			lbl_shift_value.text = "DESLOCAMENTO: -3 (CORRETO)"
			lbl_preview_text.text = DECRYPTED_MSGS[captured_index]
			lbl_preview_text.add_theme_color_override("font_color", Color("#00FF66"))
			btn_save_signal.visible = false
		else:
			lbl_captured_title.text = "SINAL FORTE DETECTADO EM " + str(freq) + " MHz!"
			lbl_captured_title.add_theme_color_override("font_color", Color("#FFAA00"))
			lbl_raw_text.text = ENCRYPTED_MSGS[captured_index]
			lbl_raw_text.add_theme_color_override("font_color", Color.WHITE)
			lbl_shift_value.text = "DESLOCAMENTO: " + ("+" if shift_atual > 0 else "") + str(shift_atual)
			
			# Calcula e exibe decodificação em tempo real
			var raw_msg = ENCRYPTED_MSGS[captured_index]
			var preview = _decodificar_cifra(raw_msg, shift_atual)
			lbl_preview_text.text = preview
			
			# Se o shift for -3, a decodificação está correta
			if shift_atual == -3:
				lbl_preview_text.add_theme_color_override("font_color", Color("#00FF66")) # Verde
				btn_save_signal.visible = true
				btn_save_signal.text = "REGISTRAR SINAL DECODIFICADO"
			else:
				lbl_preview_text.add_theme_color_override("font_color", Color("#FF5555")) # Vermelho / Errado
				btn_save_signal.visible = false

# ══════════════════════════════════════════════
#  CÁLCULO DA CIFRA DE CÉSAR
# ══════════════════════════════════════════════

func _decodificar_cifra(texto_cifrado: String, shift: int) -> String:
	var resultado = ""
	for i in range(texto_cifrado.length()):
		var c = texto_cifrado[i]
		var code = c.unicode_at(0)
		
		if code >= 65 and code <= 90: # A-Z (Maiúsculas)
			var new_code = code + shift
			while new_code < 65:
				new_code += 26
			while new_code > 90:
				new_code -= 26
			resultado += String.chr(new_code)
		elif code >= 97 and code <= 122: # a-z (Minúsculas)
			var new_code = code + shift
			while new_code < 97:
				new_code += 26
			while new_code > 122:
				new_code -= 26
			resultado += String.chr(new_code)
		else:
			resultado += c # Espaços, números e pontuações permanecem inalterados
	return resultado

# ══════════════════════════════════════════════
#  AÇÃO DOS BOTÕES
# ══════════════════════════════════════════════

func _on_cifra_info_pressed() -> void:
	# Cria o pop-up explicativo da Cifra de César
	var popup_bg = ColorRect.new()
	popup_bg.color = Color(0, 0, 0, 0.75)
	popup_bg.set_anchors_preset(PRESET_FULL_RECT)
	layer.add_child(popup_bg)
	
	var popup_panel = PanelContainer.new()
	popup_panel.custom_minimum_size = Vector2(620, 430)
	popup_panel.set_anchors_preset(PRESET_CENTER)
	popup_panel.grow_horizontal = GROW_DIRECTION_BOTH
	popup_panel.grow_vertical = GROW_DIRECTION_BOTH
	
	var sb_popup = StyleBoxFlat.new()
	sb_popup.bg_color = Color(0.05, 0.08, 0.14, 0.98)
	sb_popup.border_width_left = 3; sb_popup.border_width_top = 3
	sb_popup.border_width_right = 3; sb_popup.border_width_bottom = 3
	sb_popup.border_color = Color("#00A2FF")
	sb_popup.corner_radius_top_left = 12
	sb_popup.corner_radius_top_right = 12
	sb_popup.corner_radius_bottom_left = 12
	sb_popup.corner_radius_bottom_right = 12
	sb_popup.shadow_size = 25
	sb_popup.shadow_color = Color("#00A2FF", 0.2)
	popup_panel.add_theme_stylebox_override("panel", sb_popup)
	popup_bg.add_child(popup_panel)
	
	var popup_margin = MarginContainer.new()
	popup_margin.add_theme_constant_override("margin_top", 25)
	popup_margin.add_theme_constant_override("margin_bottom", 25)
	popup_margin.add_theme_constant_override("margin_left", 30)
	popup_margin.add_theme_constant_override("margin_right", 30)
	popup_panel.add_child(popup_margin)
	
	var popup_vbox = VBoxContainer.new()
	popup_vbox.add_theme_constant_override("separation", 18)
	popup_margin.add_child(popup_vbox)
	
	var popup_title = Label.new()
	popup_title.text = "MANUAL TÉCNICO: CIFRA DE CÉSAR"
	popup_title.add_theme_font_override("font", FONTE)
	popup_title.add_theme_font_size_override("font_size", 28)
	popup_title.add_theme_color_override("font_color", Color("#00A2FF"))
	popup_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_vbox.add_child(popup_title)
	
	var popup_desc = RichTextLabel.new()
	popup_desc.custom_minimum_size = Vector2(0, 240)
	popup_desc.bbcode_enabled = true
	popup_desc.text = "[color=#CCCCCC]A [color=#00A2FF][b]Cifra de César[/b][/color] é uma técnica clássica de criptografia por substituição.\n\nCada letra do texto original é [b]substituída[/b] por outra que está um número fixo de posições atrás ou à frente no alfabeto.\n\n[color=#FFAA00]Funcionamento prático com recuo de 3 posições (Deslocamento: -3):[/color]\n• Letra [b]D[/b] recua 3 posições e vira [b]A[/b]\n• Letra [b]E[/b] recua 3 posições e vira [b]B[/b]\n• Letra [b]F[/b] recua 3 posições e vira [b]C[/b]\n\n[color=#00FF66][b]DIRETRIZ DE DESCRIPTOGRAFIA:[/b]\ninterceptações mostram que as mensagens militares estão cifradas com [b]DESLOCAMENTO: -3[/b]. Ajuste os botões '-' e '+' até obter esse valor para que a mensagem de resistência apareça limpa e legível![/color][/color]"
	popup_desc.add_theme_font_override("normal_font", FONTE)
	popup_desc.add_theme_font_size_override("normal_font_size", 18)
	popup_vbox.add_child(popup_desc)
	
	var popup_close = Button.new()
	popup_close.text = "ENTENDIDO"
	popup_close.custom_minimum_size = Vector2(160, 45)
	popup_close.size_flags_horizontal = SIZE_SHRINK_CENTER
	popup_close.add_theme_font_override("font", FONTE)
	popup_close.add_theme_font_size_override("font_size", 20)
	popup_close.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	
	var sb_close = StyleBoxFlat.new()
	sb_close.bg_color = Color(0.0, 0.4, 0.7, 0.95)
	sb_close.corner_radius_top_left = 6
	sb_close.corner_radius_top_right = 6
	sb_close.corner_radius_bottom_left = 6
	sb_close.corner_radius_bottom_right = 6
	popup_close.add_theme_stylebox_override("normal", sb_close)
	
	popup_close.pressed.connect(func():
		popup_bg.queue_free()
	)
	popup_vbox.add_child(popup_close)

func _on_save_signal_pressed() -> void:
	if dialogo_descoberta_em_execucao or captured_index == -1 or shift_atual != -3: return
	
	var descoberta_idx := captured_index
	dialogo_descoberta_em_execucao = true
	_set_interacao_minigame(false)
	decrypted_states[descoberta_idx] = true
	GameState.confianca += 2 # Recompensa por decodificar cada sinal
	GameState.registrar_escolha("Decodificou canal em " + str(TARGET_FREQS[descoberta_idx]) + " MHz", +2)
	
	# Efeito visual de confirmação (breve piscar verde no painel de decodificação)
	var tween = create_tween()
	var original_mod = panel_decode.modulate
	tween.tween_property(panel_decode, "modulate", Color(0, 2.0, 0.5, 1.0), 0.1)
	tween.tween_property(panel_decode, "modulate", original_mod, 0.3)
	
	_atualizar_ui_estado()
	await tween.finished
	await _tocar_timeline_descoberta(descoberta_idx)

func _tocar_timeline_descoberta(descoberta_idx: int) -> void:
	if descoberta_idx < 0 or descoberta_idx >= DISCOVERY_TIMELINES.size():
		_set_interacao_minigame(true)
		dialogo_descoberta_em_execucao = false
		return
	
	dialogo_descoberta_em_execucao = true
	_set_interacao_minigame(false)
	await TimelineManager.tocar_dialogo(DISCOVERY_TIMELINES[descoberta_idx], false)
	
	if descoberta_idx == DISCOVERY_TIMELINES.size() - 1:
		GameState.fase_atual = 3
		GameState.fase3_passo = "inicio"
		GameState.fase2_passo = "radio_concluida"
		GameState.salvar_jogo(false)
	
	_set_interacao_minigame(true)
	dialogo_descoberta_em_execucao = false
	_atualizar_ui_estado()

func _set_interacao_minigame(habilitada: bool) -> void:
	slider_tuner.editable = habilitada
	btn_save_signal.disabled = not habilitada
	btn_finish.disabled = not habilitada

func _on_finish_pressed() -> void:
	if finalizado: return
	finalizado = true
	
	# Reabilita visualizador de confiança principal
	if get_tree().root.has_node("MedidorConfianca"):
		get_tree().root.get_node("MedidorConfianca").visible = true
		
	GameState.fase_atual = 3
	GameState.fase3_passo = "inicio"
	GameState.fase2_passo = "radio_concluida"
	await GameState.retornar_para_game_scene_apos_minigame()

# ══════════════════════════════════════════════
#  DESENHO DO OSCILOSCÓPIO CRT (RETRO WAVE)
# ══════════════════════════════════════════════

func _on_oscilloscope_draw() -> void:
	var size_rect = oscilloscope.size
	
	# 1. Desenha a grade (grid) verde estilo terminal antigo
	var grid_color = Color(0.0, 0.3, 0.1, 0.25)
	var step = 20
	for x in range(0, int(size_rect.x), step):
		oscilloscope.draw_line(Vector2(x, 0), Vector2(x, size_rect.y), grid_color, 1.0)
	for y in range(0, int(size_rect.y), step):
		oscilloscope.draw_line(Vector2(0, y), Vector2(size_rect.x, y), grid_color, 1.0)
		
	# 2. Desenha a linha central guia
	oscilloscope.draw_line(Vector2(0, size_rect.y / 2.0), Vector2(size_rect.x, size_rect.y / 2.0), Color(0.0, 0.4, 0.1, 0.4), 1.5)
	
	# 3. Calcula e plota a onda (senoidal morphing para estática)
	var points = PackedVector2Array()
	var num_points = 120
	var amp = size_rect.y * 0.32
	var center_y = size_rect.y / 2.0
	
	# Quanto mais próximo da frequência correta, menor o ruído (noise_factor)
	var noise_factor = 1.0 - signal_strength
	
	for i in range(num_points):
		var t = float(i) / (num_points - 1)
		var x = t * size_rect.x
		
		# Onda senoidal limpa
		var freq_mult = 12.0
		if captured_index != -1:
			freq_mult = 8.0 + captured_index * 6.0
		var clean_y = sin(t * freq_mult - wave_time) * amp
		
		# Onda de estática aleatória (ruído)
		var noise_y = randf_range(-amp * 1.3, amp * 1.3)
		
		# Mescla dinâmica
		var final_y = center_y + lerp(clean_y, noise_y, noise_factor)
		points.append(Vector2(x, final_y))
		
	# 4. Desenha a linha da onda em verde fluorescente CRT com sombra brilhosa
	var wave_color = Color(0.0, 1.0, 0.4, 0.9)
	var glow_color = Color(0.0, 1.0, 0.4, 0.25)
	
	# Desenha efeito de brilho (glow) com espessura maior por baixo
	for i in range(points.size() - 1):
		oscilloscope.draw_line(points[i], points[i+1], glow_color, 5.0)
		
	# Desenha a linha principal fina por cima
	for i in range(points.size() - 1):
		oscilloscope.draw_line(points[i], points[i+1], wave_color, 2.0)
		
	# 5. Adiciona scanlines analógicas por cima do osciloscópio (Efeito CRT Analógico)
	var scanline_color = Color(0.0, 0.04, 0.01, 0.3)
	for y in range(0, int(size_rect.y), 4):
		oscilloscope.draw_line(Vector2(0, y), Vector2(size_rect.x, y), scanline_color, 1.5)
