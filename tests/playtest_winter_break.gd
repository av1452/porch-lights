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
	for i in ch.MARSHMALLOWS + 1:
		ch._cocoa.interact(ch.player); await idle()
	print("marshmallows=", ch._marshmallows, " cocoa done=", ch._done.has("cocoa"))
	ch.get_node("ThankYouNote").interact(ch.player); await idle()
	ch.front_door.interact(ch.player); await create_timer(1.0).timeout
	ch.player.teleport(Vector3(-1.55, 0.05, 4.1), 180.0)
	await create_timer(1.5).timeout
	print("outside=", ch._outside, " snow pile enabled=", ch._snow_pile.enabled)
	for i in 3:
		ch._snow_pile.interact(ch.player); await idle()
	print("snowman parts=", ch._snowman_parts, " done=", ch._done.keys(), " step=", ch.step)
	# The evening: a board game you can see, with dice you can reach from the couch.
	for i in 60:
		await create_timer(0.5).timeout
		if ch._dice and not ch.busy:
			break
	# Seated on the couch: looking down at the board picks up the dice.
	ch.player.tween_look_at(ch.BOARD_AT, 0.01)
	for i in 4:
		await physics_frame
	print("board on table=", ch._board.is_inside_tree(), " seated=", ch.player.seated, " dice targeted=", ch.player._target == ch._dice,
		" clock=", ch.get_node("House/LivingRoom/Things/Clock").memory_text.left(5), " tv=", ch.tv_screen.channel)
	for i in ch.ROLLS.size():
		ch._dice.interact(ch.player)
		if i == ch.ROLLS.size() - 1:
			break # the last roll ends the chapter
		await idle()
		print("roll ", i + 1, ": bottle cap on space ", ch._cap_space)
	for i in 80:
		await create_timer(1.0).timeout
		if root.has_node("Chapter7"):
			break
	print("new year's eve loaded=", root.has_node("Chapter7"))
	quit()
