class_name FatherTimeDioramaRoot
extends Node3D

const FirstSliceContentScript = preload("res://src/gameplay/father_time_diorama/first_slice_content.gd")
const FirstSliceTuningScript = preload("res://src/gameplay/father_time_diorama/first_slice_tuning.gd")
const FirstSliceBootValidatorScript = preload("res://src/core/runtime/first_slice_boot_validator.gd")
const FatherTimeRunStateScript = preload("res://src/core/runtime/father_time_run_state.gd")
const CAMERA_EXTRA_PULLBACK := 0.08
const CAMERA_EXTRA_LIFT := 0.02

var _content: Dictionary = {}
var _tuning: Dictionary = {}
var _compiled_slice: Dictionary = {}
var _run_state = FatherTimeRunStateScript.new()
var _artifact_order_by_era: Dictionary = {}
var _slot_indicator_by_slot_id: Dictionary = {}
var _placed_artifact_by_slot_id: Dictionary = {}
var _landmark_labels_by_era: Dictionary = {}
var _hovered_slot_id := ""
var _camera_tween: Tween
var _consequence_tween: Tween
var _default_tableau_transforms: Dictionary = {}
var _has_initialized_camera := false

@onready var _main_camera: Camera3D = $CameraRig/MainCamera
@onready var _directional_light: DirectionalLight3D = $DirectionalLight3D
@onready var _fill_light: OmniLight3D = $FillLight3D
@onready var _rim_light: OmniLight3D = $RimLight3D
@onready var _artifact_tray_anchor: Node3D = $ArtifactTrayAnchor
@onready var _artifact_tray_plinth: MeshInstance3D = $ArtifactTrayAnchor/ArtifactTrayPlinth
@onready var _artifact_preview_pivot: Node3D = $ArtifactTrayAnchor/ArtifactPreviewPivot
@onready var _canvas_layer: CanvasLayer = $CanvasLayer
@onready var _boot_status_label: Label = $CanvasLayer/BootStatusLabel
@onready var _instruction_label: Label = $CanvasLayer/InstructionLabel
@onready var _consequence_label: Label = $CanvasLayer/ConsequenceLabel

func _ready() -> void:
	_content = FirstSliceContentScript.build()
	_tuning = FirstSliceTuningScript.build()
	_configure_artifact_tray()

	var validator = FirstSliceBootValidatorScript.new()
	var validation: Dictionary = validator.validate(self, _content)

	if not bool(validation.get("ok", false)):
		_show_boot_failure(validation.get("errors", []))
		return

	_compiled_slice = validation.get("compiled", {})
	_run_state.bootstrap(String(_compiled_slice.get("starting_era_id", "")))
	_build_artifact_order()
	_cache_default_tableau_transforms()
	_create_slot_indicators()
	_create_landmark_labels()

	_select_first_available_artifact_for_active_era()

	_enter_live_era(_run_state.active_era_id)
	_set_consequence_copy(_get_opening_prompt(), _get_tone_color("consequence"), false)
	_show_boot_success()

func _process(_delta: float) -> void:
	_update_landmark_label_positions()

func _unhandled_input(event: InputEvent) -> void:
	if _compiled_slice.is_empty():
		return

	if _run_state.branch_state == FatherTimeRunStateScript.ENDING_SAVED:
		return
	if _run_state.branch_state == FatherTimeRunStateScript.ENDING_COLLAPSE:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		if key_event.keycode == KEY_Q:
			_cycle_active_artifact(-1)
		elif key_event.keycode == KEY_E:
			_cycle_active_artifact(1)

	if event is InputEventMouseMotion:
		_update_hover_from_mouse((event as InputEventMouseMotion).position)

	if event is InputEventMouseButton and event.pressed:
		var button_event := event as InputEventMouseButton
		_update_hover_from_mouse(button_event.position)
		if button_event.button_index == MOUSE_BUTTON_LEFT:
			_try_commit_hovered_slot(false)
		elif button_event.button_index == MOUSE_BUTTON_RIGHT:
			_try_commit_hovered_slot(true)

func get_compiled_slice() -> Dictionary:
	return _compiled_slice

func get_run_state():
	return _run_state

func get_valid_slot_nodes_for_active_artifact() -> Array[Node3D]:
	var artifact_id := String(_run_state.active_artifact_id)
	var artifacts: Dictionary = _compiled_slice.get("artifacts", {})
	if not artifacts.has(artifact_id):
		return []

	return artifacts[artifact_id].get("valid_slot_nodes", [])

func get_active_artifact_id() -> String:
	return _run_state.active_artifact_id

func get_active_era_id() -> String:
	return _run_state.active_era_id

func get_branch_state() -> String:
	return _run_state.branch_state

func resolve_artifact_to_slot(slot_id: String, use_corruption_outcome: bool) -> bool:
	var artifacts: Dictionary = _compiled_slice.get("artifacts", {})
	if not artifacts.has(_run_state.active_artifact_id):
		return false

	var artifact_bundle: Dictionary = artifacts[_run_state.active_artifact_id]
	var valid_slot_ids: Array = artifact_bundle.get("valid_slot_ids", [])
	if not valid_slot_ids.has(slot_id):
		push_error("[FatherTimeDioramaRoot] Slot '%s' is not valid for artifact '%s'." % [
			slot_id,
			_run_state.active_artifact_id,
		])
		return false

	_hovered_slot_id = slot_id
	return _try_commit_hovered_slot(use_corruption_outcome)

func set_active_artifact(artifact_id: String) -> void:
	var artifacts: Dictionary = _compiled_slice.get("artifacts", {})
	if not artifacts.has(artifact_id):
		push_error("[FatherTimeDioramaRoot] Unknown artifact '%s'." % artifact_id)
		return

	_run_state.set_active_artifact(artifact_id)
	_update_slot_indicator_state()
	_show_boot_success()

