# opera-bookmarks.awk

* Export (Chromium) Opera bookmarks and QuickDial thumbnails
* Convert bookmark data to SQLite database and CSV file.

See section Examples further down in this document.

## Supported Platforms

This application consists of some [JSON.awk](https://github.com/step-/JSON.awk)
callback files, and requires `JSON.awk`, and commands `awk`, `base64` and
`mkdir`. It was developed and tested on Linux. It should be able to run
unchanged on Mac OSX, provided that JSON.awk can also run, which for some Mac
users has been [challenging](https://github.com/step-/JSON.awk/issues/15).
Windows users need to install the missing commands before they can run this
application.

Converting bookmarks to SQLite and CSV requires command `sqlite3`.

## Installing

Download or clone this repository and move it in a directory of your
choosing.  Run the examples.

The examples in this document assume that the repository folder is located
inside the Opera profile folder, where Opera stores its files `Bookmarks` and
`BookmarksExtras`.  The default Opera profile folder on Linux is located in
`$XDG_CONFIG_HOME`, usually `~/.config`. The full path to JSON.awk must be
substituted in the examples. Alternatively, you can create link JSON.awk from
the repository folder.

```
~/.config
├── opera
    ├── Bookmarks
    ├── BookmarksExtras
    ├── this-repo
        ├── JSON.awk -> /path/to/JSON.awk
        ├── lib
        │   ├── splitBookmarks.awk
        │   ├── splitBookmarksExtras.awk
        │   ├── toFile.awk
        │   └── toSql.awk
        ├── LICENSE.MIT
        ├── LICENSE.APACHE2
        └── README.md
```

## Usage

### lib/splitBookmarks.awk

**Output**

Records to stdout.
Record separator: empty line.
Record format: newline separated list of shell variable assignments.

**Usage**

```sh
awk -f lib/splitBookmarks.awk -f JSON.awk -v STREAM=0 [Options] /path/to/Bookmarks
```

**Options**

```
-v OUTFILE="path"    write to "path" rather than to stdout.
```

### lib/splitBookmarksExtras.awk

**Requirements**

Linux commands: base64, mkdir.

**Output**

List of written image IDs to stdout; image (and base64) files written to destination directory.

**Usage**

```sh
awk -f lib/splitBookmarksExtras.awk -f JSON.awk -v STREAM=0 [Options] /path/to/BookmarksExtras
```

**Options**

```
-v B64=1             also write base64 encoded files (default 0).
-v CLOBBER=1         overwrite an existing base64/image file (default 0).
-v DEST_DIR="bookmark-extras"     destination directory for image and base64 files.
-v DRY_RUN=1         list files that would be written but don't write them (default 0).
-v OUTFILE="path"    write to "path" rather than to stdout.
```

### lib/toFile.awk

**Output**

List of written file IDs to stdout; files written to destination directory.
If a file ID is missing, the record is written to stderr.

**Usage**

```sh
awk -f lib/toFile.awk [Options] file | "-"
```

**Options**

```
-v CLOBBER=1         overwrite an existing file (default 0).
-v DEST_DIR="bookmark-files"     destination directory for new files.
-v DRY_RUN=1         list files that would be written but don't write them (default 0).
-v OUTFILE="path"    write to "path" rather than to stdout.
```

### lib/toSql.awk

**Output**

SQLite table dump statements, which can create a table when fed into sqlite3.

**Usage**

```sh
awk -f lib/toSql.awk [Options] file | "-"
```

**Options**

```
-v OUTFILE="path"    write to "path" rather than to stdout
-v TABLE="t"         SQL table name
```

## Examples

### Extract bookmark info files

To directory `bookmark-files`. Each file is named by the value of the `id` key it contains.

```sh
awk -f lib/splitBookmarks.awk -f JSON.awk -v STREAM=0 ../Bookmarks |
awk -f lib/toFile.awk | head
```

### Extract image thumbnails

To directory `bookmark-extras`. Each thumbnail is named by its extracted key,
which corresponds to the value of an `imageID` key contained in one or more
info files. Think of the `imageID` value as a link to the image data file.

```sh
awk -f lib/splitBookmarksExtras.awk -f JSON.awk -v STREAM=0 ../BookmarksExtras | head
```

Note that the thumbnails that Opera stores in file `Bookmarks` must be extraced
individually from the info files that contain key `meta_info_imageData`.  No
script is currently provided to do that because the procedure simply involves
feeding the `meta_info_imageData` value to command `base64 -d`.

### Convert Bookmarks to CSV

Command `sqlite3` required.

```sh
awk -f lib/splitBookmarks.awk -f JSON.awk -v STREAM=0 ../Bookmarks |
awk -f lib/toSql.awk |
sqlite3 /tmp/t.sqlite &&
sqlite3 -csv -header /tmp/t.sqlite "select * from t" > bookmarks.csv
```

### Display duplicated bookmark IDs

Linux commands `sort` and `uniq` required.

There shouldn't be any, that is, no output is expected if everything is OK.

```sh
awk -f lib/splitBookmarks.awk -f JSON.awk -v STREAM=0 ../Bookmarks |
grep ^id= | sort | uniq -cd
```

