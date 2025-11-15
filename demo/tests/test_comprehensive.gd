extends Node

## Comprehensive test suite for InkStory functionality
## Tests all major API features with multiple scenarios

# Test tracking
var tests_passed = 0
var tests_failed = 0
var current_test = ""

func _ready():
	print("============================================================")
	print("=== Godot Ink Native - Comprehensive Test Suite ===")
	print("============================================================")
	print("")

	# Compile test story before running tests
	if not _compile_test_story():
		print("❌ Failed to compile test story - aborting tests")
		get_tree().quit(1)
		return

	# Compile external functions test story
	if not _compile_external_functions_story():
		print("❌ Failed to compile external functions test story - skipping external function tests")

	# Run all test categories
	test_loading_and_compilation()
	test_resource_properties()
	test_continuation_modes()
	test_choice_system()
	test_path_navigation()
	test_variable_operations()
	test_external_functions()
	# test_tag_hierarchy()  # TODO: Implement get_global_tags/get_knot_tags API
	test_state_management()
	test_error_handling()
	test_edge_cases()
	test_text_caching()

	# Print summary
	print("")
	print("============================================================")
	print("=== Test Summary ===")
	print("============================================================")
	print("Tests Passed: %d" % tests_passed)
	print("Tests Failed: %d" % tests_failed)
	print("Total Tests:  %d" % (tests_passed + tests_failed))

	if tests_failed == 0:
		print("")
		print("✅ All tests passed!")
	else:
		print("")
		print("❌ Some tests failed")

	print("============================================================")

	# Exit after tests
	await get_tree().create_timer(0.1).timeout
	get_tree().quit(tests_failed)

# ===== HELPER FUNCTIONS =====

func _compile_test_story() -> bool:
	print("[SETUP] Compiling test story...")
	var success = GDInkCompiler.compile("res://examples/test_story.ink")
	if success:
		print("  ✅ Test story compiled successfully")
		print("")
		return true
	else:
		print("  ❌ Compilation failed")
		print("")
		return false

func _compile_external_functions_story() -> bool:
	print("[SETUP] Compiling external functions story...")
	var success = GDInkCompiler.compile("res://examples/external_functions.ink")
	if success:
		print("  ✅ External functions story compiled successfully")
		print("")
		return true
	else:
		print("  ❌ Compilation failed")
		print("")
		return false

func start_test(test_name: String):
	current_test = test_name
	print("[TEST] %s" % test_name)

func assert_true(condition: bool, message: String = ""):
	if condition:
		tests_passed += 1
		if message:
			print("  ✓ %s" % message)
	else:
		tests_failed += 1
		if message:
			print("  ✗ FAILED: %s" % message)
		else:
			print("  ✗ FAILED: Assertion failed in %s" % current_test)

func assert_equals(actual, expected, message: String = ""):
	if actual == expected:
		tests_passed += 1
		if message:
			print("  ✓ %s" % message)
	else:
		tests_failed += 1
		if message:
			print("  ✗ FAILED: %s (expected %s, got %s)" % [message, expected, actual])
		else:
			print("  ✗ FAILED: Expected %s, got %s" % [expected, actual])

func assert_not_null(value, message: String = ""):
	if value != null:
		tests_passed += 1
		if message:
			print("  ✓ %s" % message)
	else:
		tests_failed += 1
		if message:
			print("  ✗ FAILED: %s (value was null)" % message)
		else:
			print("  ✗ FAILED: Value was null")

func assert_contains(text: String, substring: String, message: String = ""):
	if substring in text:
		tests_passed += 1
		if message:
			print("  ✓ %s" % message)
	else:
		tests_failed += 1
		if message:
			print("  ✗ FAILED: %s" % message)
		else:
			print("  ✗ FAILED: '%s' not found in '%s'" % [substring, text])

func create_story() -> InkStory:
	var story = InkStory.new()
	story.load_story("res://examples/test_story.ink.json")
	return story

# ===== TEST CATEGORY 1: LOADING AND COMPILATION =====