func _enter_live_era(era_id: String) -> void:
	var eras: Dictionary = _compiled_slice.get("eras", {})
	for candidate_era_id in eras.keys():
		var era_bundle: Dictionary = eras[candidate_era_id]
		var era_node := era_bundle.get("node") as Node3D
		if era_node == null:
			continue

		var is_active := String(candidate_era_id) == era_id
		era_node.visible = is_active
		if is_active:
			era_node.process_mode = Node.PROCESS_MODE_INHERIT
		else:
			era_node.process_mode = Node.PROCESS_MODE_DISABLED

	if eras.has(era_id):
		var active_era_bundle: Dictionary = eras[era_id]
		var camera_anchor := active_era_bundle.get("hero_camera_anchor") as Node3D
		_run_state.set_active_era(era_id)
		if camera_anchor != null:
			_move_camera_to(camera_anchor.global_transform, not _has_initialized_camera)
			_has_initialized_camera = true
	_update_landmark_label_visibility()
	_update_slot_indicator_state()
	_refresh_status_copy()
	_update_instruction_copy()

func _show_boot_success() -> void:
	_refresh_status_copy()
	_update_instruction_copy()
	_refresh_active_artifact_preview()

func _show_boot_failure(errors: Array) -> void:
	var error_text := FirstSliceBootValidatorScript.format_errors(errors)
	var message := "Boot validation failed.\n%s" % error_text
	push_error("[FatherTimeDioramaRoot] %s" % message)
	_set_boot_status(message, true)
	_artifact_tray_anchor.visible = false

func _set_boot_status(message: String, is_error: bool) -> void:
	_boot_status_label.text = message
	if is_error:
		_boot_status_label.modulate = _tuning.get("boot_status_error_color", Color(1.0, 0.62, 0.62, 1.0))
	else:
		_boot_status_label.modulate = _tuning.get("boot_status_ok_color", Color(0.84, 0.91, 1.0, 1.0))

func _refresh_status_copy() -> void:
	var message := "%s\n%s" % [
		_get_active_era_display_name(),
		_get_current_goal_summary(),
	]
	_boot_status_label.text = message
	_boot_status_label.modulate = _get_status_color()
	_apply_scene_grading()

func _get_active_era_display_name() -> String:
	var eras: Dictionary = _compiled_slice.get("eras", {})
	if eras.has(_run_state.active_era_id):
		return String(eras[_run_state.active_era_id].get("display_name", _run_state.active_era_id))
	return _run_state.active_era_id

func _get_active_artifact_display_name() -> String:
	var artifacts: Dictionary = _compiled_slice.get("artifacts", {})
	if artifacts.has(_run_state.active_artifact_id):
		return String(artifacts[_run_state.active_artifact_id].get("display_name", _run_state.active_artifact_id))
	if _run_state.branch_state == FatherTimeRunStateScript.ENDING_SAVED:
		return "DeLorean-ready tableau"
	if _run_state.branch_state == FatherTimeRunStateScript.ENDING_COLLAPSE:
		return "Paradox locked"
	return "Awaiting selection"

func _get_timeline_read() -> String:
	if _run_state.branch_state == FatherTimeRunStateScript.ENDING_SAVED:
		return "Stabilized"
	if _run_state.branch_state == FatherTimeRunStateScript.ENDING_COLLAPSE:
		return "Collapsed into paradox"

	var warning_threshold := int(_tuning.get("instability_warning_threshold", 4))
	var collapse_threshold := int(_tuning.get("instability_collapse_threshold", 8))
	if _run_state.instability >= collapse_threshold:
		return "Paradox imminent"
	if _run_state.instability >= warning_threshold:
		return "Biff pressure rising"
	if _run_state.instability < 0:
		return "History repairing itself"
	return "Contained"

func _get_status_color() -> Color:
	if _run_state.branch_state == FatherTimeRunStateScript.ENDING_SAVED:
		return _get_tone_color("saved")
	if _run_state.branch_state == FatherTimeRunStateScript.ENDING_COLLAPSE:
		return _get_tone_color("collapse")
	if _run_state.instability >= int(_tuning.get("instability_warning_threshold", 4)):
		return _get_tone_color("warning")
	return _get_tone_color("status")

func _get_tone_color(tone: String) -> Color:
	match tone:
		"saved":
			return _tuning.get("saved_text_color", Color(0.72, 0.95, 0.87, 1.0))
		"collapse":
			return _tuning.get("collapse_text_color", Color(1.0, 0.58, 0.54, 1.0))
		"warning":
			return _tuning.get("warning_text_color", Color(1.0, 0.82, 0.47, 1.0))
		"consequence":
			return _tuning.get("consequence_text_color", Color(0.94, 0.9, 0.82, 1.0))
		"instruction":
			return _tuning.get("instruction_text_color", Color(0.9, 0.87, 0.79, 1.0))
		_:
			return _tuning.get("status_text_color", Color(0.96, 0.92, 0.84, 1.0))

func _configure_artifact_tray() -> void:
	_artifact_tray_anchor.visible = false
	_artifact_tray_plinth.material_override = _make_surface_material(
		_tuning.get("artifact_tray_base_color", Color(0.2, 0.16, 0.12, 1.0))
	)

