BEGIN {
	RS = "\r\n"
	outputName = "unknown.zip"
	if (!prefix) {
		print("Variable prefix not set, exiting...")
		exit
	}
	if (!outputPath) {
		print("Variable outputPath not set, exiting...")
		exit
	}
	system("mkdir -p " prefix)
}

# When we encounter a section header (e.g., :FONTS), we set the current directory.
/^:/ {
	currentDir = prefix "/" substr($0,2)
	system("mkdir -p " currentDir)
}

# For each file entry, extract the source file and target filename, then copy.
{
	gsub(/\\/,"/",$0)
	split($0, parts, "|")
	sourceFile = parts[1]
	targetFile = parts[2]
	# A section header like :FONTS
	if (targetFile == "") next
	destPath = currentDir "/" targetFile
	
	# This is a special case: a nested structure
	if (match(tolower(sourceFile),"\\.wad$")) {
		if (!currentDir) currentDir = prefix
		# Remove .wad extension, because it has done its purpose: inform us that this is a nested structure
		sub("\\.wad$", "", sourceFile)
		split(sourceFile, sourceFileParts, "/")
		# ex: StandartWAD...
		base = sourceFileParts[1]
		# ex: STDANIMTEXTURES...
		src = sourceFileParts[2]
		# ex: BARREL...
		basename = sourceFileParts[3]

		basepath = base "/" src
		zipFile = basename ".zip"
		destPath = prefix "/" src "/" zipFile
		system("(cd "basepath " ;zip -r $(pwd)/../../" destPath " ./" basename " ; )")
		next
	} else {
	if (!currentDir) destPath = prefix "/" targetFile
	else destPath = currentDir "/" targetFile
	system("cp -r -p " sourceFile " " destPath)
	}
}

END {
	if (prefix && outputPath) {
		system("(cd " prefix " ; " "zip -r " "../" outputPath " " "." " ; )")
		system("rm -r " prefix)
	}
}
