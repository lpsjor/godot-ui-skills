extends SceneTree
## Print the rects of every Control in a scene at an explicit viewport size.
##
## Usage:
##   SCENE=res://path/to/screen.tscn WIDTH=720 HEIGHT=1280 \
##     godot --headless --path . -s measure_layout.gd
##
## The scene is instantiated inside a SubViewport. Do not use the headless
## root viewport for design-size measurements; its size may not match.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene_path := OS.get_environment("SCENE")
	if scene_path == "":
		push_error("SCENE is required")
		quit(1)
		return
	var width := int(OS.get_environment("WIDTH"))
	var height := int(OS.get_environment("HEIGHT"))
	if width <= 0:
		width = 720
	if height <= 0:
		height = 1280

	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("cannot load %s" % scene_path)
		quit(1)
		return

	var viewport := SubViewport.new()
	viewport.size = Vector2i(width, height)
	root.add_child(viewport)
	var scene := packed.instantiate()
	viewport.add_child(scene)
	if scene is Control:
		(scene as Control).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	for _i in 3:
		await process_frame

	print("viewport=%dx%d scene=%s" % [width, height, scene_path])
	_walk(scene, scene.name)
	quit(0)

func _walk(node: Node, path: String) -> void:
	for child in node.get_children():
		var child_path := "%s/%s" % [path, child.name]
		if child is Control:
			var control := child as Control
			print("%s pos=%s size=%s min=%s" % [
				child_path,
				control.position,
				control.size,
				control.get_combined_minimum_size(),
			])
		_walk(child, child_path)
