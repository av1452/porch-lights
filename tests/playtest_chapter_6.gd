extends SceneTree
# Automated playthrough of Chapter 6. Run headless from the project folder:
# godot --headless -s res://tests/playtest_chapter_6.gd
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
	ch = load("res://scenes/chapter_6_christmas_morning.tscn").instantiate()
	root.add_child(ch)
	await create_timer(12.0).timeout
	print("start pos=", ch.player.global_position, " porch light on=", ch.porch_light.light_energy > 0.0)
	ch._on_see_tree(); await until_step(ch.Step.STOCKING)
	for i in ch.STOCKING.size():
		ch._stocking.interact(ch.player); await idle()
	print("stocking emptied=", ch._pulled, " on the floor=", ch.get_children().filter(func(n): return n.name in ["Candy", "Yoyo", "Cards", "Toothbrush", "Orange"]).size())
	await until_step(ch.Step.PRESENT)
	ch._present.interact(ch.player); await until_step(ch.Step.DAD)
	print("racer unboxed=", ch._present.find_child("RoboRacer", true, false) != null)
	ch.grandma.interact(ch.player); await idle()
	ch.dad.interact(ch.player); await until_step(ch.Step.FLIP)
	for i in ch.FLIPS.size():
		ch._pan.interact(ch.player); await idle()
	await until_step(ch.Step.OUTSIDE)
	print("pancakes flipped=", ch._flips, " jamie in yard=", ch.jamie.position.z > 6.0)
	ch.front_door.interact(ch.player); await until_step(ch.Step.PORCH)
	ch._on_porch(); await until_step(ch.Step.THROW)
	print("can reach jamie=", ch.player.ray.target_position.length() > Vector3(-1.55, 1.15, 4.3).distance_to(ch.jamie.global_position + Vector3(0, 1.3, 0)), " prompt=", ch.jamie.prompt)
	ch.jamie.interact(ch.player)
	for i in 80:
		await create_timer(1.0).timeout
		if root.has_node("WinterBreak"):
			break
	print("winter break loaded=", root.has_node("WinterBreak"))
	quit()
