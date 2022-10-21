@tool
class_name EditorDebuggerDock extends Control

@onready var _editor_debugger_tree: Tree = $VBoxContainer/Tree as Tree
@onready var _highlight_color_picker_button: ColorPickerButton = %HighlightColorPickerButton as ColorPickerButton
@onready var _highlight_color_reset_button: TextureButton = %HighlightColorResetButton as TextureButton
@onready var _show_in_inspection_check_button: CheckButton = %ShowInInspectionCheckButton as CheckButton
@onready var _animation_time_spin_box: SpinBox = %AnimationTimeSpinBox as SpinBox
@onready var _animation_time_reset_button: TextureButton = %AnimationTimeResetButton as TextureButton

@onready var _popup_menu: PopupMenu = $PopupMenu as PopupMenu
@onready var _save_branch_file_dialog: FileDialog = $SaveBranchFileDialog as FileDialog

signal node_selected(node: Node)

const _default_highlight_modulate: Color = Color(0, 0, 1, 0.2)
var _editor_ui_highlight: Control

const _defult_aniamtion_time: float = 0.3
var _animation_time: float = 0.3

var base_control: Control

func _enter_tree() -> void:
	pass

func _ready() -> void:
	_highlight_color_picker_button.color = _default_highlight_modulate
	_highlight_color_reset_button.hide()
	_animation_time_spin_box.value = _animation_time
	_animation_time_reset_button.hide()
	
	_editor_debugger_tree.item_activated.connect(_editor_debugger_tree_node_selected)
	_editor_debugger_tree.item_selected.connect(_editor_node_select)
	_editor_debugger_tree.item_mouse_selected.connect(_editor_debugger_tree_item_mouse_selected)
	_highlight_color_picker_button.color_changed.connect(_highlight_modulate_changed)
	_highlight_color_reset_button.pressed.connect(_highlight_color_reset_button_pressed)
	_show_in_inspection_check_button.pressed.connect(_show_in_inspection_check_button_pressed)
	_animation_time_spin_box.value_changed.connect(_animation_time_spin_box_value_changed)
	_animation_time_reset_button.pressed.connect(_animation_time_reset_button_pressed)
	_popup_menu.id_pressed.connect(_popup_menu_id_pressed)
	_save_branch_file_dialog.dir_selected.connect(_save_branch_file_dialog_folder_selected)
	_save_branch_file_dialog.file_selected.connect(_save_branch_file_dialog_folder_selected)
	_update_editor_debugger_tree()
	if _editor_ui_highlight == null:
		_editor_ui_highlight = ColorRect.new()
		_editor_ui_highlight.color = _default_highlight_modulate
#	_tween = _editor_ui_highlight.create_tween()
#	_tween = create_tween()
	_editor_ui_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_editor_ui_highlight.hide()
	get_viewport().call_deferred("add_child", _editor_ui_highlight)
	pass

func _exit_tree() -> void:
	if is_instance_valid(_editor_ui_highlight):
		_editor_ui_highlight.queue_free()

func _update_editor_debugger_tree() -> void:
	var editor_root: Node = get_tree().get_root()
	if not is_instance_valid(editor_root):
		return
	_editor_debugger_tree.clear()
	var editor_debugger_tree_root: TreeItem = _editor_debugger_tree.get_root()
	if editor_debugger_tree_root == null:
		editor_debugger_tree_root = _create_editor_debugger_tree_item(editor_root, null)
	
	_update_editor_debugger_tree_branch(editor_root, editor_debugger_tree_root)
	pass

## editor_node 与 editor_debugger_tree_branch 相对应
func _update_editor_debugger_tree_branch(editor_node: Node, editor_debugger_tree_branch: TreeItem) -> void:
	var editor_node_children: Array[Node] = editor_node.get_children()
	var editor_debugger_tree_branch_items: Array[TreeItem] = editor_debugger_tree_branch.get_children()
	
	for i in editor_node_children.size():
		var current_item: TreeItem
		var current_node: Node = editor_node_children[i]
		if i < editor_debugger_tree_branch_items.size():
			current_item = editor_debugger_tree_branch_items[i]
			if StringName(current_item.get_text(1)) != current_node.name:
				_update_item_from_node(current_item, current_node)
		else:
			current_item = _create_editor_debugger_tree_item(current_node, editor_debugger_tree_branch)
			editor_debugger_tree_branch_items.append(current_item)
		_update_editor_debugger_tree_branch(current_node, current_item)

	if editor_node.get_child_count() < editor_debugger_tree_branch_items.size():
		for i in range(editor_node.get_child_count(), editor_debugger_tree_branch_items.size()):
			editor_debugger_tree_branch_items[i].free()
	pass

