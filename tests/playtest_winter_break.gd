extends SceneTree
# Automated playthrough of Winter Break. Run headless from the project folder:
# godot --headless -s res://tests/playtest_winter_break.gd
var ch
func idle() -> void:
	await create_timer(0.3).timeout
	while ch.busy:
		await create_timer(0.2).timeout
func _initialize():
	Engine.time_scale = 6.0
	ch = load("res://scenes/winter_break_days.tscn").instantiate()
	root.add_child(ch)
	await create_timer(9.0).timeout
	print("start step=", ch.step, " porch light on=", ch.porch_light.light_energy > 0.0, " locked=", ch.player.input_locked)
	ch.mom.interact(ch.player); await idle()
	ch.get_node("ThankYouNote").interact(ch.player); await idle()
	ch.front_door.interact(ch.player); await create_timer(1.0).timeout
	ch.player.teleport(Vector3(-1.55, 0.05, 4.1), 180.0)
	await create_timer(1.5).timeout
	print("outside=", ch._outside, " snow pile enabled=", ch._snow_pile.enabled)
	for i in 3:
		ch._snow_pile.interact(ch.player); await idle()
	print("snowman parts=", ch._snowman_parts, " done=", ch._done.keys(), " step=", ch.step)
	for i in 80:
		await create_timer(1.0).timeout
		if root.has_node("Chapter7"):
			break
	print("new year's eve loaded=", root.has_node("Chapter7"))
	quit()