func _create_landmark_labels() -> void:
	_landmark_labels_by_era.clear()
	var label_specs: Dictionary = {
		"1955": [
			{"node_path": "Era1955/ClockTowerProxy", "text": "Clock Tower", "world_offset": Vector3(0, 3.0, 0), "screen_offset": Vector2(-28, -16)},
			{"node_path": "Era1955/TownSquareProxy", "text": "Town Square", "world_offset": Vector3(0, 1.35, 0), "screen_offset": Vector2(-34, -14)},
			{"node_path": "Era1955/DinerProxy", "text": "Doc's Diner", "world_offset": Vector3(0, 1.0, 0), "screen_offset": Vector2(-30, -14)},
		],
		"1985": [
			{"node_path": "Era1985/BiffPressureProxy", "text": "Biff", "world_offset": Vector3(0, 3.0, 0), "screen_offset": Vector2(-10, -18)},
			{"node_path": "Era1985/MallProxy", "text": "Twin Pines Mall", "world_offset": Vector3(0, 2.0, 0), "screen_offset": Vector2(-48, -18)},
			{"node_path": "Era1985/BillboardProxy", "text": "Biff Billboard", "world_offset": Vector3(0, 3.0, 0), "screen_offset": Vector2(-50, -18)},
		],
		"2015": [
			{"node_path": "Era2015/DeLoreanProxy", "text": "DeLorean", "world_offset": Vector3(0, 1.4, 0), "screen_offset": Vector2(-28, -18)},
			{"node_path": "Era2015/FutureTowerProxy", "text": "Clock Tower Spire", "world_offset": Vector3(0, 4.1, 0), "screen_offset": Vector2(-60, -18)},
			{"node_path": "Era2015/HoverLaneProxy", "text": "Hover Lane", "world_offset": Vector3(0, 1.5, 0), "screen_offset": Vector2(-34, -18)},
		],
	}

	for era_id_variant in label_specs.keys():
		var era_id := String(era_id_variant)
		var labels: Array = []
		var era_specs: Array = label_specs.get(era_id, [])
		for spec_variant in era_specs:
			var spec: Dictionary = spec_variant
			var target_node := get_node_or_null(NodePath(String(spec.get("node_path", "")))) as Node3D
			if target_node == null:
				continue

			var label := Label.new()
			label.name = "%sCallout" % String(spec.get("text", "Landmark")).replace(" ", "")
			label.text = String(spec.get("text", "Landmark"))
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			label.add_theme_font_size_override("font_size", 14)
			label.add_theme_constant_override("outline_size", 6)
			label.add_theme_color_override("font_color", _tuning.get("landmark_label_color", Color(0.98, 0.95, 0.84, 1.0)))
			label.add_theme_color_override("font_outline_color", _tuning.get("landmark_label_outline_color", Color(0.11, 0.09, 0.06, 0.95)))
			label.visible = false
			_canvas_layer.add_child(label)
			labels.append({
				"label": label,
				"target": target_node,
				"world_offset": spec.get("world_offset", Vector3(0, 1.5, 0)),
				"screen_offset": spec.get("screen_offset", Vector2(-32, -18)),
			})
		_landmark_labels_by_era[era_id] = labels

func _update_landmark_label_visibility() -> void:
	for era_id_variant in _landmark_labels_by_era.keys():
		var era_id := String(era_id_variant)
		var labels: Array = _landmark_labels_by_era.get(era_id, [])
		for label_variant in labels:
			var label := (label_variant as Dictionary).get("label") as Label
			if label != null:
				label.visible = era_id == _run_state.active_era_id

func _update_landmark_label_positions() -> void:
	var viewport_rect := get_viewport().get_visible_rect()
	for era_id_variant in _landmark_labels_by_era.keys():
		var era_id := String(era_id_variant)
		var labels: Array = _landmark_labels_by_era.get(era_id, [])
		for label_variant in labels:
			var label_bundle := label_variant as Dictionary
			var label := label_bundle.get("label") as Label
			var target := label_bundle.get("target") as Node3D
			if label == null or target == null:
				continue
			if era_id != _run_state.active_era_id:
				label.visible = false
				continue

			var world_offset: Vector3 = label_bundle.get("world_offset", Vector3.ZERO)
			var world_point: Vector3 = target.global_position + world_offset
			if _main_camera.is_position_behind(world_point):
				label.visible = false
				continue

			var screen_offset: Vector2 = label_bundle.get("screen_offset", Vector2.ZERO)
			var screen_position: Vector2 = _main_camera.unproject_position(world_point) + screen_offset
			var label_size: Vector2 = label.get_combined_minimum_size()
			var clamped_x := clampf(screen_position.x, 12.0, viewport_rect.size.x - label_size.x - 12.0)
			var clamped_y := clampf(screen_position.y, 12.0, viewport_rect.size.y - label_size.y - 12.0)
			label.position = Vector2(clamped_x, clamped_y)
			label.visible = true

func _make_surface_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	return material

func _refresh_active_artifact_preview() -> void:
	_clear_artifact_preview()
	_artifact_tray_anchor.visible = false

func _build_artifact_proxy_root(artifact_id: String, context: String) -> Node3D:
	var preview_root := Node3D.new()
	var preview_specs: Dictionary = _get_artifact_preview_spec(artifact_id)
	if context == "placed":
		preview_root.rotation_degrees = _get_placed_artifact_rotation(artifact_id)
		preview_root.position = _get_placed_artifact_offset(artifact_id)
		preview_root.scale = Vector3(0.55, 0.55, 0.55)
	else:
		preview_root.rotation_degrees = preview_specs.get("tilt_degrees", Vector3.ZERO)
		preview_root.scale = Vector3(0.18, 0.18, 0.18)

	match artifact_id:
		"save_clock_tower_flyer":
			_build_flyer_preview(preview_root, preview_specs)
		"lightning_cable_hook":
			_build_hook_preview(preview_root, preview_specs)
		"sports_almanac":
			_build_almanac_preview(preview_root, preview_specs)
		"delorean_key":
			_build_key_preview(preview_root, preview_specs)
		_:
			_build_placeholder_preview(preview_root, preview_specs)

	return preview_root

