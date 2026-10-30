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
	print("start porch light=", ch.porch_light.light_energy, " mom visible=", ch.mom.visible, " step=", ch.step, " grandma here=", ch.grandma.is_inside_tree())
	await create_timer(3.0).timeout
	print("objective: ", ch.hud._objective.text.replace("\n", " | "))
	# Every bulb you can check faces into the room, and Jamie isn't standing in front of them.
	var room_side := true
	for c in ch._checks:
		var off: Vector3 = c.global_position - ch.get_node("ChristmasTree").global_position
		room_side = room_side and off.x + off.z > 0.0 and c.global_position.distance_to(ch.jamie.global_position) > 0.6
	print("bulbs on the room side=", room_side, " checks=", ch._checks.size())
	# Afternoon: cookies, wrapping, and the dead bulb.
	ch._sugar_cookies.interact(ch.player); await idle()
	ch._wrapping.interact(ch.player); await idle()
	ch.jamie.interact(ch.player); await idle()
	for i in ch._checks.size():
		ch._checks[i].interact(ch.player); await idle()
	print("afternoon done=", ch._day_done.keys(), " tree lit=", ch._tree_glow.light_energy > 0.0)
	await until_step(ch.Step.GRANDMA, 60.0)
	print("evening: grandma here=", ch.grandma.is_inside_tree(), " fudge=", ch._fudge.is_inside_tree())
	ch.jamie.interact(ch.player); await idle()
	ch.grandma.interact(ch.player); await until_step(ch.Step.PRESENT)
	ch._present.interact(ch.player); await until_step(ch.Step.BANDANA)
	ch.dog.get_node("PetBody").interact(ch.player); await until_step(ch.Step.PICTURE)
	print("bandana on biscuit=", ch.dog._torso.has_node("Bandana"))
	ch.mom.interact(ch.player); await until_step(ch.Step.COOKIES)
	ch._santa_plate.interact(ch.player); await until_step(ch.Step.CARROTS)
	print("plate moved to living room=", ch._santa_plate.position.z < 1.0 and ch._santa_plate.position.x < 1.0)
	ch._carrots.interact(ch.player); await until_step(ch.Step.PORCH_LIGHT)
	ch.porch_switch.interact(ch.player); await until_step(ch.Step.OUTSIDE)
	print("porch light on=", ch.porch_light.light_energy > 0.0)
	ch.front_door.interact(ch.player); await until_step(ch.Step.PORCH)
	ch._on_porch()
	await until_step(ch.Step.DREAM, 150.0)
	print("dream: hall in tree=", ch._dream_hall.is_inside_tree(), " locked=", ch.player.input_locked)
	ch.player.teleport(ch.DREAM_DOG + Vector3(0, 0, 3.0), 0.0)
	await create_timer(2.0).timeout
	print("biscuit greeted=", ch._dream_dog_greeted)
	ch._dream_hall.get_node("DreamDoor").interact(ch.player)
	for i in 80:
		await create_timer(1.0).timeout
		if root.has_node("Chapter6"):
			break
	print("chapter 6 loaded=", root.has_node("Chapter6"))
	quit()
