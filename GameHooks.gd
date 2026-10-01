extends Node



























var game = null





func ready():
	pass



func game_started(match_data):
	pass


func game_ended(winner):
	pass


func undo():
	pass


func playback_started():
	pass





func pre_tick():
	pass


func post_tick():
	pass



func process_tick():
	pass


func physics_process(delta):
	pass


func player_actionable(player):
	pass




func player_acted(player, action, data, extra):
	pass





func object_spawned(obj):
	pass


func particle_effect_spawned(fx):
	pass






func pre_apply_hitboxes(players):
	pass


func post_apply_hitboxes(players):
	pass


func hitbox_refreshed(hitbox_name):
	pass


func clashed(a, b):
	pass




func parried(parrier, attacker):
	pass


func blocked(blocker, attacker):
	pass


func global_hitlag(amount):
	pass


func super_started(ticks, player):
	pass


func forfeit(id):
	pass
