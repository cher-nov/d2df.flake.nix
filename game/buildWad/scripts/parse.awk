#!/usr/bin/awk -f

BEGIN {
	RS = "\r\n"
	if (!prefix) {
		print("Variable prefix not set, exiting...")
		exit
	}
	system("mkdir -p " prefix ";")
}

# When we encounter a section header (e.g., :FONTS), we set the current directory.
/^:/ {
	currentDir = prefix "/" substr($0,2)
  print("Setting currentDir to " currentDir)
	system("mkdir -p " currentDir ";")
}

# For each file entry, extract the source file and target filename, then copy.
{
	gsub(/\\/,"/",$0)
	split($0, parts, "|")
	targetFile = parts[2]
	sourceFile = parts[1]
	split(sourceFile, sourceFileParts, "/")
	# ex: StandartWAD
	sourceBase = sourceFileParts[1]
	# ex: STDANIMTEXTURES
	sourceSection = sourceFileParts[2]
	# ex: BARREL...
	sourceBasename = sourceFileParts[3]

	# A section header like :FONTS
	if (targetFile == "") next

	split(sourceBasename, sourceBasenameParts, ".")
	if (sourceBasenameParts[2] == "") {
		targetFileExtension = ""
	} else {
		targetFileExtension = "." sourceBasenameParts[2]
	}

	# This is a special case: a nested structure
	if (match(tolower(sourceFile),"\\.wad$")) {
		if (!currentDir) currentDir = prefix
		basepath = sourceBase "/" sourceSection "/" sourceBasenameParts[1]
		destPath = currentDir "/" sourceBasenameParts[1]
    print("Copying from " basepath " to " destPath)
		system("mkdir -p " "\"" destPath "\"" ";")
		system("cp -f -r " "\"" basepath "\"" "/*"  " " "\"" destPath "\"" ";")
		next
	} else {
		if (!currentDir) destPath = prefix "/" targetFile
		else destPath = currentDir "/" targetFile
    print("Copying " sourceFile " to " destPath)
		system("cp -f -r -p " "\"" sourceFile "\"" " " "\"" destPath "\"" ";")
	}
}

END {
}
