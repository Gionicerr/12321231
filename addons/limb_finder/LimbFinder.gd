tool
extends Panel





const DEFAULT_LIMBS = [
	"Head", 
	"LeftHand", "RightHand", 
	"LeftFoot", "RightFoot", 
]

var editor_plugin: EditorPlugin

var loaded_node: Node = null

var limb_data: Dictionary = {}


var unique_textures: Array = []

var manual_textures: Dictionary = {}

var selected_limb: String = ""
var selected_texture: Texture = null



var clipboard_entries: Dictionary = {}

onready var node_label: Label = $"%NodeLabel"
onready var limb_list: ItemList = $"%LimbList"
onready var new_limb_edit: LineEdit = $"%NewLimbEdit"
onready var add_limb_button: Button = $"%AddLimbButton"
onready var remove_limb_button: Button = $"%RemoveLimbButton"
onready var sprite_row: GridContainer = $"%SpriteRow"
onready var sprite_count_label: Label = $"%SpriteCountLabel"
onready var add_sprite_button: Button = $"%AddSpriteButton"
onready var remove_sprite_button: Button = $"%RemoveSpriteButton"
onready var canvas = $"%SpriteCanvas"
onready var sprite_label: Label = $"%SpriteLabel"
onready var coord_label: Label = $"%CoordLabel"
onready var clear_button: Button = $"%ClearButton"
onready var copy_limb_button: Button = $"%CopyLimbButton"
onready var paste_limb_button: Button = $"%PasteLimbButton"
onready var copy_all_button: Button = $"%CopyAllButton"
onready var paste_all_button: Button = $"%PasteAllButton"
onready var flipped_check: CheckBox = $"%FlippedCheck"
onready var absent_check: CheckBox = $"%AbsentCheck"
onready var hint_label: Label = $"%HintLabel"
onready var add_sprite_dialog: FileDialog = $"%AddSpriteDialog"

func _ready():
	add_limb_button.connect("pressed", self, "_on_add_limb_pressed")
	new_limb_edit.connect("text_entered", self, "_on_new_limb_submitted")
	remove_limb_button.connect("pressed", self, "_on_remove_limb_pressed")
	limb_list.connect("item_selected", self, "_on_limb_selected")
	canvas.connect("limb_set", self, "_on_limb_set")
	clear_button.connect("pressed", self, "_on_clear_pressed")
	copy_limb_button.connect("pressed", self, "_on_copy_limb_pressed")
	paste_limb_button.connect("pressed", self, "_on_paste_limb_pressed")
	copy_all_button.connect("pressed", self, "_on_copy_all_pressed")
	paste_all_button.connect("pressed", self, "_on_paste_all_pressed")
	flipped_check.connect("toggled", self, "_on_flipped_toggled")
	absent_check.connect("toggled", self, "_on_absent_toggled")
	add_sprite_button.connect("pressed", self, "_on_add_sprite_pressed")
	remove_sprite_button.connect("pressed", self, "_on_remove_sprite_pressed")
	add_sprite_dialog.connect("file_selected", self, "_on_extra_sprite_selected")
	hint_label.text = "click + drag on the sprite to place a limb."
	_refresh_node_label()



func load_node(node: Node):
	if loaded_node == node:
		return
	loaded_node = node
	_load_data_from_node()
	_collect_unique_textures()
	_refresh_node_label()
	_refresh_limb_list()
	_refresh_sprite_grid()
	_pick_default_selection()
	_refresh_canvas()

func _load_data_from_node():
	limb_data.clear()
	if loaded_node and loaded_node.has_meta("limb_data"):
		var raw = loaded_node.get_meta("limb_data")
		if raw is Dictionary:
			limb_data = raw.duplicate(true)
	
	
	var added = false
	for name in DEFAULT_LIMBS:
		if not limb_data.has(name):
			limb_data[name] = {}
			added = true
	if added and loaded_node:
		_save_data_to_node()

func _save_data_to_node():
	if not loaded_node:
		return
	loaded_node.set_meta("limb_data", limb_data.duplicate(true))

func _get_extras() -> Array:
	if not loaded_node:
		return []
	if not loaded_node.has_meta("limb_extra_sprites"):
		return []
	var raw = loaded_node.get_meta("limb_extra_sprites")
	if raw is Array:
		return raw
	return []

