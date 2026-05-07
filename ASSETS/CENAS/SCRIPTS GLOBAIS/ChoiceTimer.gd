extends CanvasLayer

const TEMPO_LIMITE := 30.0
const FONTE = preload("res://ASSETS/FONTES/determination.ttf")

var timer_ativo := false
var tempo_restante := 0.0
var escolha_feita := false

var barra_container: Control
var barra_fundo: ColorRect
var barra_progresso: ColorRect
var label_tempo: Label
var largura_barra: float = 0.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	_criar_interface()
	_desativar_completamente()
	call_deferred("_conectar_sinais")

func _conectar_sinais():
	if Dialogic.has_subsystem("Choices"):
		Dialogic.Choices.question_shown.connect(_on_question_shown)
		Dialogic.Choices.choice_selected.connect(_on_choice_selected)
		print("[ChoiceTimer] Conectado ao sistema de escolhas.")
	else:
		push_warning("[ChoiceTimer] Subsistema Choices não encontrado.")
	Dialogic.timeline_started.connect(_on_timeline_started)

func _on_timeline_started():
	pass

func forcar_parar():
	timer_ativo = false
	escolha_feita = true
	if barra_container:
		barra_container.visible = false
		barra_container.modulate.a = 0.0
	set_process(false)

func _desativar_completamente() -> void:
	timer_ativo = false
	set_process(false)
	if barra_container:
		barra_container.visible = false

func _criar_interface():
	barra_container = Control.new()
	barra_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	barra_container.custom_minimum_size = Vector2(0, 44)
	barra_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(barra_container)

	barra_fundo = ColorRect.new()
	barra_fundo.color = Color(0.0, 0.0, 0.0, 0.75)
	barra_fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	barra_fundo.anchor_left = 0.05
	barra_fundo.anchor_right = 0.95
	barra_fundo.anchor_top = 0.0
	barra_fundo.anchor_bottom = 0.0
	barra_fundo.offset_top = 10
	barra_fundo.offset_bottom = 42
	barra_container.add_child(barra_fundo)

	barra_progresso = ColorRect.new()
	barra_progresso.color = Color("#FF8C00")
	barra_progresso.mouse_filter = Control.MOUSE_FILTER_IGNORE
	barra_progresso.anchor_left = 0.05
	barra_progresso.anchor_right = 0.95
	barra_progresso.anchor_top = 0.0
	barra_progresso.anchor_bottom = 0.0
	barra_progresso.offset_top = 12
	barra_progresso.offset_bottom = 40
	barra_container.add_child(barra_progresso)

	label_tempo = Label.new()
	label_tempo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_tempo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_tempo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_tempo.add_theme_font_override("font", FONTE)
	label_tempo.add_theme_font_size_override("font_size", 22)
	label_tempo.add_theme_color_override("font_color", Color.WHITE)
	label_tempo.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1.0))
	label_tempo.add_theme_constant_override("shadow_offset_x", 2)
	label_tempo.add_theme_constant_override("shadow_offset_y", 2)
	label_tempo.anchor_left = 0.0
	label_tempo.anchor_right = 1.0
	label_tempo.anchor_top = 0.0
	label_tempo.anchor_bottom = 0.0
	label_tempo.offset_top = 8
	label_tempo.offset_bottom = 44
	barra_container.add_child(label_tempo)

func _on_question_shown(_info: Dictionary):
	escolha_feita = false
	tempo_restante = TEMPO_LIMITE
	timer_ativo = true

	set_process(true)
	set_process_input(false)
	set_process_unhandled_input(false)

	barra_container.visible = true
	barra_progresso.color = Color("#FF8C00")
	barra_progresso.modulate.a = 1.0

	await get_tree().process_frame
	largura_barra = barra_fundo.size.x

	barra_container.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(barra_container, "modulate:a", 1.0, 0.3)
	print("[ChoiceTimer] Timer iniciado: ", TEMPO_LIMITE, "s")

func _on_choice_selected(_info: Dictionary):
	if escolha_feita:
		return
	escolha_feita = true
	resetar()

func _process(delta: float):
	if not timer_ativo:
		return
	if get_tree().paused:
		return
	tempo_restante -= delta
	if tempo_restante <= 0:
		tempo_restante = 0
		timer_ativo = false
		_tempo_esgotado()
		return
	_atualizar_visual()

func _atualizar_visual():
	var progresso = tempo_restante / TEMPO_LIMITE
	barra_progresso.anchor_right = 0.05 + (0.90 * progresso)
	label_tempo.text = "ESCOLHA EM " + str(ceili(tempo_restante)) + "s"
	if tempo_restante <= 5.0:
		barra_progresso.color = Color("#FF2222")
		var pulso = abs(sin(tempo_restante * 5.0))
		barra_progresso.modulate.a = 0.5 + (pulso * 0.5)
		label_tempo.text = "⚠ " + str(ceili(tempo_restante)) + "s ⚠"
		label_tempo.add_theme_color_override("font_color", Color("#FF4444"))
	elif tempo_restante <= 10.0:
		barra_progresso.color = Color("#FFD700")
		barra_progresso.modulate.a = 1.0
		label_tempo.add_theme_color_override("font_color", Color("#FFD700"))
	else:
		barra_progresso.color = Color("#FF8C00")
		barra_progresso.modulate.a = 1.0
		label_tempo.add_theme_color_override("font_color", Color.WHITE)

func _tempo_esgotado():
	if escolha_feita:
		return
	escolha_feita = true
	print("[ChoiceTimer] Tempo esgotado! Selecionando aleatoriamente...")

	var botoes_visiveis: Array[Button] = []
	for node in get_tree().get_nodes_in_group("dialogic_choice_button"):
		if node is Button and node.visible and not node.disabled:
			botoes_visiveis.append(node)

	if botoes_visiveis.is_empty():
		print("[ChoiceTimer] Nenhum botão encontrado!")
		resetar()
		return

	var idx = randi() % botoes_visiveis.size()
	var escolhido: Button = botoes_visiveis[idx]
	print("[ChoiceTimer] Escolha automática: ", escolhido.text)

	label_tempo.text = "ESCOLHA AUTOMÁTICA!"
	label_tempo.add_theme_color_override("font_color", Color("#22FF55"))

	var tw = create_tween()
	tw.tween_property(escolhido, "modulate", Color(2.0, 2.0, 0.5), 0.2)
	tw.tween_property(escolhido, "modulate", Color.WHITE, 0.2)
	await tw.finished

	if escolhido is DialogicNode_ChoiceButton:
		escolhido.choice_selected.emit()
	else:
		escolhido.pressed.emit()

	resetar()

func resetar():
	timer_ativo = false
	escolha_feita = false
	if not barra_container:
		return
	var tw = create_tween()
	tw.tween_property(barra_container, "modulate:a", 0.0, 0.3)
	tw.tween_callback(_desativar_completamente)