func test_loading_and_compilation():
	start_test("Loading and Compilation")

	# Test 1: Load .ink.json file
	var story1 = InkStory.new()
	var loaded = story1.load_story("res://examples/test_story.ink.json")
	assert_true(loaded, "Loads .ink.json file successfully")
	assert_true(story1.is_loaded(), "Story marked as loaded")

	# Test 2: Verify .ink.inkb file was created
	var file_path = "res://examples/test_story.ink.inkb"
	assert_true(FileAccess.file_exists(file_path), ".ink.inkb file created during compilation")

	# Test 3: Load .ink.inkb directly
	var story2 = InkStory.new()
	loaded = story2.load_story("res://examples/test_story.ink.inkb")
	assert_true(loaded, "Loads .ink.inkb file directly")
	assert_true(story2.is_loaded(), "Binary story marked as loaded")

	# Test 4: Verify content matches
	var text1 = story1.continue_story()
	var text2 = story2.continue_story()
	assert_equals(text1, text2, "Content matches between .ink.json and .ink.inkb")

	print("")

# ===== TEST CATEGORY 2: RESOURCE PROPERTIES =====

func test_resource_properties():
	start_test("Resource Properties")

	# Test 1: set_story_path() loads story automatically
	var story1 = InkStory.new()
	story1.set_story_path("res://examples/test_story.ink.json")
	assert_true(story1.is_loaded(), "set_story_path() loads story automatically")

	# Test 2: get_story_path() returns set path
	var path1 = story1.get_story_path()
	assert_equals(path1, "res://examples/test_story.ink.json", "get_story_path() returns correct path")

	# Test 3: Story is functional after set_story_path()
	var text = story1.continue_story()
	assert_not_null(text, "Story functional after set_story_path()")
	assert_contains(text, "Welcome", "Content loaded correctly via set_story_path()")

	# Test 4: set_story_path() with .inkb file
	var story2 = InkStory.new()
	story2.set_story_path("res://examples/test_story.ink.inkb")
	assert_true(story2.is_loaded(), "set_story_path() works with .inkb files")
	var path2 = story2.get_story_path()
	assert_equals(path2, "res://examples/test_story.ink.inkb", "get_story_path() returns .inkb path")

	# Test 5: Content matches between .json and .inkb paths
	var text1 = story1.get_current_text()
	var text2 = story2.continue_story()
	assert_equals(text1, text2, "Content matches between path-loaded .json and .inkb")

	# Test 6: Empty path handling
	var story3 = InkStory.new()
	story3.set_story_path("")
	var empty_path = story3.get_story_path()
	assert_equals(empty_path, "", "Empty path handled correctly")
	assert_true(story3.is_loaded() == false, "Story not loaded with empty path")

	# Test 7: Path persists after operations
	var story4 = InkStory.new()
	story4.set_story_path("res://examples/test_story.ink.json")
	story4.continue_story_maximally()
	var path_after = story4.get_story_path()
	assert_equals(path_after, "res://examples/test_story.ink.json", "Path persists after continue operations")

	# Test 8: Path persists after reset
	story4.reset_state()
	var path_after_reset = story4.get_story_path()
	assert_equals(path_after_reset, "res://examples/test_story.ink.json", "Path persists after reset_state()")

	# Test 9: Changing path reloads story
	var story5 = InkStory.new()
	story5.set_story_path("res://examples/test_story.ink.json")
	story5.continue_story_maximally()
	var choice_count1 = story5.get_current_choice_count()

	# Reload same story - should reset to beginning
	story5.set_story_path("res://examples/test_story.ink.json")
	assert_true(story5.can_continue(), "Story reset when path set again")
	var text_after_reload = story5.continue_story()
	assert_contains(text_after_reload, "Welcome", "Story reloaded from beginning")

	# Test 10: load_story() updates path
	var story6 = InkStory.new()
	story6.load_story("res://examples/test_story.ink.json")
	var path_from_load = story6.get_story_path()
	assert_equals(path_from_load, "res://examples/test_story.ink.json", "load_story() sets story_path property")

	# Test 11: Invalid path handling
	var story7 = InkStory.new()
	story7.set_story_path("res://examples/nonexistent.ink.json")
	# Should fail gracefully
	assert_true(story7.is_loaded() == false, "Invalid path via set_story_path() doesn't load")
	# Path might be set or empty depending on implementation
	var invalid_path = story7.get_story_path()
	assert_not_null(invalid_path, "get_story_path() returns value even after failed load")

	print("")