func _save_extras(extras: Array):
	if not loaded_node:
		return
	loaded_node.set_meta("limb_extra_sprites", extras.duplicate())

func _collect_unique_textures():
	unique_textures.clear()
	manual_textures.clear()
	if not loaded_node:
		return
	var seen: Dictionary = {}
	
	
	var flip = loaded_node.get_node_or_null("Flip")
	if flip:
		for child in _all_descendants(flip):
			if child is AnimatedSprite and child.frames:
				for anim_name in child.frames.get_animation_names():
					var count = child.frames.get_frame_count(anim_name)
					for i in range(count):
						var tex = child.frames.get_frame(anim_name, i)
						if tex and not seen.has(tex) and not _is_excluded_texture(tex):
							seen[tex] = true
							unique_textures.append(tex)
	
	
	for prop_name in ["character_portrait", "character_portrait2"]:
		if prop_name in loaded_node:
			var tex = loaded_node.get(prop_name)
			if tex is Texture and not seen.has(tex) and not _is_excluded_texture(tex):
				seen[tex] = true
				unique_textures.append(tex)
	
	
	
	for tex in _get_extras():
		if tex is Texture and not seen.has(tex):
			seen[tex] = true
			unique_textures.append(tex)
			manual_textures[tex] = true
	unique_textures.sort_custom(self, "_compare_texture_names")

func _compare_texture_names(a: Texture, b: Texture) -> bool:
	var a_name = a.resource_path.get_file() if a.resource_path else ""
	var b_name = b.resource_path.get_file() if b.resource_path else ""
	return a_name < b_name




func _is_excluded_texture(tex: Texture) -> bool:
	if loaded_node == null:
		return false
	var tex_path = tex.resource_path if tex.resource_path else ""
	if not ("stickman" in tex_path):
		return false
	var node_path = loaded_node.filename if loaded_node.filename else ""
	return not ("stickman" in node_path)

func _all_descendants(node: Node) -> Array:
	var result: = []
	for child in node.get_children():
		result.append(child)
		result.append_array(_all_descendants(child))
	return result



func _refresh_node_label():
	if loaded_node:
		node_label.text = "Editing: " + loaded_node.name
	else:
		node_label.text = "Select a BaseObj node to edit."

func _refresh_limb_list():
	limb_list.clear()
	var names = limb_data.keys()
	for n in names:
		limb_list.add_item(n)
	
	if selected_limb in names:
		var idx = names.find(selected_limb)
		limb_list.select(idx)
	elif names.size() > 0:
		selected_limb = names[0]
		limb_list.select(0)
	else:
		selected_limb = ""

func _refresh_sprite_grid():
	
	
	
	for child in sprite_row.get_children():
		sprite_row.remove_child(child)
		child.queue_free()
	sprite_count_label.text = "Sprites (%d)" % unique_textures.size()
	for tex in unique_textures:
		
		
		var panel: = PanelContainer.new()
		panel.add_stylebox_override("panel", _make_sprite_panel_style(false))
		var btn: = TextureButton.new()
		btn.texture_normal = tex
		btn.expand = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.rect_min_size = Vector2(48, 48)
		btn.toggle_mode = true
		
		btn.focus_mode = Control.FOCUS_NONE
		var path = tex.resource_path if tex.resource_path else "(unsaved)"
		btn.hint_tooltip = path.get_file()
		if manual_textures.has(tex):
			btn.hint_tooltip += "\n(manually added)"
		btn.connect("pressed", self, "_on_sprite_picked", [tex])
		panel.add_child(btn)
		sprite_row.add_child(panel)
	_update_sprite_button_states()

func _make_sprite_panel_style(selected: bool) -> StyleBoxFlat:
	var sb: = StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	
	
	sb.set_border_width_all(2)
	if selected:
		sb.border_color = Color(1.0, 0.85, 0.2)
	else:
		sb.border_color = Color(0, 0, 0, 0)
	return sb

func _update_sprite_button_states():
	var i: = 0
	for tex in unique_textures:
		if i >= sprite_row.get_child_count():
			break
		var panel = sprite_row.get_child(i)
		var btn = panel.get_child(0)
		var is_selected = (tex == selected_texture)
		btn.pressed = is_selected
		
		var entry = (limb_data[selected_limb][tex]
				if selected_limb != "" and limb_data.has(selected_limb) and limb_data[selected_limb].has(tex)
				else null)
		if entry != null and entry.get("absent", false):
			btn.modulate = Color(0.7, 0.55, 0.55)
		elif entry != null:
			btn.modulate = Color(0.6, 1.0, 0.6)
		elif manual_textures.has(tex):
			btn.modulate = Color(0.85, 0.9, 1.0)
		else:
			btn.modulate = Color(1, 1, 1)
		panel.add_stylebox_override("panel", _make_sprite_panel_style(is_selected))
		i += 1
	remove_sprite_button.disabled = (selected_texture == null
			or not manual_textures.has(selected_texture))

