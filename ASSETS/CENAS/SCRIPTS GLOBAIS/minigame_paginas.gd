extends Control

const FONTE = preload("res://ASSETS/FONTES/determination.ttf")

const TODAS_PAGINAS = [
	{
		"texto": "Todo cidadão tem direito à educação gratuita e de qualidade.",
		"resposta": "direito",
		"adulterada": false,
		"explicacao": "A educação é um direito fundamental garantido pela Constituição."
	},
	{
		"texto": "É dever do cidadão votar nas eleições e participar da vida política.",
		"resposta": "dever",
		"adulterada": false,
		"explicacao": "Participar da vida política é um dever cívico de todo cidadão."
	},
	{
		"texto": "O governo pode censurar qualquer informação que julgue perigosa para a ordem pública.",
		"resposta": "adulterada",
		"adulterada": true,
		"explicacao": "⚠ VERSÃO ADULTERADA DO REGIME! A liberdade de informação é um direito fundamental."
	},
	{
		"texto": "Todo cidadão tem direito à liberdade de expressão e manifestação pacífica.",
		"resposta": "direito",
		"adulterada": false,
		"explicacao": "A liberdade de expressão é um pilar fundamental da democracia."
	},
	{
		"texto": "É dever do cidadão respeitar e preservar o patrimônio público e comunitário.",
		"resposta": "dever",
		"adulterada": false,
		"explicacao": "Preservar o patrimônio público é responsabilidade de todos os cidadãos."
	},
	{
		"texto": "O Estado tem o dever de garantir saúde, moradia e segurança a todos os cidadãos.",
		"resposta": "direito",
		"adulterada": false,
		"explicacao": "Saúde, moradia e segurança são direitos sociais garantidos pelo Estado."
	},
	{
		"texto": "Cidadãos que discordarem do governo devem ser realocados para zonas de trabalho forçado.",
		"resposta": "adulterada",
		"adulterada": true,
		"explicacao": "⚠ VERSÃO ADULTERADA DO REGIME! Nenhum cidadão pode ser punido por discordar do governo."
	},
	{
		"texto": "É dever do cidadão pagar impostos para financiar serviços públicos coletivos.",
		"resposta": "dever",
		"adulterada": false,
		"explicacao": "O pagamento de impostos é um dever que sustenta os serviços públicos de todos."
	},
	{
		"texto": "Todo cidadão tem direito a um julgamento justo e à presunção de inocência.",
		"resposta": "direito",
		"adulterada": false,
		"explicacao": "O direito a um julgamento justo é garantia fundamental do Estado de Direito."
	},
	{
		"texto": "O regime tem autoridade para suspender eleições em períodos de instabilidade social.",
		"resposta": "adulterada",
		"adulterada": true,
		"explicacao": "⚠ VERSÃO ADULTERADA DO REGIME! Eleições são direito inalienável do povo e não podem ser suspensas."
	}
]

# Fases de dificuldade
const TEMPO_FASE2 = 20.0
const TEMPO_FASE3 = 12.0
const MAX_ERROS = 3

var paginas_embaralhadas: Array = []
var pagina_atual: int = 0
var acertos: int = 0
var erros: int = 0
var esta_arrastando: bool = false
var pos_original_pagina: Vector2
var timer_restante: float = 0.0
var usar_timer: bool = false
var aguardando_proxima: bool = false

@onready var texto_pagina: Label        = $PaginaContainer/PaginaCard/TextoPagina
@onready var pagina_card: PanelContainer = $PaginaContainer/PaginaCard
@onready var feedback: Label            = $Feedback
@onready var progresso: Label           = $Progresso
@onready var explicacao: PanelContainer = $Explicacao
@onready var texto_explicacao: Label    = $Explicacao/TextoExplicacao
@onready var botao_direito: Button      = $PaginaContainer/BotoesContainer/BotaoDireito
@onready var botao_dever: Button        = $PaginaContainer/BotoesContainer/BotaoDever
@onready var botao_adulterada: Button   = $PaginaContainer/BotoesContainer/BotaoAdulterada
@onready var zona_esquerda: Control     = $ZonaEsquerda
@onready var zona_direita: Control      = $ZonaDireita
@onready var pagina_container: Control  = $PaginaContainer
@onready var label_timer: Label         = $LabelTimer
@onready var label_erros: Label         = $LabelErros

