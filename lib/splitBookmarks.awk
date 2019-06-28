# Callbacks that translate or process JSON text
# Mawk must always define all callbacks.
# Gawk and busybox awk must define callbacks when STREAM=1 only.
# More info in FAQ.md#5.

# Output:
#   Records to stdout.
#   Record separator: empty line.
#   Record format: newline separated list of shell variable assignments.

# Usage:
#   awk -f lib/splitBookmarks.awk -f JSON.awk -v STREAM=0 [OPTIONS] /path/to/Bookmarks
# OPTIONS:
#   -v OUTFILE="path"    write to "path" rather than to stdout.

#-------------------------------- START / END ----------------------------------

BEGIN {
	if ("" == OUTFILE) {
		OUTFILE = "/dev/stdout"
	}
}

END {
	if (0 == STREAM) {
		exit(STATUS) # set in cb_fail1
	}
}

#---------------------------------- HELPERS ------------------------------------

# Print then POP TOS
function pop_object() {
	if (OBJ_TOP +0) {
		print OBJ_DATA[OBJ_PATH[OBJ_TOP--]] "\n" > OUTFILE
	}
}

# Push to TOS
function push_object(jpath,   path) {
	path = jpath
	gsub(/""/, "/", path)
	gsub(/"/, "/", path)
	OBJ_DATA[OBJ_PATH[++OBJ_TOP] = jpath] = format_key_value("path", "\"" (path ? path : "/") "\"")
}

# Add to TOS
function add_key_value(key, value) {
	if (OBJ_TOP +0) {
		OBJ_DATA[OBJ_PATH[OBJ_TOP]] = OBJ_DATA[OBJ_PATH[OBJ_TOP]] "\n" format_key_value(key, value)
	}
}

function format_key_value(key, value) {
	return key "=" value
}

# Enquire any object path, pass "" for TOS
function which_object(depth) {
	depth = depth +0
	return OBJ_PATH[!depth ? OBJ_TOP : depth]
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
function cb_parse_object_enter(jpath,   array_item_jpath) {

#	print "cb_parse_object_enter("jpath") token("TOKEN")" >"/dev/stderr"

	# Process each object separately. Special case: process "meta_info"
	# leaf object together with its container object.
	if (!match(jpath, /"meta_info"$/)) {
		push_object(jpath)
	}
}

# cb_parse_object_exit - end parsing an object.
# Called in JSON.awk's main loop when STREAM=0 only.
function cb_parse_object_exit(jpath, status,   array_item_jpath) {

#	print "cb_parse_object_exit("jpath") status("status") token("TOKEN") value("CB_VALUE")" >"/dev/stderr"

	# We didn't push the "meta_info" object, therefore we won't pop it.
	if (!match(jpath, /"meta_info"$/)) {
		pop_object()
	}
}

# cb_append_jpath_component - format jpath components
# Called in JSON.awk's main loop when STREAM=0 only.
function cb_append_jpath_component (jpath, component) {

	# A null component marks the beginning of the JSON text stream.
	# Components can be integers, for array items, or quoted strings, for
	# object keys. So we return combinations of strings like "text""text"
	# and "text"integer, i.e. ..."children"3"meta_info"...
	if ("" != component) {
		return jpath component
	}
}

# cb_append_jpath_value - format a jpath / value pair
# Called in JSON.awk's main loop when STREAM=0 only.
# Here we selectively collect object key-values.
function cb_append_jpath_value (jpath, value,   key) {

#	print "cb_append_jpath_value("jpath") ("jpath") value("value")" >"/dev/stderr"

	# trim leading array item jpath
	key = substr(jpath, length(which_object()) +1)
	# unquote
	key = substr(key, 2, length(key) -2)
	# forge valid shell identifier
	gsub(/""/, "_", key)

	add_key_value(key, value)
}

# cb_jpaths - process cb_append_jpath_value outputs
# Called in JSON.awk's main loop when STREAM=0 only.
# See also cb_parse_array_enter and cb_parse_object_enter.
function cb_jpaths (ary, size) {
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

