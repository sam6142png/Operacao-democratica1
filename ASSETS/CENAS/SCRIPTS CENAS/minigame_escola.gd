extends Control

# === RECURSOS ===
const FONTE = preload("res://ASSETS/FONTES/determination.ttf")
const FONTE_MONO = preload("res://ASSETS/FONTES/dogicapixel.ttf")
const BG_TEX = preload("res://ASSETS/SPRITES/FUNDOS/Sala de Aula.png")
const AUDIO_VOZ = preload("res://ASSETS/SOUNDS/Fala minigame escola.mp3")
const CLICK_SOUND = preload("res://ASSETS/SOUNDS/FSX/BotoesClick.mp3")
const HOVER_SOUND = preload("res://ASSETS/SOUNDS/FSX/BotoesHover.mp3")

const ALARME_MAX: int = 5
const FREQ_ALVO: float = 98.7
const FREQ_TOLERANCIA: float = 0.25

enum Etapa { FIOS, DISJUNTORES, SINTONIA }

var etapa_atual: int = Etapa.FIOS
var alarme: int = 0
var finalizado: bool = false
var dialogo_em_execucao: bool = false
var medidor_visivel_antes: bool = true

var fios: Array[Dictionary] = [
	{"id": "vermelho", "nome": "ENERGIA", "cor": Color("#ff4b4b")},
	{"id": "azul", "nome": "SINAL", "cor": Color("#00a2ff")},
	{"id": "verde", "nome": "TERRA", "cor": Color("#62ff86")},
	{"id": "amarelo", "nome": "AUDIO", "cor": Color("#ffdf7d")}
]
var fio_selecionado: String = ""
var fios_conectados: Dictionary = {}

var ordem_disjuntores: Array[String] = ["luzes", "salas", "patio", "amplificador"]
var disjuntores_ligados: Array[String] = []

var frequencia_atual: float = 95.0
var estabilidade: float = 0.0
var segurando_trava: bool = false
var wave_time: float = 0.0

var layer: CanvasLayer
var root: VBoxContainer
var stage_panel: PanelContainer
var stage_box: VBoxContainer
var lbl_titulo: Label
var lbl_subtitulo: Label
var lbl_alarme: Label
var progress_etapa: ProgressBar
var progress_alarme: ProgressBar
var sfx_click: AudioStreamPlayer
var sfx_hover: AudioStreamPlayer
var oscilloscope: Control
var slider_freq: HSlider
var lbl_freq: Label
var lbl_signal: Label
var progress_estabilidade: ProgressBar
var btn_travar: Button

func _ready() -> void:
	randomize()
	_configurar_medidor(false)
	_configurar_audio()
	_montar_base()
	_mostrar_intro()


func _process(delta: float) -> void:
	if finalizado or dialogo_em_execucao:
		return

	if etapa_atual == Etapa.SINTONIA:
		wave_time += delta * 14.0
		if oscilloscope:
			oscilloscope.queue_redraw()
		_atualizar_sintonia(delta)


func _configurar_medidor(visivel: bool) -> void:
	if get_tree().root.has_node("MedidorConfianca"):
		var medidor = get_tree().root.get_node("MedidorConfianca")
		medidor_visivel_antes = medidor.visible
		medidor.visible = visivel


func _configurar_audio() -> void:
	sfx_click = AudioStreamPlayer.new()
	sfx_click.stream = CLICK_SOUND
	sfx_click.bus = "SFX"
	add_child(sfx_click)

	sfx_hover = AudioStreamPlayer.new()
	sfx_hover.stream = HOVER_SOUND
	sfx_hover.bus = "SFX"
	add_child(sfx_hover)


