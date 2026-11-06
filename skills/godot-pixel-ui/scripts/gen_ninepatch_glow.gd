extends SceneTree
## Generate a white-alpha 9-patch glow texture.
##
## Usage:
##   OUT=assets/vfx/card_glow.png SIZE=64 BAND=12 INNER=24 POWER=1.6 \
##     godot --headless --path . -s gen_ninepatch_glow.gd
##
## The center is transparent. Put the texture on a NinePatchRect with patch
## margins = INNER, behind the card, and tint it with the per-variant accent.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var out_path := OS.get_environment("OUT")
	if out_path == "":
		push_error("OUT is required")
		quit(1)
		return
	var size := int(OS.get_environment("SIZE"))
	if size <= 0:
		size = 64
	var band := float(OS.get_environment("BAND"))
	if band <= 0.0:
		band = 12.0
	var inner := float(OS.get_environment("INNER"))
	if inner <= band:
		inner = band * 2.0
	var power := float(OS.get_environment("POWER"))
	if power <= 0.0:
		power = 1.6

	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(1, 1, 1, 0))
	for y in size:
		for x in size:
			var distance := minf(minf(x, y), minf(size - 1 - x, size - 1 - y))
			var alpha := 0.0
			if distance < band:
				alpha = smoothstep(0.0, band, distance)
			elif distance < inner:
				alpha = 1.0 - smoothstep(band, inner, distance)
			alpha = pow(clampf(alpha, 0.0, 1.0), power)
			image.set_pixel(x, y, Color(1, 1, 1, alpha))

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_path.get_base_dir()))
	var error := image.save_png(ProjectSettings.globalize_path(out_path))
	if error != OK:
		push_error("save_png failed: %s" % error_string(error))
		quit(1)
		return
	print("saved %s (%dx%d, band=%s, inner=%s)" % [out_path, size, size, band, inner])
	quit(0)
