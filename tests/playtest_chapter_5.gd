extends SceneTree
# Automated playthrough of Chapter 5. Run headless from the project folder:
# godot --headless -s res://tests/playtest_chapter_5.gd
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
	ch = load("res://scenes/chapter_5_christmas_eve.tscn").instantiate()
	root.add_child(ch)
	await create_timer(9.0).timeout
	print("start porch light=", ch.porch_light.light_energy, " mom visible=", ch.mom.visible)
	ch.jamie.interact(ch.player); await idle()
	ch.grandma.interact(ch.player); await until_step(ch.Step.PRESENT)
	ch._present.interact(ch.player); await until_step(ch.Step.PICTURE)
	ch.mom.interact(ch.player); await until_step(ch.Step.COOKIES)
	ch._santa_plate.interact(ch.player); await until_step(ch.Step.CARROTS)
	print("plate moved to living room=", ch._santa_plate.position.z < 1.0 and ch._santa_plate.position.x < 1.0)
	ch._carrots.interact(ch.player); await until_step(ch.Step.PORCH_LIGHT)
	ch.porch_switch.interact(ch.player); await until_step(ch.Step.OUTSIDE)
	print("porch light on=", ch.porch_light.light_energy > 0.0)
	ch.front_door.interact(ch.player); await until_step(ch.Step.PORCH)
	ch._on_porch()
	for i in 80:
		await create_timer(1.0).timeout
		if root.has_node("Chapter6"):
			break
	print("chapter 6 loaded=", root.has_node("Chapter6"))
	quit()
