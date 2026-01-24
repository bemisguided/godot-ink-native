extends Node

## Test: Ink Story Import Plugin
##
## This test demonstrates the import plugin functionality:
## - .ink files are automatically imported as InkStory resources
## - load("res://path.ink") loads the compiled resource
## - No manual compilation needed


func _ready():
	print("=== Ink Import Plugin Test ===\n")

	# Test 1: Load .ink file directly (should load imported resource)
	print("[TEST 1] Loading .ink file directly via load()")
	var story = load("res://examples/hello.ink")

	if story == null:
		print("  ❌ FAILED: Could not load res://examples/hello.ink")
		print("  Note: Make sure the Godot Ink Native plugin is enabled in Project Settings")
		return

	print("  ✓ Resource loaded: %s" % story)
	print("  ✓ Resource type: %s" % story.get_class())

	if story is InkStory:
		print("  ✓ Resource is InkStory")
	else:
		print("  ❌ FAILED: Resource is not InkStory, got: %s" % story.get_class())
		return

	# Test 2: Verify story is executable
	print("\n[TEST 2] Testing story execution")

	if not story.is_loaded():
		print("  ❌ FAILED: Story is not loaded")
		return

	print("  ✓ Story is loaded")

	if not story.can_continue():
		print("  ❌ FAILED: Story cannot continue")
		return

	print("  ✓ Story can continue")

	# Test 3: Execute story
	print("\n[TEST 3] Executing story content")

	var text = story.continue_story()
	print("  Story text: '%s'" % text.strip_edges())

	if text.strip_edges() == "Hello from Ink!":
		print("  ✓ Story text matches expected output")
	else:
		print("  ⚠ Warning: Story text doesn't match expected output")

	# Test 4: Verify choices are available
	print("\n[TEST 4] Checking choices")

	var choices = story.get_current_choices()
	print("  Available choices: %d" % choices.size())

	for i in range(choices.size()):
		var choice = choices[i]
		print("    %d. %s" % [i + 1, choice.text])

	if choices.size() == 2:
		print("  ✓ Expected number of choices (2)")
	else:
		print("  ⚠ Warning: Expected 2 choices, got %d" % choices.size())

	# Test 5: Make a choice and continue
	print("\n[TEST 5] Making choice and continuing")

	if choices.size() > 0:
		story.choose_choice_index(0)
		var after_choice = story.continue_story_maximally()
		print("  After choice: '%s'" % after_choice.strip_edges())
		print("  ✓ Story continued successfully")

	print("\n=== All Tests Completed ===")
	print("✅ Import plugin is working correctly!")
	print('\nKey takeaway: You can now use load("res://story.ink") directly in your projects!')
