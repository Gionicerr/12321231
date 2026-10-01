extends Node

signal nag_window()

var VERSION = "1.9.106-steam-unstable"
const RESOLUTION = Vector2(640, 360)

const STYLE_SAVE_FEATURE_ENABLED = true






const MOD_DISABLE_VERSIONS = ["1.10.0"]




var mods_disabled_by_version_transition = false

var audio_player
var music_enabled = true
var master_value = 1.0
var fx_value = 1.0
var ui_value = 1.0
var music_value = 1.0
var freeze_ghost_prediction = true
var freeze_ghost_sound = true
var ghost_afterimages = true
var fullscreen = false
var cap_framerate = true
var vsync = true





const XY_SNAP_TOGGLE_ENABLED = false
var xyplot_invert_snap = false
var show_hitboxes = false
var show_extra_info = false
var light_mode = false
var frame_advance = false
var show_playback_controls = false



var playback_hotkeys_require_window = true
var show_projectile_owners = true
var playback_speed_mod = 1
var default_dojo = 0
var current_game = null
var css_open = false
var has_supporter_pack_file = false
var enable_custom_colors = true
var enable_custom_particles = true
var enable_custom_hit_sparks = true
var enable_emotes = true
var enable_timer_sound = true
var steam_demo_version = false
var show_last_move_indicators = true
var show_community_events = true
var speed_lines_enabled = true
var replay_extra_freeze_frames = true
var enable_replay_backups = true
var seen_custom_character_nag = false
var forfeit_buttons_enabled = false
var show_health_count = false


var show_next_turn_info_hud = false



var show_next_turn_info_on_chars = true
var auto_fc = true
var ghost_speed = 2
var allow_save_default = true






var custom_name = ""
var name_hue = 0.0
var name_saturation = 0.5




var name_color_customized = false





var lobby_busy_mode = false




const REPLAY_VERSION_MODES = ["all", "warn", "same"]
var replay_version_mode = "warn"



var blocked_users: = []

var winws_detected = false




var ui_hidden = false

var active_sfx_overrides = {}

var mods_loaded = false
var loading_character = ""

var mouse_world_position = Vector2()
var rng = BetterRng.new()

var name_paths = {
	"Ninja": "res://characters/stickman/NinjaGuy.tscn", 
	"Cowboy": "res://characters/swordandgun/SwordGuy.tscn", 
	"Wizard": "res://characters/wizard/Wizard.tscn", 
	"Robot": "res://characters/robo/Robot.tscn", 
	"Mutant": "res://characters/mutant/Mutant.tscn", 

}

var songs = {
	"bg1": preload("res://sound/music/bg1.mp3")
}

var character_select_node = null

var characters_cache = {}

func get_cached_character(name):
	return characters_cache[name]

func full_version():
	return ( not steam_demo_version) and SteamHustle.STARTED

func world_to_screen(x, y) -> Vector2:
	if not is_instance_valid(current_game):
		return Vector2()
	return Vector2()

func screen_to_world(xy: Vector2):
	if not is_instance_valid(current_game):
		return xy
	var camera = current_game.camera
	var viewport_size = current_game.get_viewport_rect().size
	
	
	
	
	return (xy - viewport_size / 2) * camera.zoom + camera.get_camera_screen_center()

func screen_to_world_int(xy: Vector2):
	return {
		"x": int(xy.x), 
		"y": int(xy.y)
	}

func winws_check():
	if _is_winws_active():
		winws_active_message()
		winws_detected = true
	return winws_detected

func _enter_tree():
	if _is_winws_active():
		winws_active_message()
		winws_detected = true
	var invalid_characters = []
	for char_name in name_paths:
		var character = load(name_paths[char_name])
		if not character:
			invalid_characters.append(char_name)
			continue
		characters_cache[char_name] = character
	for character in invalid_characters:
		name_paths.erase(character)

	steam_demo_version = "steam" in VERSION and "beta" in VERSION
	audio_player = AudioStreamPlayer.new()
	call_deferred("add_child", audio_player)
	audio_player.bus = "Music"
	
	var data = get_player_data()
	for key in data.options:
		set(key, data.options[key])





	randomize()
	rng.randomize()
	set_music_enabled(music_enabled)
	set_fullscreen(fullscreen)
	set_cap_framerate(cap_framerate)
	set_vsync(vsync)





func get_ghost_speed_modifier():
	if ghost_speed == 1:
		return 0.25
	
	
	
	
	if ghost_speed == 5:
		return 0.5
	if ghost_speed > 1:
		return float(ghost_speed - 1)

func get_playback_speed_factor() -> float:
	if playback_speed_mod == - 1:
		return 0.75
	elif playback_speed_mod > 0:
		return 1.0 / playback_speed_mod
	return 1.0

func _ready():
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	if randi() % 50 == 0 and not SteamHustle.STARTED:
		emit_signal("nag_window")