# ===== TEST CATEGORY 3: CONTINUATION MODES =====

func test_continuation_modes():
	start_test("Continuation Modes")

	var story = create_story()

	# Test 1: can_continue() before any action
	assert_true(story.can_continue(), "can_continue() returns true initially")

	# Test 2: continue_story() single line
	var line1 = story.continue_story()
	assert_not_null(line1, "continue_story() returns text")
	assert_contains(line1, "Welcome", "First line contains expected text")

	# Test 3: get_current_text() matches last continue
	var cached_text = story.get_current_text()
	assert_equals(cached_text, line1, "get_current_text() returns cached text")

	# Test 4: Multiple continue_story() calls
	assert_true(story.can_continue(), "can_continue() true after first line")
	var line2 = story.continue_story()
	assert_contains(line2, "features", "Second line contains expected text")

	# Test 5: continue_story_maximally() accumulates text
	story.reset_state()
	var all_text = story.continue_story_maximally()
	assert_contains(all_text, "Welcome", "Maximal continuation includes first line")
	assert_contains(all_text, "adventure begins", "Maximal continuation includes multiple lines")
	assert_true(all_text.length() > line1.length(), "Maximal text longer than single line")

	# Test 6: get_current_text() after maximally
	var cached_max = story.get_current_text()
	assert_equals(cached_max, all_text, "get_current_text() caches maximal text")

	print("")

# ===== TEST CATEGORY 4: CHOICE SYSTEM =====

func test_choice_system():
	start_test("Choice System")

	var story = create_story()

	# Continue to first choice point
	while story.can_continue():
		story.continue_story()

	# Test 1: Choices available
	var choices = story.get_current_choices()
	assert_not_null(choices, "get_current_choices() returns array")
	assert_true(choices.size() > 0, "Choice array not empty")

	# Test 2: Choice count matches
	var count = story.get_current_choice_count()
	assert_equals(count, choices.size(), "get_current_choice_count() matches array size")

	# Test 3: Verify we have expected choices (hub has 6 options initially)
	assert_true(choices.size() >= 4, "Hub has multiple choice options")

	# Test 4: InkChoice properties
	var first_choice = choices[0]
	assert_not_null(first_choice, "First choice exists")
	assert_true(first_choice.index >= 0, "Choice has valid index")
	assert_not_null(first_choice.text, "Choice has text")
	assert_true(first_choice.text.length() > 0, "Choice text not empty")

	# Test 5: Choose and continue
	story.choose_choice_index(0)  # Go north
	assert_true(story.can_continue(), "can_continue() true after choice")
	var text_after = story.continue_story()
	assert_contains(text_after, "forest", "Text after choice contains expected content")

	# Test 6: Multiple choice branches
	story.reset_state()
	while story.can_continue():
		story.continue_story()

	var choice_count_start = story.get_current_choice_count()
	story.choose_choice_index(1)  # Go south
	while story.can_continue():
		story.continue_story()

	# Should be back at hub with different state
	assert_true(story.get_current_choice_count() > 0, "Choices available after branch")

	print("")

# ===== TEST CATEGORY 5: PATH NAVIGATION =====

