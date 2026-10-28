extends SceneTree
# Automated playthrough of Chapter 3. Run headless from the project folder:
# godot --headless -s res://tests/playtest_chapter_3.gd
var ch
func idle() -> void:
	await create_timer(0.3).timeout
	while ch.busy:
		await create_timer(0.2).timeout
## Waits for a story step (gives up after `limit` seconds so a failure can't hang the run).
func until_step(step: int, limit := 120.0) -> void:
	var t := 0.0
	while ch.step != step and t < limit:
		await create_timer(0.5).timeout
		t += 0.5
	await idle()
func _initialize():
	Engine.time_scale = 6.0
	ch = load("res://scenes/chapter_3_drive_home.tscn").instantiate()
	root.add_child(ch)
	await create_timer(9.0).timeout
	print("seated=", ch.player.seated, " locked=", ch.player.input_locked, " pos=", ch.player.global_position)
	ch.get_node("CarRide/Cabin/Leftovers").interact(ch.player); await idle()
	ch.dad.interact(ch.player); await idle()
	ch.jamie.interact(ch.player)
	await until_step(ch.Step.SLEEP)
	print("after overhear step=", ch.step, " hoodie enabled=", ch.get_node("CarRide/Cabin/Hoodie").enabled)
	ch.get_node("CarRide/Cabin/Hoodie").interact(ch.player)
	await create_timer(1.0).timeout; await idle()
	if ch.street == null:
		print("FAIL: never reached the dream"); quit(); return
	print("dream step=", ch.step, " car in tree=", ch.car.is_inside_tree(), " seated=", ch.player.seated, " pos=", ch.player.global_position)
	# walk down the dream street
	ch.player.teleport(Vector3(-17.8, -0.4, -10.0), 0.0)
	await create_timer(1.0).timeout
	var dark: int = ch.street.porch_lights.filter(func(e): return e.get("dark", false)).size()
	print("lights gone dark behind you: ", dark, " / ", ch.street.porch_lights.size(), " y=", ch.player.global_position.y)
	ch.player.teleport(Vector3(-24.0, -0.4, -64.0), 90.0)
	await create_timer(1.0).timeout
	print("near grandma step=", ch.step)
	ch.grandma.interact(ch.player)
	await create_timer(40.0).timeout
	print("end step=", ch.step, " far light on=", ch.street.far_light.light.light_energy > 0.0)
	ch.queue_free(); await create_timer(0.3).timeout
	quit()
