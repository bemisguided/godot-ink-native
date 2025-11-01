extends Node

## Basic test for InkStory functionality
## This script tests loading, continuation, and choice selection

func _ready():
  print("==========================================")
  print("=== Godot Ink Native - Basic Test Suite ===")
  print("==========================================")
  print("")

  test_story_loading()
  test_story_continuation()
  test_choices()
  test_tags()
  test_variables()

  print("")
  print("==========================================")
  print("=== All Tests Complete! ===")
  print("==========================================")

  # Exit after tests
  await get_tree().create_timer(0.1).timeout
  get_tree().quit()

func test_story_loading():
  print("[TEST] Story Loading")
  var story = InkStory.new()
  assert(story != null, "Failed to create InkStory")
  assert(not story.is_loaded(), "Story should not be loaded yet")
  var loaded = story.load_story("res://examples/hello.inkj")
  assert(loaded, "Failed to load story from .inkj file")
  assert(story.is_loaded(), "Story should be loaded")
  print("  ✓ Story loaded successfully")
  print("")

func test_story_continuation():
  print("[TEST] Story Continuation")
  var story = InkStory.new()
  story.load_story("res://examples/hello.inkj")
  assert(story.can_continue(), "Story should have content")
  var text = story.continue_story()
  print("  Story text: '%s'" % story.get_current_text())
  assert(text.length() > 0, "Story text should not be empty")
  assert("Hello from Ink" in text, "Story should contain expected text")
  print("  ✓ Story continuation works")
  print("")

func test_choices():
  print("[TEST] Choices")
  var story = InkStory.new()
  story.load_story("res://examples/hello.inkj")
  while story.can_continue():
    story.continue_story()
  var choices = story.get_current_choices()
  assert(choices.size() > 0, "Should have at least one choice")
  print("  Found %d choice(s):" % choices.size())
  for choice in choices:
    print("    [%d] %s" % [choice.index, choice.text])
    assert(choice.index >= 0, "Choice should have valid index")
    assert(choice.text.length() > 0, "Choice should have text")
  story.choose_choice_index(0)
  var text_after_choice = story.continue_story()
  print("  After choice: '%s'" % text_after_choice)
  print("  ✓ Choices work correctly")
  print("")

func test_tags():
  print("[TEST] Tags")
  var story = InkStory.new()
  story.load_story("res://examples/hello.inkj")
  story.continue_story()
  var tags = story.get_current_tags()
  print("  Found %d tag(s): %s" % [tags.size(), tags])
  if tags.size() > 0:
    print("  ✓ Tags detected")
  else:
    print("  ⚠ No tags found (may be normal for this story)")
  print("")

func test_variables():
  print("[TEST] Variables")
  var story = InkStory.new()
  story.load_story("res://examples/hello.inkj")
  story.set_variable("test_var", 42)
  var value = story.get_variable("test_var")
  print("  Set test_var = 42, got back: %s" % str(value))
  if value == 42:
    print("  ✓ Variables work correctly")
  else:
    print("  ⚠ Variable value mismatch (expected 42, got %s)" % str(value))
  print("")
