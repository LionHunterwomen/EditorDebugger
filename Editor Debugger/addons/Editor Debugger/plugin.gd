@tool
extends EditorPlugin

var Dock: PackedScene = load("res://addons/Editor Debugger/dock.tscn") as PackedScene
var dock: EditorDebuggerDock

## TODO f12

func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	dock = Dock.instantiate() as EditorDebuggerDock
	dock.base_control = get_editor_interface().get_base_control()
	dock.node_selected.connect(_on_EditorDebugger_node_selected)
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BL, dock)
	pass


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	remove_control_from_docks(dock)
	dock.queue_free()
	dock = null
	pass

func _on_EditorDebugger_node_selected(node: Node) -> void:
	if is_instance_valid(node) and dock.is_show_inspection_enabled():
		get_editor_interface().inspect_object(node)
	else:
		var selected_nodes: Array[Node] = get_editor_interface().get_selection().get_selected_nodes()
		if selected_nodes.size():
			get_editor_interface().inspect_object(selected_nodes[0])
	pass
