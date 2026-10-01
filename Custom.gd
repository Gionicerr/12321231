extends Node

const SUPPORTER_PACK = 2232850



const ATTACH_PAIRS = {
	"Hands": ["LeftHand", "RightHand"], 
	"Feet": ["LeftFoot", "RightFoot"], 
	
	
	
	
	"Eyes": ["Head", "Head"], 
}



const ATTACH_LIMB_MIGRATIONS: = {
	"UpperBody": "", 
	"LowerBody": "", 
	"Body": "", 
	"LeftArm": "LeftHand", 
	"RightArm": "RightHand", 
	"LeftLeg": "LeftFoot", 
	"RightLeg": "RightFoot", 
}

func migrate_attach_limb(name: String) -> String:
	if name in ATTACH_LIMB_MIGRATIONS:
		return ATTACH_LIMB_MIGRATIONS[name]
	return name



func swap_left_right_limb(name: String) -> String:
	if name.begins_with("Left"):
		return "Right" + name.substr(4)
	if name.begins_with("Right"):
		return "Left" + name.substr(5)
	return name






const MAX_AURA_SINGLES = 3
const MAX_AURA_INTERNAL = 6


func is_pair_attach(attach_limb: String) -> bool:
	return attach_limb in ATTACH_PAIRS


func pair_limbs(attach_limb: String):
	if attach_limb in ATTACH_PAIRS:
		return ATTACH_PAIRS[attach_limb]
	return null




func style_auras(style) -> Array:
	if style == null:
		return []
	if style.has("auras") and style["auras"] is Array:
		var out: = []
		for entry in style["auras"]:
			if entry is Dictionary:
				out.append({
					"show": entry.get("show", false), 
					"settings": entry.get("settings"), 
				})
		return out
	var legacy: = []
	if style.get("show_aura") and style.get("aura_settings"):
		legacy.append({"show": true, "settings": style.get("aura_settings")})
	if style.get("show_aura_2") and style.get("aura_settings_2"):
		legacy.append({"show": true, "settings": style.get("aura_settings_2")})
	return legacy





func expand_aura_entries(entries: Array) -> Array:
	var out: = []
	var single_count: = 0
	for e in entries:
		if not e.get("show", false):
			continue
		var s = e.get("settings")
		if not (s is Dictionary):
			continue
		var attach = migrate_attach_limb(s.get("attach_limb", ""))
		if is_pair_attach(attach):
			if out.size() + 2 > MAX_AURA_INTERNAL:
				continue
			out.append({"settings": s, "attach_limb": attach, "pair_index": 0})
			out.append({"settings": s, "attach_limb": attach, "pair_index": 1})
		else:
			if single_count >= MAX_AURA_SINGLES:
				continue
			if out.size() + 1 > MAX_AURA_INTERNAL:
				continue
			single_count += 1
			out.append({"settings": s, "attach_limb": attach, "pair_index": 0})
	return out



func resolve_attach_limb(entry: Dictionary) -> String:
	var attach = entry.get("attach_limb", "")
	if is_pair_attach(attach):
		var pair = ATTACH_PAIRS[attach]
		return pair[entry.get("pair_index", 0)]
	return attach

var hitsparks = {
	"bash": "res://fx/HitEffect1.tscn", 
	"bash2": "res://fx/hitsparks/HitEffect1Alt.tscn", 
	"bash3": "res://fx/hitsparks/HitEffect2Alt.tscn", 
	"fire": "res://fx/hitsparks/FireHitEffect.tscn", 
	"hearts": "res://fx/hitsparks/HeartHitEffect.tscn", 
	"petals": "res://fx/hitsparks/PetalHitEffect.tscn", 
	"coins": "res://fx/hitsparks/CoinHitEffect.tscn", 
	"dust": "res://fx/hitsparks/DustHitEffect.tscn", 
	"acid": "res://fx/hitsparks/AcidHitEffect.tscn", 
	"elec": "res://fx/hitsparks/ElectricHitEffect.tscn", 
}




const HITSPARK_SPRITE_NAMES = ["", "bash", "bash2", "bash3", "fire", "hearts", "petals", "acid", "elec"]
const HITSPARK_SPRITE_NONE_LABEL = "(none)"
const CUSTOM_HITSPARK_SCENE_PATH = "res://fx/hitsparks/CustomHitEffect.tscn"



const HITSPARK_SPRITE_SCALES = {
	"elec": Vector2(1.36, 0.68), 
}



