extends SceneTree
# Automated playthrough of Chapter 7, New Year's Eve. Run headless from the project folder:
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
	ch = load("res://scenes/chapter_7_new_years_eve.tscn").instantiate()
	root.add_child(ch)
	await create_timer(9.0).timeout
	print("start step=", ch.step, " tv=", ch.tv_screen.channel, " porch light on=", ch.porch_light.light_energy > 0.0)
	for i in 3:
		ch._ornaments.interact(ch.player); await idle()
	await create_timer(6.0).timeout; await idle()
	ch._snacks.interact(ch.player); await idle()
	ch.jamie.interact(ch.player); await idle()
	await until_step(ch.Step.QUIET, 120.0)
	print("after midnight: step=", ch.step, " photo=", root.get_node("Game").photos.any(func(p): return p.caption.begins_with("Midnight")), " porch light on=", ch.porch_light.light_energy > 0.0)
	ch.get_node("TreeLights").interact(ch.player); await create_timer(0.5).timeout
	ch.get_node("House/LivingRoom/Things/Window").interact(ch.player)
	await until_step(ch.Step.DREAM, 60.0)
	print("dream: hall in tree=", ch._dream_hall.is_inside_tree(), " locked=", ch.player.input_locked)
	ch.player.teleport(ch.DREAM_DOG + Vector3(0, 0, 3.0), 0.0)
	await create_timer(2.0).timeout
	print("biscuit greeted=", ch._dream_dog_greeted)
	ch._dream_hall.get_node("DreamDoor").interact(ch.player)
	await create_timer(90.0).timeout
	print("end step=", ch.step, " porch light on=", ch.porch_light.light_energy > 0.0, " card=", ch.hud._card_title.text, " finished=", root.get_node("Game").finished)
	ch.queue_free(); await create_timer(0.3).timeout
	quit()
