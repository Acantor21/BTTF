class_name FirstSliceBootValidator
extends RefCounted

const FatherTimeRunStateScript = preload("res://src/core/runtime/father_time_run_state.gd")

const REQUIRED_TOP_LEVEL_KEYS := [
	"starting_era_id",
	"eras",
	"slots",
	"artifacts",
	"outcomes",
]

func validate(root: Node, content: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var compiled := {
		"starting_era_id": String(content.get("starting_era_id", "")),
		"eras": {},
		"slots": {},
		"artifacts": {},
		"outcomes": content.get("outcomes", {}),
	}

	_validate_top_level_keys(content, errors)
	if not errors.is_empty():
		return {
			"ok": false,
			"errors": errors,
			"compiled": {},
		}

	var eras: Dictionary = content.get("eras", {})
	var slots: Dictionary = content.get("slots", {})
	var artifacts: Dictionary = content.get("artifacts", {})
	var outcomes: Dictionary = content.get("outcomes", {})
	var starting_era_id := String(content.get("starting_era_id", ""))

	if not eras.has(starting_era_id):
		errors.append("starting_era_id '%s' does not exist in eras." % starting_era_id)

	_compile_eras(root, eras, compiled, errors)
	_compile_slots(root, slots, compiled, errors)
	_validate_outcomes(eras, outcomes, errors)
	_compile_artifacts(artifacts, compiled, errors)
	_validate_branch_reachability(compiled, errors)

	return {
		"ok": errors.is_empty(),
		"errors": errors,
		"compiled": compiled if errors.is_empty() else {},
	}

static func format_errors(errors: Array) -> String:
	var lines: Array[String] = []
	for error_value in errors:
		lines.append("- %s" % String(error_value))

	var result := ""
	for index in lines.size():
		if index > 0:
			result += "\n"
		result += lines[index]
	return result

func _validate_top_level_keys(content: Dictionary, errors: Array[String]) -> void:
	for key in REQUIRED_TOP_LEVEL_KEYS:
		if not content.has(key):
			errors.append("Missing required top-level key '%s'." % key)

func _compile_eras(root: Node, eras: Dictionary, compiled: Dictionary, errors: Array[String]) -> void:
	for era_id_variant in eras.keys():
		var era_id := String(era_id_variant)
		var era_spec: Dictionary = eras[era_id_variant]
		var node_path_string := String(era_spec.get("node_path", ""))
		var camera_anchor_path_string := String(era_spec.get("hero_camera_anchor_path", ""))
		var placard_anchor_path_string := String(era_spec.get("placard_anchor_path", ""))

		var era_node := root.get_node_or_null(NodePath(node_path_string)) as Node3D
		var hero_camera_anchor := root.get_node_or_null(NodePath(camera_anchor_path_string)) as Node3D
		var placard_anchor := root.get_node_or_null(NodePath(placard_anchor_path_string)) as Node3D

		if era_node == null:
			errors.append("Era '%s' is missing node_path '%s'." % [era_id, node_path_string])
		if hero_camera_anchor == null:
			errors.append("Era '%s' is missing hero_camera_anchor_path '%s'." % [era_id, camera_anchor_path_string])
		if placard_anchor == null:
			errors.append("Era '%s' is missing placard_anchor_path '%s'." % [era_id, placard_anchor_path_string])

		compiled["eras"][era_id] = {
			"display_name": String(era_spec.get("display_name", era_id)),
			"node": era_node,
			"node_path": node_path_string,
			"hero_camera_anchor": hero_camera_anchor,
			"hero_camera_anchor_path": camera_anchor_path_string,
			"placard_anchor": placard_anchor,
			"placard_anchor_path": placard_anchor_path_string,
		}

func _compile_slots(root: Node, slots: Dictionary, compiled: Dictionary, errors: Array[String]) -> void:
	for slot_id_variant in slots.keys():
		var slot_id := String(slot_id_variant)
		var slot_spec: Dictionary = slots[slot_id_variant]
		var era_id := String(slot_spec.get("era_id", ""))
		var node_path_string := String(slot_spec.get("node_path", ""))
		var slot_node := root.get_node_or_null(NodePath(node_path_string)) as Node3D

		if not compiled["eras"].has(era_id):
			errors.append("Slot '%s' points to unknown era '%s'." % [slot_id, era_id])
		if slot_node == null:
			errors.append("Slot '%s' is missing node_path '%s'." % [slot_id, node_path_string])

		compiled["slots"][slot_id] = {
			"era_id": era_id,
			"node": slot_node,
			"node_path": node_path_string,
		}

func _validate_outcomes(eras: Dictionary, outcomes: Dictionary, errors: Array[String]) -> void:
	var has_saved := false
	var has_collapse := false

	for outcome_id_variant in outcomes.keys():
		var outcome_id := String(outcome_id_variant)
		var outcome_spec: Dictionary = outcomes[outcome_id_variant]
		var branch_state := String(outcome_spec.get("branch_state", ""))
		var next_era_id := String(outcome_spec.get("next_era_id", ""))

		if not eras.has(next_era_id):
			errors.append("Outcome '%s' points to unknown next_era_id '%s'." % [outcome_id, next_era_id])

		if branch_state == FatherTimeRunStateScript.ENDING_SAVED:
			has_saved = true
		elif branch_state == FatherTimeRunStateScript.ENDING_COLLAPSE:
			has_collapse = true
		elif branch_state != FatherTimeRunStateScript.ENDING_CONTINUE:
			errors.append("Outcome '%s' has invalid branch_state '%s'." % [outcome_id, branch_state])

	if not has_saved:
		errors.append("No saved ending outcome exists in the first-slice content.")
	if not has_collapse:
		errors.append("No collapse ending outcome exists in the first-slice content.")

func _compile_artifacts(artifacts: Dictionary, compiled: Dictionary, errors: Array[String]) -> void:
	for artifact_id_variant in artifacts.keys():
		var artifact_id := String(artifact_id_variant)
		var artifact_spec: Dictionary = artifacts[artifact_id_variant]
		var starting_era_id := String(artifact_spec.get("starting_era_id", ""))
		var valid_slot_ids: Array[String] = []
		var valid_slot_nodes: Array[Node3D] = []
		var raw_valid_slot_ids: Array = artifact_spec.get("valid_slot_ids", [])
		var success_outcome_id := String(artifact_spec.get("success_outcome_id", ""))
		var corruption_outcome_id := String(artifact_spec.get("corruption_outcome_id", ""))

		if not compiled["eras"].has(starting_era_id):
			errors.append("Artifact '%s' points to unknown starting_era_id '%s'." % [artifact_id, starting_era_id])

		for slot_id_value in raw_valid_slot_ids:
			var slot_id := String(slot_id_value)
			valid_slot_ids.append(slot_id)
			if not compiled["slots"].has(slot_id):
				errors.append("Artifact '%s' points to unknown slot '%s'." % [artifact_id, slot_id])
				continue
			valid_slot_nodes.append(compiled["slots"][slot_id]["node"])

		if valid_slot_ids.is_empty():
			errors.append("Artifact '%s' must declare at least one valid_slot_id." % artifact_id)

		if not compiled["outcomes"].has(success_outcome_id):
			errors.append("Artifact '%s' points to unknown success_outcome_id '%s'." % [artifact_id, success_outcome_id])

		if corruption_outcome_id != "" and not compiled["outcomes"].has(corruption_outcome_id):
			errors.append("Artifact '%s' points to unknown corruption_outcome_id '%s'." % [artifact_id, corruption_outcome_id])

		compiled["artifacts"][artifact_id] = {
			"display_name": String(artifact_spec.get("display_name", artifact_id)),
			"starting_era_id": starting_era_id,
			"valid_slot_ids": valid_slot_ids,
			"valid_slot_nodes": valid_slot_nodes,
			"success_outcome_id": success_outcome_id,
			"corruption_outcome_id": corruption_outcome_id,
		}

func _validate_branch_reachability(compiled: Dictionary, errors: Array[String]) -> void:
	var reachable_saved := false
	var reachable_collapse := false
	var artifacts: Dictionary = compiled.get("artifacts", {})
	var outcomes: Dictionary = compiled.get("outcomes", {})

	for artifact_id in artifacts.keys():
		var artifact_spec: Dictionary = artifacts[artifact_id]
		var success_outcome_id := String(artifact_spec.get("success_outcome_id", ""))
		var corruption_outcome_id := String(artifact_spec.get("corruption_outcome_id", ""))

		if outcomes.has(success_outcome_id):
			var success_outcome: Dictionary = outcomes[success_outcome_id]
			if String(success_outcome.get("branch_state", "")) == FatherTimeRunStateScript.ENDING_SAVED:
				reachable_saved = true

		if corruption_outcome_id != "" and outcomes.has(corruption_outcome_id):
			var corruption_outcome: Dictionary = outcomes[corruption_outcome_id]
			if String(corruption_outcome.get("branch_state", "")) == FatherTimeRunStateScript.ENDING_COLLAPSE:
				reachable_collapse = true

	if not reachable_saved:
		errors.append("No artifact path currently reaches the saved ending.")
	if not reachable_collapse:
		errors.append("No artifact path currently reaches the collapse ending.")