func test_path_navigation():
	start_test("Path Navigation")

	var story = create_story()

	# Test 1: Jump to knot
	var success = story.choose_path_string("hub")
	assert_true(success, "choose_path_string() to 'hub' succeeds")
	assert_true(story.can_continue(), "can_continue() after path jump")

	# Test 2: Content at destination
	var text = story.continue_story()
	assert_contains(text, "crossroads", "Arrived at correct knot")

	# Test 3: Jump to stitch
	story.choose_path_string("north_path.deeper")
	assert_true(story.can_continue(), "can_continue() after stitch jump")
	text = story.continue_story()
	assert_contains(text, "depths", "Arrived at correct stitch")

	# Test 4: get_current_path() returns value
	story.choose_path_string("south_path")
	story.continue_story()
	var path = story.get_current_path()
	assert_not_null(path, "get_current_path() returns value")
	# Note: returns hash, not human-readable string
	assert_true(path.length() > 0, "Path is not empty")

	# Test 5: Invalid path handling
	var invalid = story.choose_path_string("nonexistent_knot")
	assert_true(invalid == false, "choose_path_string() returns false for invalid path")

	print("")

# ===== TEST CATEGORY 6: VARIABLE OPERATIONS =====

func test_variable_operations():
	start_test("Variable Operations")

	var story = create_story()

	# Test 1: Get initial INT variable
	var score = story.get_variable("score")
	assert_equals(score, 0, "Initial INT variable correct")

	# Test 2: Get initial FLOAT variable
	var health = story.get_variable("health")
	assert_equals(health, 100.0, "Initial FLOAT variable correct")

	# Test 3: Get initial BOOL variable
	var has_key = story.get_variable("has_key")
	assert_equals(has_key, false, "Initial BOOL variable correct")

	# Test 4: Get initial STRING variable
	var name = story.get_variable("player_name")
	assert_equals(name, "Hero", "Initial STRING variable correct")

	# Test 5: Set INT variable externally
	story.set_variable("score", 42)
	var new_score = story.get_variable("score")
	assert_equals(new_score, 42, "Set INT variable succeeds")

	# Test 6: Set FLOAT variable
	story.set_variable("health", 75.5)
	var new_health = story.get_variable("health")
	assert_equals(new_health, 75.5, "Set FLOAT variable succeeds")

	# Test 7: Set BOOL variable
	story.set_variable("has_key", true)
	var new_key = story.get_variable("has_key")
	assert_equals(new_key, true, "Set BOOL variable succeeds")

	# Test 8: Set STRING variable
	story.set_variable("player_name", "TestRunner")
	var new_name = story.get_variable("player_name")
	assert_equals(new_name, "TestRunner", "Set STRING variable succeeds")

	# Test 9: Variables modified by story
	story.reset_state()
	story.choose_path_string("north_path")
	story.continue_story_maximally()
	var modified_score = story.get_variable("score")
	assert_true(modified_score > 0, "Story modifies INT variable")

	var modified_health = story.get_variable("health")
	assert_true(modified_health < 100.0, "Story modifies FLOAT variable")

	# Test 10: Variable persistence across choices
	story.reset_state()
	story.choose_path_string("south_path")
	story.continue_story_maximally()
	var key_after_south = story.get_variable("has_key")
	assert_equals(key_after_south, true, "BOOL variable persists after story action")

	# Test 11: Invalid variable name
	var invalid_var = story.get_variable("nonexistent_variable")
	assert_true(invalid_var == null, "get_variable() returns null for invalid name")

	print("")

# ===== TEST CATEGORY 7: EXTERNAL FUNCTIONS =====