func hitspark_sprite_label(sprite_name: String) -> String:
	if sprite_name == "":
		return HITSPARK_SPRITE_NONE_LABEL
	return sprite_name





func make_custom_hitspark_scene(config) -> PackedScene:
	var template = load(CUSTOM_HITSPARK_SCENE_PATH)
	if template == null:
		return null
	
	
	
	
	
	
	return template







var p1_selected_style = null
var p2_selected_style = null

var simple_colors = ["94e4ff", "ffc1a1", "ecffa4", "fec2ff", "6e8696", "ffea5d", "04579a", "85001f", "008561", "9f42ba", "343537", "ff9444"]
var simple_outlines = ["04579a", "85001f", "008561", "9f42ba", "343537", "ff9444", "94e4ff", "ffc1a1", "ecffa4", "fec2ff", "6e8696", "ffea5d"]

func _ready():
	for i in range(simple_colors.size()):
		simple_colors[i] = Color(simple_colors[i])
		simple_outlines[i] = Color(simple_outlines[i])
	make_custom_folder()
	
func make_custom_folder():
	var dir = Directory.new()
	if not dir.dir_exists("user://custom"):
		dir.make_dir("user://custom")

func apply_style_to_material(style, material: ShaderMaterial, force_extras = false):
	if style.character_color != null:
		material.set_shader_param("color", style.character_color)
	material.set_shader_param("use_outline", style.use_outline)
	if style.outline_color != null:
		material.set_shader_param("outline_color", style.outline_color)
	if style.get("extra_color_1") != null:
		material.set_shader_param("extra_color_1", style.extra_color_1)
		if force_extras:
			material.set_shader_param("use_extra_color_1", true)
	else:
		material.set_shader_param("use_extra_color_1", false)
	if style.get("extra_color_2") != null:
		material.set_shader_param("extra_color_2", style.extra_color_2)
		if force_extras:
			material.set_shader_param("use_extra_color_2", true)
	else:
		material.set_shader_param("use_extra_color_2", false)
	pass


func is_combo_simple(color, outline):
	return simple_colors.find(color) == simple_outlines.find(outline)

func is_color_dlc(color):
	if color == null:
		return false
	if not (color is Color):
		return not (Color(color) in simple_colors)
	return not (color in simple_colors)

func is_outline_dlc(color):
	if color == null:
		return false
	if not (color is Color):
		return not (Color(color) in simple_outlines)
	return not (color in simple_outlines)

func hitspark_to_dlc(spark_name):


	return 0

func can_use_style(player_id, style):
	if not requires_dlc(style):
		return Global.full_version()
	return true





















func requires_dlc(data):













	return false


func save_style(style):
	make_custom_folder()
	var file = File.new()
	var filename_ = "user://custom/" + style.style_name + ".style"
	
	if not style.has("mod_data"):
		style["mod_data"] = {}
	file.open(filename_, File.WRITE)
	file.store_var(style, true)
	file.close()
	return filename_

func save_style_workshop(style):
	var dir = Directory.new()
	var file = File.new()
	var folder_path = "user://custom/" + style.style_name
	if not dir.dir_exists(folder_path):
		dir.make_dir(folder_path)
	var filename_ = folder_path + "/" + style.style_name + ".style"
	if not style.has("mod_data"):
		style["mod_data"] = {}
	file.open(filename_, File.WRITE)
	file.store_var(style, true)
	file.close()
	return folder_path

func load_all_styles():
	make_custom_folder()
	var dir = Directory.new()
	var files = []
	var _directories = []
	var styles = []
	dir.open("user://custom")
	dir.list_dir_begin(false, true)

	Global.add_dir_contents(dir, files, _directories, false, ".style")

	if SteamHustle.STARTED and SteamHustle.WORKSHOP_ENABLED:
		var workshop = SteamWorkshop.new()
		for item in Steam.getSubscribedItems():
			var info: Dictionary
			info = workshop.get_item_install_info(item)
			if info.ret:
				dir.open(info.folder)
				dir.list_dir_begin(false, true)
				Global.add_dir_contents(dir, files, _directories, false, ".style")
	
	files.sort_custom(self, "sort_styles")



	for path in files:
		var file = File.new()
		file.open(path, File.READ)
		var data = file.get_var()
		file.close()
		if not (data is Dictionary):
			continue
		if not data.has("mod_data"):
			data["mod_data"] = {}
		styles.append(data)

	return [styles, files]

func get_style_name(path):
	return path.get_file().split(".")[0].strip_edges()

func sort_styles(a: String, b: String):
	return get_style_name(a) < get_style_name(b)