func _clear_artifact_preview() -> void:
	for child in _artifact_preview_pivot.get_children():
		child.queue_free()

func _get_artifact_preview_spec(artifact_id: String) -> Dictionary:
	var all_specs: Dictionary = _tuning.get("artifact_preview_specs", {})
	return all_specs.get(artifact_id, {})

func _get_placed_artifact_rotation(artifact_id: String) -> Vector3:
	match artifact_id:
		"save_clock_tower_flyer":
			return Vector3(0, -12, 0)
		"lightning_cable_hook":
			return Vector3(0, 18, 0)
		"sports_almanac":
			return Vector3(-4, 14, 0)
		"delorean_key":
			return Vector3(0, 24, 0)
		_:
			return Vector3.ZERO

func _get_placed_artifact_offset(artifact_id: String) -> Vector3:
	match artifact_id:
		"save_clock_tower_flyer":
			return Vector3(0, 0.02, 0.0)
		"lightning_cable_hook":
			return Vector3(-0.04, 0.0, 0.0)
		"sports_almanac":
			return Vector3(0.0, 0.02, 0.0)
		"delorean_key":
			return Vector3(-0.03, 0.04, 0.0)
		_:
			return Vector3.ZERO

func _build_flyer_preview(preview_root: Node3D, preview_specs: Dictionary) -> void:
	var primary: Color = preview_specs.get("primary_color", Color(0.96, 0.88, 0.62, 1.0))
	var accent: Color = preview_specs.get("accent_color", Color(0.63, 0.24, 0.18, 1.0))
	preview_root.add_child(_make_box_piece("FlyerBody", Vector3(0.92, 0.04, 0.68), Vector3(0, 0.02, 0), primary))
	preview_root.add_child(_make_box_piece("FlyerHeader", Vector3(0.92, 0.035, 0.16), Vector3(0, 0.05, -0.2), accent))
	preview_root.add_child(_make_box_piece("FlyerFold", Vector3(0.92, 0.02, 0.08), Vector3(0, 0.03, 0.24), accent))

func _build_hook_preview(preview_root: Node3D, preview_specs: Dictionary) -> void:
	var primary: Color = preview_specs.get("primary_color", Color(0.86, 0.72, 0.34, 1.0))
	var accent: Color = preview_specs.get("accent_color", Color(0.48, 0.35, 0.16, 1.0))
	preview_root.add_child(_make_box_piece("HookBase", Vector3(0.28, 0.06, 0.18), Vector3(-0.1, 0.03, 0), accent))
	preview_root.add_child(_make_box_piece("HookStem", Vector3(0.11, 0.72, 0.11), Vector3(-0.1, 0.39, 0), primary))
	preview_root.add_child(_make_box_piece("HookArm", Vector3(0.52, 0.1, 0.1), Vector3(0.14, 0.68, 0), primary))
	preview_root.add_child(_make_box_piece("HookTip", Vector3(0.1, 0.3, 0.1), Vector3(0.36, 0.54, 0), accent))

func _build_almanac_preview(preview_root: Node3D, preview_specs: Dictionary) -> void:
	var primary: Color = preview_specs.get("primary_color", Color(0.79, 0.42, 0.29, 1.0))
	var accent: Color = preview_specs.get("accent_color", Color(0.95, 0.79, 0.31, 1.0))
	preview_root.add_child(_make_box_piece("BookBody", Vector3(0.72, 0.16, 0.96), Vector3(0, 0.08, 0), primary))
	preview_root.add_child(_make_box_piece("BookSpine", Vector3(0.08, 0.17, 0.96), Vector3(-0.32, 0.085, 0), accent))
	preview_root.add_child(_make_box_piece("Bookmark", Vector3(0.06, 0.03, 0.24), Vector3(0.06, 0.17, 0.28), accent))

func _build_key_preview(preview_root: Node3D, preview_specs: Dictionary) -> void:
	var primary: Color = preview_specs.get("primary_color", Color(0.77, 0.91, 1.0, 1.0))
	var accent: Color = preview_specs.get("accent_color", Color(0.42, 0.72, 0.84, 1.0))
	preview_root.add_child(_make_box_piece("KeyHead", Vector3(0.36, 0.14, 0.36), Vector3(-0.2, 0.07, 0), primary))
	preview_root.add_child(_make_box_piece("KeyStem", Vector3(0.7, 0.06, 0.12), Vector3(0.16, 0.07, 0), primary))
	preview_root.add_child(_make_box_piece("KeyToothA", Vector3(0.12, 0.12, 0.12), Vector3(0.42, 0.04, 0), accent))
	preview_root.add_child(_make_box_piece("KeyToothB", Vector3(0.08, 0.08, 0.12), Vector3(0.54, 0.02, 0), accent))

func _build_placeholder_preview(preview_root: Node3D, preview_specs: Dictionary) -> void:
	var primary: Color = preview_specs.get("primary_color", Color(0.78, 0.78, 0.78, 1.0))
	preview_root.add_child(_make_box_piece("Placeholder", Vector3(0.48, 0.32, 0.48), Vector3(0, 0.16, 0), primary))

func _make_box_piece(name: String, size: Vector3, position: Vector3, color: Color) -> MeshInstance3D:
	var piece := MeshInstance3D.new()
	piece.name = name
	var mesh := BoxMesh.new()
	mesh.size = size
	piece.mesh = mesh
	piece.position = position
	piece.material_override = _make_surface_material(color)
	return piece

