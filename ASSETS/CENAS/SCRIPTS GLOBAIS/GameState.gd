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
## Quando true, game_scene deve rodar iniciar_sequencia_fase() (retorno de minigame).
var aguardando_sequencia_fase: bool = false

var decisoes_fase_1 = {
	"falou_com_velho": false,
	"ajudou_vila": false
}
var decisoes_fase_2 = {}
var fase2_passo: String = "inicio"
var fase3_passo: String = "inicio"
var fase4_passo: String = "praca"
var cartas_final_desbloqueadas: Array[String] = []
var aliados_final: Dictionary = {}
var resultado_final: String = ""
var pontuacao_final: Dictionary = {}
var registros_democraticos: Array[Dictionary] = []

# Log de escolhas para exibir no menu de pausa
# Cada entrada: {"texto": "...", "delta": +1 ou -1}
var log_escolhas: Array = []

func registrar_escolha(texto: String, delta: int):
	log_escolhas.append({"texto": texto, "delta": delta})


func registrar_registro_democratico(fase: String, conceito: String, evidencia: String, impacto: String, reflexao: String) -> Dictionary:
	var registro := {
		"fase": fase,
		"conceito": conceito,
		"evidencia": evidencia,
		"impacto": impacto,
		"reflexao": reflexao
	}
	for i in range(registros_democraticos.size()):
		if str(registros_democraticos[i].get("fase", "")) == fase:
			registros_democraticos[i] = registro
			return registro
	registros_democraticos.append(registro)
	return registro


func mostrar_registro_democratico(registro: Dictionary) -> void:
	registrar_registro_democratico(
		str(registro.get("fase", "")),
		str(registro.get("conceito", "")),
		str(registro.get("evidencia", "")),
		str(registro.get("impacto", "")),
		str(registro.get("reflexao", ""))
	)
	salvar_jogo(false)
	await _mostrar_painel_registro_democratico(registro)


