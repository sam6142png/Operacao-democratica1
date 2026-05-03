extends CanvasLayer

const FONTE = preload("res://ASSETS/FONTES/determination.ttf")

var overlay: ColorRect
var titulo_lbl: Label
var dica_texto: RichTextLabel
var loading_texto: Label

var FATOS = [
	"[center]O [color=#22FF55]Ceará[/color] aboliu a escravidão em 1884, quatro anos antes da Lei Áurea.[/center]",
	"[center]A palavra [color=#22FF55]Democracia[/color] vem da Grécia e significa 'Poder do Povo'.[/center]",
	"[center]Nossa [color=#22FF55]Constituição de 1988[/color] é chamada 'Cidadã' pela ampla participação popular.[/center]",
	"[center]Cidadania é prática! Checar [color=#22FF55]Fake News[/color] antes de compartilhar protege a democracia.[/center]",
	"[center]O Voto Feminino no Brasil só foi garantido em [color=#22FF55]1932[/color]. Direitos são conquistados.[/center]",
	"[center][color=#22FF55]Chico da Matilde[/color] fechou o porto do Ceará ao tráfico negreiro, um ato heroico civil.[/center]",
	"[center]Todo cidadão tem o dever de fiscalizar verbas em portais de [color=#22FF55]Transparência[/color].[/center]",
	"[center]O Art. 5º da Constituição afirma que [color=#22FF55]TODOS são iguais perante a lei[/color], sem distinção.[/center]",
	"[center]Estar em um Estado Democrático de Direito significa que [color=#22FF55]até mesmo o governo[/color] obedece às leis.[/center]"
]

var fatos_restantes: Array = []

func _ready() -> void:
	layer = 1000  # fica acima de tudo
	randomize() # Garante aleatoriedade sempre que abrir o jogo
	_garantir_overlay()

func _sortear_dica() -> String:
	if fatos_restantes.is_empty():
		fatos_restantes = FATOS.duplicate()
		fatos_restantes.shuffle()
	return fatos_restantes.pop_back()

func _garantir_overlay() -> void:
	if overlay == null:
		# Fundo Escuro Full Screen
		overlay = ColorRect.new()
		overlay.color = Color(0, 0, 0, 0)
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(overlay)
		
		# Container Central dinâmico (não quebra independente da resolução)
		var vbox = VBoxContainer.new()
		vbox.set_anchors_preset(Control.PRESET_CENTER)
		vbox.anchor_left = 0.5
		vbox.anchor_right = 0.5
		vbox.anchor_top = 0.5
		vbox.anchor_bottom = 0.5
		vbox.offset_left = -450
		vbox.offset_right = 450
		vbox.offset_top = -150
		vbox.offset_bottom = 150
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Título Elegante
		titulo_lbl = Label.new()
		titulo_lbl.text = "— VOCÊ SABIA? —"
		titulo_lbl.add_theme_font_override("font", FONTE)
		titulo_lbl.add_theme_font_size_override("font_size", 46)
		titulo_lbl.add_theme_color_override("font_color", Color(1.0, 0.55, 0.0))
		titulo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(titulo_lbl)
		
		# Espaço em branco
		var espaco = Control.new()
		espaco.custom_minimum_size = Vector2(0, 40)
		vbox.add_child(espaco)
		
		# Texto da Dica
		dica_texto = RichTextLabel.new()
		dica_texto.bbcode_enabled = true
		dica_texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dica_texto.add_theme_font_override("normal_font", FONTE)
		dica_texto.add_theme_font_size_override("normal_font_size", 34)
		dica_texto.add_theme_color_override("font_shadow_color", Color(0,0,0,1))
		dica_texto.add_theme_constant_override("shadow_offset_x", 3)
		dica_texto.add_theme_constant_override("shadow_offset_y", 3)
		dica_texto.custom_minimum_size = Vector2(900, 150)
		dica_texto.scroll_active = false
		vbox.add_child(dica_texto)
		
		vbox.modulate.a = 0.0
		overlay.add_child(vbox)
		
		# Texto Carregando (Canto Inferior Direito seguro)
		loading_texto = Label.new()
		loading_texto.text = "Carregando a missão..."
		loading_texto.add_theme_font_override("font", FONTE)
		loading_texto.add_theme_font_size_override("font_size", 24)
		loading_texto.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		
		loading_texto.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		loading_texto.anchor_left = 1.0
		loading_texto.anchor_right = 1.0
		loading_texto.anchor_top = 1.0
		loading_texto.anchor_bottom = 1.0
		loading_texto.offset_left = -300
		loading_texto.offset_right = -40
		loading_texto.offset_top = -60
		loading_texto.offset_bottom = -20
		loading_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		loading_texto.modulate.a = 0.0
		
		overlay.add_child(loading_texto)