func winws_active_message():
		OS.alert("""[EN]
The \"winws\" process has been detected running on your machine.
This process and several pieces of software using it (such as \"zapret\" and its variations) are known to crash Steam lobbies and cause major interruptions in online play.
Until a proper fix is found, please refrain from joining multiplayer lobbies with any software using \"winws\" while it is running. Thank you.

[RU]
На вашем компьютере обнаружен запущенный процесс \"winws\".
Известно, что этот процесс и несколько программ, использующих его (например, \"zapret\" и его вариации), приводят к сбоям в работе лобби Steam и серьезным перебоям в сетевой игре.
Пока не будет найдено надлежащее исправление, пожалуйста, воздержитесь от присоединения к многопользовательским лобби с любым программным обеспечением, использующим \"winws\", пока оно запущено. Спасибо.""", "Winws detected")

func _is_winws_active() -> bool:
	var winws_active = false
	if OS.get_name() == "Windows":
		var output = []
		
		OS.execute("powershell.exe", ["/C", "get-process winws | measure-object -line | select Lines -expandproperty Lines"], true, output)
		var result = output[0].to_int()
		winws_active = result > 0
		print("Number of winws processes: " + str(result))
	return winws_active

func set_music_enabled(on):
	music_enabled = on
	if on:
		play_random_song()
	else:
		audio_player.stop()

func play_random_song():
	play_song(rng.choose(songs.keys()))

func has_supporter_pack():
	return true

func set_playback_controls(on):
	show_playback_controls = on
	save_options()
	
func set_fullscreen(on):
	fullscreen = on
	if fullscreen:
		OS.window_fullscreen = true
		OS.window_borderless = true
	else:
		OS.window_fullscreen = false
		OS.window_borderless = false
	save_options()

func set_cap_framerate(on):
	cap_framerate = on
	Engine.target_fps = 60 if on else 0
	save_options()

func set_vsync(on):
	vsync = on
	OS.vsync_enabled = on
	save_options()

func set_hitboxes(on):
	show_hitboxes = on
	save_options()

func play_song(song_name):
	audio_player.stream = songs[song_name]
	audio_player.play()

func add_dir_contents(dir: Directory, files: Array, directories: Array, recursive: bool = true, extension: String = "", full_path = true):
	var file_name = dir.get_next()

	while (file_name != ""):
		var path = dir.get_current_dir().plus_file(file_name) if full_path else file_name
		
		if dir.current_is_dir():
			if recursive:

				var subDir = Directory.new()
				subDir.open(path)
				subDir.list_dir_begin(true, false)
				directories.append(path)
				add_dir_contents(subDir, files, directories)
		else:

			if extension == "" or path.ends_with(extension):
				files.append(path)

		file_name = dir.get_next()

	dir.list_dir_end()

func save_username(username: String):
	save_player_data({"username": username})




func get_display_name(fallback: String = "") -> String:
	return custom_name if custom_name != "" else fallback





func has_name_color() -> bool:
	return name_color_customized

func get_name_color() -> Color:
	return Color.from_hsv(name_hue, name_saturation, 1.0)




func publish_name_color():
	if SteamLobby.LOBBY_ID == 0:
		return
	var hex = get_name_color().to_html(false) if has_name_color() else ""
	Steam.setLobbyMemberData(SteamLobby.LOBBY_ID, "name_color", hex)





func get_remote_name_color(steam_id):
	if steam_id == SteamHustle.STEAM_ID:
		return get_name_color() if has_name_color() else null
	if SteamLobby.LOBBY_ID == 0:
		return null
	var hex = Steam.getLobbyMemberData(SteamLobby.LOBBY_ID, steam_id, "name_color")
	if hex == "":
		return null
	return Color("#" + hex)

func save_option(value, option):
	set(option, value)
	save_options()

func set_light_mode(on):
	light_mode = on
	save_options()

func save_options():
	save_player_data({
		"options": {
			"music_enabled": music_enabled, 
			"freeze_ghost_prediction": freeze_ghost_prediction, 
			"freeze_ghost_sound": freeze_ghost_sound, 
			"ghost_afterimages": ghost_afterimages, 
			"ghost_speed": ghost_speed, 
			"fullscreen": fullscreen, 
			"cap_framerate": cap_framerate, 
			"vsync": vsync, 
			"xyplot_invert_snap": xyplot_invert_snap, 
			"show_hitboxes": show_hitboxes, 
			"show_last_move_indicators": show_last_move_indicators, 
			"show_community_events": show_community_events, 
			"show_playback_controls": show_playback_controls, 
			"playback_hotkeys_require_window": playback_hotkeys_require_window, 
			"show_projectile_owners": show_projectile_owners, 
			"enable_timer_sound": enable_timer_sound, 
			"default_dojo": 0, 
			"show_extra_info": show_extra_info, 

			"enable_emotes": enable_emotes, 
			"enable_custom_colors": enable_custom_colors, 
			"enable_custom_particles": enable_custom_particles, 
			"enable_custom_hit_sparks": enable_custom_hit_sparks, 
			"speed_lines_enabled": speed_lines_enabled, 
			"auto_fc": auto_fc, 
			"replay_extra_freeze_frames": replay_extra_freeze_frames, 
			"enable_replay_backups": enable_replay_backups, 
			"seen_custom_character_nag": seen_custom_character_nag, 

			"master_value": master_value, 
			"fx_value": fx_value, 
			"ui_value": ui_value, 
			"music_value": music_value, 
			"allow_save_default": allow_save_default, 
			"replay_version_mode": replay_version_mode, 
			"blocked_users": blocked_users, 
			"custom_name": custom_name, 
			"name_hue": name_hue, 
			"name_saturation": name_saturation, 
			"name_color_customized": name_color_customized, 
			"show_health_count": show_health_count, 
			"show_next_turn_info_hud": show_next_turn_info_hud, 
			"show_next_turn_info_on_chars": show_next_turn_info_on_chars, 
		}
	})