func _pick_default_selection():
	if not selected_texture or unique_textures.find(selected_texture) == - 1:
		selected_texture = unique_textures[0] if unique_textures.size() > 0 else null

func _input(event):
	if not is_visible_in_tree():
		return
	if not (event is InputEventKey) or not event.pressed:
		return
	
	
	
	var focused = get_focus_owner()
	if focused == null or not is_a_parent_of(focused):
		return
	
	if focused is LineEdit or focused is TextEdit:
		return
	if loaded_node == null:
		return
	
	var nudge = Vector2()
	match event.scancode:
		KEY_LEFT: nudge = Vector2( - 1, 0)
		KEY_RIGHT: nudge = Vector2(1, 0)
		KEY_UP: nudge = Vector2(0, - 1)
		KEY_DOWN: nudge = Vector2(0, 1)
	if nudge != Vector2():
		_nudge_active_limb(nudge)
		get_tree().set_input_as_handled()
		return
	
	if event.echo or unique_textures.size() == 0:
		return
	if event.scancode == KEY_SPACE:
		var idx = unique_textures.find(selected_texture)
		idx = (idx + 1) % unique_textures.size()
		selected_texture = unique_textures[idx]
		_update_sprite_button_states()
		_refresh_canvas()
		get_tree().set_input_as_handled()
	elif event.scancode == KEY_V:
		if event.shift:
			_paste_all_from_prev_sprite()
		else:
			_paste_limb_from_prev_sprite()
		get_tree().set_input_as_handled()

func _nudge_active_limb(delta: Vector2):
	if selected_limb == "" or selected_texture == null:
		return
	var entry = _get_entry(selected_limb, selected_texture)
	if entry == null:
		return
	if entry is Dictionary and entry.get("absent", false):
		return
	var new_entry = entry.duplicate(true)
	new_entry["x"] = int(new_entry.get("x", 0)) + int(delta.x)
	new_entry["y"] = int(new_entry.get("y", 0)) + int(delta.y)
	var prev = _entry_snapshot(selected_limb, selected_texture)
	_commit_entry_change(selected_limb, selected_texture, new_entry, prev, 
			"Nudge limb '%s'" % selected_limb)

func _prev_texture():
	if unique_textures.size() < 2 or selected_texture == null:
		return null
	var idx = unique_textures.find(selected_texture)
	if idx == - 1:
		return null
	var prev_idx = (idx - 1 + unique_textures.size()) % unique_textures.size()
	return unique_textures[prev_idx]

func _paste_limb_from_prev_sprite():
	if selected_limb == "" or selected_texture == null:
		return
	var prev_tex = _prev_texture()
	if prev_tex == null:
		return
	if not limb_data.has(selected_limb) or not limb_data[selected_limb].has(prev_tex):
		return
	var src = limb_data[selected_limb][prev_tex]
	if not (src is Dictionary):
		return
	var prev_entry = _entry_snapshot(selected_limb, selected_texture)
	_commit_entry_change(selected_limb, selected_texture, src.duplicate(true), 
			prev_entry, "Paste limb '%s' from prev sprite" % selected_limb)

func _paste_all_from_prev_sprite():
	if selected_texture == null:
		return
	var prev_tex = _prev_texture()
	if prev_tex == null:
		return
	var entries: = {}
	for name in limb_data:
		if limb_data[name].has(prev_tex):
			var e = limb_data[name][prev_tex]
			if e is Dictionary:
				entries[name] = e.duplicate(true)
	if entries.empty():
		return
	var tex = selected_texture
	var old_state: = {}
	for name in entries:
		old_state[name] = (limb_data[name][tex].duplicate(true)
				if limb_data.has(name) and limb_data[name].has(tex)
				else null)
	var ur = _undo_redo()
	if ur:
		ur.create_action("Paste all limbs from prev sprite")
		ur.add_do_method(self, "_apply_paste_all", entries, tex)
		ur.add_undo_method(self, "_apply_paste_all_state", old_state, tex)
		ur.commit_action()
	else:
		_apply_paste_all(entries, tex)

