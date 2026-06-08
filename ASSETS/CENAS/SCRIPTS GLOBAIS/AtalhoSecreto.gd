extends Node
## Atalho oculto: pula narrativa da fase 1 e vai ao minigame de páginas.
## Shift+Ctrl+P  ou  digitar P → A → G em até 2,5 s (em qualquer tela de jogo).

const CENA_MINIGAME_PAGINAS := "res://ASSETS/CENAS/minigame_paginas.tscn"
const SEQUENCIA := [KEY_P, KEY_A, KEY_G]
const JANELA_SEQUENCIA_SEC := 2.5

var _indice_sequencia := 0
var _ultima_tecla_msec := 0
var _executando := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	if _executando:
		return
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
		
	# Atalho: Libera todas as conquistas e toca Toasts
	if key_event.keycode == KEY_K and key_event.shift_pressed and key_event.ctrl_pressed:
		get_viewport().set_input_as_handled()
		_liberar_conquistas_teste()
		return
		
	# Atalho: Testa Caixa de Diálogo Xilografia
	if key_event.keycode == KEY_T and key_event.shift_pressed and key_event.ctrl_pressed:
		get_viewport().set_input_as_handled()
		_testar_estilo_dialogo("res://ASSETS/DIALOGIC/STYLES/XilografiaCariri.tres")
		return

	# Atalho: Testa Caixa de Diálogo Palácio Dourado
	if key_event.keycode == KEY_Y and key_event.shift_pressed and key_event.ctrl_pressed:
		get_viewport().set_input_as_handled()
		_testar_estilo_dialogo("res://ASSETS/DIALOGIC/STYLES/PalacioDourado.tres")
		return
		
	# Atalho: Reseta todas as conquistas e o save
	if key_event.keycode == KEY_R and key_event.shift_pressed and key_event.ctrl_pressed:
		get_viewport().set_input_as_handled()
		_resetar_conquistas_teste()
		return
		
	if _combo_direto(key_event):
		get_viewport().set_input_as_handled()
		_executar_atalho()
		return
	if _sequencia_pag(key_event):
		get_viewport().set_input_as_handled()
		_executar_atalho()


func _combo_direto(event: InputEventKey) -> bool:
	return event.keycode == KEY_P and event.shift_pressed and event.ctrl_pressed


func _sequencia_pag(event: InputEventKey) -> bool:
	var agora := Time.get_ticks_msec()
	if _indice_sequencia > 0 and (agora - _ultima_tecla_msec) > int(JANELA_SEQUENCIA_SEC * 1000.0):
		_indice_sequencia = 0
	if event.keycode != SEQUENCIA[_indice_sequencia]:
		_indice_sequencia = 0
		if event.keycode == SEQUENCIA[0]:
			_indice_sequencia = 1
			_ultima_tecla_msec = agora
		return false
	_indice_sequencia += 1
	_ultima_tecla_msec = agora
	return _indice_sequencia >= SEQUENCIA.size()


func _executar_atalho() -> void:
	_indice_sequencia = 0
	_executando = true
	print("[AtalhoSecreto] Pulando diálogos → minigame de páginas")
	await GameState.atalho_ir_minigame_paginas()
	_executando = false


func _liberar_conquistas_teste() -> void:
	print("[AtalhoSecreto] Desbloqueando todas as conquistas para teste...")
	var conquistas = ["historiador", "radio_perfeito", "escola_ok", "praca_pacifica", "fim_democratico", "fim_qualquer"]
	for id in conquistas:
		GameState.conquistas_desbloqueadas[id] = true
		GameState.criar_toast_conquista(id)
		# Espera 1.2 segundos para os toasts cascatearem elegantemente
		await get_tree().create_timer(1.2).timeout
	GameState.salvar_jogo(false)


func _resetar_conquistas_teste() -> void:
	print("[AtalhoSecreto] Resetando estado de jogo e conquistas...")
	for key in GameState.conquistas_desbloqueadas.keys():
		GameState.conquistas_desbloqueadas[key] = false
	GameState.skin_dante_selecionada = "padrao"
	GameState.estilo_textbox_selecionado = "res://ASSETS/DIALOGIC/STYLES/Base_testebox.tres"
	GameState.aplicar_estilizacao_dialogic()
	GameState.reset_save()
	if get_tree().current_scene and "title" in get_tree().current_scene.name.to_lower():
		get_tree().reload_current_scene()


func _testar_estilo_dialogo(estilo_path: String) -> void:
	print("[AtalhoSecreto] Testando estilo de diálogo: ", estilo_path)
	for id in ["historiador", "radio_perfeito", "escola_ok", "praca_pacifica", "fim_democratico", "fim_qualquer"]:
		GameState.conquistas_desbloqueadas[id] = true
	GameState.estilo_textbox_selecionado = estilo_path
	TimelineManager.tocar_dialogo("Timeline_VilaPeixeiro")
