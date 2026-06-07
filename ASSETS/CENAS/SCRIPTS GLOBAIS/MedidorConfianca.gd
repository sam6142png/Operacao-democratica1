extends CanvasLayer

const MAX_CONFIANCA = 10
const MAX_INCLINACAO = 25.0
const TEMPO_VISIVEL = 3.0

@onready var anim: AnimationPlayer = get_node_or_null("Anim")
@onready var sprite_balanca: TextureRect = get_node_or_null("MainControl/Panel/VBox/ScaleContainer/SpriteBalanca")
@onready var label_valor: Label = get_node_or_null("MainControl/Panel/VBox/LabelValor")
@onready var label_notificacao: Label = get_node_or_null("MainControl/Notification")
@onready var main_control: Control = get_node_or_null("MainControl")

var angulo_atual: float = 0.0
var timer_sumir: SceneTreeTimer = null

func _ready() -> void:
	# Inicialmente escondido (modulate.a já está em 0 no tscn)
	main_control.modulate.a = 0.0
	
	# Conecta ao GameState para atualizações automáticas
	if GameState.has_signal("confianca_changed"):
		GameState.confianca_changed.connect(_on_confianca_changed)

func _on_confianca_changed(novo_valor: int, delta: int) -> void:
	_atualizar_visual(novo_valor, delta)
	_aparecer()
	_criar_explosao_particulas(delta)

func _atualizar_visual(valor: int, delta: int) -> void:
	# Atualiza o texto do valor total
	label_valor.text = "Confiança: " + str(valor)
	
	# Calcula a inclinação
	var proporcao = clamp(float(valor) / MAX_CONFIANCA, -1.0, 1.0)
	var alvo = -proporcao * MAX_INCLINACAO
	
	# Anima a rotação da balança
	var tween = create_tween()
	tween.tween_property(sprite_balanca, "rotation_degrees", alvo, 0.8)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	
	# Configura a notificação de ganho/perda
	if delta != 0:
		var prefixo = "+" if delta > 0 else ""
		label_notificacao.text = prefixo + str(delta)
		
		if delta > 0:
			label_notificacao.add_theme_color_override("font_color", Color("#59A5FF"))
			anim.play("impact_pos")
		else:
			label_notificacao.add_theme_color_override("font_color", Color("#CC1A1A"))
			anim.play("impact_neg")
	
	# Cores do valor total
	if valor > 0:
		label_valor.add_theme_color_override("font_color", Color("#59A5FF"))
	elif valor < 0:
		label_valor.add_theme_color_override("font_color", Color("#CC1A1A"))
	else:
		label_valor.add_theme_color_override("font_color", Color("#AAAAAA"))

func _aparecer() -> void:
	# Se já estiver sumindo ou escondido, toca a animação de show
	if main_control.modulate.a < 0.5:
		anim.play("show")
	
	# Reinicia o timer para sumir
	if timer_sumir:
		timer_sumir = null
		
	timer_sumir = get_tree().create_timer(TEMPO_VISIVEL)
	timer_sumir.timeout.connect(_sumir)

func _sumir() -> void:
	if anim.is_playing() and anim.current_animation == "show":
		await anim.animation_finished
	
	anim.play("hide")
	timer_sumir = null


func _criar_explosao_particulas(delta: int) -> void:
	if delta == 0:
		return
	
	var cor = Color("#59A5FF") if delta > 0 else Color("#CC1A1A")
	var prefixo = "+" if delta > 0 else ""
	var texto_particula = prefixo + str(delta)
	
	var base_node: Control = sprite_balanca if sprite_balanca else main_control
	if not base_node:
		return
	
	# Spawn de 5 mini-partículas de texto com dispersão elástica
	for i in range(5):
		var lbl := Label.new()
		lbl.text = texto_particula
		
		# Tenta carregar a fonte do projeto, senão usa a padrão
		var fonte_res = load("res://ArticaPro-Bold.ttf")
		if fonte_res:
			lbl.add_theme_font_override("font", fonte_res)
		
		lbl.add_theme_font_size_override("font_size", randi_range(20, 32))
		lbl.add_theme_color_override("font_color", cor)
		lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		lbl.add_theme_constant_override("outline_size", 5)
		
		var spawn_pos = base_node.global_position + Vector2(base_node.size.x / 2.0, base_node.size.y / 2.0)
		spawn_pos += Vector2(randf_range(-40.0, 40.0), randf_range(-25.0, 25.0))
		
		lbl.global_position = spawn_pos
		lbl.scale = Vector2(0.1, 0.1)
		lbl.pivot_offset = Vector2(30.0, 15.0)
		
		add_child(lbl)
		
		# Destino com dispersão aleatória em leque para cima
		var dest_pos = spawn_pos + Vector2(randf_range(-140.0, 140.0), randf_range(-180.0, -80.0))
		var rot = randf_range(-35.0, 35.0)
		
		var tw := create_tween().set_parallel(true)
		tw.tween_property(lbl, "global_position", dest_pos, 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(lbl, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(lbl, "rotation_degrees", rot, 0.85)
		
		# Desaparece suavemente após o movimento
		var tw_fade := create_tween()
		tw_fade.tween_interval(0.5)
		tw_fade.tween_property(lbl, "modulate:a", 0.0, 0.35)
		tw_fade.tween_callback(lbl.queue_free)
