extends SceneTree
# Automated playthrough of the class party (school). Run headless from the project folder:
# godot --headless -s res://tests/playtest_school.gd
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
	ch = load("res://scenes/school_class_party.tscn").instantiate()
	root.add_child(ch)
	await create_timer(9.0).timeout
	print("start locked=", ch.player.input_locked, " y=", ch.player.global_position.y, " kids=", ch.kids.size())
	ch.kids["Tyler B."].interact(ch.player); await idle()
	ch._mailbox.interact(ch.player); await until_step(ch.Step.SNOWFLAKE)
	ch._crafts.interact(ch.player); await until_step(ch.Step.GIFT)
	ch._gifts.interact(ch.player); await until_step(ch.Step.MAYA)
	ch.kids["Maya"].interact(ch.player); await until_step(ch.Step.PARTY)
	var game = root.get_node("Game")
	var photos_before: int = game.photos.size()
	ch._snacks.interact(ch.player); await until_step(ch.Step.CUPCAKES)
	for kid_name in ch.kids.keys():
		ch.kids[kid_name].interact(ch.player); await idle()
	await until_step(ch.Step.RUG)
	print("cupcakes left=", ch._unserved.size())
	print("class photo saved=", game.photos.any(func(p): return p.caption == "Mrs. Patterson's class party"), " (", photos_before, " before)")
	ch._rug.interact(ch.player); await until_step(ch.Step.BELL)
	print("after bell: door enabled=", ch._door.enabled, " seated=", ch.player.seated)
	ch._door.interact(ch.player)
	await until_step(ch.Step.DREAM, 200.0)
	print("bench → dream: step=", ch.step, " dream hall=", ch.dream_hall != null, " real hall freed=", not is_instance_valid(ch.hall), " locked=", ch.player.input_locked)
	ch.player.teleport(ch.DREAM_AT + ch.dream_hall.far_spot + Vector3(0, 0, 2.5), 0.0)
	await create_timer(2.0).timeout
	print("biscuit greeted=", ch._dog_greeted)
	ch.dream_hall.far_door.interact(ch.player)
	for i in 60:
		await create_timer(1.0).timeout
		if root.has_node("Chapter5"):
			break
	print("christmas eve loaded=", root.has_node("Chapter5"))
	quit()
