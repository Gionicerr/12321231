tool
extends TextureRect

signal limb_set(pos, dir)


var active_pos = null

var active_dir = null

var other_limbs = {}


var dragging = false
var drag_start = Vector2()
var drag_current = Vector2()

func _ready():
	
	focus_mode = Control.FOCUS_ALL

func clear():
	active_pos = null
	active_dir = null
	dragging = false
	update()

func set_active(pos, dir):
	active_pos = pos
	active_dir = dir
	dragging = false
	update()

func set_others(limbs):
	other_limbs = limbs
	update()

func _draw():
	if not texture:
		return
	var scale = _scale()
	
	for name in other_limbs:
		var entry = other_limbs[name]
		var p = entry.pos * scale
		draw_circle(p, 4, Color(0.2, 0.2, 0.2, 0.6))
		draw_circle(p, 3, Color(0.6, 0.6, 1.0, 0.6))
		if entry.has("dir") and entry.dir != Vector2():
			draw_line(p, p + entry.dir.normalized() * 14, Color(0.6, 0.6, 1.0, 0.6), 1.5)
	
	var draw_pos = null
	var draw_dir = null
	if dragging:
		draw_pos = drag_start
		var diff = drag_current - drag_start
		if diff.length() > 1:
			draw_dir = diff.normalized()
	elif active_pos != null:
		draw_pos = active_pos * scale
		if active_dir != null and active_dir != Vector2():
			draw_dir = active_dir.normalized()
	if draw_pos != null:
		draw_circle(draw_pos, 5, Color.black)
		draw_circle(draw_pos, 4, Color.red)
		if draw_dir != null:
			draw_line(draw_pos, draw_pos + draw_dir * 22, Color.black, 2.0)
			draw_line(draw_pos, draw_pos + draw_dir * 22, Color.yellow, 1.0)


func _scale():
	if not texture:
		return 1.0
	var ts = texture.get_size()
	if ts.x == 0:
		return 1.0
	return rect_size.x / ts.x

const SHIFT_SNAP_STEP = PI / 16

func _snap_to_angle(diff: Vector2) -> Vector2:
	if diff.length() < 2:
		return diff
	var snapped_angle = round(diff.angle() / SHIFT_SNAP_STEP) * SHIFT_SNAP_STEP
	return Vector2.RIGHT.rotated(snapped_angle) * diff.length()

func _gui_input(event):
	if not texture:
		return
	var scale = _scale()
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if event.pressed:
			
			
			grab_focus()
			dragging = true
			drag_start = event.position
			drag_current = event.position
			update()
		else:
			if not dragging:
				return
			dragging = false
			
			var tex_pos = drag_start / scale
			var tex_pos_floor = Vector2(floor(tex_pos.x), floor(tex_pos.y))
			
			var diff = event.position - drag_start
			if event.shift:
				diff = _snap_to_angle(diff)
			var dir
			if diff.length() < 2:
				dir = Vector2()
			else:
				dir = diff.normalized()
			emit_signal("limb_set", tex_pos_floor, dir)
	elif event is InputEventMouseMotion and dragging:
		drag_current = event.position
		
		
		if event.shift:
			drag_current = drag_start + _snap_to_angle(drag_current - drag_start)
		update()