func _refresh_canvas():
	canvas.clear()
	if not selected_texture:
		canvas.texture = null
		sprite_label.text = "(no sprite)"
		coord_label.text = ""
		flipped_check.set_pressed_no_signal(false)
		flipped_check.disabled = true
		absent_check.set_pressed_no_signal(false)
		absent_check.disabled = true
		clear_button.disabled = true
		return
	canvas.texture = selected_texture
	sprite_label.text = selected_texture.resource_path.get_file() if selected_texture.resource_path else "(unsaved texture)"
	
	var entry = _get_entry(selected_limb, selected_texture)
	var is_absent = entry != null and entry.get("absent", false)
	absent_check.disabled = (selected_limb == "")
	absent_check.set_pressed_no_signal(is_absent)
	flipped_check.disabled = (selected_limb == "" or entry == null or is_absent)
	clear_button.disabled = (selected_limb == "" or entry == null)
	if entry and not is_absent:
		canvas.set_active(Vector2(entry.x, entry.y), Vector2(entry.dir_x, entry.dir_y))
		flipped_check.set_pressed_no_signal(entry.get("flipped", false))
		coord_label.text = "x=%d y=%d  dir=(%.2f, %.2f)  flipped=%s" % [
			entry.x, entry.y, entry.dir_x, entry.dir_y, str(entry.get("flipped", false))]
	elif is_absent:
		canvas.set_active(null, null)
		flipped_check.set_pressed_no_signal(false)
		coord_label.text = "marked absent on this sprite"
	else:
		canvas.set_active(null, null)
		flipped_check.set_pressed_no_signal(false)
		coord_label.text = "no data on this sprite"
	
	var others: = {}
	for name in limb_data:
		if name == selected_limb:
			continue
		var by_tex = limb_data[name]
		if by_tex.has(selected_texture):
			var e = by_tex[selected_texture]
			others[name] = {
				"pos": Vector2(e.x, e.y), 
				"dir": Vector2(e.dir_x, e.dir_y), 
			}
	canvas.set_others(others)

func _get_entry(limb_name: String, tex: Texture):
	if not limb_data.has(limb_name):
		return null
	if not limb_data[limb_name].has(tex):
		return null
	return limb_data[limb_name][tex]



func _on_add_limb_pressed():
	_add_limb(new_limb_edit.text)

func _on_new_limb_submitted(text):
	_add_limb(text)

func _add_limb(name: String):
	name = name.strip_edges()
	if name == "" or limb_data.has(name):
		return
	var ur = _undo_redo()
	if ur:
		ur.create_action("Add limb '%s'" % name)
		ur.add_do_method(self, "_apply_add_limb", name)
		ur.add_undo_method(self, "_apply_remove_limb", name, {})
		ur.commit_action()
	else:
		_apply_add_limb(name)
	new_limb_edit.text = ""

func _apply_add_limb(name: String):
	limb_data[name] = {}
	selected_limb = name
	_save_data_to_node()
	_refresh_limb_list()
	_update_sprite_button_states()
	_refresh_canvas()

func _on_remove_limb_pressed():
	if selected_limb == "" or not limb_data.has(selected_limb):
		return
	var name = selected_limb
	var snapshot = limb_data[name].duplicate(true)
	var ur = _undo_redo()
	if ur:
		ur.create_action("Remove limb '%s'" % name)
		ur.add_do_method(self, "_apply_remove_limb", name, {})
		ur.add_undo_method(self, "_apply_add_limb_with_data", name, snapshot)
		ur.commit_action()
	else:
		_apply_remove_limb(name, {})

func _apply_remove_limb(name: String, _ignored):
	if limb_data.has(name):
		limb_data.erase(name)
	if selected_limb == name:
		selected_limb = ""
	_save_data_to_node()
	_refresh_limb_list()
	_update_sprite_button_states()
	_refresh_canvas()

func _apply_add_limb_with_data(name: String, data: Dictionary):
	limb_data[name] = data.duplicate(true)
	selected_limb = name
	_save_data_to_node()
	_refresh_limb_list()
	_update_sprite_button_states()
	_refresh_canvas()