func _place_artifact_at_slot(slot_id: String, artifact_id: String) -> void:
	var slot_bundle: Dictionary = _compiled_slice.get("slots", {}).get(slot_id, {})
	var slot_node := slot_bundle.get("node") as Node3D
	if slot_node == null:
		return

	if _placed_artifact_by_slot_id.has(slot_id):
		var existing := _placed_artifact_by_slot_id[slot_id] as Node3D
		if existing != null:
			existing.queue_free()

	var placed_root := _build_artifact_proxy_root(artifact_id, "placed")
	placed_root.name = "%sPlacedArtifact" % artifact_id
	slot_node.add_child(placed_root)
	_placed_artifact_by_slot_id[slot_id] = placed_root

func _make_indicator_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material

func _apply_indicator_color(indicator: MeshInstance3D, color: Color) -> void:
	var material := indicator.material_override as StandardMaterial3D
	if material != null:
		material.albedo_color = color

func _apply_scene_grading() -> void:
	if _run_state.branch_state == FatherTimeRunStateScript.ENDING_SAVED:
		_directional_light.light_color = Color(0.96, 0.98, 1.0, 1.0)
		_directional_light.light_energy = 1.95
		_fill_light.light_color = Color(0.68, 0.92, 1.0, 1.0)
		_fill_light.light_energy = 0.8
		_rim_light.light_color = Color(0.74, 0.95, 0.9, 1.0)
		_rim_light.light_energy = 0.28
		return

	if _run_state.branch_state == FatherTimeRunStateScript.ENDING_COLLAPSE:
		_directional_light.light_color = Color(1.0, 0.74, 0.62, 1.0)
		_directional_light.light_energy = 1.55
		_fill_light.light_color = Color(0.71, 0.42, 0.36, 1.0)
		_fill_light.light_energy = 0.32
		_rim_light.light_color = Color(1.0, 0.42, 0.34, 1.0)
		_rim_light.light_energy = 0.78
		return

	var warning_threshold := int(_tuning.get("instability_warning_threshold", 4))
	if _run_state.instability >= warning_threshold:
		_directional_light.light_color = Color(1.0, 0.88, 0.76, 1.0)
		_directional_light.light_energy = 1.75
		_fill_light.light_color = Color(0.78, 0.63, 0.48, 1.0)
		_fill_light.light_energy = 0.48
		_rim_light.light_color = Color(1.0, 0.72, 0.42, 1.0)
		_rim_light.light_energy = 0.62
		return

	_directional_light.light_color = Color(1.0, 0.96, 0.88, 1.0)
	_directional_light.light_energy = 1.8
	_fill_light.light_color = Color(0.72, 0.81, 0.92, 1.0)
	_fill_light.light_energy = 0.65
	_rim_light.light_color = Color(0.95, 0.76, 0.53, 1.0)
	_rim_light.light_energy = 0.4
	_apply_2015_tableau()

func _cache_default_tableau_transforms() -> void:
	_default_tableau_transforms.clear()
	for node_path in [
		"Era2015/Ground",
		"Era2015/DeLoreanProxy",
		"Era2015/FutureTowerProxy",
		"Era2015/HoverLaneProxy",
	]:
		var node := get_node_or_null(NodePath(node_path)) as Node3D
		if node != null:
			_default_tableau_transforms[String(node_path)] = node.transform

func _apply_2015_tableau() -> void:
	var ground := get_node_or_null(^"Era2015/Ground") as Node3D
	var delorean := get_node_or_null(^"Era2015/DeLoreanProxy") as Node3D
	var tower := get_node_or_null(^"Era2015/FutureTowerProxy") as Node3D
	var lane := get_node_or_null(^"Era2015/HoverLaneProxy") as Node3D
	if ground == null or delorean == null or tower == null or lane == null:
		return

	_reset_tableau_node("Era2015/Ground", ground)
	_reset_tableau_node("Era2015/DeLoreanProxy", delorean)
	_reset_tableau_node("Era2015/FutureTowerProxy", tower)
	_reset_tableau_node("Era2015/HoverLaneProxy", lane)

	match _run_state.branch_state:
		FatherTimeRunStateScript.ENDING_SAVED:
			delorean.position = Vector3(0, 0, -0.2)
			delorean.rotation_degrees = Vector3(0, -8, 0)
			tower.position = Vector3(-2.45, 0, -1.95)
			tower.scale = Vector3(1.0, 1.08, 1.0)
			lane.position = Vector3(2.2, 0.12, -0.28)
			lane.rotation_degrees = Vector3(0, 3, 0)
		FatherTimeRunStateScript.ENDING_COLLAPSE:
			delorean.position = Vector3(-0.25, -0.02, -0.1)
			delorean.rotation_degrees = Vector3(0, 18, -9)
			tower.position = Vector3(-2.0, -0.08, -1.55)
			tower.rotation_degrees = Vector3(0, 0, 10)
			tower.scale = Vector3(1.0, 0.94, 1.0)
			lane.position = Vector3(2.35, -0.08, -0.05)
			lane.rotation_degrees = Vector3(0, -10, -6)
			ground.scale = Vector3(1.0, 1.0, 0.92)
		_:
			if _run_state.instability >= int(_tuning.get("instability_warning_threshold", 4)):
				delorean.position = Vector3(0.05, 0, -0.42)
				delorean.rotation_degrees = Vector3(0, 7, 0)
				tower.position = Vector3(-2.2, 0, -1.75)
				tower.rotation_degrees = Vector3(0, 0, 3)
				lane.position = Vector3(2.1, 0.05, -0.15)
				lane.rotation_degrees = Vector3(0, -4, 0)

