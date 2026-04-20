extends Control

const MENSAGENS = [
	{
		"cifrada": "RSHUDCDR FLQCD — UHJLVWURV GHVWUXLGRV FRQIRUPH RUGHQDGR",
		"gabarito": "OPERACAO CINZA — REGISTROS DESTRUIDOS CONFORME ORDENADO",
		"deslocamento": 3,
		"timeline_acerto": "radio_mensagem_decifrada"
	},
	{
		"cifrada": "HQFRPHQGD GH TXHLMR FRDOKR FKHJRX DR SDODFlr FHQWUDO",
		"gabarito": "ENCOMENDA DE QUEIJO COALHO CHEGOU AO PALACIO CENTRAL",
		"deslocamento": 3,
		"timeline_acerto": "radio_mensagem_decifrada_2"
	},
	{
		"cifrada": "RSHUDCDR FRQVHQVR — PRELOLCDCDR QD SUDC GR SDODFIR",
		"gabarito": "OPERACAO CONSENSO — MOBILIZACAO NA PRACA DO PALACIO",
		"deslocamento": 3,
		"timeline_acerto": "radio_mensagem_decifrada_3"
	}
]

var mensagem_atual: int = 0
var tentativas: int = 0

@onready var mensagem_cifrada_label: Label   = $PainelRadio/Layout/MensagemCifrada
@onready var mensagem_decifrada_label: Label = $PainelRadio/Layout/MensagemDecifrada
@onready var slider: HSlider                 = $PainelRadio/Layout/RodaCifra
@onready var deslocamento_label: Label       = $PainelRadio/Layout/DeslocamentoLabel
@onready var botao_confirmar: Button         = $PainelRadio/Layout/BotaoConfirmar
@onready var dica_label: Label               = $PainelRadio/Layout/DicaLabel
@onready var painel_decisao: Control         = $PainelDecisao

func _ready() -> void:
	painel_decisao.visible = false
	dica_label.text = ""
	_carregar_mensagem(0)

	slider.value_changed.connect(_on_slider_changed)
	botao_confirmar.pressed.connect(_on_confirmar)
	$PainelDecisao/LayoutDecisao/BotaoDivulgar.pressed.connect(func(): _decisao("divulgar"))
	$PainelDecisao/LayoutDecisao/BotaoAlterar.pressed.connect(func(): _decisao("alterar"))
	$PainelDecisao/LayoutDecisao/BotaoGuardar.pressed.connect(func(): _decisao("guardar"))

	# Conecta sinal do Dialogic
	Dialogic.signal_event.connect(_on_dialogic_signal)

func _on_dialogic_signal(valor: String) -> void:
	match valor:
		"minigame_encerrado":
			get_tree().change_scene_to_file("res://ASSETS/CENAS/game_scene.tscn")

func _bloquear_interacao() -> void:
	slider.editable = false
	botao_confirmar.disabled = true

func _liberar_interacao() -> void:
	slider.editable = true
	botao_confirmar.disabled = false

func _carregar_mensagem(indice: int) -> void:
	mensagem_atual = indice
	tentativas = 0
	slider.value = 0
	dica_label.text = ""
	mensagem_cifrada_label.text = MENSAGENS[indice]["cifrada"]
	mensagem_decifrada_label.text = ""
	deslocamento_label.text = "Deslocamento: 0"

func _on_slider_changed(valor: float) -> void:
	var deslocamento = int(valor)
	deslocamento_label.text = "Deslocamento: " + str(deslocamento)
	mensagem_decifrada_label.text = _decifrar(
		MENSAGENS[mensagem_atual]["cifrada"], deslocamento
	)

func _decifrar(texto: String, deslocamento: int) -> String:
	var resultado = ""
	for caractere in texto:
		if caractere == " " or caractere == "—":
			resultado += caractere
		elif caractere >= "A" and caractere <= "Z":
			var pos = (ord(caractere) - ord("A") - deslocamento + 26) % 26
			resultado += char(ord("A") + pos)
		else:
			resultado += caractere
	return resultado

func _on_confirmar() -> void:
	var tentativa = mensagem_decifrada_label.text.strip_edges()
	tentativas += 1

	if tentativa == MENSAGENS[mensagem_atual]["gabarito"]:
		await _acertou()
	else:
		await _errou()

func _acertou() -> void:
	_bloquear_interacao()
	dica_label.text = ""

	await TimelineManager.tocar_dialogo(MENSAGENS[mensagem_atual]["timeline_acerto"])

	if mensagem_atual < MENSAGENS.size() - 1:
		_carregar_mensagem(mensagem_atual + 1)
		_liberar_interacao()
	else:
		await TimelineManager.tocar_dialogo("radio_escolha_intro")
		painel_decisao.visible = true

func _errou() -> void:
	_bloquear_interacao()
	if tentativas == 1:
		dica_label.text = "Dica: pense em quantas posições cada letra foi avançada."
		await TimelineManager.tocar_dialogo("radio_dica_leve")
	elif tentativas == 2:
		dica_label.text = "Dica: tente o número " + str(MENSAGENS[mensagem_atual]["deslocamento"]) + "."
		await TimelineManager.tocar_dialogo("radio_dica_direta")
	else:
		dica_label.text = "Dica: o deslocamento é " + str(MENSAGENS[mensagem_atual]["deslocamento"]) + "."
	_liberar_interacao()

func _decisao(escolha: String) -> void:
	GameState.DecisaoRadio_Fase2 = escolha
	painel_decisao.visible = false
	_bloquear_interacao()

	match escolha:
		"divulgar":
			await TimelineManager.tocar_dialogo("radio_decisao_divulgar")
		"alterar":
			await TimelineManager.tocar_dialogo("radio_decisao_alterar")
		"guardar":
			await TimelineManager.tocar_dialogo("radio_decisao_guardar")

	await TimelineManager.tocar_dialogo("radio_encerramento")
	# A troca de cena acontece via sinal "minigame_encerrado" do Dialogic