func _on_limb_selected(idx):
	selected_limb = limb_list.get_item_text(idx)
	_update_sprite_button_states()
	_refresh_canvas()



func _on_sprite_picked(tex: Texture):
	selected_texture = tex
	_update_sprite_button_states()
	_refresh_canvas()

func _on_add_sprite_pressed():
	if not loaded_node:
		return
	add_sprite_dialog.popup_centered_ratio(0.6)

func _on_extra_sprite_selected(path):
	if not loaded_node:
		return
	var tex = load(path)
	if not (tex is Texture):
		push_warning("Limb Finder: file at %s is not a Texture" % path)
		return
	
	for existing in unique_textures:
		if existing == tex:
			return
	var extras = _get_extras().duplicate()
	extras.append(tex)
	var ur = _undo_redo()
	if ur:
		ur.create_action("Add sprite '%s'" % path.get_file())
		ur.add_do_method(self, "_apply_set_extras", extras, tex)
		ur.add_undo_method(self, "_apply_set_extras", _get_extras().duplicate(), selected_texture)
		ur.commit_action()
	else:
		_apply_set_extras(extras, tex)

func _on_remove_sprite_pressed():
	if not selected_texture or not manual_textures.has(selected_texture):
		return
	var to_remove = selected_texture
	var old_extras = _get_extras().duplicate()
	var new_extras = []
	for t in old_extras:
		if t != to_remove:
			new_extras.append(t)
	var ur = _undo_redo()
	if ur:
		ur.create_action("Remove sprite")
		ur.add_do_method(self, "_apply_set_extras", new_extras, null)
		ur.add_undo_method(self, "_apply_set_extras", old_extras, to_remove)
		ur.commit_action()
	else:
		_apply_set_extras(new_extras, null)

func _apply_set_extras(extras: Array, focus_texture):
	_save_extras(extras)
	_collect_unique_textures()
	if focus_texture and unique_textures.find(focus_texture) != - 1:
		selected_texture = focus_texture
	else:
		_pick_default_selection()
	_refresh_sprite_grid()
	_refresh_canvas()



func _on_limb_set(pos: Vector2, dir: Vector2):
	if selected_limb == "" or selected_texture == null:
		return
	var prev = _entry_snapshot(selected_limb, selected_texture)
	var flipped = prev.get("flipped", false) if prev != null else false
	var new_entry = {
		"x": int(pos.x), 
		"y": int(pos.y), 
		"dir_x": dir.x, 
		"dir_y": dir.y, 
		"flipped": flipped, 
	}
	_commit_entry_change(selected_limb, selected_texture, new_entry, prev, "Set limb '%s'" % selected_limb)

func _on_clear_pressed():
	if selected_limb == "" or selected_texture == null:
		return
	var prev = _entry_snapshot(selected_limb, selected_texture)
	if prev == null:
		return
	var ur = _undo_redo()
	if ur:
		ur.create_action("Clear limb '%s'" % selected_limb)
		ur.add_do_method(self, "_apply_clear", selected_limb, selected_texture)
		ur.add_undo_method(self, "_apply_entry", selected_limb, selected_texture, prev)
		ur.commit_action()
	else:
		_apply_clear(selected_limb, selected_texture)

func _apply_clear(limb_name: String, tex: Texture):
	if limb_data.has(limb_name) and limb_data[limb_name].has(tex):
		limb_data[limb_name].erase(tex)
	_save_data_to_node()
	_update_sprite_button_states()
	_refresh_canvas()



func _on_copy_limb_pressed():
	if selected_limb == "" or selected_texture == null:
		return
	var entry = _get_entry(selected_limb, selected_texture)
	if entry == null:
		clipboard_entries.clear()
		return
	clipboard_entries = {selected_limb: entry.duplicate(true)}

func _on_paste_limb_pressed():
	if selected_limb == "" or selected_texture == null or clipboard_entries.empty():
		return
	
	
	var src
	if clipboard_entries.has(selected_limb):
		src = clipboard_entries[selected_limb]
	elif clipboard_entries.size() == 1:
		src = clipboard_entries.values()[0]
	else:
		return
	var prev = _entry_snapshot(selected_limb, selected_texture)
	_commit_entry_change(selected_limb, selected_texture, src.duplicate(true), prev, 
			"Paste limb '%s'" % selected_limb)