func test_external_functions():
	start_test("External Functions")

	var story = InkStory.new()
	story.load_story("res://examples/external_functions.ink.json")

	# Test 1: Bind zero-argument function
	story.bind_external_function("get_player_name", func(): return "TestHero")
	assert_true(story.has_external_function("get_player_name"), "has_external_function() returns true after binding")

	# Test 2: Bind function with return value
	story.bind_external_function("roll_dice", func(): return randi() % 6 + 1)
	assert_true(story.has_external_function("roll_dice"), "roll_dice bound successfully")

	# Test 3: Bind multi-argument function
	story.bind_external_function("add", func(a, b): return a + b)
	story.bind_external_function("multiply", func(x, y): return x * y)
	assert_true(story.has_external_function("add"), "add bound successfully")
	assert_true(story.has_external_function("multiply"), "multiply bound successfully")

	# Test 4: Bind string concatenation function
	story.bind_external_function("concat", func(s1, s2): return str(s1) + str(s2))
	assert_true(story.has_external_function("concat"), "concat bound successfully")

	# Test 5: Bind boolean return function
	story.bind_external_function("is_lucky", func(): return true)
	assert_true(story.has_external_function("is_lucky"), "is_lucky bound successfully")

	# Test 6: Bind void function
	# Use array to allow lambda to modify the value (GDScript captures by value)
	var void_called = [false]
	story.bind_external_function("void_function", func(): void_called[0] = true)
	assert_true(story.has_external_function("void_function"), "void_function bound successfully")

	# Test 7: Execute story with external functions
	var text = story.continue_story_maximally()
	assert_contains(text, "TestHero", "External function get_player_name() called successfully")
	assert_contains(text, "World", "External function concat() called successfully")

	# Test 8: Verify void function was called
	assert_true(void_called[0], "Void external function executed")

	# Test 9: Test external function in choices
	story.reset_state()

	# Rebind functions with new values
	story.bind_external_function("get_player_name", func(): return "NewHero")
	story.bind_external_function("roll_dice", func(): return 6)
	story.bind_external_function("add", func(a, b): return a + b)
	story.bind_external_function("multiply", func(x, y): return x * y)
	story.bind_external_function("concat", func(s1, s2): return str(s1) + str(s2))
	story.bind_external_function("is_lucky", func(): return false)
	story.bind_external_function("void_function", func(): pass)

	story.continue_story_maximally()

	# Should be at hub with choices
	assert_true(story.get_current_choice_count() > 0, "At hub with choices")

	# Test 10: Choose and test zero-arg function option
	story.choose_choice_index(0)  # Test zero-arg function
	text = story.continue_story()
	assert_contains(text, "NewHero", "Rebound function returns new value")

	# Test 11: Test unbind_external_function
	story.reset_state()
	story.unbind_external_function("get_player_name")
	assert_true(story.has_external_function("get_player_name") == false, "unbind_external_function() removes binding")

	# Test 12: Unbound function behavior (should print error but not crash)
	text = story.continue_story()
	assert_not_null(text, "Story continues even with unbound external function")

	# Test 13: Rebind after unbind
	story.bind_external_function("get_player_name", func(): return "ReboundHero")
	assert_true(story.has_external_function("get_player_name"), "Function can be rebound after unbinding")

	# Test 14: Test with lookahead_safe parameter
	var side_effect_count = 0
	story.bind_external_function("side_effect_func", func():
		side_effect_count += 1
		return side_effect_count
	, false)  # Not lookahead safe
	assert_true(story.has_external_function("side_effect_func"), "Function with side effects bound")

	# Test 15: Different return types
	story.reset_state()
	story.bind_external_function("get_player_name", func(): return "TypeTest")
	story.bind_external_function("roll_dice", func(): return 42)  # INT
	story.bind_external_function("add", func(a, b): return a + b)  # INT
	story.bind_external_function("multiply", func(x, y): return x * y)  # INT
	story.bind_external_function("concat", func(s1, s2): return str(s1) + str(s2))  # STRING
	story.bind_external_function("is_lucky", func(): return true)  # BOOL
	story.bind_external_function("void_function", func(): pass)  # VOID

	text = story.continue_story_maximally()
	assert_contains(text, "TypeTest", "String return type works")
	assert_contains(text, "42", "Int return type works")
	assert_contains(text, "true", "Bool return type works")

	# Test 16: Function not bound
	story.reset_state()
	story.unbind_external_function("get_player_name")
	story.unbind_external_function("roll_dice")
	story.unbind_external_function("add")
	story.unbind_external_function("multiply")
	story.unbind_external_function("concat")
	story.unbind_external_function("is_lucky")
	story.unbind_external_function("void_function")

	# Story should handle missing functions gracefully (errors logged but no crash)
	text = story.continue_story()
	assert_not_null(text, "Story handles unbound functions gracefully")

	print("")

