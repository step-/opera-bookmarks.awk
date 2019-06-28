# Output:
#   SQLite table dump statements, which can create a table when fed into sqlite3.

# Usage:
#   awk -f lib/toSql.awk [OPTIONS] file | "-"
# OPTIONS:
#   -v OUTFILE="path"    write to "path" rather than to stdout
#   -v TABLE="t"         SQL table name

#-------------------------------- START / END ----------------------------------

BEGIN {
	if ("" == OUTFILE) {
		OUTFILE = "/dev/stdout"
	}

	RS = ""
}
END {
	dump_sql(TABLE ? TABLE : "t")
}

#---------------------------------- HELPERS ------------------------------------

function dump_sql(table,   i, keys, values) {
	print "PRAGMA foreign_keys=OFF;\nBEGIN TRANSACTION;" > OUTFILE
	print "DROP TABLE IF EXISTS " table ";" > OUTFILE
	printf "CREATE TABLE IF NOT EXISTS " table " (" KEY[1] > OUTFILE
	for(i = 2; i <= nKEY; i++) {
		printf ", %s", KEY[i] > OUTFILE
	}
	print ");" > OUTFILE
	for(i = 1; i <= nKVS; i++) {

		# split 'k="v"\nk="v"' into 'k,\nk' and '"v",\n"v"'
		keys = values = KVS[i]
		gsub(/=[^\n]+/, "", keys)
		gsub(/\n/, ",\n", keys)
		sub(/^/, "\n", values)
		gsub(/\n[^=]+=/, "\n", values)
		sub(/^\n/, "", values)
		gsub(/\n/, ",\n", values)

		# JSON to SQL: escape interior single quotes and unescape interior double quotes
		gsub(/'/,   "''", values)
		gsub(/\\"/,  "\"", values)
		# replace exterior " with '
		gsub(/",\n"/, "',\n'", values)
		gsub(/",\n/, "',\n", values)  # for integer values, i.e. key 'version'
		gsub(/^"|"$/, "'", values)

		printf "INSERT INTO %s (%s) VALUES (%s);\n", table, keys, values > OUTFILE
	}
	print "COMMIT;" > OUTFILE
}

# Track all keys, which will become table columns.
function track_keys(kvs,   K, nK, i) {
	gsub(/=[^\n]+/, "", kvs)
	nK = split(kvs, K, /\n/)
	for(i = 1; i <= nK; i++) {
		if (!(K[i] in KEYS)) {
			KEY[++nKEY] = KEYS[K[i]] = K[i]
		}
	}
}

#------------------------------------ MAIN -------------------------------------

{
	track_keys(    KVS[++nKVS] = $0   )
}

