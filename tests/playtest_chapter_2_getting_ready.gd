extends SceneTree
# Automated playthrough of Thanksgiving: Getting Ready (and the drive there).
# godot --headless -s res://tests/playtest_chapter_2_getting_ready.gd
var ch
func idle() -> void:
	await create_timer(0.3).timeout
	while ch.busy:
		await create_timer(0.2).timeout
func _initialize():
	Engine.time_scale = 6.0
	ch = load("res://scenes/chapter_2_getting_ready.tscn").instantiate()
	root.add_child(ch)
	await create_timer(9.0).timeout
	print("start step=", ch.step, " locked=", ch.player.input_locked, " y=", ch.player.global_position.y)
	ch.front_door.interact(ch.player); await idle()
	print("door before ready: step=", ch.step, " door enabled=", ch.front_door.enabled)
	for n in ["Coat", "Handheld", "Leash"]:
		ch.get_node(n).interact(ch.player); await idle()
	await create_timer(4.0).timeout; await idle()
	print("gathered step=", ch.step)
	ch.front_door.interact(ch.player); await create_timer(1.0).timeout
	print("door open: enabled=", ch.front_door.enabled)
	ch.player.teleport(Vector3(-1.55, 0.05, 4.1), 180.0)
	await create_timer(4.0).timeout
	print("driving step=", ch.step, " car=", ch.car != null, " seated=", ch.player.seated, " pos=", ch.player.global_position)
	await create_timer(70.0).timeout
	print("thanksgiving loaded: ", root.has_node("Chapter2"))
	quit()