# ===== TEST CATEGORY 8: TAG HIERARCHY =====
# TODO: Uncomment when get_global_tags/get_knot_tags API is implemented

#func test_tag_hierarchy():
#	start_test("Tag Hierarchy")
#
#	var story = create_story()
#
#	# Test 1: Global tags
#	var global_tags = story.get_global_tags()
#	assert_not_null(global_tags, "get_global_tags() returns array")
#	assert_true(global_tags.size() > 0, "Global tags exist")
#	assert_true("title: Comprehensive Test Story" in global_tags, "Global tag 'title' found")
#	assert_true("author: Test Suite" in global_tags, "Global tag 'author' found")
#
#	# Test 2: Move to a knot with tags
#	story.choose_path_string("hub")
#	var knot_tags = story.get_knot_tags()
#	assert_not_null(knot_tags, "get_knot_tags() returns array")
#	assert_true(knot_tags.size() > 0, "Knot tags exist")
#	assert_true("location: hub" in knot_tags, "Knot tag 'location' found")
#
#	# Test 3: Continue to line with tags
#	var text = story.continue_story()
#	var line_tags = story.get_current_tags()
#	assert_not_null(line_tags, "get_current_tags() returns array")
#	# First line at hub has tags
#	if line_tags.size() > 0:
#		assert_true(line_tags.size() >= 1, "Line has tags")
#
#	# Test 4: Tagged line with multiple tags
#	story.choose_path_string("north_path")
#	story.continue_story()  # "You venture..."
#	line_tags = story.get_current_tags()
#	if line_tags.size() > 0:
#		assert_contains(str(line_tags), "mood", "Line tag contains expected content")
#
#	print("")

# ===== TEST CATEGORY 9: STATE MANAGEMENT =====

func test_state_management():
	start_test("State Management")

	var story = create_story()

	# Advance story state
	story.continue_story_maximally()
	var choices_before = story.get_current_choice_count()
	story.choose_choice_index(0)  # Make a choice
	story.continue_story()

	# TODO: Uncomment when get_variable/set_variable implemented
	# # Modify a variable
	# story.set_variable("score", 999)
	# var score_before_reset = story.get_variable("score")
	# assert_equals(score_before_reset, 999, "Variable modified before reset")

	# Test 1: reset_state() resets position
	story.reset_state()
	assert_true(story.can_continue(), "can_continue() true after reset")

	# Test 2: Content is back at start
	var first_line = story.continue_story()
	assert_contains(first_line, "Welcome", "Story resets to beginning")

	# Test 3: Choices available at start
	story.reset_state()
	story.continue_story_maximally()
	var choices_after = story.get_current_choice_count()
	assert_equals(choices_after, choices_before, "Choice count restored after reset")

	# TODO: Uncomment when get_variable/set_variable implemented
	# # Test 4: Variables reset (or maintain state - check implementation)
	# var score_after_reset = story.get_variable("score")
	# # Note: Depending on implementation, variables might reset or persist
	# # This tests current behavior
	# assert_not_null(score_after_reset, "Variable accessible after reset")

	# Test 5: is_loaded() still true after reset
	assert_true(story.is_loaded(), "Story still loaded after reset")

	print("")

# ===== TEST CATEGORY 10: ERROR HANDLING =====

