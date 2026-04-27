@tool
extends EditorPlugin

var seManager:Control
var seMerger:Node
func _enable_plugin() -> void:
	
	add_autoload_singleton("SE", "res://addons/godotse/semanager.gd")

func _disable_plugin() -> void:
	remove_autoload_singleton("SE")
	if ProjectSettings.has_setting("GodotSe/memory/max_animation_allocation_in_mb"):
		ProjectSettings.set_setting("GodotSe/memory/max_animation_allocation_in_mb", null)
	pass


func _enter_tree() -> void:
	add_custom_type("SEInfo", "Node", preload("res://addons/godotse/seinfo.gd"), preload("res://addons/godotse/assets/seanim_dark.png"))
	
	seManager = preload("res://addons/godotse/assets/se.tscn").instantiate();
	seManager.tool_plugin = self
	
	seMerger = seManager.get_child(6).get_child(0)
	seMerger.tool_plugin = self
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL,seManager)

		
func get_selected_nodes() -> Array:
	var ret:Array = []
	var all:Array[Node] = get_editor_interface().get_selection().get_selected_nodes()
	for n:Node in all:
		if n as Skeleton3D != null:
			ret.append(n)
	return ret
func get_selected_animation_player() -> Array:
	var ret:Array = []
	var all:Array[Node] = get_editor_interface().get_selection().get_selected_nodes()
	for n:Node in all:
		if n as AnimationPlayer != null:
			ret.append(n)
	return ret
func _exit_tree() -> void:
	remove_autoload_singleton("SE")
	remove_custom_type("SEInfo")
	if seManager and is_instance_valid(seManager):
		remove_control_from_docks(seManager)
		seManager.free();