func _create_editor_debugger_tree_item(node: Node, root_item: TreeItem) -> TreeItem:
	var current_item: TreeItem = _editor_debugger_tree.create_item(root_item)
	current_item.set_text(0, node.get_class())
	current_item.set_text(1, node.name)
#	current_item.set_metadata(0, node)
	current_item.collapsed = true
	
	if node is Control:
		current_item.set_tooltip_text(0, node.tooltip_text)
	return current_item

func _update_item_from_node(item: TreeItem, node: Node) -> void:
	item.set_text(0, node.get_class())
	item.set_text(1, node.name)
	if node is Control:
		item.set_tooltip_text(0, node.tooltip_text)
	pass

func _editor_debugger_tree_node_selected() -> void:
	var selected_item: TreeItem = _editor_debugger_tree.get_selected() 
	selected_item.collapsed = false
	pass

#func _get_editor_node_form_selected_editor_debugger_tree_item() -> Node:
#	var selected_item: TreeItem = _editor_debugger_tree.get_selected()
#	if is_instance_valid(selected_item):
#		var node: Node = selected_item.get_metadata(0)
#		if not is_instance_valid(node):
##			_update_editor_debugger_tree_branch(selected_item.get_parent().get_metadata(0), selected_item.get_metadata(0))
#			_update_editor_debugger_tree()
#		return selected_item.get_metadata(0)
#	return null

func _get_editor_node_form_selected_editor_debugger_tree_item() -> Node:
	var selected_item: TreeItem = _editor_debugger_tree.get_selected()
	if selected_item.get_parent() == null:
		return get_tree().get_root()
	var parent_item: TreeItem = selected_item
	var path: String = selected_item.get_text(1)
	while parent_item.get_parent() != null:
		parent_item = parent_item.get_parent()
		if parent_item.get_parent() == null:
			break
		path = parent_item.get_text(1) + "/" + path
	var node = get_tree().get_root().get_node_or_null(NodePath(path))
	return node

func _get_editor_node_form_editor_debugger_tree_item(item: TreeItem) -> Node:
	if item.get_parent() == null:
		return get_tree().get_root()
	var parent_item: TreeItem = item
	var path: String = item.get_text(1)
	while parent_item.get_parent() != null:
		parent_item = parent_item.get_parent()
		if parent_item.get_parent() == null:
			break
		path = parent_item.get_text(1) + "/" + path
	var node = get_tree().get_root().get_node_or_null(NodePath(path))
	return node

func _editor_node_select() -> void:
#	_show_editor_debugger_tree_item(_editor_debugger_tree.get_selected())
	var selected_editor_node: Node = _get_editor_node_form_selected_editor_debugger_tree_item()
	_editor_node_highlight(selected_editor_node)
	node_selected.emit(selected_editor_node)

func _editor_node_highlight(node: Node) -> void:
	if is_instance_valid(node) and node.is_inside_tree():
		if node is Control and ClassDB.class_exists(node.get_class()):
			node = node as Control
			var rect: Rect2 = node.get_global_rect()
			if _editor_ui_highlight.visible:
				var _tween: Tween = create_tween()
				_tween.set_trans(Tween.TRANS_CIRC)
				_tween.stop()
				_tween.set_parallel(true)
				_tween.tween_property(_editor_ui_highlight, "position", rect.position, _animation_time).from(_editor_ui_highlight.position)
				_tween.tween_property(_editor_ui_highlight, "size", rect.size, _animation_time).from(_editor_ui_highlight.size)
				_tween.play()
			else:
				_editor_ui_highlight.position = rect.position
				_editor_ui_highlight.size = rect.size
				var _tween: Tween = create_tween()
				_tween.set_trans(Tween.TRANS_LINEAR)
				_tween.stop()
				_tween.set_parallel(false)
				_tween.tween_property(_editor_ui_highlight, "modulate:a", 1.0, _animation_time).from(0.0)
				_tween.play()
			_editor_ui_highlight.show()
			return
#	var tween: Tween = _editor_ui_highlight.create_tween()
	var _tween: Tween = create_tween()
	_tween.set_trans(Tween.TRANS_LINEAR)
	_tween.stop()
	_tween.set_parallel(false)
	_tween.tween_property(_editor_ui_highlight, "modulate:a", 0.0, _animation_time).from(1.0)
	_tween.tween_callback(_editor_ui_highlight.hide)
	_tween.play()
#	_editor_ui_highlight.hide()

func _highlight_modulate_changed(color: Color) -> void:
	_highlight_color_reset_button.visible = color != _default_highlight_modulate
	
	if _editor_ui_highlight is ColorRect:
		_editor_ui_highlight.color = color
		return
	_editor_ui_highlight.modulate = color
	pass

func _highlight_color_reset_button_pressed() -> void:
	_highlight_color_picker_button.color = _default_highlight_modulate
	_highlight_color_picker_button.color_changed.emit(_highlight_color_picker_button.color)
	pass

