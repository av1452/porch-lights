extends SceneTree
# Automated playthrough of Chapter 2. Run headless from the project folder:
# godot --headless -s res://tests/playtest_chapter_2.gd
var ch
func idle() -> void:
	await create_timer(0.3).timeout
	while ch.busy:
		await create_timer(0.2).timeout
func _initialize():
	Engine.time_scale = 6.0
	ch = load("res://scenes/chapter_2_thanksgiving.tscn").instantiate()
	root.add_child(ch)
	await create_timer(9.0).timeout
	print("step0 locked=", ch.player.input_locked, " y=", ch.player.global_position.y)
	# Biscuit came too; the TV and the cousins face the tables.
	var tv_fwd: Vector3 = ch.tv_cart.global_basis.z
	var maddie: Node3D = ch.get_node("Story/Cousins/Maddie")
	var to_table: Vector3 = (ch.get_node("House/Furniture/CardTable") as Node3D).global_position - maddie.global_position
	to_table.y = 0.0
	print("biscuit here=", ch._biscuit.is_inside_tree(), " tv faces tables=", tv_fwd.x < -0.5,
		" maddie faces kids table=", maddie.global_basis.z.dot(to_table.normalized()) > 0.7)
	ch.get_node("Story/Grandma").interact(ch.player); await idle()
	print("after hi step=", ch.step, " seat enabled=", ch.seat.enabled, " stool in tree=", ch.grandma_stool.is_inside_tree())
	ch.get_node("Story/Diners/Dad").interact(ch.player); await idle()
	ch.get_node("Story/YourSeat").interact(ch.player)
	await create_timer(1.0).timeout
	print("seated=", ch.player.seated, " pos=", ch.player.global_position)
	await idle(); await create_timer(12.0).timeout; await idle()
	print("after dinner step=", ch.step, " diners in tree=", ch.diners.is_inside_tree(), " y=", ch.player.global_position.y)
	var dad: Node3D = ch.get_node("Story/Diners/Dad")
	print("dad in the den=", dad.global_position.x > 4.1, " den tv=", ch._house.den_tv.channel, " dining tv=", ch._tv.channel)
	ch.get_node("Story/GrandmaAtTable/Grandma").interact(ch.player); await create_timer(40.0).timeout
	print("end step=", ch.step)
	await create_timer(4.0).timeout
	ch.queue_free(); await create_timer(0.3).timeout
	quit()