func get_default_player_data():
	return {
		"username": "", 
		"last_style": "", 
		"last_game_format": "", 
		
		
		
		
		"opened_mod_sensitive_versions": [], 
		"options": {
			"music_enabled": true, 
			"freeze_ghost_prediction": true, 
			"freeze_ghost_sound": true, 
			"ghost_afterimages": true, 
			"fullscreen": false, 
			"cap_framerate": true, 
			"vsync": true, 
			"xyplot_invert_snap": false, 
			"ghost_speed": 2, 
			"show_hitboxes": false, 
			"show_last_move_indicators": true, 
			"show_playback_controls": false, 
			"playback_hotkeys_require_window": true, 
			"default_dojo": 0, 
			"enable_timer_sound": true, 
			"enable_emotes": true, 
			"enable_custom_colors": true, 
			"enable_custom_particles": true, 
			"enable_custom_hit_sparks": true, 
			"show_projectile_owners": true, 
			"speed_lines_enabled": true, 
			"auto_fc": true, 
			"show_extra_info": false, 
			"replay_extra_freeze_frames": true, 
			"enable_replay_backups": true, 
			"seen_custom_character_nag": false, 

			"master_value": 1.0, 
			"fx_value": 1.0, 
			"ui_value": 1.0, 
			"music_value": 1.0, 
			"allow_save_default": true, 
			"replay_version_mode": "warn", 
			"blocked_users": [], 
			"custom_name": "", 
			"name_hue": 0.0, 
			"name_saturation": 0.5, 
			"name_color_customized": false, 
			"show_health_count": false, 
			"show_community_events": true, 
			"show_next_turn_info_hud": false, 
			"show_next_turn_info_on_chars": true, 
		}
	}

func get_player_data():
	var file = File.new()
	var default_data = get_default_player_data()
	if not file.file_exists("user://playerdata.json"):
		save_player_data(default_data)
		return default_data
	file.open("user://playerdata.json", File.READ)
	var data = parse_json(file.get_as_text())
	file.close()
	
	
	
	
	if not (data is Dictionary):
		return default_data
	for key in default_data:
		if not (key in data):
			data[key] = default_data[key]
	return data

func save_player_data(data: Dictionary):
	var file = File.new()
	var existing_data = get_default_player_data()
	if file.file_exists("user://playerdata.json"):
		file.open("user://playerdata.json", File.READ)
		var loaded = parse_json(file.get_as_text())
		file.close()
		if loaded is Dictionary:
			existing_data = loaded
	for key in data:
		existing_data[key] = data[key]
	
	
	
	var tmp_path = "user://playerdata.json.%d.tmp" % OS.get_process_id()
	file.open(tmp_path, File.WRITE)
	file.store_string(JSON.print(existing_data, "  "))
	file.close()
	var dir = Directory.new()
	dir.rename(tmp_path, "user://playerdata.json")

func reload():
	if character_select_node:
		character_select_node.get_parent().remove_child(character_select_node)
	get_tree().reload_current_scene()



func current_base_version() -> String:
	var v = VERSION
	var dash = v.find("-")
	if dash >= 0:
		v = v.substr(0, dash)
	return v





func should_disable_mods_for_version_transition() -> bool:
	var base = current_base_version()
	if not (base in MOD_DISABLE_VERSIONS):
		return false
	var file = File.new()
	
	
	if not file.file_exists("user://playerdata.json"):
		return false
	if file.open("user://playerdata.json", File.READ) != OK:
		return false
	var data = parse_json(file.get_as_text())
	file.close()
	if not (data is Dictionary):
		return false
	var opened = data.get("opened_mod_sensitive_versions", [])
	if not (opened is Array):
		return false
	return not (base in opened)




func mark_mod_sensitive_version_opened(version: String):
	var file = File.new()
	var opened = []
	if file.file_exists("user://playerdata.json"):
		if file.open("user://playerdata.json", File.READ) == OK:
			var data = parse_json(file.get_as_text())
			file.close()
			if data is Dictionary and data.get("opened_mod_sensitive_versions") is Array:
				opened = data["opened_mod_sensitive_versions"]
	if version in opened:
		return
	opened.append(version)
	save_player_data({"opened_mod_sensitive_versions": opened})
