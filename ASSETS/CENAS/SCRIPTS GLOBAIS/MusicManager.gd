extends Node

const VOLUME_PADRAO = -14.0 # Volume ambiente confortável para diálogos

const TRILHAS_PADRAO = [
	"res://ASSETS/SOUNDS/BACKG SOUNDS/trilha_sem_acao_1.mp3",
	"res://ASSETS/SOUNDS/BACKG SOUNDS/trilha_sem_acao_2.mp3",
	"res://ASSETS/SOUNDS/BACKG SOUNDS/trilha_sem_acao_3.mp3"
]
const TRILHA_PALACIO = "res://ASSETS/SOUNDS/BACKG SOUNDS/trilha_sem_acao_4.mp3"

var player1: AudioStreamPlayer
var player2: AudioStreamPlayer
var player_ativo: AudioStreamPlayer

var musica_atual_caminho: String = ""
var tween_crossfade: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Toca mesmo com o jogo pausado
	
	player1 = AudioStreamPlayer.new()
	player2 = AudioStreamPlayer.new()
	
	add_child(player1)
	add_child(player2)
	
	# Conecta os sinais de término para reprodução aleatória/looping
	player1.finished.connect(_on_player_finished.bind(player1))
	player2.finished.connect(_on_player_finished.bind(player2))
	
	# Determina o canal de barramento de áudio apropriado
	var bus_idx = AudioServer.get_bus_index("Musica")
	if bus_idx != -1:
		player1.bus = "Musica"
		player2.bus = "Musica"
	else:
		player1.bus = "Master"
		player2.bus = "Master"
		
	player_ativo = player1

## Executa a música padrão de fundo de forma aleatória
func play_default_music() -> void:
	if musica_atual_caminho in TRILHAS_PADRAO and player_ativo.playing:
		return # Já está tocando uma das trilhas padrão, não precisa interromper
		
	var trilha = TRILHAS_PADRAO[randi() % TRILHAS_PADRAO.size()]
	play_music(trilha, VOLUME_PADRAO, 1.8)

## Callback chamado quando uma trilha termina de tocar
func _on_player_finished(player: AudioStreamPlayer) -> void:
	if player == player_ativo:
		if musica_atual_caminho == TRILHA_PALACIO:
			# A trilha do palácio toca em loop contínuo
			player.play()
		elif musica_atual_caminho in TRILHAS_PADRAO:
			# Escolhe uma trilha padrão diferente da atual para tocar em seguida
			var disponiveis = TRILHAS_PADRAO.duplicate()
			disponiveis.erase(musica_atual_caminho)
			if disponiveis.is_empty():
				disponiveis = TRILHAS_PADRAO.duplicate()
			var nova_trilha = disponiveis[randi() % disponiveis.size()]
			play_music(nova_trilha, VOLUME_PADRAO, 1.8)

## Executa uma música específica com transição suave (crossfade)
func play_music(caminho: String, volume_alvo: float = 0.0, crossfade_time: float = 1.2) -> void:
	if caminho.is_empty():
		return
	
	if musica_atual_caminho == caminho:
		if player_ativo.playing:
			# Se já estiver tocando, apenas faz um ajuste suave de volume se necessário
			var tw = create_tween()
			tw.tween_property(player_ativo, "volume_db", volume_alvo, 0.6)
			return
	
	musica_atual_caminho = caminho
	var stream = load(caminho)
	if not stream:
		push_error("[MusicManager] Falha ao carregar música: " + caminho)
		return
		
	# Para qualquer transição anterior
	if tween_crossfade and tween_crossfade.is_valid():
		tween_crossfade.kill()
		
	var player_novo = player2 if player_ativo == player1 else player1
	
	player_novo.stream = stream
	player_novo.volume_db = -80.0
	player_novo.play()
	
	tween_crossfade = create_tween().set_parallel(true)
	
	# Fade-in do novo player
	tween_crossfade.tween_property(player_novo, "volume_db", volume_alvo, crossfade_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	
	# Fade-out do player anteriormente ativo
	if player_ativo.playing:
		tween_crossfade.tween_property(player_ativo, "volume_db", -80.0, crossfade_time).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
		tween_crossfade.chain().tween_callback(player_ativo.stop)
		
	player_ativo = player_novo

## Para a música atual com fade out
func stop_music(fade_time: float = 1.0) -> void:
	musica_atual_caminho = ""
	if tween_crossfade and tween_crossfade.is_valid():
		tween_crossfade.kill()
		
	if player_ativo.playing:
		var tw = create_tween()
		tw.tween_property(player_ativo, "volume_db", -80.0, fade_time).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(player_ativo.stop)
