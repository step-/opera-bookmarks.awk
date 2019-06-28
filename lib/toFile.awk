# Output:
#   List of written file IDs to stdout; files written to destination directory.
#   If a file ID is missing, the record is written to stderr.

# Usage:
#   awk -f lib/toFile.awk [OPTIONS] file | "-"
# OPTIONS:
#   -v CLOBBER=1         overwrite an existing file (default 0).
#   -v DEST_DIR="bookmark-files"     destination directory for new files.
#   -v DRY_RUN=1         list files that would be written but don't write them (default 0).
#   -v OUTFILE="path"    write to "path" rather than to stdout.

#-------------------------------- START / END ----------------------------------

BEGIN {
	if ("" == DEST_DIR) { DEST_DIR = "bookmark-files" }
	STATUS = system("mkdir -p \"" DEST_DIR "\"")
	if (STATUS != 0)
		exit

	if ("" == OUTFILE) {
		OUTFILE = "/dev/stdout"
	}

	CLOBBER = CLOBBER +0
	DRY_RUN = DRY_RUN +0

	RS = ""
}

#---------------------------------- HELPERS ------------------------------------

function write_file(data,   id, file, exists, x, status) {
	# name the new file by key 'id'
	if (match(data, /(^|\n)id="[^\n]+/)) {
		id = substr(data, RSTART, RLENGTH)
		id = substr(id, index(id, "=") +1)
		id = substr(id, 2, length(id) -2) # unquote
		file = DEST_DIR "/" id ".sh"
	}

	if ("" == file) {
		print data > "/dev/stderr"
		print "" > "/dev/stderr"
		return 1
	}

	if (exists = (-1 != (getline x < file))) {
		close(file)
	}

	if (DRY_RUN) {
		print file > OUTFILE
		return 0
	}

	if (!exists || CLOBBER) {
		print data > file
		status = close(file)

		if (0 == status) {
			print file > OUTFILE
		}
	}

	return status
}


#------------------------------------ MAIN -------------------------------------

{
	write_file($0)
}

