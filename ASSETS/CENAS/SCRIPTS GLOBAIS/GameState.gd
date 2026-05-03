extends Node

const SAVE_PREFIX = "user://save_slot_"

var slot_atual: int = 1

signal confianca_changed(novo_valor: int, delta: int)

var reputacao: int = 0
var confianca: int = 0:
	set(val):
		var delta = val - confianca
		confianca = val
		confianca_changed.emit(confianca, delta)

var fase_atual: int = 1
var acertos_paginas_fase1: int = 0
var adulterada_identificada_fase1: bool = false
var cena_atual: String = "res://ASSETS/CENAS/game_scene.tscn"
var timeline_atual: String = ""

var decisoes_fase_1 = {
	"falou_com_velho": false,
	"ajudou_vila": false
}

var decisoes_fase_2 = {}

func get_save_path(slot: int) -> String:
	return SAVE_PREFIX + str(slot) + ".json"

func salvar_jogo(slot: int = -1):
	if slot == -1: slot = slot_atual
	# Captura cena atual automaticamente se for uma cena de jogo
	if get_tree() and get_tree().current_scene:
		var scene = get_tree().current_scene
		var s_name = scene.name.to_lower()
		# NUNCA salva se for a cena do menu
		if "title" not in s_name and "menu" not in s_name:
			cena_atual = scene.scene_file_path
	
	# Captura timeline atual se houver alguma tocando
	if Dialogic.current_timeline:
		timeline_atual = Dialogic.current_timeline.resource_path
	
	var save_data = {
		"data_salvamento": Time.get_datetime_string_from_system(false, true),
		"reputacao": reputacao,
		"confianca": confianca,
		"fase_atual": fase_atual,
		"acertos_paginas_fase1": acertos_paginas_fase1,
		"adulterada_identificada_fase1": adulterada_identificada_fase1,
		"cena_atual": cena_atual,
		"timeline_atual": timeline_atual,
		"decisoes_fase_1": decisoes_fase_1,
		"decisoes_fase_2": decisoes_fase_2
	}
	
	var file = FileAccess.open(get_save_path(slot), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		# Salva o estado do Dialogic no slot correspondente
		Dialogic.Save.save("slot_" + str(slot))

func carregar_jogo(slot: int = -1):
	if slot == -1: slot = slot_atual
	var path = get_save_path(slot)
	if not FileAccess.file_exists(path):
		return
		
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(content)
		if error == OK:
			var data = json.get_data()
			if typeof(data) == TYPE_DICTIONARY:
				if data.has("reputacao"): reputacao = data["reputacao"]
				if data.has("confianca"): confianca = data["confianca"]
				if data.has("fase_atual"): fase_atual = data["fase_atual"]
				if data.has("acertos_paginas_fase1"): acertos_paginas_fase1 = data["acertos_paginas_fase1"]
				if data.has("adulterada_identificada_fase1"): adulterada_identificada_fase1 = data["adulterada_identificada_fase1"]
				if data.has("decisoes_fase_1"): decisoes_fase_1 = data["decisoes_fase_1"]
				if data.has("decisoes_fase_2"): decisoes_fase_2 = data["decisoes_fase_2"]
				if data.has("cena_atual"): cena_atual = data["cena_atual"]
				if data.has("timeline_atual"): timeline_atual = data["timeline_atual"]
				
				# Carrega o estado do Dialogic do slot correspondente
				Dialogic.Save.load("slot_" + str(slot))

func reset_save(slot: int = -1):
	if slot == -1: slot = slot_atual
	slot_atual = slot
	reputacao = 0
	confianca = 0
	fase_atual = 1
	acertos_paginas_fase1 = 0
	adulterada_identificada_fase1 = false
	decisoes_fase_1 = {"falou_com_velho": false, "ajudou_vila": false}
	decisoes_fase_2 = {}
	cena_atual = "res://ASSETS/CENAS/game_scene.tscn"
	# Reseta o Dialogic para o estado inicial
	Dialogic.end_timeline()
	if Dialogic.has_subsystem("VAR"):
		# Tenta resetar variáveis para os valores padrão do editor
		Dialogic.VAR.reset_all()
	
	timeline_atual = ""
	salvar_jogo(slot)