func _mostrar_painel_registro_democratico(registro: Dictionary) -> void:
	var overlay := CanvasLayer.new()
	overlay.layer = 120
	get_tree().root.add_child(overlay)

	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.84)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(920, 540)
	panel.add_theme_stylebox_override("panel", _registro_stylebox(Color("#0d1014", 0.98), Color("#ffe28a"), 3, 8, 18, Color("#ffe28a", 0.16)))
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_bottom", 34)
	margin.add_theme_constant_override("margin_left", 42)
	margin.add_theme_constant_override("margin_right", 42)
	panel.add_child(margin)

	var root := VBoxContainer.new()
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)

	var title := _registro_label("REGISTRO DEMOCRATICO ADICIONADO", 34, Color("#ffe28a"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	var fase := _registro_label(str(registro.get("fase", "")).to_upper(), 18, Color("#62ff86"))
	fase.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(fase)

	root.add_child(_registro_linha())
	root.add_child(_registro_bloco("CONCEITO", str(registro.get("conceito", "")), Color("#54d6ff")))
	root.add_child(_registro_bloco("EVIDENCIA", str(registro.get("evidencia", "")), Color("#ffe28a")))
	root.add_child(_registro_bloco("IMPACTO", str(registro.get("impacto", "")), Color("#62ff86")))

	var reflexao := _registro_label(str(registro.get("reflexao", "")), 21, Color("#f5ead7"))
	reflexao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reflexao.autowrap_mode = TextServer.AUTOWRAP_WORD
	root.add_child(reflexao)

	var btn := Button.new()
	btn.text = "CONTINUAR"
	btn.custom_minimum_size = Vector2(260, 54)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", Color("#21180f"))
	btn.add_theme_stylebox_override("normal", _registro_stylebox(Color("#ffe28a"), Color("#2b2118"), 2, 6))
	btn.add_theme_stylebox_override("hover", _registro_stylebox(Color("#fff4d6"), Color("#ffe28a"), 2, 6))
	root.add_child(btn)

	panel.modulate.a = 0.0
	panel.scale = Vector2(0.96, 0.96)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(panel, "modulate:a", 1.0, 0.22)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	await btn.pressed
	overlay.queue_free()


func _registro_bloco(titulo: String, texto: String, cor: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _registro_stylebox(Color("#151820", 0.94), cor, 2, 6))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)
	var lbl_titulo := _registro_label(titulo, 15, cor)
	box.add_child(lbl_titulo)
	var lbl_texto := _registro_label(texto, 20, Color("#f5ead7"))
	lbl_texto.autowrap_mode = TextServer.AUTOWRAP_WORD
	box.add_child(lbl_texto)
	return panel


func _registro_label(texto: String, tamanho: int, cor: Color) -> Label:
	var lbl := Label.new()
	lbl.text = texto
	lbl.add_theme_font_size_override("font_size", tamanho)
	lbl.add_theme_color_override("font_color", cor)
	return lbl


func _registro_linha() -> ColorRect:
	var linha := ColorRect.new()
	linha.color = Color("#ffe28a", 0.24)
	linha.custom_minimum_size = Vector2(0, 2)
	return linha


func _registro_stylebox(bg: Color, border: Color, border_width: int = 0, radius: int = 0, shadow_size: int = 0, shadow_color: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_left = border_width
	sb.border_width_top = border_width
	sb.border_width_right = border_width
	sb.border_width_bottom = border_width
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	sb.shadow_size = shadow_size
	sb.shadow_color = shadow_color
	return sb

# --- Lógica de Salvamento ---

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_FILE)

func salvar_jogo(capturar_cena_atual: bool = true):
	# 1. Captura contexto da cena atual
	if capturar_cena_atual and get_tree() and get_tree().current_scene:
		var scene = get_tree().current_scene
		var s_name = scene.name.to_lower()
		# Evita salvar se estivermos em menus ou telas de transição
		if "title" not in s_name and "menu" not in s_name and "tela" not in s_name:
			cena_atual = scene.scene_file_path
	
	# 2. Captura estado do diálogo
	if aguardando_sequencia_fase:
		timeline_atual = ""
	elif Dialogic.current_timeline:
		timeline_atual = extrair_nome_timeline(Dialogic.current_timeline.resource_path)
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
		"aguardando_sequencia_fase": aguardando_sequencia_fase,
		"decisoes_fase_1": decisoes_fase_1,
		"decisoes_fase_2": decisoes_fase_2,
		"fase2_passo": fase2_passo,
		"fase3_passo": fase3_passo,
		"fase4_passo": fase4_passo,
		"cartas_final_desbloqueadas": cartas_final_desbloqueadas,
		"aliados_final": aliados_final,
		"resultado_final": resultado_final,
		"pontuacao_final": pontuacao_final,
		"registros_democraticos": registros_democraticos,
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

func limpar_timeline_ativa() -> void:
	timeline_atual = ""


func extrair_nome_timeline(caminho: String) -> String:
	if caminho.is_empty():
		return ""
	if "://" in caminho:
		return caminho.get_file().get_basename()
	return caminho


func limpar_save_dialogic() -> void:
	if Dialogic.has_subsystem("Save"):
		Dialogic.Save.reset_slot("autosave")


func preparar_transicao_minigame(caminho_cena: String) -> void:
	await TimelineManager.parar_tudo()
	limpar_timeline_ativa()
	aguardando_sequencia_fase = false
	limpar_save_dialogic()
	cena_atual = caminho_cena
	salvar_jogo(false)


## Encerra Dialogic, marca retorno à game_scene e troca de cena (fluxo pós-minigame).
func retornar_para_game_scene_apos_minigame() -> void:
	await TimelineManager.parar_tudo()
	limpar_timeline_ativa()
	limpar_save_dialogic()
	aguardando_sequencia_fase = true
	Dialogic.paused = false
	cena_atual = "res://ASSETS/CENAS/game_scene.tscn"
	salvar_jogo(false)
	await FadeManager.carregar_cena(cena_atual)
	await get_tree().process_frame
	_garantir_sequencia_fase_na_cena_atual()

const CENA_MINIGAME_PAGINAS: String = "res://ASSETS/CENAS/minigame_paginas.tscn"


## Atalho secreto: estado mínimo da fase 1 + minigame de páginas (pula intro e timelines).
func atalho_ir_minigame_paginas() -> void:
	ChoiceTimer.forcar_parar()
	fase_atual = 1
	fase2_passo = "inicio"
	fase3_passo = "inicio"
	acertos_paginas_fase1 = 0
	adulterada_identificada_fase1 = false
	await preparar_transicao_minigame(CENA_MINIGAME_PAGINAS)
	await FadeManager.carregar_cena(CENA_MINIGAME_PAGINAS)


func _garantir_sequencia_fase_na_cena_atual() -> void:
	var cena: Node = get_tree().current_scene
	if cena and cena.has_method("_tentar_iniciar_sequencia"):
		cena.call_deferred("_tentar_iniciar_sequencia")


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
	
	if aguardando_sequencia_fase:
		timeline_atual = ""
		print("[GameState] Retomando sequência de fase após minigame...")
		_garantir_sequencia_fase_na_cena_atual()
	elif timeline_atual != "":
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
				fase2_passo = data.get("fase2_passo", "inicio")
				fase3_passo = data.get("fase3_passo", "inicio")
				fase4_passo = data.get("fase4_passo", "praca")
				cartas_final_desbloqueadas.clear()
				for carta_final in data.get("cartas_final_desbloqueadas", []):
					cartas_final_desbloqueadas.append(str(carta_final))
				aliados_final = data.get("aliados_final", {})
				resultado_final = data.get("resultado_final", "")
				pontuacao_final = data.get("pontuacao_final", {})
				registros_democraticos.clear()
				for registro in data.get("registros_democraticos", []):
					if typeof(registro) == TYPE_DICTIONARY:
						registros_democraticos.append(registro)
				log_escolhas = data.get("log_escolhas", [])
				cena_atual = data.get("cena_atual", "res://ASSETS/CENAS/game_scene.tscn")
				timeline_atual = data.get("timeline_atual", "")
				aguardando_sequencia_fase = data.get("aguardando_sequencia_fase", false)
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
	fase2_passo = "inicio"
	fase3_passo = "inicio"
	fase4_passo = "praca"
	cartas_final_desbloqueadas = []
	aliados_final = {}
	resultado_final = ""
	pontuacao_final = {}
	registros_democraticos = []
	cena_atual = "res://ASSETS/CENAS/game_scene.tscn"
	timeline_atual = ""
	aguardando_sequencia_fase = false
	log_escolhas = []
	
	# Encerra processos ativos
	await TimelineManager.parar_tudo()
	
	# Salva o estado "limpo" para sobrescrever o anterior
	salvar_jogo()
	print("[GameState] Save resetado com sucesso.")
