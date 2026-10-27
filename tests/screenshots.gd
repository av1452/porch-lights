extends SceneTree
# Renders a screenshot of each room into screenshots/ (needs a real renderer, not --headless).
# godot --path . --rendering-method gl_compatibility -s res://tests/screenshots.gd -- chapter_1_halloween
var ch
func shot(name: String, pos: Vector3, yaw: float, pitch: float = 0.0) -> void:
	ch.player.teleport(pos, yaw)
	ch.player.head.rotation.x = deg_to_rad(pitch)
	for i in 8:
		await process_frame
	await create_timer(0.3).timeout
	root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://screenshots/%s.png" % name))
func _initialize():
	Engine.time_scale = 6.0
	var which: String = OS.get_cmdline_user_args()[0]
	ch = load("res://scenes/%s.tscn" % which).instantiate()
	root.add_child(ch)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://screenshots"))
	await create_timer(10.0).timeout
	Engine.time_scale = 1.0
	if which.begins_with("chapter_1"):
		await shot("1_living_room", Vector3(-0.3, 0.05, 1.6), 15, -8)
		await shot("2_living_room_back", Vector3(0.5, 0.05, -1.2), 200, -5)
		await shot("3_kitchen", Vector3(2.4, 0.05, 0.3), -95, -5)
		await shot("4_hallway", Vector3(2.0, 0.05, -1.8), 0, -3)
		ch.jamie_door.rotation.y = deg_to_rad(95)
		await shot("5_jamie_room", Vector3(2.1, 0.05, -4.2), 80, -8)
		await shot("6_kid_room", Vector3(2.9, 0.05, -6.6), -100, 0)
		ch._enter_dream()
		ch.player.camera.fov = 90
		await shot("7_dream_hall", Vector3(2.0, 0.05, -7.0), 0, 0)
	else:
		await shot("8_grandma_entry", Vector3(-3.3, 0.05, 0.3), -75, -6)
		await shot("9_grandma_kitchen", Vector3(-0.2, 0.05, 2.4), 150, -6)
		await shot("10_kids_table", Vector3(0.3, 0.05, 0.6), 60, -14)
	quit()
