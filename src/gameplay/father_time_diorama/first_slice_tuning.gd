class_name FirstSliceTuning
extends RefCounted

static func build() -> Dictionary:
	return {
		"snap_radius": 1.2,
		"camera_move_seconds": 1.1,
		"camera_tween_trans": Tween.TRANS_SINE,
		"camera_tween_ease": Tween.EASE_IN_OUT,
		"caption_fade_seconds": 0.35,
		"caption_tween_trans": Tween.TRANS_QUAD,
		"caption_tween_ease": Tween.EASE_OUT,
		"hover_radius_pixels": 56.0,
		"instability_warning_threshold": 4,
		"instability_collapse_threshold": 8,
		"boot_status_ok_color": Color(0.95, 0.91, 0.8, 1.0),
		"boot_status_error_color": Color(1.0, 0.62, 0.62, 1.0),
		"status_text_color": Color(0.97, 0.92, 0.82, 1.0),
		"instruction_text_color": Color(0.92, 0.87, 0.77, 1.0),
		"warning_text_color": Color(1.0, 0.82, 0.47, 1.0),
		"saved_text_color": Color(0.72, 0.95, 0.87, 1.0),
		"collapse_text_color": Color(1.0, 0.58, 0.54, 1.0),
		"consequence_text_color": Color(0.95, 0.91, 0.84, 1.0),
		"artifact_tray_base_color": Color(0.23, 0.17, 0.11, 1.0),
		"artifact_tray_trim_color": Color(0.55, 0.41, 0.23, 1.0),
		"landmark_label_color": Color(0.97, 0.93, 0.81, 1.0),
		"landmark_label_outline_color": Color(0.14, 0.11, 0.08, 0.95),
		"landmark_label_font_size": 17,
		"landmark_label_outline_size": 7,
		"artifact_preview_specs": {
			"save_clock_tower_flyer": {
				"primary_color": Color(0.96, 0.88, 0.62, 1.0),
				"accent_color": Color(0.63, 0.24, 0.18, 1.0),
				"tilt_degrees": Vector3(-18, -12, 4),
			},
			"lightning_cable_hook": {
				"primary_color": Color(0.86, 0.72, 0.34, 1.0),
				"accent_color": Color(0.48, 0.35, 0.16, 1.0),
				"tilt_degrees": Vector3(0, -20, 0),
			},
			"sports_almanac": {
				"primary_color": Color(0.79, 0.42, 0.29, 1.0),
				"accent_color": Color(0.95, 0.79, 0.31, 1.0),
				"tilt_degrees": Vector3(-6, 16, 0),
			},
			"delorean_key": {
				"primary_color": Color(0.77, 0.91, 1.0, 1.0),
				"accent_color": Color(0.42, 0.72, 0.84, 1.0),
				"tilt_degrees": Vector3(0, -18, 0),
			},
		},
		"slot_indicator_idle_scale": Vector3(0.94, 0.94, 0.94),
		"slot_indicator_hover_scale": Vector3(1.14, 1.14, 1.14),
		"slot_indicator_idle_color": Color(0.66, 0.5, 0.24, 0.94),
		"slot_indicator_hover_color": Color(1.0, 0.84, 0.38, 1.0),
		"slot_indicator_socket_color": Color(0.26, 0.18, 0.09, 1.0),
	}