func _ready() -> void:
	_aplicar_fonte()
	pos_original_pagina = pagina_container.position
	pagina_card.gui_input.connect(_on_pagina_input)
	botao_direito.pressed.connect(func(): _avaliar("direito"))
	botao_dever.pressed.connect(func(): _avaliar("dever"))
	botao_adulterada.pressed.connect(func(): _avaliar("adulterada"))
	Dialogic.signal_event.connect(_on_sinal_dialogic)
	_iniciar_rodada()

func _on_sinal_dialogic(sinal: String) -> void:
	if sinal == "paginas_encerradas":
		get_tree().change_scene_to_file("res://ASSETS/CENAS/game_scene.tscn")

func _aplicar_fonte() -> void:
	for label in [texto_pagina, feedback, progresso, texto_explicacao,
		label_timer, label_erros,
		$ZonaEsquerda/LabelDireito, $ZonaDireita/LabelDever]:
		label.add_theme_font_override("font", FONTE)
	for btn in [botao_direito, botao_dever, botao_adulterada]:
		btn.add_theme_font_override("font", FONTE)

func _iniciar_rodada() -> void:
	paginas_embaralhadas = TODAS_PAGINAS.duplicate()
	paginas_embaralhadas.shuffle()
	pagina_atual = 0
	acertos = 0
	erros = 0
	aguardando_proxima = false
	label_erros.text = "Erros: 0/" + str(MAX_ERROS)
	label_timer.text = ""
	_carregar_pagina(0)

func _carregar_pagina(idx: int) -> void:
	pagina_atual = idx
	explicacao.visible = false
	feedback.text = ""
	aguardando_proxima = false
	pagina_container.position = pos_original_pagina
	pagina_container.modulate = Color.WHITE

	var pagina = paginas_embaralhadas[idx]
	texto_pagina.text = pagina["texto"]
	progresso.text = "Página " + str(idx + 1) + " de " + str(paginas_embaralhadas.size())
	label_erros.text = "Erros: " + str(erros) + "/" + str(MAX_ERROS)

	# Cor do texto baseada na fase
	if pagina["adulterada"]:
		texto_pagina.add_theme_color_override("font_color", Color("#FFDD88"))
	else:
		texto_pagina.add_theme_color_override("font_color", Color("#FFFFFF"))

	# Define timer baseado na fase de dificuldade
	if idx >= 6:
		usar_timer = true
		timer_restante = TEMPO_FASE3
		label_timer.add_theme_color_override("font_color", Color("#FF4444"))
	elif idx >= 3:
		usar_timer = true
		timer_restante = TEMPO_FASE2
		label_timer.add_theme_color_override("font_color", Color("#FFAA00"))
	else:
		usar_timer = false
		timer_restante = 0.0
		label_timer.text = ""

	_liberar_botoes()
	_animar_entrada()

func _animar_entrada() -> void:
	pagina_container.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(pagina_container, "modulate:a", 1.0, 0.4)\
		.set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	# Timer
	if usar_timer and not aguardando_proxima:
		timer_restante -= delta
		label_timer.text = "Tempo: " + str(int(timer_restante)) + "s"

		# Pisca vermelho nos últimos 5 segundos
		if timer_restante <= 5.0:
			label_timer.modulate.a = 1.0 if fmod(Time.get_ticks_msec() / 500.0, 2.0) < 1.0 else 0.4

		if timer_restante <= 0.0:
			usar_timer = false
			label_timer.text = "Tempo esgotado!"
			_avaliar("timeout")
			return

	# Drag and drop
	if esta_arrastando:
		pagina_container.global_position = get_global_mouse_position() - pagina_container.size / 2
		var rect_esq = zona_esquerda.get_global_rect()
		var rect_dir = zona_direita.get_global_rect()
		var pos_mouse = get_global_mouse_position()
		if rect_esq.has_point(pos_mouse):
			zona_esquerda.modulate = Color(0.4, 0.8, 1.0, 0.4)
			zona_direita.modulate = Color(1.0, 0.4, 0.1, 0.15)
		elif rect_dir.has_point(pos_mouse):
			zona_direita.modulate = Color(1.0, 0.6, 0.2, 0.4)
			zona_esquerda.modulate = Color(0.2, 0.5, 1.0, 0.15)
		else:
			zona_esquerda.modulate = Color(0.2, 0.5, 1.0, 0.15)
			zona_direita.modulate = Color(1.0, 0.4, 0.1, 0.15)
	elif not esta_arrastando and pagina_container.global_position != pos_original_pagina and not aguardando_proxima:
		var rect_esq = zona_esquerda.get_global_rect()
		var rect_dir = zona_direita.get_global_rect()
		var pos_centro = pagina_container.global_position + pagina_container.size / 2
		
		pagina_container.position = pos_original_pagina
		
		if rect_esq.has_point(pos_centro):
			_avaliar("direito")
		elif rect_dir.has_point(pos_centro):
			_avaliar("dever")
		
		esta_arrastando = false
		zona_esquerda.modulate = Color(0.2, 0.5, 1.0, 0.15)
		zona_direita.modulate = Color(1.0, 0.4, 0.1, 0.15)