func carregar_cena(cena_alvo_path: String) -> void:
	_garantir_overlay()
	
	# Sorteia a dica sem repetir
	dica_texto.text = _sortear_dica()
	
	# Fade Out do jogo antigo
	var tween = create_tween()
	tween.tween_property(overlay, "color", Color(0.05, 0.05, 0.06, 1.0), 0.5).set_ease(Tween.EASE_IN)
	
	# Revela a Interface de Loading
	var vbox_ui = overlay.get_child(0)
	tween.tween_property(vbox_ui, "modulate:a", 1.0, 0.4)
	tween.parallel().tween_property(loading_texto, "modulate:a", 1.0, 0.4)
	
	await tween.finished
	
	# Sistema simples e estável: Animação de piscar e espera 3 segundos
	var piscando = true
	var timer_pisca = Timer.new()
	timer_pisca.wait_time = 0.5
	timer_pisca.timeout.connect(func(): if piscando: loading_texto.visible = !loading_texto.visible)
	add_child(timer_pisca)
	timer_pisca.start()
	
	# Tempo garantido de leitura
	await get_tree().create_timer(3.0).timeout
	
	# Troca de cena de forma limpa sem threading (evita crash do Godot 4)
	get_tree().change_scene_to_file(cena_alvo_path)
	
	# Limpeza
	piscando = false
	timer_pisca.queue_free()
	loading_texto.visible = true
	
	# Fade In do novo jogo
	var tween_in = create_tween()
	tween_in.tween_property(vbox_ui, "modulate:a", 0.0, 0.2)
	tween_in.parallel().tween_property(loading_texto, "modulate:a", 0.0, 0.2)
	tween_in.tween_property(overlay, "color", Color(0, 0, 0, 0), 0.6).set_ease(Tween.EASE_OUT)

func transicao_com_dica(tempo_leitura: float = 3.0) -> void:
	_garantir_overlay()
	
	# Sorteia a dica sem repetir
	dica_texto.text = _sortear_dica()
	
	# Fade Out (cobre o jogo)
	var tween = create_tween()
	tween.tween_property(overlay, "color", Color(0.05, 0.05, 0.06, 1.0), 0.5).set_ease(Tween.EASE_IN)
	
	var vbox_ui = overlay.get_child(0)
	tween.tween_property(vbox_ui, "modulate:a", 1.0, 0.4)
	
	await tween.finished
	
	# Pausa para leitura (simulando "carregamento" do próximo capítulo)
	await get_tree().create_timer(tempo_leitura).timeout
	
	# Fade In (Revela o jogo de novo)
	var tween_in = create_tween()
	tween_in.tween_property(vbox_ui, "modulate:a", 0.0, 0.2)
	tween_in.tween_property(overlay, "color", Color(0, 0, 0, 0), 0.6).set_ease(Tween.EASE_OUT)
	await tween_in.finished

func fade_out(duracao: float = 0.6) -> void:
	_garantir_overlay()
	overlay.get_child(0).modulate.a = 0.0
	loading_texto.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(overlay, "color", Color(0, 0, 0, 1), duracao).set_ease(Tween.EASE_IN)
	await tween.finished

func fade_in(duracao: float = 0.8) -> void:
	_garantir_overlay()
	var tween = create_tween()
	tween.tween_property(overlay, "color", Color(0, 0, 0, 0), duracao).set_ease(Tween.EASE_OUT)
	await tween.finished
