extends Node

var failures := 0
var checks := 0


func _ready() -> void:
	call_deferred("_run_all")


func _run_all() -> void:
	print("Putt & Pixel - Headless-Tests")
	var ball_physics_test := preload("res://tests/ball_physics_test.gd").new(self, _check)
	var moving_mechanisms_test := preload("res://tests/moving_mechanisms_test.gd").new(self, _check)
	var game_shell_test := preload("res://tests/game_shell_test.gd").new(self, _check)
	var technical_holes_test := preload("res://tests/technical_holes_test.gd").new(self, _check)
	var adventure_holes_test := preload("res://tests/adventure_holes_test.gd").new(self, _check)
	var classic_course_test := preload("res://tests/classic_course_test.gd").new(self, _check)
	var arrow_course_test := preload("res://tests/arrow_course_test.gd").new(self, _check)
	var labyrinth_course_test := preload("res://tests/labyrinth_course_test.gd").new(self, _check)
	await ball_physics_test._test_shot_state_machine()
	await load("res://tests/golfer_animation_test.gd").run(self, _check)
	await load("res://tests/golfer_profiles_test.gd").run(self, _check)
	await load("res://tests/course_preview_test.gd").run(self, _check)
	await load("res://tests/golfer_routes_test.gd").run(self, _check)
	ball_physics_test._test_ball_math()
	await ball_physics_test._test_hazard_reset()
	await ball_physics_test._test_tunnel_pair()
	await moving_mechanisms_test._test_rotating_obstacle_wakes_ball()
	await load("res://tests/guardian_tee_test.gd").run(self, _check)
	await load("res://tests/mill_rotors_test.gd").run(self, _check)
	await load("res://tests/factory_gear_test.gd").run(self, _check)
	await load("res://tests/park_tuning_test.gd").run(self, _check)
	await moving_mechanisms_test._test_timed_gate()
	await moving_mechanisms_test._test_seesaw_obstacle()
	await moving_mechanisms_test._test_rotated_obstacle_definitions()
	ball_physics_test._test_slope_directions()
	ball_physics_test._test_atomic_arrow_dynamics()
	await ball_physics_test._test_slope_wall_settling()
	technical_holes_test._test_wall_tiles()
	await load("res://tests/wall_join_test.gd").run(self, _check)
	load("res://tests/curved_outline_test.gd").run(_check)
	await ball_physics_test._test_rotated_surface_zones()
	await technical_holes_test._test_hole_catalog()
	await adventure_holes_test._test_reference_hole()
	await adventure_holes_test._test_classic_diamond_hole()
	await adventure_holes_test._test_double_gate_hole()
	await adventure_holes_test._test_cannon_workshop()
	await classic_course_test._test_classic_nine_course()
	await load("res://tests/classic_route_margin_test.gd").run(self, _check)
	await arrow_course_test._test_arrow_armageddon_course()
	await load("res://tests/arrow_intro_design_test.gd").run(self, _check)
	await load("res://tests/arrow_middle_design_test.gd").run(self, _check)
	await load("res://tests/arrow_late_design_test.gd").run(self, _check)
	await load("res://tests/arrow_finale_design_test.gd").run(self, _check)
	await labyrinth_course_test._test_labyrinth_nine_course()
	await load("res://tests/labyrinth_live_test.gd").run(self, _check)
	await technical_holes_test._test_slope_test_hole()
	await technical_holes_test._test_flow_test_hole()
	await technical_holes_test._test_scroll_test_hole()
	await technical_holes_test._test_curve_lab()
	await technical_holes_test._test_real_lane_references()
	await technical_holes_test._test_gate_lane_family()
	await game_shell_test._test_repeated_hole_switch_input()
	game_shell_test._test_distance_scale()
	await game_shell_test._test_feedback_systems()
	await load("res://tests/sidebar_hud_test.gd").run(self, _check)
	await load("res://tests/scorecard_layout_test.gd").run(self, _check)
	await load("res://tests/prototype_course_test.gd").run(self, _check)
	await game_shell_test._test_game_shell()
	await load("res://tests/eight_worlds_test.gd").run(self, _check)
	await load("res://tests/world_routes_test.gd").run(self, _check)
	game_shell_test._test_controller_support()
	await load("res://tests/cleanup_regression_test.gd").run(self, _check)
	print("\nErgebnis: %d Checks, %d Fehler" % [checks, failures])
	await get_tree().process_frame
	get_tree().quit(0 if failures == 0 else 1)


func _check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("  OK  ", description)
	else:
		failures += 1
		push_error("  FEHLER  " + description)
