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