func _montar_base() -> void:
	layer = CanvasLayer.new()
	layer.layer = 10
	add_child(layer)

	var bg := TextureRect.new()
	bg.texture = BG_TEX
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.modulate = Color(0.08, 0.09, 0.12)
	layer.add_child(bg)

	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.58)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(shade)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	margin.add_theme_constant_override("margin_left", 70)
	margin.add_theme_constant_override("margin_right", 70)
	layer.add_child(margin)

	root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	margin.add_child(root)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 30)
	root.add_child(top)

	var title_box := VBoxContainer.new()
	lbl_titulo = _label("CAIXA DE SOM DA ESCOLA", 38, Color("#ff9f2f"), FONTE)
	lbl_subtitulo = _label("Reconecte os fios, arme os disjuntores e sintonize a Radio Livre", 13, Color("#9fb3c8"), FONTE_MONO)
	title_box.add_child(lbl_titulo)
	title_box.add_child(lbl_subtitulo)
	top.add_child(title_box)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)

	var etapa_box := VBoxContainer.new()
	etapa_box.custom_minimum_size = Vector2(260, 0)
	etapa_box.add_child(_label("PROGRESSO DA INVASAO", 11, Color("#62ff86"), FONTE_MONO, HORIZONTAL_ALIGNMENT_CENTER))
	progress_etapa = ProgressBar.new()
	progress_etapa.min_value = 0.0
	progress_etapa.max_value = 3.0
	progress_etapa.show_percentage = false
	progress_etapa.custom_minimum_size = Vector2(0, 16)
	progress_etapa.add_theme_stylebox_override("background", _stylebox(Color("#071108"), Color.TRANSPARENT, 0, 4))
	progress_etapa.add_theme_stylebox_override("fill", _stylebox(Color("#2eec73"), Color.TRANSPARENT, 0, 4))
	etapa_box.add_child(progress_etapa)
	top.add_child(etapa_box)

	var alarm_box := VBoxContainer.new()
	alarm_box.custom_minimum_size = Vector2(260, 0)
	lbl_alarme = _label("ALARME: 0/" + str(ALARME_MAX), 11, Color("#ff4b4b"), FONTE_MONO, HORIZONTAL_ALIGNMENT_CENTER)
	alarm_box.add_child(lbl_alarme)
	progress_alarme = ProgressBar.new()
	progress_alarme.min_value = 0.0
	progress_alarme.max_value = float(ALARME_MAX)
	progress_alarme.show_percentage = false
	progress_alarme.custom_minimum_size = Vector2(0, 16)
	progress_alarme.add_theme_stylebox_override("background", _stylebox(Color("#170707"), Color.TRANSPARENT, 0, 4))
	progress_alarme.add_theme_stylebox_override("fill", _stylebox(Color("#d63030"), Color.TRANSPARENT, 0, 4))
	alarm_box.add_child(progress_alarme)
	top.add_child(alarm_box)

	stage_panel = PanelContainer.new()
	stage_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage_panel.add_theme_stylebox_override("panel", _stylebox(Color("#050b12", 0.95), Color("#00a2ff", 0.55), 2, 8, 18, Color("#00a2ff", 0.08)))
	root.add_child(stage_panel)

	var stage_margin := MarginContainer.new()
	stage_margin.add_theme_constant_override("margin_top", 28)
	stage_margin.add_theme_constant_override("margin_bottom", 28)
	stage_margin.add_theme_constant_override("margin_left", 34)
	stage_margin.add_theme_constant_override("margin_right", 34)
	stage_panel.add_child(stage_margin)

	stage_box = VBoxContainer.new()
	stage_box.add_theme_constant_override("separation", 20)
	stage_margin.add_child(stage_box)


func _mostrar_intro() -> void:
	_tocar_dialogic_e_continuar("fase3_escola_minigame_inicio", Callable(self, "_iniciar_fios"))