func _reset_tableau_node(path: String, node: Node3D) -> void:
	if _default_tableau_transforms.has(path):
		node.transform = _default_tableau_transforms[path]

func _build_artifact_order() -> void:
	_artifact_order_by_era.clear()
	var eras: Dictionary = _content.get("eras", {})

	for era_id_variant in eras.keys():
		var era_id := String(era_id_variant)
		_artifact_order_by_era[era_id] = FirstSliceContentScript.get_artifact_ids_for_era(_content, era_id)

func _create_slot_indicators() -> void:
	_slot_indicator_by_slot_id.clear()
	var slots: Dictionary = _compiled_slice.get("slots", {})

	for slot_id_variant in slots.keys():
		var slot_id := String(slot_id_variant)
		var slot_bundle: Dictionary = slots[slot_id_variant]
		var slot_node := slot_bundle.get("node") as Node3D
		if slot_node == null:
			continue

		var indicator_root := Node3D.new()
		indicator_root.name = "%sIndicator" % slot_id

		var base := MeshInstance3D.new()
		base.name = "Pedestal"
		var base_mesh := CylinderMesh.new()
		base_mesh.top_radius = 0.26
		base_mesh.bottom_radius = 0.3
		base_mesh.height = 0.05
		base.mesh = base_mesh
		base.position = Vector3(0, 0.025, 0)
		base.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		base.material_override = _make_indicator_material(_tuning.get("slot_indicator_idle_color", Color(0.66, 0.5, 0.24, 0.94)))
		indicator_root.add_child(base)

		var socket := MeshInstance3D.new()
		socket.name = "Socket"
		var socket_mesh := CylinderMesh.new()
		socket_mesh.top_radius = 0.14
		socket_mesh.bottom_radius = 0.18
		socket_mesh.height = 0.03
		socket.mesh = socket_mesh
		socket.position = Vector3(0, 0.065, 0)
		socket.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		socket.material_override = _make_indicator_material(_tuning.get("slot_indicator_socket_color", Color(0.26, 0.18, 0.09, 1.0)))
		indicator_root.add_child(socket)

		var halo := MeshInstance3D.new()
		halo.name = "Halo"
		var halo_mesh := CylinderMesh.new()
		halo_mesh.top_radius = 0.29
		halo_mesh.bottom_radius = 0.31
		halo_mesh.height = 0.015
		halo.mesh = halo_mesh
		halo.position = Vector3(0, 0.095, 0)
		halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		halo.material_override = _make_indicator_material(_tuning.get("slot_indicator_idle_color", Color(0.66, 0.5, 0.24, 0.94)))
		indicator_root.add_child(halo)

		slot_node.add_child(indicator_root)
		_slot_indicator_by_slot_id[slot_id] = {
			"root": indicator_root,
			"base": base,
			"socket": socket,
			"halo": halo,
		}

func _select_first_available_artifact_for_active_era() -> void:
	var artifact_id := _get_first_available_artifact_id(_run_state.active_era_id)
	if artifact_id == "":
		_run_state.clear_active_artifact()
	else:
		_run_state.set_active_artifact(artifact_id)

func _get_first_available_artifact_id(era_id: String) -> String:
	var artifact_ids: Array = _artifact_order_by_era.get(era_id, [])
	for artifact_id_variant in artifact_ids:
		var artifact_id := String(artifact_id_variant)
		if not _run_state.is_artifact_resolved(artifact_id):
			return artifact_id
	return ""

func _cycle_active_artifact(direction: int) -> void:
	var artifact_ids: Array = _artifact_order_by_era.get(_run_state.active_era_id, [])
	var unresolved: Array[String] = []
	for artifact_id_variant in artifact_ids:
		var artifact_id := String(artifact_id_variant)
		if not _run_state.is_artifact_resolved(artifact_id):
			unresolved.append(artifact_id)

	if unresolved.is_empty():
		_run_state.clear_active_artifact()
		_update_slot_indicator_state()
		_show_boot_success()
		return

	var current_index := 0
	if unresolved.has(_run_state.active_artifact_id):
		current_index = unresolved.find(_run_state.active_artifact_id)

	var next_index := wrapi(current_index + direction, 0, unresolved.size())
	set_active_artifact(unresolved[next_index])

func _update_hover_from_mouse(mouse_position: Vector2) -> void:
	var candidate_slot_id := _find_hovered_slot_id(mouse_position)
	if candidate_slot_id == _hovered_slot_id:
		return

	_hovered_slot_id = candidate_slot_id
	_update_slot_indicator_state()
	_update_instruction_copy()

