tool

extends Control
const NUM_LINES = 100
const LINE_MIN_SIZE = 20
const LINE_MAX_SIZE = 200
const TICK_DIV = 100.0
const SPEED = 1
const CAMERA_SPEED_DIVISOR = 16.0
const MIN_INTENSITY = 0.05






const INTENSITY_LERP_AT_60HZ = 0.95



const SUSTAINED_TARGET_THRESHOLD = 0.5





const SUSTAINED_TIME_THRESHOLD = 0.05









const VERTICAL_SPEED_BOOST = 0.0





const CHARACTER_FADE_RADIUS_X = 350.0
const CHARACTER_FADE_RADIUS_Y = 250.0






const LOW_SPEED_VISIBILITY = 0.25




const MIN_DRAW_INTENSITY = 0.01




export var dir = Vector2()
export var intensity = 0.0
export var noise: OpenSimplexNoise
export var noise2: OpenSimplexNoise
export var on = false
export (float, EASE) var intensity_easing = 0
var speed = 0.0








var _smoothed_target = 0.0




var _sustained_above = 0.0



var _last_dt = 1.0 / 60.0
var center = Vector2(320, 180)





var p1_anchor = Vector2(320, 180)
var p2_anchor = Vector2(320, 180)
var tick = 0

func set_direction(dir):
	self.dir = - dir

func set_player_anchors(p1: Vector2, p2: Vector2):
	p1_anchor = p1
	p2_anchor = p2

func set_speed(speed):
	
	
	
	
	
	
	var t = 1.0 - pow(1.0 - INTENSITY_LERP_AT_60HZ, _last_dt * 60.0)
	
	
	
	
	var verticality = abs(dir.y) if dir.length_squared() > 0.0 else 0.0
	var boosted_speed = abs(speed) * (1.0 + VERTICAL_SPEED_BOOST * verticality)
	var target = clamp(boosted_speed / CAMERA_SPEED_DIVISOR, MIN_INTENSITY, 1.0)
	_smoothed_target = lerp(_smoothed_target, target, t)
	intensity = _smoothed_target * _smoothed_target
	
	
	
	if target >= SUSTAINED_TARGET_THRESHOLD:
		_sustained_above = min(_sustained_above + _last_dt, SUSTAINED_TIME_THRESHOLD * 2.0)
	else:
		_sustained_above = max(_sustained_above - _last_dt, 0.0)
	self.speed = speed


func get_line_x(num):
	var t = tick / TICK_DIV * speed
	return noise.get_noise_2d(num, t) * 6400

func get_line_y(num):
	var t = tick / TICK_DIV * speed
	return noise2.get_noise_2d(num, t) * 3600

func get_variation(num):
	return noise2.get_noise_1d(num)

func _process(delta):
	
	
	
	_last_dt = delta
	update()

func _physics_process(delta):
	tick += 1

func _draw():

	if on and intensity > MIN_DRAW_INTENSITY and Global.speed_lines_enabled:
		dir = dir.normalized()
		
		
		
		
		
		
		var sustain_factor = lerp(LOW_SPEED_VISIBILITY, 1.0, clamp(_sustained_above / SUSTAINED_TIME_THRESHOLD, 0.0, 1.0))
		for i in range(NUM_LINES):
			var variation = get_variation(NUM_LINES - i)

			var x = get_line_x(i)
			var y = get_line_y(i)

			var pos = Vector2(x, y) + (tick * dir * (speed * abs(intensity)))
			pos.x = fposmod(pos.x, 640)
			pos.y = fposmod(pos.y, 360)
			
			
			
			
			
			
			
			var dx1 = abs(pos.x - p1_anchor.x) / CHARACTER_FADE_RADIUS_X
			var dy1 = abs(pos.y - p1_anchor.y) / CHARACTER_FADE_RADIUS_Y
			var dx2 = abs(pos.x - p2_anchor.x) / CHARACTER_FADE_RADIUS_X
			var dy2 = abs(pos.y - p2_anchor.y) / CHARACTER_FADE_RADIUS_Y
			var s = min(Vector2(dx1, dy1).length(), Vector2(dx2, dy2).length())
			var line_intensity = intensity * variation * ease(s, intensity_easing) * sustain_factor
			var line_size = lerp(LINE_MIN_SIZE, LINE_MAX_SIZE, line_intensity)
			var start = pos - dir * line_size / 2.0
			var end = pos + dir * line_size / 2.0
	
			var color = Color.white
			color.a = max(line_intensity, 0)
			draw_line(start, end, color, 1.5 + line_intensity)
