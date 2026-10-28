extends SceneTree
# Automated playthrough of Chapter 1. Run headless from the project folder:
# godot --headless -s res://tests/playtest_chapter_1.gd
# Plays through Chapter 1 automatically by calling interact() in story order.
var ch
func use(path: String) -> void:
	var n = ch.get_node(path)
	print("  use ", path.get_file(), " enabled=", n.enabled, " step=", ch.step)
	n.interact(ch.player)
func idle() -> void:
	while ch.busy:
		await create_timer(0.2).timeout
func _initialize():
	Engine.time_scale = 6.0
	ch = load("res://scenes/chapter_1_halloween.tscn").instantiate()
	root.add_child(ch)
	await create_timer(9.0).timeout
	print("locked after intro: ", ch.player.input_locked)
	use("Story/Candy"); await create_timer(5.0).timeout; await idle()
	ch.get_node("Story/KitchenOverhear").player_entered.emit()
	await create_timer(0.3).timeout; await idle()
	use("Story/Mom"); await create_timer(0.3).timeout; await idle()
	use("Story/PorchSwitch"); await create_timer(5.5).timeout; await idle()
	use("House/JamieRoom/JamieDoor"); await create_timer(0.3).timeout; await idle()
	await create_timer(1.5).timeout
	print("door rot: ", ch.jamie_door.rotation_degrees.y)
	use("House/JamieRoom/JamieRoomFull/Things/Jamie"); await create_timer(0.3).timeout; await idle()
	use("House/JamieRoom/JamieRoomFull/Things/JamieComputer"); await create_timer(0.3).timeout; await idle()
	await create_timer(1.5).timeout; await idle()
	use("House/KidRoom/Things/Bed"); await create_timer(0.3).timeout; await idle()
	print("dreaming step=", ch.step, " pos=", ch.player.global_position, " dreamhall in tree=", ch.dream_hall.is_inside_tree(), " jamie_dream=", ch.jamie_dream.is_inside_tree())
	# walk forward a bit to make sure the floor holds
	await create_timer(1.0).timeout
	print("y after dream settle: ", ch.player.global_position.y)
	ch.get_node("DreamHall/DreamDoor").interact(ch.player)
	await create_timer(16.0).timeout; await idle()
	# Interlude: 2 a.m. (scripts/interlude_porch_light.gd)
	var il = ch.interlude
	print("interlude active=", il.active, " step=", il.step, " pos=", ch.player.global_position, " dreamhall in tree=", ch.dream_hall.is_inside_tree(), " hall_end=", ch.hall_end.is_inside_tree())
	il._on_pass_jamie(); await create_timer(0.3).timeout; await idle()
	print("jamie coming=", il._jamie_coming, " jamie door rot=", ch.jamie_door.rotation_degrees.y)
	il._on_overhear(); await create_timer(0.3).timeout; await idle()
	il._on_reach_dog()
	use("House/LivingRoom/Things/FrontDoor")
	print("door with light off: enabled=", ch.get_node("House/LivingRoom/Things/FrontDoor").enabled, " step=", il.step)
	use("Story/PorchSwitch"); await create_timer(0.5).timeout
	use("House/LivingRoom/Things/FrontDoor"); await create_timer(4.0).timeout
	print("door open step=", il.step, " dog at ", ch.dog.global_position)
	il._on_porch()
	for i in 60:
		await create_timer(2.0).timeout
		if root.has_node("Chapter2"):
			break
	print("street lights left on: ", ch.street.porch_lights.filter(func(e): return e.light.light_energy > 0.01).size(), " far light=", ch.street.far_light.light.light_energy)
	print("chapter 2 loaded after interlude: ", root.has_node("Chapter2"))
	quit()
