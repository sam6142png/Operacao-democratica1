@tool
extends DialogicLayoutLayer

@onready var holder: ColorRect = $DialogicNode_BackgroundHolder

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if holder:
		holder.child_entered_tree.connect(_on_background_child_entered)

func _on_background_child_entered(node: Node) -> void:
	# Quando uma imagem de fundo (TextureRect) é criada pelo Dialogic, aplicamos o shader de pixelização
	if node is TextureRect or node is Control:
		_aplicar_shader_pixelate(node)

func _aplicar_shader_pixelate(target: Control) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://ASSETS/SHADERS/pixelate.gdshader")
	target.material = mat
