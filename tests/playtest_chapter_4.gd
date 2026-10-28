extends SceneTree
# Automated playthrough of Chapter 4. Run headless from the project folder:
# godot --headless -s res://tests/playtest_chapter_4.gd
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
	ch = load("res://scenes/chapter_4_winter_break.tscn").instantiate()
	root.add_child(ch)
	await create_timer(9.0).timeout
	print("start locked=", ch.player.input_locked, " y=", ch.player.global_position.y, " calendar=", ch.get_node("House/Kitchen/Furniture/CalendarMonth").text, " tv=", ch.tv_screen.channel)
	ch.jamie.interact(ch.player); await idle()
	ch.dad.interact(ch.player); await until_step(ch.Step.SET_TABLE)
	ch._plates.interact(ch.player); await until_step(ch.Step.PHONE)
	print("ringing=", ch._ringing)
	ch.phone.interact(ch.player); await until_step(ch.Step.JAMIE)
	print("dad visible=", ch.dad.visible, " ringing=", ch._ringing)
	ch.jamie.interact(ch.player); await until_step(ch.Step.BULB)
	ch._checks[0].interact(ch.player); await idle()
	print("wrong bulb: step=", ch.step, " lit=", ch._bulb_mats[0].emission_energy_multiplier)
	ch._checks[ch.DEAD_CHECK].interact(ch.player); await until_step(ch.Step.COUCH)
	print("tree lit=", ch._bulb_mats[0].emission_energy_multiplier > 0.0, " glow=", ch._tree_glow.light_energy)
	ch.couch.interact(ch.player); await until_step(ch.Step.DREAM)
	await create_timer(4.0).timeout; await idle()
	print("dream: snow=", ch._snow != null and ch._snow.is_inside_tree(), " seated=", ch.player.seated, " ringing=", ch._ringing)
	ch.phone.interact(ch.player)
	await create_timer(50.0).timeout
	print("end step=", ch.step)
	ch.queue_free(); await create_timer(0.3).timeout
	quit()
