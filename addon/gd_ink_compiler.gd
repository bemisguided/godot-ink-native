@tool
class_name GDInkCompiler
extends RefCounted

## GDInkCompiler - Static utility for compiling Ink source files
##
## This tool wraps the inklecate binary to compile .ink files to .ink.json format
## within the Godot editor. Automatically detects the correct platform-specific binary.

## Compiles an Ink source file to JSON format using inklecate
##
## @param source_path: Path to .ink source file (e.g., "res://story.ink")
## @param output_path: Optional output path (defaults to source_basename.ink.json)
## @return: true on success, false on failure
static func compile(source_path: String, output_path: String = "") -> bool:
	# Determine output path if not provided
	if output_path.is_empty():
		output_path = source_path.get_basename() + ".ink.json"

	# Validate paths
	if not _validate_and_prepare(source_path, output_path):
		return false

	# Get inklecate binary path
	var inklecate_path = _get_inklecate_path()
	if inklecate_path.is_empty():
		return false

	# Convert resource paths to filesystem paths
	var source_fs_path = ProjectSettings.globalize_path(source_path)
	var output_fs_path = ProjectSettings.globalize_path(output_path)

	# Build command arguments
	var args = ["-o", output_fs_path, source_fs_path]

	# Execute inklecate
	print("Compiling: %s -> %s" % [source_path, output_path])

	var output = []
	var exit_code = OS.execute(inklecate_path, args, output, true, false)

	# Print output
	for line in output:
		if not line.is_empty():
			print(line)

	# Check result
	if exit_code != 0:
		push_error("Inklecate compilation failed with exit code: %d" % exit_code)
		return false

	# Verify output file was created
	if not FileAccess.file_exists(output_path):
		push_error("Compilation appeared to succeed but output file not found: %s" % output_path)
		return false

	print("✅ Compilation successful: %s" % output_path)
	return true


## Gets the path to the inklecate binary for the current platform
## @return: Filesystem path to inklecate binary, or empty string on error
static func _get_inklecate_path() -> String:
	var executable_name = "inklecate"

	# Windows uses .exe extension
	if OS.get_name() == "Windows":
		executable_name = "inklecate.exe"

	# Path relative to addon
	var inklecate_res_path = "res://addons/gd-ink-native/bin/" + executable_name
	var inklecate_fs_path = ProjectSettings.globalize_path(inklecate_res_path)

	# Check if binary exists
	if not FileAccess.file_exists(inklecate_res_path):
		push_error("Inklecate binary not found at: %s" % inklecate_res_path)
		push_error("Make sure the Godot Ink Native addon is properly installed with binaries")
		return ""

	return inklecate_fs_path


## Validates source file and prepares output directory
## @param source: Source .ink file path
## @param output: Output .ink.json file path
## @return: true if valid, false otherwise
static func _validate_and_prepare(source: String, output: String) -> bool:
	# Check source file exists
	if not FileAccess.file_exists(source):
		push_error("Source file not found: %s" % source)
		return false

	# Check source file is .ink
	if not source.get_extension() == "ink":
		push_error("Source file must have .ink extension: %s" % source)
		return false

	# Ensure output directory exists
	var output_dir = output.get_base_dir()
	var output_fs_dir = ProjectSettings.globalize_path(output_dir)

	if not DirAccess.dir_exists_absolute(output_fs_dir):
		var err = DirAccess.make_dir_recursive_absolute(output_fs_dir)
		if err != OK:
			push_error("Failed to create output directory: %s (error code: %d)" % [output_dir, err])
			return false

	return true