func _on_pagina_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			esta_arrastando = event.pressed

func _avaliar(escolha: String) -> void:
	if aguardando_proxima:
		return
	aguardando_proxima = true
	usar_timer = false
	_bloquear_botoes()

	var pagina = paginas_embaralhadas[pagina_atual]
	var acertou = false

	if escolha == "timeout":
		# Tempo esgotado — erro sem penalidade de confiança extra
		erros += 1
		_mostrar_feedback(false, "✗ Tempo esgotado!")
		_mostrar_explicacao(pagina["explicacao"])

	elif pagina["adulterada"] and escolha == "adulterada":
		# Identificou corretamente uma adulterada
		acertou = true
		acertos += 1
		GameState.confianca += 2
		_mostrar_feedback(true, "⚠ Você identificou uma versão adulterada pelo regime!")
		_mostrar_explicacao(pagina["explicacao"])

	elif not pagina["adulterada"] and escolha == pagina["resposta"]:
		# Acertou direito ou dever
		acertou = true
		acertos += 1
		GameState.confianca += 1
		_mostrar_feedback(true, "✓ Correto!")
		_mostrar_explicacao(pagina["explicacao"])

	elif pagina["adulterada"] and escolha != "adulterada":
		# Não identificou a adulterada — penalidade maior
		erros += 1
		GameState.confianca -= 2
		_mostrar_feedback(false, "✗ Cuidado! Essa era uma versão adulterada pelo regime!")
		_mostrar_explicacao(pagina["explicacao"])

	else:
		# Errou direito/dever
		erros += 1
		GameState.confianca -= 1
		_mostrar_feedback(false, "✗ Incorreto!")
		_mostrar_explicacao(pagina["explicacao"])

	label_erros.text = "Erros: " + str(erros) + "/" + str(MAX_ERROS)

	if erros >= MAX_ERROS:
		await get_tree().create_timer(2.0).timeout
		_reiniciar()
		return

	await get_tree().create_timer(3.0).timeout
	_proxima_pagina()
func _reiniciar() -> void:
	feedback.text = "O regime ainda controla sua mente... tente novamente"
	feedback.add_theme_color_override("font_color", Color("#FF4444"))
	explicacao.visible = false
	await get_tree().create_timer(2.5).timeout
	_iniciar_rodada()

func _mostrar_feedback(acerto: bool, msg: String) -> void:
	feedback.text = msg
	if acerto:
		feedback.add_theme_color_override("font_color", Color("#59FF88"))
	else:
		feedback.add_theme_color_override("font_color", Color("#FF4444"))

func _mostrar_explicacao(texto: String) -> void:
	texto_explicacao.text = texto
	explicacao.visible = true
	explicacao.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(explicacao, "modulate:a", 1.0, 0.3)

func _voltar_centro() -> void:
	var tween = create_tween()
	tween.tween_property(pagina_container, "position", pos_original_pagina, 0.3)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _proxima_pagina() -> void:
	if pagina_atual < paginas_embaralhadas.size() - 1:
		_liberar_botoes()
		_carregar_pagina(pagina_atual + 1)
	else:
		_encerrar()

func _encerrar() -> void:
	GameState.acertos_paginas_fase1 = acertos
	await TimelineManager.tocar_dialogo("timeline_resultado_paginas")

func _bloquear_botoes() -> void:
	botao_direito.disabled = true
	botao_dever.disabled = true
	botao_adulterada.disabled = true

func _liberar_botoes() -> void:
	botao_direito.disabled = false
	botao_dever.disabled = false
	botao_adulterada.disabled = false
