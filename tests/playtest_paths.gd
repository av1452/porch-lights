extends SceneTree
# Walks Leo's route in every chapter set in the family house (out of his room,
# down the hallway, into the living room) with his body size, and reports
# anything standing in the way. Run headless:
# godot --headless -s res://tests/playtest_paths.gd
const SCENES := [
	"res://scenes/chapter_1_halloween.tscn", "res://scenes/chapter_2_getting_ready.tscn",
	"res://scenes/chapter_5_christmas_eve.tscn", "res://scenes/chapter_6_christmas_morning.tscn",
	"res://scenes/winter_break_days.tscn", "res://scenes/chapter_7_new_years_eve.tscn",
]
## The narrow part: Leo's room → his door → the hallway (1 m wide) → the
## living room. The living room itself is open, so people there can be walked around.
const ROUTE: Array[Vector3] = [Vector3(4.4, 0, -6.95), Vector3(3.0, 0, -6.85), Vector3(2.4, 0, -6.8),
	Vector3(2.0, 0, -6.4), Vector3(2.0, 0, -2.4), Vector3(2.0, 0, -1.9)]
func _initialize():
	var blocked_any := false
	for path in SCENES:
		Engine.time_scale = 6.0
		var ch = load(path).instantiate()
		root.add_child(ch)
		await create_timer(9.0).timeout
		var space: PhysicsDirectSpaceState3D = ch.get_world_3d().direct_space_state
		var shape := CapsuleShape3D.new()
		shape.radius = 0.25
		shape.height = 1.3
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = shape
		q.collision_mask = 1
		q.exclude = [ch.player.get_rid()]
		var hits := {}
		for k in ROUTE.size() - 1:
			var a: Vector3 = ROUTE[k]
			var b: Vector3 = ROUTE[k + 1]
			var steps := int(a.distance_to(b) / 0.1) + 1
			for i in steps + 1:
				var p := a.lerp(b, float(i) / steps)
				q.transform = Transform3D(Basis(), p + Vector3(0, 0.7, 0))
				for r in space.intersect_shape(q, 8):
					var c: Object = r.collider
					var name := str(c.name) if c is Node else str(c)
					if c is Node and (c as Node).is_inside_tree():
						name = str(ch.get_path_to(c))
					hits[name] = p.snapped(Vector3.ONE * 0.1)
		blocked_any = blocked_any or not hits.is_empty()
		print(path.get_file(), ": ", "clear" if hits.is_empty() else "BLOCKED by " + str(hits))
		ch.queue_free()
		await create_timer(0.5).timeout
	print("all clear=", not blocked_any)
	quit()
