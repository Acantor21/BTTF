extends SceneTree

const ROOT_SCENE := preload("res://scenes/father_time_diorama/FatherTimeDioramaRoot.tscn")
const OUTPUT_DIR := "/tmp/father_time_diorama_captures"

func _initialize() -> void:
	var output_error := DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)
	if output_error != OK:
		push_error("Failed to create capture output directory: %s" % OUTPUT_DIR)
		quit(1)
		return

	var failed := false
	failed = failed or not await _capture_boot()
	failed = failed or not await _capture_saved()
	failed = failed or not await _capture_collapse()

	if failed:
		quit(1)
		return

	print("PASS: Father Time Diorama captures written to %s" % OUTPUT_DIR)
	quit(0)

func _capture_boot() -> bool:
	var root = await _spawn_root()
	var ok := await _write_capture(root, "boot")
	root.queue_free()
	await process_frame
	return ok

func _capture_saved() -> bool:
	var root = await _spawn_root()
	root.set_active_artifact("save_clock_tower_flyer")
	if not root.resolve_artifact_to_slot("flyer_slot_1955", false):
		push_error("Failed to resolve saved path flyer step.")
		root.queue_free()
		await process_frame
		return false
	if not root.resolve_artifact_to_slot("hook_slot_1955", false):
		push_error("Failed to resolve saved path hook step.")
		root.queue_free()
		await process_frame
		return false
	if not root.resolve_artifact_to_slot("almanac_slot_1985", false):
		push_error("Failed to resolve saved path almanac step.")
		root.queue_free()
		await process_frame
		return false
	if not root.resolve_artifact_to_slot("key_slot_2015", false):
		push_error("Failed to resolve saved path key step.")
		root.queue_free()
		await process_frame
		return false

	var ok := await _write_capture(root, "saved")
	root.queue_free()
	await process_frame
	return ok

func _capture_collapse() -> bool:
	var root = await _spawn_root()
	root.set_active_artifact("save_clock_tower_flyer")
	if not root.resolve_artifact_to_slot("flyer_slot_1955", false):
		push_error("Failed to resolve collapse path flyer step.")
		root.queue_free()
		await process_frame
		return false
	if not root.resolve_artifact_to_slot("hook_slot_1955", false):
		push_error("Failed to resolve collapse path hook step.")
		root.queue_free()
		await process_frame
		return false
	if not root.resolve_artifact_to_slot("almanac_slot_1985", true):
		push_error("Failed to resolve collapse path almanac corruption step.")
		root.queue_free()
		await process_frame
		return false
	if not root.resolve_artifact_to_slot("key_slot_2015", true):
		push_error("Failed to resolve collapse path key corruption step.")
		root.queue_free()
		await process_frame
		return false

	var ok := await _write_capture(root, "collapse")
	root.queue_free()
	await process_frame
	return ok

func _spawn_root():
	var root = ROOT_SCENE.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame
	return root

func _write_capture(root, slug: String) -> bool:
	await process_frame
	await process_frame

	var image := get_root().get_texture().get_image()
	if image == null:
		push_error("Failed to capture screenshot for %s." % slug)
		return false

	var output_path := "%s/%s.png" % [OUTPUT_DIR, slug]
	var err := image.save_png(output_path)
	if err != OK:
		push_error("Failed to write screenshot for %s to %s." % [slug, output_path])
		return false

	print("WROTE: %s" % output_path)
	return true
