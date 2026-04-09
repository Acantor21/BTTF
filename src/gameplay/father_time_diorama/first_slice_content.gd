class_name FirstSliceContent
extends RefCounted

static func build() -> Dictionary:
	return {
		"starting_era_id": "1955",
		"artifact_order_by_era": {
			"1955": ["save_clock_tower_flyer", "lightning_cable_hook"],
			"1985": ["sports_almanac"],
			"2015": ["delorean_key"],
		},
		"eras": {
			"1955": {
				"display_name": "Hill Valley, 1955",
				"node_path": "Era1955",
				"hero_camera_anchor_path": "Era1955/HeroCameraAnchor",
				"placard_anchor_path": "Era1955/PlacardAnchor",
			},
			"1985": {
				"display_name": "Hill Valley, 1985",
				"node_path": "Era1985",
				"hero_camera_anchor_path": "Era1985/HeroCameraAnchor",
				"placard_anchor_path": "Era1985/PlacardAnchor",
			},
			"2015": {
				"display_name": "Hill Valley, 2015",
				"node_path": "Era2015",
				"hero_camera_anchor_path": "Era2015/HeroCameraAnchor",
				"placard_anchor_path": "Era2015/PlacardAnchor",
			},
		},
		"slots": {
			"flyer_slot_1955": {
				"era_id": "1955",
				"node_path": "Era1955/SlotAnchors/FlyerSlot",
			},
			"hook_slot_1955": {
				"era_id": "1955",
				"node_path": "Era1955/SlotAnchors/HookSlot",
			},
			"almanac_slot_1985": {
				"era_id": "1985",
				"node_path": "Era1985/SlotAnchors/AlmanacSlot",
			},
			"key_slot_2015": {
				"era_id": "2015",
				"node_path": "Era2015/SlotAnchors/KeySlot",
			},
		},
		"artifacts": {
			"save_clock_tower_flyer": {
				"display_name": "Save the Clock Tower flyer",
				"starting_era_id": "1955",
				"valid_slot_ids": ["flyer_slot_1955"],
				"success_outcome_id": "flyer_thread_secured",
			},
			"lightning_cable_hook": {
				"display_name": "lightning cable hook",
				"starting_era_id": "1955",
				"valid_slot_ids": ["hook_slot_1955"],
				"success_outcome_id": "hook_alignment_locked",
			},
			"sports_almanac": {
				"display_name": "Sports Almanac",
				"starting_era_id": "1985",
				"valid_slot_ids": ["almanac_slot_1985"],
				"success_outcome_id": "almanac_contained",
				"corruption_outcome_id": "almanac_corrupts",
			},
			"delorean_key": {
				"display_name": "DeLorean key",
				"starting_era_id": "2015",
				"valid_slot_ids": ["key_slot_2015"],
				"success_outcome_id": "timeline_saved",
				"corruption_outcome_id": "timeline_collapses",
			},
		},
		"outcomes": {
			"flyer_thread_secured": {
				"branch_state": "continue",
				"next_era_id": "1955",
				"caption": "The town remembers why the Clock Tower matters.",
				"instability_delta": -1,
			},
			"hook_alignment_locked": {
				"branch_state": "continue",
				"next_era_id": "1985",
				"caption": "Doc's setup gains structural certainty.",
				"instability_delta": -2,
			},
			"almanac_contained": {
				"branch_state": "continue",
				"next_era_id": "2015",
				"caption": "Biff's corruption pressure is contained, for now.",
				"instability_delta": -3,
			},
			"almanac_corrupts": {
				"branch_state": "continue",
				"next_era_id": "2015",
				"caption": "Biff's version of history starts to take hold.",
				"instability_delta": 6,
			},
			"timeline_saved": {
				"branch_state": "saved",
				"next_era_id": "2015",
				"caption": "The DeLorean stands ready in a repaired timeline.",
				"instability_delta": -2,
			},
			"timeline_collapses": {
				"branch_state": "collapse",
				"next_era_id": "2015",
				"caption": "The key locks the Clock Tower district into paradox.",
				"instability_delta": 8,
			},
		},
	}

static func get_artifact_ids_for_era(content: Dictionary, era_id: String) -> Array[String]:
	var artifact_ids: Array[String] = []
	var artifacts: Dictionary = content.get("artifacts", {})
	var explicit_order: Array = content.get("artifact_order_by_era", {}).get(era_id, [])

	for artifact_id_variant in explicit_order:
		var explicit_artifact_id := String(artifact_id_variant)
		if artifacts.has(explicit_artifact_id) and not artifact_ids.has(explicit_artifact_id):
			artifact_ids.append(explicit_artifact_id)

	for artifact_id_variant in artifacts.keys():
		var artifact_id := String(artifact_id_variant)
		var artifact_spec: Dictionary = artifacts[artifact_id_variant]
		if String(artifact_spec.get("starting_era_id", "")) == era_id and not artifact_ids.has(artifact_id):
			artifact_ids.append(artifact_id)

	return artifact_ids
