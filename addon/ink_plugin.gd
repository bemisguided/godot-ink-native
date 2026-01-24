@tool
extends EditorPlugin

## Godot Ink Native Editor Plugin
##
## Registers the Ink Story importer to automatically compile .ink files into InkStory resources.
## This enables seamless integration where users can reference .ink files directly:
##   load("res://story.ink") → loads imported InkStory resource

var importer_plugin: EditorImportPlugin


func _enter_tree() -> void:
	# Load and register the import plugin
	importer_plugin = preload("ink_story_importer.gd").new()
	add_import_plugin(importer_plugin)

	print("Godot Ink Native: Import plugin registered")


func _exit_tree() -> void:
	# Unregister and cleanup
	if importer_plugin:
		remove_import_plugin(importer_plugin)
		importer_plugin = null

	print("Godot Ink Native: Import plugin unregistered")
