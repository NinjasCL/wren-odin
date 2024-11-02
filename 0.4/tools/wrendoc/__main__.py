"""
# WrenDoc

This is a simple documentation generator.
The idea is to parse files and look for
markdown style comments (/** */).

Then generate the proper .md files inside docs
directory.

- Source: https://github.com/NinjasCL/domepunk/tree/main/tools/docs
- License:  MPL-2.0 license
- Python: 3.7
"""
import re
import glob
import sys
import config
from pathlib import Path

# Avoid parsing the file
# e.g. /** doc-disable */
CMD_DISABLE = "doc-disable"

# Sets the filename for the doc
# e.g /** doc-name: MyDoc */
CMD_FILENAME = "doc-name:"

CMD_HEADER = "doc-header"

def commandIsDisable(comment):
	return comment.strip().startswith(CMD_DISABLE)

def commandIsFilename(comment):
	return comment.strip().startswith(CMD_FILENAME)

def commandIsHeader(comment):
	return comment.strip().startswith(CMD_HEADER)

def getPath(path = None):
	# Safely get the first arg
	# Use default path if not found
	path = path or dict(enumerate(sys.argv)).get(1) + "/" or "../../"
	return path

def getDocPath(path = None):
	return f"{getPath(path)}{config.docs}"

def getFiles(path = None):
	path = getPath(path)
	files = list(Path(path).glob('**/*.odin'))
	return files

def getFileContent(path):
	with open(path) as file:
		return file.read()

def getFileInfo(path):
	return Path(path)

def getLineNumber(index, content):
	line = 1
	for pos, char in enumerate(content):
		if char == "\n":
			line += 1
		if index == pos:
			return line
	return None

def getComments(content, file):
	# Regex for /** comment start
	startCommentRegex = re.compile("\s*\S*(\/\*\*)")

	# for all the found matches
	# search for the corresponding */
	# and save the comment inside
	comments = []
	startMatches = startCommentRegex.finditer(content)
	endCommentChar = "*/"
	openCurlyBraceChar = "{"
	filename = None
	header = ""

	for startMatch in startMatches:
		start = startMatch.span()[1]
		end = content.find(endCommentChar, start)
		lineno = getLineNumber(start, content)

		if end >= 0:
			comment = content[start:end]
			# count leading spaces https://stackoverflow.com/a/13649013
			spaces = (len(comment) - 1) - len(comment.lstrip())

			if comment != "":

				if commandIsDisable(comment):
					return []

				if commandIsFilename(comment):
					filename = comment[comment.find(CMD_FILENAME) + len(CMD_FILENAME):].strip()
					continue

				if commandIsHeader(comment):
					header = comment[comment.find(CMD_HEADER) + len(CMD_HEADER):]
					continue

				nextlineStart = end + len(endCommentChar)
				nextlineEnd = content.find(openCurlyBraceChar, nextlineStart)
				nextline = content[nextlineStart:nextlineEnd]
				nextlineno = getLineNumber(nextlineStart, content)

				comments.append(
					(
						(comment, start, end, lineno),
						(nextline, nextlineStart, nextlineEnd, nextlineno),
						(spaces, filename, header)
					)
				)

	return comments

def getHref(line, lineno, url):
	sanitized = line.replace("\n", " ")
	return f"[{sanitized}]({url}#L{lineno})\n"

def saveFile(path, content):
	file = open(path, "w+")
	file.write(content)
	file.close()

def makeMarkdownFile(comments, file):

	info = getFileInfo(file)
	# print(info, info.name, info.stem, info.parent)
	url = f"https://{config.repo}/{config.branch}/{info}"

	markdown = f"""<!-- file: {info} -->
<!-- documentation automatically generated using domepunk/tools/doc -->"""

	apiHeaderPresent = False
	addedHeaderContent = False

	for index, comment in enumerate(comments):
		content, line, meta = comment
		spaces, filename, header = meta

		if not addedHeaderContent:
			markdown += header
			addedHeaderContent = True

		content, cstart, cend, clineno = content
		line, lstart, lend, llineno = line

		line = line.strip()

		# Headers
		#classKeyword = ":: proc"

		# if line.startswith(f"{classKeyword} "):
		#   title = f"{classKeyword.title()}" + line[len(classKeyword):]
		#   markdown += f"\n---\n## {getHref(title, llineno, url)}\n"
		#   apiHeaderPresent = False
		# else:
		if not apiHeaderPresent:
			markdown += "\n## API\n"
			apiHeaderPresent = True

		markdown += f"\n### {getHref(line, llineno, url)}\n"

		# Write comment contents to the markdown file
		buffer = ""
		for char in content:
			buffer += char
			if char == "\n":
				# Strip leading spaces to have a proper markdown doc
				markdown += buffer[spaces:].rstrip() + char
				buffer = ""

	# End parsing and save file
	name = f"{info}".lower().strip().replace("/", "-").replace("\\", "-")
	if filename:
		name = filename

	doc = f"{getDocPath()}/{name}.md"
	saveFile(doc, markdown)


def main():
	files = getFiles()
	total = 0
	pending = 0
	for file in files:
		content = getFileContent(file)
		comments = getComments(content, file)
		pending = len(comments)
		if pending > 0:
			total += pending
			makeMarkdownFile(comments, file)

	print(f"✨ Jobs Done!: found {len(files)} files. parsed {total} comments. docs saved in `{getDocPath()}`")

if __name__ == "__main__":
	main()