func _on_copy_all_pressed():
	if selected_texture == null:
		return
	clipboard_entries.clear()
	for name in limb_data:
		if limb_data[name].has(selected_texture):
			var e = limb_data[name][selected_texture]
			if e is Dictionary:
				clipboard_entries[name] = e.duplicate(true)

func _on_paste_all_pressed():
	if selected_texture == null or clipboard_entries.empty():
		return
	var tex = selected_texture
	var old_state: = {}
	for name in clipboard_entries:
		old_state[name] = (limb_data[name][tex].duplicate(true)
				if limb_data.has(name) and limb_data[name].has(tex)
				else null)
	var ur = _undo_redo()
	if ur:
		ur.create_action("Paste all limbs")
		ur.add_do_method(self, "_apply_paste_all", clipboard_entries.duplicate(true), tex)
		ur.add_undo_method(self, "_apply_paste_all_state", old_state, tex)
		ur.commit_action()
	else:
		_apply_paste_all(clipboard_entries.duplicate(true), tex)

func _apply_paste_all(entries: Dictionary, tex: Texture):
	for name in entries:
		if not limb_data.has(name):
			limb_data[name] = {}
		limb_data[name][tex] = entries[name].duplicate(true)
	_save_data_to_node()
	_update_sprite_button_states()
	_refresh_canvas()

func _apply_paste_all_state(state: Dictionary, tex: Texture):
	for name in state:
		var entry = state[name]
		if entry == null:
			if limb_data.has(name) and limb_data[name].has(tex):
				limb_data[name].erase(tex)
		else:
			if not limb_data.has(name):
				limb_data[name] = {}
			limb_data[name][tex] = entry.duplicate(true)
	_save_data_to_node()
	_update_sprite_button_states()
	_refresh_canvas()

func _on_flipped_toggled(pressed):
	if selected_limb == "" or selected_texture == null:
		return
	var entry = _get_entry(selected_limb, selected_texture)
	if entry == null:
		entry = {"x": 0, "y": 0, "dir_x": 0.0, "dir_y": 0.0, "flipped": false}
	if entry.get("flipped", false) == pressed:
		return
	var prev = _entry_snapshot(selected_limb, selected_texture)
	var new_entry = entry.duplicate(true)
	new_entry["flipped"] = pressed
	_commit_entry_change(selected_limb, selected_texture, new_entry, prev, "Toggle flip '%s'" % selected_limb)

func _on_absent_toggled(pressed):
	if selected_limb == "" or selected_texture == null:
		return
	var entry = _get_entry(selected_limb, selected_texture)
	var currently_absent = entry != null and entry.get("absent", false)
	if currently_absent == pressed:
		return
	var prev = _entry_snapshot(selected_limb, selected_texture)
	var new_entry
	if pressed:
		new_entry = {"absent": true}
	else:
		
		new_entry = null
	if new_entry == null:
		var ur = _undo_redo()
		if ur:
			ur.create_action("Mark limb '%s' present" % selected_limb)
			ur.add_do_method(self, "_apply_clear", selected_limb, selected_texture)
			ur.add_undo_method(self, "_apply_entry", selected_limb, selected_texture, prev)
			ur.commit_action()
		else:
			_apply_clear(selected_limb, selected_texture)
	else:
		_commit_entry_change(selected_limb, selected_texture, new_entry, prev, "Mark limb '%s' absent" % selected_limb)



func _entry_snapshot(limb_name, tex):
	var e = _get_entry(limb_name, tex)
	if e == null:
		return null
	return e.duplicate(true)

func _commit_entry_change(limb_name: String, tex: Texture, new_entry, old_entry, label: String):
	var ur = _undo_redo()
	if ur:
		ur.create_action(label)
		ur.add_do_method(self, "_apply_entry", limb_name, tex, new_entry)
		ur.add_undo_method(self, "_apply_entry", limb_name, tex, old_entry)
		ur.commit_action()
	else:
		_apply_entry(limb_name, tex, new_entry)

func _apply_entry(limb_name: String, tex: Texture, entry):
	if not limb_data.has(limb_name):
		limb_data[limb_name] = {}
	if entry == null:
		if limb_data[limb_name].has(tex):
			limb_data[limb_name].erase(tex)
	else:
		limb_data[limb_name][tex] = entry.duplicate(true)
	_save_data_to_node()
	_update_sprite_button_states()
	_refresh_canvas()

func _undo_redo():
	if editor_plugin:
		return editor_plugin.get_undo_redo()
	return null