func _animation_time_spin_box_value_changed(value :float) -> void:
	_animation_time = value
	_animation_time_reset_button.visible = _animation_time != _defult_aniamtion_time
	pass

func _animation_time_reset_button_pressed() -> void:
	_animation_time = _defult_aniamtion_time
	_animation_time_spin_box.value = _animation_time
	_animation_time_reset_button.hide()
	pass

func is_show_inspection_enabled() -> bool:
	return _show_in_inspection_check_button.button_pressed

func _show_in_inspection_check_button_pressed() -> void:
	if _show_in_inspection_check_button.button_pressed:
		_editor_node_select()
		return
	node_selected.emit(null)
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_F12 and event.pressed:
			_pick_editor_node_from_position(get_global_mouse_position())
#			_editor_debugger_tree.clear()
	pass

func _pick_editor_node_from_position(pos: Vector2) -> void:
	_update_editor_debugger_tree()
	var pick: Callable = func(pos, node, pick: Callable) -> Node:
		var picked_node: Node
		for child in node.get_children():
			if child is CanvasItem and not child.visible:
				continue
			if child == _editor_ui_highlight:
				continue
			if child is Viewport:
				continue
			if child is Control:
				if child.get_global_rect().has_point(pos):
					node = pick.call(pos, child, pick)
					if node != null:
						picked_node = node
						break
					picked_node = child
					break
			else:
				node = pick.call(pos, child, pick)
				if node != null:
					picked_node = node
					break
		return picked_node
	
	var node = pick.call(pos, get_tree().get_root(), pick)
	_select_editor_debugger_tree_from_editor_node(node)

func _select_editor_debugger_tree_from_editor_node(node: Node) -> void:
	if node == null:
		_editor_node_highlight(null)
		print_debug("select null")
		return
	
	_update_editor_debugger_tree()
	
	var current_node: Node = get_tree().get_root()
	var current_item: TreeItem = _editor_debugger_tree.get_root()
	var editor_node_path: NodePath = node.get_path()
	
	var select_item: TreeItem
	
	for i in range(1, editor_node_path.get_name_count()):
		var node_name: StringName = editor_node_path.get_name(i)
		var item_children: Array[TreeItem] = current_item.get_children()
		var child_item: TreeItem
		
		for item in item_children:
			if item.get_text(1) == node_name:
				child_item = item
		
		if child_item == null:
			_update_editor_debugger_tree_branch(current_node, current_item)
		
		item_children = current_item.get_children()
		for item in item_children:
			if item.get_text(1) == node_name:
				child_item = item
		
		if child_item == null:
			select_item = current_item
			break
		
		current_node = current_node.get_node(NodePath(node_name))
		current_item = child_item
		select_item = child_item
	
	if select_item != null:
		_show_editor_debugger_tree_item(select_item)
		select_item.select(0)
		_editor_debugger_tree.ensure_cursor_is_visible()

func _show_editor_debugger_tree_item(item: TreeItem) -> void:
	if item:
		var parent_item: TreeItem = item.get_parent()
		while parent_item != null:
			parent_item.collapsed = false
			parent_item = parent_item.get_parent()
	pass

func _editor_debugger_tree_item_mouse_selected(pos: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		_popup_menu.position = get_global_mouse_position()
		_popup_menu.show()

func _popup_menu_id_pressed(id: int) -> void:
	match id:
		0:
#			_save_branch()
			_save_branch_file_dialog.popup_centered_ratio()
#			_save_branch_file_dialog.popup_centered()
	
	pass

func _save_branch_file_dialog_folder_selected(path: String) -> void:
	_save_branch(path)
	pass

func _save_branch(path: String) -> void:
	var selected_item: TreeItem = _editor_debugger_tree.get_selected()
	if selected_item == null:
		return
	
	var branch_node_dic: Dictionary
	var branch_root_node: Node = _get_editor_node_form_editor_debugger_tree_item(selected_item)
	
	var foo: Callable = func(parent_node: Node, foo: Callable) -> void:
		for child in parent_node.get_children():
			if child.owner != null:
				branch_node_dic[child] = child.owner
			
			if not ClassDB.can_instantiate(child.get_class()):
				print(child.get_class())
				
				pass
			
			child.owner = branch_root_node
			foo.call(child, foo)
	
	var refoo: Callable = func() -> void:
		for node in branch_node_dic.keys() as Array[Node]:
			node.owner = branch_node_dic[node]
	
	foo.call(branch_root_node, foo)
	
	var packed_scene: PackedScene = PackedScene.new()
	var err = packed_scene.pack(branch_root_node)
	if err == OK:
		err = ResourceSaver.save(packed_scene, path)
		if err == OK:
			print_rich("Save Complate")
		else:
			printerr("save err", err)
	else:
		printerr("pack err", err)
	
	refoo.call()

	pass