func _iniciar_fios() -> void:
	etapa_atual = Etapa.FIOS
	fio_selecionado = ""
	fios_conectados.clear()
	progress_etapa.value = 0.0
	_limpar_stage()

	stage_box.add_child(_label("1. LIGAR OS FIOS SOLTOS", 34, Color("#ffb86c"), FONTE, HORIZONTAL_ALIGNMENT_CENTER))
	var instrucao := _label("Clique em um fio solto e depois no terminal com a mesma funcao. Errou a ligacao, o alarme sobe.", 17, Color("#cfe5ff"), FONTE_MONO, HORIZONTAL_ALIGNMENT_CENTER)
	instrucao.autowrap_mode = TextServer.AUTOWRAP_WORD
	stage_box.add_child(instrucao)

	var board := HBoxContainer.new()
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.add_theme_constant_override("separation", 42)
	stage_box.add_child(board)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 16)
	left.add_child(_label("FIOS SOLTOS", 22, Color("#ffdf7d"), FONTE, HORIZONTAL_ALIGNMENT_CENTER))
	board.add_child(left)

	var shuffled_fios: Array = fios.duplicate()
	shuffled_fios.shuffle()
	for fio in shuffled_fios:
		var fio_data: Dictionary = fio
		var fio_cor: Color = fio_data["cor"]
		var btn := _button(String(fio_data["nome"]), 320, Color("#111923"), fio_cor)
		btn.pressed.connect(_selecionar_fio.bind(String(fio_data["id"]), btn))
		left.add_child(btn)

	var center := PanelContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_theme_stylebox_override("panel", _stylebox(Color("#07131d"), Color("#00a2ff", 0.45), 2, 6))
	board.add_child(center)
	var center_box := VBoxContainer.new()
	center_box.alignment = BoxContainer.ALIGNMENT_CENTER
	center_box.add_theme_constant_override("separation", 10)
	center.add_child(center_box)
	center_box.add_child(_label("PAINEL DE JUNCAO", 24, Color("#00a2ff"), FONTE, HORIZONTAL_ALIGNMENT_CENTER))
	center_box.add_child(_label("A energia precisa de caminho seguro antes da radio entrar.", 18, Color("#dbeaff"), FONTE, HORIZONTAL_ALIGNMENT_CENTER))
	center_box.add_child(_label("Ensinamento: comunicacao livre precisa de infraestrutura; sem acesso ao meio, a voz e silenciada.", 15, Color("#9fb3c8"), FONTE_MONO, HORIZONTAL_ALIGNMENT_CENTER))

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 16)
	right.add_child(_label("TERMINAIS", 22, Color("#62ff86"), FONTE, HORIZONTAL_ALIGNMENT_CENTER))
	board.add_child(right)

	var shuffled_terms: Array = fios.duplicate()
	shuffled_terms.shuffle()
	for fio in shuffled_terms:
		var term_data: Dictionary = fio
		var term_cor: Color = term_data["cor"]
		var btn := _button("TERMINAL " + String(term_data["nome"]), 360, Color("#0d1c12"), term_cor)
		btn.pressed.connect(_conectar_terminal.bind(String(term_data["id"]), btn))
		right.add_child(btn)


func _selecionar_fio(id: String, btn: Button) -> void:
	if id in fios_conectados:
		return
	_play_click()
	fio_selecionado = id
	btn.modulate = Color(1.35, 1.35, 1.35)


func _conectar_terminal(id: String, btn: Button) -> void:
	if fio_selecionado == "":
		_punir("Escolha um fio antes de tentar encaixar no terminal.")
		return

	if fio_selecionado == id:
		_play_click()
		fios_conectados[id] = true
		btn.text = "CONECTADO"
		btn.disabled = true
		btn.modulate = Color("#62ff86")
		fio_selecionado = ""
		if fios_conectados.size() == fios.size():
			progress_etapa.value = 1.0
			_tocar_dialogic_e_continuar("fase3_escola_minigame_fios_ok", Callable(self, "_iniciar_disjuntores"))
	else:
		fio_selecionado = ""
		_punir("Ligacao errada. O painel chiou e a patrulha ouviu ruido na linha.")


func _iniciar_disjuntores() -> void:
	etapa_atual = Etapa.DISJUNTORES
	disjuntores_ligados.clear()
	_limpar_stage()

	stage_box.add_child(_label("2. ARMAR OS DISJUNTORES", 34, Color("#ffb86c"), FONTE, HORIZONTAL_ALIGNMENT_CENTER))
	var instrucao := _label("Ligue na ordem de carga: LUZES, SALAS, PATIO, AMPLIFICADOR. Se ligar o amplificador cedo demais, sobrecarrega.", 17, Color("#cfe5ff"), FONTE_MONO, HORIZONTAL_ALIGNMENT_CENTER)
	instrucao.autowrap_mode = TextServer.AUTOWRAP_WORD
	stage_box.add_child(instrucao)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 22)
	grid.add_theme_constant_override("v_separation", 22)
	stage_box.add_child(grid)

	var labels: Dictionary = {
		"luzes": "LUZES",
		"salas": "SALAS",
		"patio": "PATIO",
		"amplificador": "AMPLIFICADOR"
	}
	var ids: Array[String] = ["amplificador", "patio", "luzes", "salas"]
	for id in ids:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(250, 300)
		card.add_theme_stylebox_override("panel", _stylebox(Color("#111923"), Color("#334155"), 2, 8))
		grid.add_child(card)

		var box := VBoxContainer.new()
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_theme_constant_override("separation", 18)
		card.add_child(box)
		box.add_child(_label(String(labels[id]), 25, Color("#f8fbff"), FONTE, HORIZONTAL_ALIGNMENT_CENTER))
		box.add_child(_label("OFF", 42, Color("#ff4b4b"), FONTE, HORIZONTAL_ALIGNMENT_CENTER))
		var btn := _button("LIGAR", 170, Color("#1a2735"), Color("#ffdf7d"))
		btn.pressed.connect(_acionar_disjuntor.bind(id, card, btn))
		box.add_child(btn)

	stage_box.add_child(_label("Ensinamento: liberdade tambem exige cuidado coletivo. Potencia sem ordem vira apagao.", 16, Color("#9fb3c8"), FONTE_MONO, HORIZONTAL_ALIGNMENT_CENTER))


