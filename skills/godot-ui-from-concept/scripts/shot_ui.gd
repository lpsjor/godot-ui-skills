extends SceneTree
## Render a scene into a PNG at an explicit size.
##
## Usage:
##   SCENE=res://scenes/home/home.tscn OUT=/tmp/home-720.png \
##     WIDTH=720 HEIGHT=1280 \
##     godot --path . --rendering-driver opengl3 --resolution 720x1280 \
##     -s shot_ui.gd
##
## Optional:
##   LOCALE=ja   switches the project's L10n autoload before instantiating.
##
## The scene is rendered inside a SubViewport, so the window resolution and the
## captured image size are independent.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene_path := OS.get_environment("SCENE")
	var out_path := OS.get_environment("OUT")
	if scene_path == "" or out_path == "":
		push_error("SCENE and OUT are required")
		quit(1)
		return
	var width := int(OS.get_environment("WIDTH"))
	var height := int(OS.get_environment("HEIGHT"))
	if width <= 0:
		width = 720
	if height <= 0:
		height = 1280

	var locale := OS.get_environment("LOCALE")
	if locale != "":
		var l10n := root.get_node_or_null("L10n")
		if l10n != null:
			l10n.set_locale(locale)

	var viewport := SubViewport.new()
	viewport.size = Vector2i(width, height)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)

	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("cannot load %s" % scene_path)
		quit(1)
		return
	var scene := packed.instantiate()
	viewport.add_child(scene)
	if scene is Control:
		(scene as Control).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	for _i in 8:
		await process_frame
	await RenderingServer.frame_post_draw

	var image := viewport.get_texture().get_image()
	var error := image.save_png(out_path)
	if error != OK:
		push_error("save_png failed: %s" % error_string(error))
		quit(1)
		return
	print("saved %s (%dx%d)" % [out_path, width, height])
	quit(0)
