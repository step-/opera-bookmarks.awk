# Callbacks that translate or process JSON text
# Mawk must always define all callbacks.
# Gawk and busybox awk must define callbacks when STREAM=1 only.
# More info in FAQ.md#5.

# Requirements:
#   Linux commands: base64, mkdir.

# Output:
#   List of written image IDs to stdout; image (and base64) files written to destination directory.

# Usage:
#   awk -f lib/splitBookmarksExtras.awk -f JSON.awk -v STREAM=0 [OPTIONS] /path/to/BookmarksExtras
# OPTIONS:
#   -v B64=1             also write base64 encoded files (default 0).
#   -v CLOBBER=1         overwrite an existing base64/image file (default 0).
#   -v DEST_DIR="bookmark-extras"     destination directory for image and base64 files.
#   -v DRY_RUN=1         list files that would be written but don't write them (default 0).
#   -v OUTFILE="path"    write to "path" rather than to stdout.

#-------------------------------- START / END ----------------------------------

BEGIN {
	if (0 == STREAM) {

		if ("" == DEST_DIR) { DEST_DIR = "bookmark-extras" }
		STATUS = system("mkdir -p \"" DEST_DIR "\"")
		if (STATUS != 0)
			exit

		if ("" == OUTFILE) {
			OUTFILE = "/dev/stdout"
		}

		B64 = B64 +0
		CLOBBER = CLOBBER +0
		DRY_RUN = DRY_RUN +0
	}
}

END {
	if (0 == STREAM)
		exit(STATUS) # set in cb_fail1 and BEGIN
}

#---------------------------------- HELPERS ------------------------------------

function write_file(file, value,   exists, data, decoder, status) {
	file = DEST_DIR "/" file
	if (exists = (-1 != (getline data < file))) {
		close(file)
	}

	if (DRY_RUN) {
		print file > OUTFILE
		return 0
	}

	if (!exists || CLOBBER) {
		data = substr(value, 2, length(value) -2)
		decoder = "base64 -d > \"" file "\""
		print data | decoder
		status = close(decoder)
		if (0 == status) {
			print file > OUTFILE

			if (B64) {
				print data > file".b64"
				status = close(file".b64")
			}
		}
	}

	return status
}

#--------------------------------- CALLBACKS -----------------------------------

# cb_parse_array_empty - parse an empty JSON array.
# Called in JSON.awk's main loop when STREAM=0 only.
function cb_parse_array_empty(jpath) {

#	print "parse_array_empty("jpath")" >"/dev/stderr"
}

# cb_parse_object_empty - parse an empty JSON object.
# Called in JSON.awk's main loop when STREAM=0 only.
function cb_parse_object_empty(jpath) {

#	print "parse_object_empty("jpath")" >"/dev/stderr"
}

# cb_parse_array_enter - begin parsing an array.
# Called in JSON.awk's main loop when STREAM=0 only.
function cb_parse_array_enter(jpath) {

#	print "cb_parse_array_enter("jpath") token("TOKEN")" >"/dev/stderr"
}

# cb_parse_array_exit - end parsing an array.
# Called in JSON.awk's main loop when STREAM=0 only.
function cb_parse_array_exit(jpath, status) {

#	print "cb_parse_array_exit("jpath") status("status") token("TOKEN") value("CB_VALUE")" >"/dev/stderr"
}

# cb_parse_object_enter - begin parsing an object.
# Called in JSON.awk's main loop when STREAM=0 only.
function cb_parse_object_enter(jpath) {

#	print "cb_parse_object_enter("jpath") token("TOKEN")" >"/dev/stderr"
}

# cb_parse_object_exit - end parsing an object.
# Called in JSON.awk's main loop when STREAM=0 only.
function cb_parse_object_exit(jpath, status) {

#	print "cb_parse_object_exit("jpath") status("status") token("TOKEN") value("CB_VALUE")" >"/dev/stderr"
}

# cb_append_jpath_component - format jpath components
# Called in JSON.awk's main loop when STREAM=0 only.
function cb_append_jpath_component (jpath, component) {

	# A null component marks the beginning of the JSON text stream
	if ("" != component) {
		# Component is all we need, since the input JSON text consists
		# of a flat object.
		return component
	}
}

# cb_append_jpath_value - format a jpath / value pair
# Called in JSON.awk's main loop when STREAM=0 only.
# The single object in BookmarksExtras holds keys (jpaths) whose values correspond to base64-encoded images.
# Save each image to a file named by the corresponding key.
# Do not overwrite existing files.
function cb_append_jpath_value (jpath, value) {

#	print "cb_append_jpath_value("jpath") ("jpath") value("value")" >"/dev/stderr"

	write_file(substr(jpath, 2, length(jpath) -2), value) # unquote
}

# cb_jpaths - process cb_append_jpath_value outputs
# Called in JSON.awk's main loop when STREAM=0 only.
# See also cb_parse_array_enter and cb_parse_object_enter.
function cb_jpaths (ary, size,   i) {
	;
}

# cb_fails - process all error messages at once after parsing
# has completed. Called in JSON.awk's END action when STREAM=0 only.
# This example illustrates printing parsing errors to stdout,
function cb_fails (ary, size,   k) {

	# Print ary - associative array of parsing failures.
	# ary's keys are the size input file names that JSON.awk read.
	for(k in ary) {
		print "cb_fails: invalid input file:", k
		print FAILS[k]
	}
}

# cb_fail1 - process a single parse error as soon as it is
# encountered.  Called in JSON.awk's main loop when STREAM=0 only.
# Return non-zero to let JSON.awk also print the message to stderr.
# This example illustrates printing the error message to stdout only.
function cb_fail1 (message) {

	print "cb_fail1: invalid input file:", FILENAME
	print message
	STATUS = 1
}

