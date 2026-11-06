extends SceneTree
## Slice a grid sprite sheet and center each icon by its opaque core.
##
## Usage:
##   SOURCE=art/source/icons.png OUT_DIR=assets/mode \
##     COLS=3 ROWS=2 NAMES=classic,fib,timed,gravity,gear,sparkle \
##     SIZE=320 THRESHOLD=0.8 MARGIN=12 \
##     godot --headless --path . -s slice_icons_centered.gd
##
## The core is alpha >= THRESHOLD. The full alpha bounds are preserved so the
## glow is not clipped. The output canvas is SIZE x SIZE.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var source := OS.get_environment("SOURCE")
	var out_dir := OS.get_environment("OUT_DIR")
	if source == "" or out_dir == "":
		push_error("SOURCE and OUT_DIR are required")
		quit(1)
		return
	var cols := int(OS.get_environment("COLS"))
	var rows := int(OS.get_environment("ROWS"))
	if cols <= 0:
		cols = 3
	if rows <= 0:
		rows = 2
	var names_raw := OS.get_environment("NAMES")
	var names: PackedStringArray = names_raw.split(",", false)
	if names.size() != cols * rows:
		push_error("NAMES count (%d) must equal COLS*ROWS (%d)" % [names.size(), cols * rows])
		quit(1)
		return
	var size := int(OS.get_environment("SIZE"))
	if size <= 0:
		size = 320
	var threshold := float(OS.get_environment("THRESHOLD"))
	if threshold <= 0.0:
		threshold = 0.8
	var margin := int(OS.get_environment("MARGIN"))
	if margin < 0:
		margin = 12

	var image := Image.load_from_file(source)
	if image == null:
		push_error("cannot load %s" % source)
		quit(1)
		return

	var out_abs := ProjectSettings.globalize_path(out_dir)
	DirAccess.make_dir_recursive_absolute(out_abs)

	var cell_w := float(image.get_width()) / float(cols)
	var cell_h := float(image.get_height()) / float(rows)
	for index in names.size():
		var name: String = names[index].strip_edges()
		if name == "":
			push_error("empty name at index %d" % index)
			quit(1)
			return
		var col := index % cols
		var row := index / cols
		var x0 := int(round(col * cell_w))
		var y0 := int(round(row * cell_h))
		var x1 := int(round((col + 1) * cell_w))
		var y1 := int(round((row + 1) * cell_h))
		var cell := image.get_region(Rect2i(x0, y0, x1 - x0, y1 - y0))
		var core_lo := Vector2i(99999, 99999)
		var core_hi := Vector2i(-1, -1)
		var full_lo := Vector2i(99999, 99999)
		var full_hi := Vector2i(-1, -1)
		for y in cell.get_height():
			for x in cell.get_width():
				var alpha := cell.get_pixel(x, y).a
				if alpha <= 0.01:
					continue
				full_lo.x = mini(full_lo.x, x)
				full_lo.y = mini(full_lo.y, y)
				full_hi.x = maxi(full_hi.x, x)
				full_hi.y = maxi(full_hi.y, y)
				if alpha >= threshold:
					core_lo.x = mini(core_lo.x, x)
					core_lo.y = mini(core_lo.y, y)
					core_hi.x = maxi(core_hi.x, x)
					core_hi.y = maxi(core_hi.y, y)
		if core_hi.x < 0 or full_hi.x < 0:
			push_error("%s: empty cell" % name)
			quit(1)
			return
		var core_center := (Vector2(core_lo) + Vector2(core_hi)) * 0.5
		var max_distance := maxf(
			maxf(core_center.x - full_lo.x, full_hi.x - core_center.x),
			maxf(core_center.y - full_lo.y, full_hi.y - core_center.y)
		)
		var scale := minf(1.0, float(size - margin * 2) / maxf(1.0, max_distance * 2.0))
		var output := Image.create(size, size, false, Image.FORMAT_RGBA8)
		output.fill(Color(0, 0, 0, 0))
		for y in size:
			for x in size:
				var sx := int(floor(core_center.x + (x + 0.5 - size * 0.5) / scale))
				var sy := int(floor(core_center.y + (y + 0.5 - size * 0.5) / scale))
				if sx >= 0 and sy >= 0 and sx < cell.get_width() and sy < cell.get_height():
					output.set_pixel(x, y, cell.get_pixel(sx, sy))
		var path := out_abs.path_join("%s.png" % name)
		var error := output.save_png(path)
		if error != OK:
			push_error("save_png failed for %s: %s" % [path, error_string(error)])
			quit(1)
			return
		print("%s core=%s..%s center=%s scale=%.3f -> %s" % [name, core_lo, core_hi, core_center, scale, path])
	quit(0)