func _acionar_disjuntor(id: String, card: PanelContainer, btn: Button) -> void:
	if id in disjuntores_ligados:
		return

	var esperado: String = ordem_disjuntores[disjuntores_ligados.size()]
	if id != esperado:
		_punir("Sobrecarga. Esse disjuntor precisava esperar os circuitos menores estabilizarem.")
		return

	_play_click()
	disjuntores_ligados.append(id)
	btn.text = "ON"
	btn.disabled = true
	card.add_theme_stylebox_override("panel", _stylebox(Color("#08190f"), Color("#62ff86"), 2, 8, 10, Color("#62ff86", 0.2)))
	progress_etapa.value = 1.0 + float(disjuntores_ligados.size()) / float(ordem_disjuntores.size())

	if disjuntores_ligados.size() == ordem_disjuntores.size():
		progress_etapa.value = 2.0
		_tocar_dialogic_e_continuar("fase3_escola_minigame_disjuntores_ok", Callable(self, "_iniciar_sintonia"))


func _iniciar_sintonia() -> void:
	etapa_atual = Etapa.SINTONIA
	frequencia_atual = 95.0
	estabilidade = 0.0
	segurando_trava = false
	_limpar_stage()

	stage_box.add_child(_label("3. SINTONIZAR A RADIO LIVRE", 34, Color("#ffb86c"), FONTE, HORIZONTAL_ALIGNMENT_CENTER))
	var instrucao := _label("Ajuste a frequencia para 98.7 MHz. Quando o sinal ficar forte, segure TRAVAR SINAL para preencher a estabilidade.", 17, Color("#cfe5ff"), FONTE_MONO, HORIZONTAL_ALIGNMENT_CENTER)
	instrucao.autowrap_mode = TextServer.AUTOWRAP_WORD
	stage_box.add_child(instrucao)

	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _stylebox(Color("#06130c"), Color("#62ff86", 0.8), 2, 8))
	stage_box.add_child(panel)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_top", 22)
	m.add_theme_constant_override("margin_bottom", 22)
	m.add_theme_constant_override("margin_left", 28)
	m.add_theme_constant_override("margin_right", 28)
	panel.add_child(m)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	m.add_child(box)

	oscilloscope = Control.new()
	oscilloscope.custom_minimum_size = Vector2(0, 190)
	oscilloscope.draw.connect(_on_oscilloscope_draw)
	box.add_child(oscilloscope)

	lbl_freq = _label("FREQUENCIA: 95.0 MHz", 30, Color("#f8fbff"), FONTE, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(lbl_freq)

	slider_freq = HSlider.new()
	slider_freq.min_value = 88.0
	slider_freq.max_value = 108.0
	slider_freq.step = 0.1
	slider_freq.value = frequencia_atual
	slider_freq.custom_minimum_size = Vector2(760, 36)
	slider_freq.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	slider_freq.value_changed.connect(_on_freq_changed)
	box.add_child(slider_freq)

	lbl_signal = _label("SINAL: 0%", 22, Color("#ff4b4b"), FONTE, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(lbl_signal)

	progress_estabilidade = ProgressBar.new()
	progress_estabilidade.min_value = 0.0
	progress_estabilidade.max_value = 100.0
	progress_estabilidade.value = 0.0
	progress_estabilidade.custom_minimum_size = Vector2(760, 18)
	progress_estabilidade.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	progress_estabilidade.show_percentage = false
	progress_estabilidade.add_theme_stylebox_override("background", _stylebox(Color("#071108"), Color.TRANSPARENT, 0, 4))
	progress_estabilidade.add_theme_stylebox_override("fill", _stylebox(Color("#2eec73"), Color.TRANSPARENT, 0, 4))
	box.add_child(progress_estabilidade)

	btn_travar = _button("TRAVAR SINAL", 320, Color("#18351f"), Color("#62ff86"))
	btn_travar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_travar.button_down.connect(func(): segurando_trava = true)
	btn_travar.button_up.connect(func(): segurando_trava = false)
	box.add_child(btn_travar)

	box.add_child(_label("Ensinamento: quando a comunicacao e livre, a escola escuta mais de uma versao e pode questionar o poder.", 16, Color("#9fb3c8"), FONTE_MONO, HORIZONTAL_ALIGNMENT_CENTER))
	_atualizar_sintonia(0.0)


func _on_freq_changed(value: float) -> void:
	frequencia_atual = value
	_atualizar_sintonia(0.0)


func _atualizar_sintonia(delta: float) -> void:
	if not lbl_freq:
		return

	var dist: float = abs(frequencia_atual - FREQ_ALVO)
	var forca_sinal: float = clamp(1.0 - dist / 2.2, 0.0, 1.0)
	lbl_freq.text = "FREQUENCIA: %.1f MHz" % frequencia_atual
	lbl_signal.text = "SINAL: " + str(int(forca_sinal * 100.0)) + "%"
	lbl_signal.add_theme_color_override("font_color", Color("#62ff86") if forca_sinal > 0.88 else Color("#ffdf7d") if forca_sinal > 0.55 else Color("#ff4b4b"))

	if segurando_trava:
		if dist <= FREQ_TOLERANCIA:
			estabilidade = min(100.0, estabilidade + delta * 34.0)
		else:
			estabilidade = max(0.0, estabilidade - delta * 26.0)
			if delta > 0.0:
				alarme = min(ALARME_MAX, alarme + 1)
				_atualizar_alarme()
				segurando_trava = false
				if alarme >= ALARME_MAX:
					_derrota("A frequencia errada abriu o canal oficial e a patrulha rastreou a escola.")
					return
	else:
		estabilidade = max(0.0, estabilidade - delta * 5.0)

	if progress_estabilidade:
		progress_estabilidade.value = estabilidade

	if estabilidade >= 100.0:
		progress_etapa.value = 3.0
		_tocar_dialogic_e_continuar("fase3_escola_minigame_sintonia_ok", Callable(self, "_vitoria"))


func _on_oscilloscope_draw() -> void:
	if not oscilloscope:
		return

	var size_rect: Vector2 = oscilloscope.size
	var grid_color := Color(0.0, 0.3, 0.1, 0.25)
	for x in range(0, int(size_rect.x), 24):
		oscilloscope.draw_line(Vector2(x, 0), Vector2(x, size_rect.y), grid_color, 1.0)
	for y in range(0, int(size_rect.y), 24):
		oscilloscope.draw_line(Vector2(0, y), Vector2(size_rect.x, y), grid_color, 1.0)

	var dist: float = abs(frequencia_atual - FREQ_ALVO)
	var forca_sinal: float = clamp(1.0 - dist / 2.2, 0.0, 1.0)
	var points := PackedVector2Array()
	var num_points: int = 140
	var amp: float = size_rect.y * 0.32
	var center_y: float = size_rect.y * 0.5
	for i in range(num_points):
		var t: float = float(i) / float(num_points - 1)
		var x_pos: float = t * size_rect.x
		var clean_y: float = sin(t * 34.0 - wave_time) * amp
		var noise_y: float = randf_range(-amp * 1.2, amp * 1.2)
		points.append(Vector2(x_pos, center_y + lerp(noise_y, clean_y, forca_sinal)))

	for i in range(points.size() - 1):
		oscilloscope.draw_line(points[i], points[i + 1], Color(0.0, 1.0, 0.4, 0.25), 5.0)
	for i in range(points.size() - 1):
		oscilloscope.draw_line(points[i], points[i + 1], Color(0.0, 1.0, 0.4, 0.9), 2.0)


func _punir(msg: String) -> void:
	_play_click()
	alarme = min(ALARME_MAX, alarme + 1)
	_atualizar_alarme()
	_mostrar_alerta(msg)
	if alarme >= ALARME_MAX:
		_derrota("A patrulha chegou antes da Radio Livre entrar no sistema.")


func _atualizar_alarme() -> void:
	lbl_alarme.text = "ALARME: " + str(alarme) + "/" + str(ALARME_MAX)
	progress_alarme.value = alarme


func _mostrar_alerta(msg: String) -> void:
	var alert := Label.new()
	alert.text = msg
	alert.add_theme_font_override("font", FONTE)
	alert.add_theme_font_size_override("font_size", 22)
	alert.add_theme_color_override("font_color", Color("#ff4b4b"))
	alert.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_box.add_child(alert)
	var tw := create_tween()
	tw.tween_property(alert, "modulate:a", 0.0, 1.2)
	tw.finished.connect(func(): alert.queue_free())


func _tocar_dialogic_e_continuar(timeline: String, ao_final: Callable) -> void:
	dialogo_em_execucao = true
	await TimelineManager.tocar_dialogo(timeline, false)
	dialogo_em_execucao = false
	if ao_final.is_valid():
		ao_final.call()


func _vitoria() -> void:
	if finalizado:
		return
	finalizado = true
	_configurar_medidor(false)

	var overlay := ColorRect.new()
	overlay.color = Color(0.02, 0.08, 0.04, 0.92)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(overlay)

	var player := AudioStreamPlayer.new()
	player.stream = AUDIO_VOZ
	player.bus = "SFX"
	add_child(player)
	player.play()
	await player.finished

	await GameState.mostrar_registro_democratico({
		"fase": "Fase 3 - Escola",
		"conceito": "Liberdade de expressao, infraestrutura publica e comunicacao livre",
		"evidencia": "O jogador reconectou fios, armou disjuntores e sintonizou a Radio Livre nos alto-falantes.",
		"impacto": "A escola deixou de receber apenas a voz oficial e passou a ouvir uma transmissao independente.",
		"reflexao": "Democracia tambem depende de acesso aos meios de comunicacao: sem canal livre, nao ha debate publico real."
	})

	_configurar_medidor(medidor_visivel_antes)
	GameState.fase3_passo = "escola_concluida"
	await GameState.retornar_para_game_scene_apos_minigame()


func _derrota(motivo: String) -> void:
	if finalizado:
		return
	finalizado = true
	_configurar_medidor(false)

	push_warning("[Minigame Escola] Derrota: " + motivo)
	_tocar_dialogic_e_continuar("fase3_escola_minigame_derrota", Callable(self, "_reiniciar"))


func _reiniciar() -> void:
	_configurar_medidor(medidor_visivel_antes)
	FadeManager.carregar_cena("res://ASSETS/CENAS/minigame_escola.tscn")


func _limpar_stage() -> void:
	for child in stage_box.get_children():
		child.queue_free()


func _play_click() -> void:
	if sfx_click:
		sfx_click.play()


func _play_hover() -> void:
	if sfx_hover:
		sfx_hover.play()


func _button(txt: String, width: int, bg: Color, border: Color) -> Button:
	var btn := Button.new()
	btn.text = txt
	btn.custom_minimum_size = Vector2(width, 54)
	btn.add_theme_font_override("font", FONTE)
	btn.add_theme_font_size_override("font_size", 21)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_stylebox_override("normal", _stylebox(bg, border, 2, 6))
	btn.add_theme_stylebox_override("hover", _stylebox(bg.lightened(0.16), border, 2, 6, 8, Color(border.r, border.g, border.b, 0.28)))
	btn.add_theme_stylebox_override("pressed", _stylebox(bg.darkened(0.1), border, 2, 6))
	btn.mouse_entered.connect(_play_hover)
	return btn


func _stylebox(bg: Color, border: Color, w: int, r: int, shadow_s: int = 0, shadow_c: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_width_left = w
	sb.border_width_top = w
	sb.border_width_right = w
	sb.border_width_bottom = w
	sb.border_color = border
	sb.corner_radius_top_left = r
	sb.corner_radius_top_right = r
	sb.corner_radius_bottom_left = r
	sb.corner_radius_bottom_right = r
	sb.shadow_size = shadow_s
	sb.shadow_color = shadow_c
	return sb


func _label(txt: String, font_size: int, color: Color, font: Font, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var lbl := Label.new()
	lbl.text = txt
	lbl.add_theme_font_override("font", font)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.horizontal_alignment = align
	return lbl