func _find_hovered_slot_id(mouse_position: Vector2) -> String:
	var artifacts: Dictionary = _compiled_slice.get("artifacts", {})
	if not artifacts.has(_run_state.active_artifact_id):
		return ""

	var artifact_bundle: Dictionary = artifacts[_run_state.active_artifact_id]
	var valid_slot_ids: Array = artifact_bundle.get("valid_slot_ids", [])
	var closest_slot_id := ""
	var closest_distance := INF
	var hover_radius := float(_tuning.get("hover_radius_pixels", 48.0))

	for slot_id_variant in valid_slot_ids:
		var slot_id := String(slot_id_variant)
		var slot_bundle: Dictionary = _compiled_slice.get("slots", {}).get(slot_id, {})
		var slot_node := slot_bundle.get("node") as Node3D
		if slot_node == null:
			continue

		if String(slot_bundle.get("era_id", "")) != _run_state.active_era_id:
			continue

		var screen_position := _main_camera.unproject_position(slot_node.global_position)
		var distance := screen_position.distance_to(mouse_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_slot_id = slot_id

	if closest_slot_id == "":
		return ""

	if closest_distance > hover_radius:
		return ""

	return closest_slot_id

func _update_slot_indicator_state() -> void:
	var artifacts: Dictionary = _compiled_slice.get("artifacts", {})
	var slots: Dictionary = _compiled_slice.get("slots", {})
	var valid_slot_ids: Array = []

	if artifacts.has(_run_state.active_artifact_id):
		valid_slot_ids = artifacts[_run_state.active_artifact_id].get("valid_slot_ids", [])

	for slot_id_variant in _slot_indicator_by_slot_id.keys():
		var slot_id := String(slot_id_variant)
		var indicator_bundle: Dictionary = _slot_indicator_by_slot_id.get(slot_id, {})
		var indicator_root := indicator_bundle.get("root") as Node3D
		var indicator_base := indicator_bundle.get("base") as MeshInstance3D
		var indicator_socket := indicator_bundle.get("socket") as MeshInstance3D
		var indicator_halo := indicator_bundle.get("halo") as MeshInstance3D
		if indicator_root == null or indicator_base == null or indicator_socket == null or indicator_halo == null:
			continue

		var slot_bundle: Dictionary = slots.get(slot_id, {})
		var is_in_live_era: bool = String(slot_bundle.get("era_id", "")) == _run_state.active_era_id
		var is_valid_for_active: bool = valid_slot_ids.has(slot_id)
		var is_hovered: bool = slot_id == _hovered_slot_id

		indicator_root.visible = is_in_live_era and is_valid_for_active and not _run_state.is_slot_resolved(slot_id)
		if not indicator_root.visible:
			continue

		indicator_root.scale = _tuning.get("slot_indicator_hover_scale", Vector3(1.14, 1.14, 1.14)) if is_hovered else _tuning.get("slot_indicator_idle_scale", Vector3(0.94, 0.94, 0.94))
		var indicator_color: Color = _tuning.get("slot_indicator_hover_color", Color(1.0, 0.84, 0.38, 1.0)) if is_hovered else _tuning.get("slot_indicator_idle_color", Color(0.66, 0.5, 0.24, 0.94))
		_apply_indicator_color(indicator_base, indicator_color)
		_apply_indicator_color(indicator_halo, indicator_color)
		_apply_indicator_color(indicator_socket, _tuning.get("slot_indicator_socket_color", Color(0.26, 0.18, 0.09, 1.0)))

func _update_instruction_copy() -> void:
	if _run_state.branch_state == FatherTimeRunStateScript.ENDING_SAVED:
		_instruction_label.text = "Timeline repaired. Restart to explore another branch."
		_instruction_label.modulate = _get_tone_color("saved")
		return

	if _run_state.branch_state == FatherTimeRunStateScript.ENDING_COLLAPSE:
		_instruction_label.text = "Paradox sealed. Restart to explore another branch."
		_instruction_label.modulate = _get_tone_color("collapse")
		return

	var artifacts: Dictionary = _compiled_slice.get("artifacts", {})
	if not artifacts.has(_run_state.active_artifact_id):
		_instruction_label.text = "No unresolved artifact remains in this era."
		_instruction_label.modulate = _get_tone_color("instruction")
		return
	
	var artifact_bundle: Dictionary = artifacts.get(_run_state.active_artifact_id, {})
	var corruption_outcome_id := String(artifact_bundle.get("corruption_outcome_id", ""))
	var goal_detail := _get_current_goal_detail()
	var cycle_hint := _get_cycle_hint()
	_instruction_label.modulate = _get_tone_color("warning") if _run_state.instability >= int(_tuning.get("instability_warning_threshold", 4)) else _get_tone_color("instruction")

	if _hovered_slot_id == "":
		if corruption_outcome_id == "":
			_instruction_label.text = "%s\nSet it into the brass socket.%s" % [goal_detail, cycle_hint]
		else:
			_instruction_label.text = "%s\nLeft click preserves. Right click corrupts.%s" % [goal_detail, cycle_hint]
		return

	if corruption_outcome_id == "":
		_instruction_label.text = "%s\nLeft click commits this socket.%s" % [goal_detail, cycle_hint]
	else:
		_instruction_label.text = "%s\nLeft preserves. Right corrupts.%s" % [goal_detail, cycle_hint]

func _get_current_goal_summary() -> String:
	match _run_state.active_artifact_id:
		"save_clock_tower_flyer":
			return "Secure flyer at Town Square"
		"lightning_cable_hook":
			return "Lock Doc's hook by the diner"
		"sports_almanac":
			return "Decide the Almanac's fate"
		"delorean_key":
			return "Commit the DeLorean key"
		_:
			if _run_state.branch_state == FatherTimeRunStateScript.ENDING_SAVED:
				return "Timeline repaired"
			if _run_state.branch_state == FatherTimeRunStateScript.ENDING_COLLAPSE:
				return "Paradox sealed"
			return "Await the next ripple"

func _get_current_goal_detail() -> String:
	match _run_state.active_artifact_id:
		"save_clock_tower_flyer":
			return "Secure the flyer at Town Square."
		"lightning_cable_hook":
			return "Lock Doc's hook beside the diner."
		"sports_almanac":
			return "Decide whether Biff keeps the Almanac."
		"delorean_key":
			return "Commit the DeLorean key on the 2015 launch pad."
		_:
			if _run_state.branch_state == FatherTimeRunStateScript.ENDING_SAVED:
				return "Timeline stabilized."
			if _run_state.branch_state == FatherTimeRunStateScript.ENDING_COLLAPSE:
				return "Paradox sealed."
			return "Await the next timeline beat."

func _get_opening_prompt() -> String:
	return "Set the flyer into Town Square to keep Hill Valley on course."

func _get_cycle_hint() -> String:
	var unresolved_count := 0
	var artifact_ids: Array = _artifact_order_by_era.get(_run_state.active_era_id, [])
	for artifact_id_variant in artifact_ids:
		if not _run_state.is_artifact_resolved(String(artifact_id_variant)):
			unresolved_count += 1
	if unresolved_count > 1:
		return " Q/E swaps artifacts."
	return ""

func _humanize_slot_id(slot_id: String) -> String:
	var cleaned := slot_id.replace("_1955", "").replace("_1985", "").replace("_2015", "")
	var words: Array = cleaned.split("_", false)
	var titled_words: Array[String] = []
	for word_variant in words:
		var word := String(word_variant)
		if word == "slot":
			continue
		titled_words.append(word.capitalize())
	return " ".join(titled_words)

func _try_commit_hovered_slot(use_corruption_outcome: bool) -> bool:
	if _hovered_slot_id == "":
		return false

	var artifacts: Dictionary = _compiled_slice.get("artifacts", {})
	if not artifacts.has(_run_state.active_artifact_id):
		return false

	var artifact_bundle: Dictionary = artifacts[_run_state.active_artifact_id]
	var outcome_id := String(artifact_bundle.get("success_outcome_id", ""))
	if use_corruption_outcome:
		var corruption_outcome_id := String(artifact_bundle.get("corruption_outcome_id", ""))
		if corruption_outcome_id == "":
			return false
		outcome_id = corruption_outcome_id

	var outcomes: Dictionary = _compiled_slice.get("outcomes", {})
	if not outcomes.has(outcome_id):
		push_error("[FatherTimeDioramaRoot] Unknown outcome '%s'." % outcome_id)
		return false

	if _run_state.is_slot_resolved(_hovered_slot_id):
		push_error("[FatherTimeDioramaRoot] Slot '%s' is already resolved." % _hovered_slot_id)
		return false

	if _run_state.is_artifact_resolved(_run_state.active_artifact_id):
		push_error("[FatherTimeDioramaRoot] Artifact '%s' is already resolved." % _run_state.active_artifact_id)
		return false

	var resolved_artifact_id: String = _run_state.active_artifact_id
	var resolved_slot_id: String = _hovered_slot_id
	var outcome_bundle: Dictionary = outcomes[outcome_id]
	if not _run_state.apply_outcome(outcome_id, outcome_bundle, resolved_artifact_id, resolved_slot_id):
		return false

	_hovered_slot_id = ""
	_handle_outcome(outcome_id, outcome_bundle, resolved_artifact_id, resolved_slot_id)
	return true

func _handle_outcome(outcome_id: String, outcome_bundle: Dictionary, artifact_id: String, slot_id: String) -> void:
	var caption := String(outcome_bundle.get("caption", outcome_id))
	var branch_state := String(outcome_bundle.get("branch_state", FatherTimeRunStateScript.ENDING_CONTINUE))
	_place_artifact_at_slot(slot_id, artifact_id)

	match branch_state:
		FatherTimeRunStateScript.ENDING_SAVED:
			_set_consequence_copy("Saved ending: %s" % caption, _get_tone_color("saved"))
		FatherTimeRunStateScript.ENDING_COLLAPSE:
			_set_consequence_copy("Collapse ending: %s" % caption, _get_tone_color("collapse"))
		_:
			_set_consequence_copy("Resolved %s into %s.\n%s" % [artifact_id, slot_id, caption], _get_tone_color("consequence"))

	_enter_live_era(_run_state.active_era_id)
	if branch_state == FatherTimeRunStateScript.ENDING_CONTINUE:
		_select_first_available_artifact_for_active_era()
	_show_boot_success()

func _set_consequence_copy(message: String, color: Color, animate: bool = true) -> void:
	if _consequence_tween != null:
		_consequence_tween.kill()

	_consequence_label.text = message
	if not animate:
		_consequence_label.modulate = color
		return

	var faded_color := color
	faded_color.a = 0.0
	_consequence_label.modulate = faded_color

	var fade_seconds := float(_tuning.get("caption_fade_seconds", 0.35))
	if fade_seconds <= 0.0:
		_consequence_label.modulate = color
		return

	_consequence_tween = create_tween()
	_consequence_tween.set_trans(int(_tuning.get("caption_tween_trans", Tween.TRANS_QUAD)))
	_consequence_tween.set_ease(int(_tuning.get("caption_tween_ease", Tween.EASE_OUT)))
	_consequence_tween.tween_property(_consequence_label, "modulate", color, fade_seconds)

func _move_camera_to(target_transform: Transform3D, instant: bool = false) -> void:
	var adjusted_origin := target_transform.origin + (target_transform.basis.z * CAMERA_EXTRA_PULLBACK) + (Vector3.UP * CAMERA_EXTRA_LIFT)
	if _camera_tween != null:
		_camera_tween.kill()

	var duration := float(_tuning.get("camera_move_seconds", 1.1))
	if instant or duration <= 0.0:
		_main_camera.global_position = adjusted_origin
		_main_camera.global_rotation = target_transform.basis.get_euler()
		return

	_camera_tween = create_tween()
	_camera_tween.set_trans(int(_tuning.get("camera_tween_trans", Tween.TRANS_SINE)))
	_camera_tween.set_ease(int(_tuning.get("camera_tween_ease", Tween.EASE_IN_OUT)))
	_camera_tween.parallel().tween_property(_main_camera, "global_position", adjusted_origin, duration)
	_camera_tween.parallel().tween_property(_main_camera, "global_rotation", target_transform.basis.get_euler(), duration)
