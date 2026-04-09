class_name FatherTimeRunState
extends RefCounted

const ENDING_CONTINUE := "continue"
const ENDING_SAVED := "saved"
const ENDING_COLLAPSE := "collapse"

var active_era_id := ""
var active_artifact_id := ""
var resolved_artifact_ids: Dictionary = {}
var resolved_slot_ids: Dictionary = {}
var instability := 0
var branch_state := ENDING_CONTINUE

func bootstrap(starting_era_id: String) -> void:
	active_era_id = starting_era_id
	active_artifact_id = ""
	resolved_artifact_ids.clear()
	resolved_slot_ids.clear()
	instability = 0
	branch_state = ENDING_CONTINUE

func set_active_era(era_id: String) -> void:
	active_era_id = era_id

func set_active_artifact(artifact_id: String) -> void:
	active_artifact_id = artifact_id

func clear_active_artifact() -> void:
	active_artifact_id = ""

func is_artifact_resolved(artifact_id: String) -> bool:
	return resolved_artifact_ids.has(artifact_id)

func is_slot_resolved(slot_id: String) -> bool:
	return resolved_slot_ids.has(slot_id)

func apply_outcome(outcome_id: String, outcome_data: Dictionary, artifact_id: String, slot_id: String) -> bool:
	if is_artifact_resolved(artifact_id):
		push_error("[FatherTimeRunState] Duplicate artifact resolution attempted: %s" % artifact_id)
		return false

	if is_slot_resolved(slot_id):
		push_error("[FatherTimeRunState] Duplicate slot resolution attempted: %s" % slot_id)
		return false

	resolved_artifact_ids[artifact_id] = outcome_id
	resolved_slot_ids[slot_id] = outcome_id
	instability += int(outcome_data.get("instability_delta", 0))
	branch_state = String(outcome_data.get("branch_state", ENDING_CONTINUE))
	active_era_id = String(outcome_data.get("next_era_id", active_era_id))
	active_artifact_id = ""
	return true
