@tool
extends EditorImportPlugin

## Ink Story Import Plugin
##
## Automatically compiles .ink files into InkStory resources during Godot's import process.
##
## Compilation pipeline:
##   .ink → (inklecate) → .ink.json → (InkCompiler) → .inkb → (InkStory) → .res
##
## Usage:
##   1. Add .ink file to project
##   2. Godot automatically compiles it
##   3. Use load("res://story.ink") to load the compiled resource


func _get_importer_name() -> String:
	return "ink.story"


func _get_visible_name() -> String:
	return "Ink Story"


func _get_recognized_extensions() -> PackedStringArray:
	return ["ink"]


func _get_save_extension() -> String:
	return "res"


func _get_resource_type() -> String:
	return "Resource"


func _get_priority() -> float:
	return 1.0


func _get_import_order() -> int:
	return 0


func _get_preset_count() -> int:
	return 1


func _get_preset_name(_preset_index: int) -> String:
	return "Default"


func _get_import_options(_path: String, _preset_index: int) -> Array[Dictionary]:
	return [
		{
			"name": "compress",
			"default_value": true,
			"property_hint": PROPERTY_HINT_NONE,
			"hint_string": "Compress the imported resource to reduce file size"
		},
		{
			"name": "count_all_visits",
			"default_value": false,
			"property_hint": PROPERTY_HINT_NONE,
			"hint_string": "Track visit counts for all content"
		}
	]


func _get_option_visibility(_path: String, _option_name: StringName, _options: Dictionary) -> bool:
	return true


func _import(
	source_file: String,
	save_path: String,
	options: Dictionary,
	_platform_variants: Array[String],
	_gen_files: Array[String]
) -> Error:
	print("Ink Importer: Starting import of %s" % source_file)

	# Step 1: Compile .ink to .ink.json using inklecate
	var json_temp_path = _get_temp_path(source_file, ".ink.json")
	var binary_temp_path = _get_temp_path(source_file, ".inkb")
	var result = _compile_to_json(source_file, json_temp_path)

	if result != OK:
		return result

	# Step 2: Compile .ink.json to .inkb using InkCompiler
	result = _compile_to_binary(json_temp_path, binary_temp_path)

	if result != OK:
		_cleanup_temp_files([json_temp_path])
		return result

	# Step 3: Create and save InkStory resource
	result = _create_and_save_resource(binary_temp_path, save_path, options)

	# Step 4: Cleanup temporary files
	_cleanup_temp_files([json_temp_path, binary_temp_path])

	if result == OK:
		print("Ink Importer: Successfully imported %s" % source_file)

	return result


## Compile .ink file to .ink.json using inklecate
## @param source_file: Source .ink file path
## @param json_path: Output .ink.json file path
## @return: OK on success, error code on failure
func _compile_to_json(source_file: String, json_path: String) -> Error:
	if not GDInkCompiler.compile(source_file, json_path):
		push_error("Ink Importer: Failed to compile .ink to .json: %s" % source_file)
		return ERR_COMPILATION_FAILED

	if not FileAccess.file_exists(json_path):
		push_error("Ink Importer: JSON file not created: %s" % json_path)
		return ERR_FILE_CANT_WRITE

	return OK


## Compile .ink.json to .inkb using InkCompiler
## @param json_path: Source .ink.json file path
## @param binary_path: Output .inkb file path
## @return: OK on success, error code on failure
func _compile_to_binary(json_path: String, binary_path: String) -> Error:
	if not InkCompiler.compile_json_file(json_path, binary_path):
		push_error("Ink Importer: Failed to compile .json to .inkb: %s" % json_path)
		return ERR_COMPILATION_FAILED

	if not FileAccess.file_exists(binary_path):
		push_error("Ink Importer: Binary file not created: %s" % binary_path)
		return ERR_FILE_CANT_WRITE

	return OK


## Create InkStory resource and save it
## @param binary_path: Source .inkb file path
## @param save_path: Output resource path (without extension)
## @param options: Import options dictionary
## @return: OK on success, error code on failure
func _create_and_save_resource(
	binary_path: String, save_path: String, options: Dictionary
) -> Error:
	var story = InkStory.new()

	if not story.load_story(binary_path):
		push_error("Ink Importer: Failed to load story from binary: %s" % binary_path)
		return ERR_INVALID_DATA

	var full_save_path = save_path + "." + _get_save_extension()
	var save_flags = ResourceSaver.FLAG_COMPRESS if options.get("compress", true) else 0
	var save_error = ResourceSaver.save(story, full_save_path, save_flags)

	if save_error != OK:
		push_error(
			(
				"Ink Importer: Failed to save imported resource: %s (error: %d)"
				% [full_save_path, save_error]
			)
		)

	return save_error


## Generates a temporary file path based on source file
## @param source_path: Original .ink file path
## @param extension: Extension for temp file (e.g., ".ink.json", ".inkb")
## @return: Temporary file path in same directory as source
func _get_temp_path(source_path: String, extension: String) -> String:
	var base = source_path.get_basename()
	return base + extension


## Cleanup temporary files created during import
## @param paths: Array of file paths to delete
func _cleanup_temp_files(paths: Array) -> void:
	for path in paths:
		if FileAccess.file_exists(path):
			var error = DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
			if error != OK:
				push_warning(
					"Ink Importer: Failed to delete temp file: %s (error: %d)" % [path, error]
				)