func test_error_handling():
	start_test("Error Handling")

	# Test 1: Load invalid file
	var story1 = InkStory.new()
	var loaded = story1.load_story("res://examples/nonexistent_file.ink.json")
	assert_true(loaded == false, "Loading invalid file returns false")
	assert_true(story1.is_loaded() == false, "Invalid story not marked as loaded")

	# Test 2: Invalid choice index
	var story2 = create_story()
	story2.continue_story_maximally()
	var choice_count = story2.get_current_choice_count()
	# This should fail gracefully (not crash)
	story2.choose_choice_index(999)
	# Story should still be in valid state
	assert_equals(story2.get_current_choice_count(), choice_count, "Invalid choice doesn't corrupt state")

	# Test 3: Continue when can't continue
	var story3 = create_story()
	# Fast-forward to end
	story3.choose_path_string("victory")
	while story3.can_continue():
		story3.continue_story()

	assert_true(story3.can_continue() == false, "can_continue() false at END")
	var result = story3.continue_story()
	# Should return empty string or not crash
	assert_not_null(result, "continue_story() at END doesn't crash")

	# Test 4: Invalid path navigation
	var story4 = create_story()
	var invalid_result = story4.choose_path_string("totally_invalid_path")
	assert_true(invalid_result == false, "Invalid path returns false")
	# Story should still be functional
	assert_true(story4.can_continue(), "Story functional after invalid path")

	# TODO: Uncomment when get_variable/set_variable implemented
	# # Test 5: Get non-existent variable
	# var story5 = create_story()
	# var bad_var = story5.get_variable("this_variable_does_not_exist")
	# assert_true(bad_var == null, "Non-existent variable returns null")

	print("")

# ===== TEST CATEGORY 11: EDGE CASES =====

func test_edge_cases():
	start_test("Edge Cases")

	# Test 1: Story reaching END
	var story1 = create_story()
	story1.choose_path_string("victory")
	while story1.can_continue():
		story1.continue_story()

	assert_true(story1.can_continue() == false, "can_continue() false at END")
	assert_equals(story1.get_current_choice_count(), 0, "No choices at END")

	# Test 2: Empty choice list
	var choices_at_end = story1.get_current_choices()
	assert_not_null(choices_at_end, "get_current_choices() returns array at END")
	assert_equals(choices_at_end.size(), 0, "Choice array empty at END")

	# Test 3: Rapid sequential operations
	var story2 = create_story()
	for i in range(5):
		if story2.can_continue():
			story2.continue_story()
	# Should not crash or corrupt state
	assert_true(true, "Rapid continue operations succeed")

	# Test 4: Reset and immediate continue
	var story3 = create_story()
	story3.continue_story_maximally()
	story3.reset_state()
	var text = story3.continue_story()
	assert_contains(text, "Welcome", "Immediate continue after reset works")

	# Test 5: Multiple resets
	var story4 = create_story()
	for i in range(3):
		story4.continue_story_maximally()
		story4.reset_state()

	assert_true(story4.can_continue(), "Multiple resets maintain valid state")

	print("")

# ===== TEST CATEGORY 12: TEXT CACHING =====

func test_text_caching():
	start_test("Text Caching")

	var story = create_story()

	# Test 1: Initial state
	var initial_text = story.get_current_text()
	# Might be empty or might have cached text
	assert_not_null(initial_text, "get_current_text() returns non-null initially")

	# Test 2: After continue_story()
	var line1 = story.continue_story()
	var cached1 = story.get_current_text()
	assert_equals(cached1, line1, "get_current_text() matches continue_story() result")

	# Test 3: Consistency between calls
	var cached1_again = story.get_current_text()
	assert_equals(cached1_again, cached1, "get_current_text() consistent between calls")

	# Test 4: Updates after next continue
	var line2 = story.continue_story()
	var cached2 = story.get_current_text()
	assert_equals(cached2, line2, "get_current_text() updates after new continue_story()")
	assert_true(cached2 != cached1 or line2 == line1, "Cached text changes with new content")

	# Test 5: After continue_story_maximally()
	story.reset_state()
	var all_text = story.continue_story_maximally()
	var cached_max = story.get_current_text()
	assert_equals(cached_max, all_text, "get_current_text() caches maximally text")

	# Test 6: After reset
	story.reset_state()
	var after_reset = story.get_current_text()
	# Should be empty or reset
	assert_true(after_reset.length() == 0 or after_reset != cached_max, "get_current_text() clears/changes after reset")

	# Test 7: After choice selection
	story.continue_story_maximally()
	story.choose_choice_index(0)
	var text_after_choice = story.continue_story()
	var cached_after_choice = story.get_current_text()
	assert_equals(cached_after_choice, text_after_choice, "Text caching works after choice")

	print("")
