extends SceneTree
# Automated playthrough of Chapter 7. Run headless from the project folder:
# godot --headless -s res://tests/playtest_chapter_7.gd
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
	ch = load("res://scenes/chapter_7_last_day_of_break.tscn").instantiate()
	root.add_child(ch)
	await create_timer(9.0).timeout
	print("start locked=", ch.player.input_locked, " calendar=", ch.get_node("House/Kitchen/Furniture/CalendarMonth").text)
	for i in 3:
		ch._box.interact(ch.player)
		await create_timer(0.5).timeout
	await until_step(ch.Step.THANK_YOU)
	ch._note.interact(ch.player); await until_step(ch.Step.JAMIE)
	ch.jamie.interact(ch.player); await until_step(ch.Step.PORCH_LIGHT)
	print("seated=", ch.player.seated, " porch light on=", ch.porch_light.light_energy > 0.0)
	ch.porch_switch.interact(ch.player)
	await create_timer(60.0).timeout
	print("end step=", ch.step, " porch light off=", ch.porch_light.light_energy == 0.0, " card=", ch.hud._card_title.text)
	ch.queue_free(); await create_timer(0.3).timeout
	quit()
