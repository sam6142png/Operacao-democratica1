extends Node

const SAVE_FILE = "user://autosave.json"

signal confianca_changed(novo_valor: int, delta: int)

# --- Variáveis de Estado ---
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

# Log de escolhas para exibir no menu de pausa
# Cada entrada: {"texto": "...", "delta": +1 ou -1}
var log_escolhas: Array = []

func registrar_escolha(texto: String, delta: int):
	log_escolhas.append({"texto": texto, "delta": delta})

# --- Lógica de Salvamento ---

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_FILE)

func salvar_jogo():
	# 1. Captura contexto da cena atual
	if get_tree() and get_tree().current_scene:
		var scene = get_tree().current_scene
		var s_name = scene.name.to_lower()
		# Evita salvar se estivermos em menus ou telas de transição
		if "title" not in s_name and "menu" not in s_name and "tela" not in s_name:
			cena_atual = scene.scene_file_path
	
	# 2. Captura estado do diálogo
	if Dialogic.current_timeline:
		timeline_atual = Dialogic.current_timeline.resource_path
	else:
		timeline_atual = ""
	
	# 3. Prepara o pacote de dados
	var save_data = {
		"timestamp": Time.get_datetime_string_from_system(false, true),
		"reputacao": reputacao,
		"confianca": confianca,
		"fase_atual": fase_atual,
		"acertos_paginas_fase1": acertos_paginas_fase1,
		"adulterada_identificada_fase1": adulterada_identificada_fase1,
		"cena_atual": cena_atual,
		"timeline_atual": timeline_atual,
		"decisoes_fase_1": decisoes_fase_1,
		"decisoes_fase_2": decisoes_fase_2,
		"log_escolhas": log_escolhas
	}
	
	# 4. Salva o arquivo JSON principal
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		
		# 5. Salva o estado interno profundo do Dialogic (variáveis internas, posição do texto)
		Dialogic.Save.save("autosave")
		print("[GameState] Jogo salvo com sucesso.")

# --- Lógica de Carregamento ---

func continuar_jogo():
	if not has_save():
		push_error("[GameState] Tentativa de carregar save inexistente.")
		return
		
	# 1. Carrega os dados básicos do JSON para a memória
	_carregar_dados_json()
	
	# 2. Inicia a transição visual
	# Usamos o FadeManager para trocar de cena com tela de loading/sabia que
	await FadeManager.carregar_cena(cena_atual)
	
	# 3. A cena agora mudou. Esperamos um pouco para o carregamento do Dialogic
	# O Dialogic precisa que o layout da nova cena esteja pronto
	await get_tree().process_frame
	
	if timeline_atual != "":
		print("[GameState] Retomando estado preciso do Dialogic...")
		# Carregamos o estado completo. O Dialogic 2 cuida de reabrir a timeline 
		# no índice exato (current_event_idx) que foi salvo no state.txt.
		Dialogic.Save.load("autosave")

func _carregar_dados_json():
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		if json.parse(content) == OK:
			var data = json.get_data()
			if typeof(data) == TYPE_DICTIONARY:
				reputacao = data.get("reputacao", 0)
				confianca = data.get("confianca", 0)
				fase_atual = data.get("fase_atual", 1)
				acertos_paginas_fase1 = data.get("acertos_paginas_fase1", 0)
				adulterada_identificada_fase1 = data.get("adulterada_identificada_fase1", false)
				decisoes_fase_1 = data.get("decisoes_fase_1", decisoes_fase_1)
				decisoes_fase_2 = data.get("decisoes_fase_2", decisoes_fase_2)
				log_escolhas = data.get("log_escolhas", [])
				cena_atual = data.get("cena_atual", "res://ASSETS/CENAS/game_scene.tscn")
				timeline_atual = data.get("timeline_atual", "")
				print("[GameState] Dados JSON carregados na memória.")

func reset_save():
	# Limpa tudo
	reputacao = 0
	confianca = 0
	fase_atual = 1
	acertos_paginas_fase1 = 0
	adulterada_identificada_fase1 = false
	decisoes_fase_1 = {"falou_com_velho": false, "ajudou_vila": false}
	decisoes_fase_2 = {}
	cena_atual = "res://ASSETS/CENAS/game_scene.tscn"
	timeline_atual = ""
	log_escolhas = []
	
	# Encerra processos ativos
	await TimelineManager.parar_tudo()
	
	# Salva o estado "limpo" para sobrescrever o anterior
	salvar_jogo()
	print("[GameState] Save resetado com sucesso.")
