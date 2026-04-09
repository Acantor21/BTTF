extends SceneTree

const ROOT_SCENE := preload("res://scenes/father_time_diorama/FatherTimeDioramaRoot.tscn")

func _initialize() -> void:
	var failed := false
	
	failed = failed or not await test_father_time_diorama_boot_enters_1955()
	failed = failed or not await test_father_time_diorama_saved_path_reaches_saved_ending()
	failed = failed or not await test_father_time_diorama_collapse_path_reaches_collapse_ending()
	failed = failed or not await test_father_time_diorama_duplicate_resolution_is_rejected()

	if failed:
		quit(1)
		return

	print("PASS: Father Time Diorama headless runner")
	quit(0)

func test_father_time_diorama_boot_enters_1955() -> bool:
	var root = await _spawn_root()

	var passed := _assert_equal("boot era", root.get_active_era_id(), "1955")
	passed = _assert_equal("boot artifact", root.get_active_artifact_id(), "save_clock_tower_flyer") and passed
	passed = _assert_equal("boot branch", root.get_branch_state(), "continue") and passed

	root.queue_free()
	return passed

func test_father_time_diorama_saved_path_reaches_saved_ending() -> bool:
	var root = await _spawn_root()
	var passed := true
	
	root.set_active_artifact("save_clock_tower_flyer")
	passed = _assert_true("saved path flyer resolve", root.resolve_artifact_to_slot("flyer_slot_1955", false)) and passed
	passed = _assert_equal("saved path after flyer era", root.get_active_era_id(), "1955") and passed
	passed = _assert_equal("saved path after flyer artifact", root.get_active_artifact_id(), "lightning_cable_hook") and passed

	passed = _assert_true("saved path hook resolve", root.resolve_artifact_to_slot("hook_slot_1955", false)) and passed
	passed = _assert_equal("saved path after hook era", root.get_active_era_id(), "1985") and passed
	passed = _assert_equal("saved path after hook artifact", root.get_active_artifact_id(), "sports_almanac") and passed

	passed = _assert_true("saved path almanac resolve", root.resolve_artifact_to_slot("almanac_slot_1985", false)) and passed
	passed = _assert_equal("saved path after almanac era", root.get_active_era_id(), "2015") and passed
	passed = _assert_equal("saved path after almanac artifact", root.get_active_artifact_id(), "delorean_key") and passed

	passed = _assert_true("saved path key resolve", root.resolve_artifact_to_slot("key_slot_2015", false)) and passed
	passed = _assert_equal("saved path branch", root.get_branch_state(), "saved") and passed
	passed = _assert_equal("saved path ending era", root.get_active_era_id(), "2015") and passed

	root.queue_free()
	return passed

func test_father_time_diorama_collapse_path_reaches_collapse_ending() -> bool:
	var root = await _spawn_root()
	var passed := true
	
	root.set_active_artifact("save_clock_tower_flyer")
	passed = _assert_true("collapse path flyer resolve", root.resolve_artifact_to_slot("flyer_slot_1955", false)) and passed
	passed = _assert_true("collapse path hook resolve", root.resolve_artifact_to_slot("hook_slot_1955", false)) and passed
	passed = _assert_true("collapse path almanac corrupt", root.resolve_artifact_to_slot("almanac_slot_1985", true)) and passed
	passed = _assert_equal("collapse path after almanac branch", root.get_branch_state(), "continue") and passed
	passed = _assert_true("collapse path key corrupt", root.resolve_artifact_to_slot("key_slot_2015", true)) and passed
	passed = _assert_equal("collapse path final branch", root.get_branch_state(), "collapse") and passed

	root.queue_free()
	return passed

func test_father_time_diorama_duplicate_resolution_is_rejected() -> bool:
	var root = await _spawn_root()
	var passed := true
	
	root.set_active_artifact("save_clock_tower_flyer")
	passed = _assert_true("duplicate test first resolve", root.resolve_artifact_to_slot("flyer_slot_1955", false)) and passed
	passed = _assert_equal("duplicate test post-resolve artifact", root.get_active_artifact_id(), "lightning_cable_hook") and passed
	passed = _assert_false("duplicate test wrong artifact to old slot", root.resolve_artifact_to_slot("flyer_slot_1955", false)) and passed

	root.queue_free()
	return passed

func _spawn_root():
	var root = ROOT_SCENE.instantiate()
	get_root().add_child(root)
	await process_frame
	return root

func _assert_equal(label: String, actual, expected) -> bool:
	if actual == expected:
		print("PASS: %s" % label)
		return true

	push_error("FAIL: %s | expected=%s actual=%s" % [label, expected, actual])
	return false

func _assert_true(label: String, condition: bool) -> bool:
	if condition:
		print("PASS: %s" % label)
		return true

	push_error("FAIL: %s | condition was false" % label)
	return false

func _assert_false(label: String, condition: bool) -> bool:
	if not condition:
		print("PASS: %s" % label)
		return true

	push_error("FAIL: %s | condition was true" % label)
	return false
