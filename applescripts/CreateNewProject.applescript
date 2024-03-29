-- Location of the Project File
set home to POSIX path of (path to home folder)
set projectsPath to home & "/Library/Mobile Documents/com~apple~CloudDocs/Dokumente/2nd-brain/1 - 🗂 Projects/"
set projectsFile to projectsPath & "project-codes.md"

try
	set projectsList to read file (projectsFile as POSIX file) using delimiter {"
"}
	set lastProject to first item of projectsList
on error
	set lastProject to ""
end try

if lastProject is not equal to "" then
	set oldDelimiters to AppleScript's text item delimiters
	set AppleScript's text item delimiters to " - "
	set dateCode to first text item of lastProject
	set AppleScript's text item delimiters to "-"
	set existingYear to text 5 thru 8 of (first text item of dateCode)
	set existingCode to last text item of dateCode
	set AppleScript's text item delimiters to oldDelimiters
else
	set existingYear to "1900"
end if

-- Create new Project Name
set currentYear to year of (current date) as string
if existingYear = currentYear then
	set newNumber to "0000" & ((existingCode as number) + 1) as string
	set numberString to text ((length of newNumber) - 3) thru (length of newNumber) of newNumber
else
	set numberString to "0001"
end if

set newCode to currentYear & "-" & numberString

tell application "Keyboard Maestro Engine"
	set projectName to getvariable "Project Name"
end tell

set projectText to newCode & " - " & projectName

log projectText

-- Create Documents
try
	tell application "Finder"
		make new folder at projectsPath as POSIX file with properties {name:projectText}
	end tell
end try

set projectFile to projectsPath & projectText & "/" & projectText & ".md"
do shell script "touch \"" & projectFile & "\""

-- Create Omni Focus Project


tell application "OmniFocus"
	tell front document
		set theProject to make new project with properties {name:projectText, sequential:false}
		set projectID to the id of theProject
		set projectURL to "[OmniFocus Project](omnifocus://task/" & projectID & ")"
	end tell
end tell


(*
tell application "Things3"
	set theProject to make new project with properties {name:projectText}
	set projectID to the id of theProject
	set projectURL to "[Things Project](things:///show?id=" & projectID & ")"
end tell
*)

-- Link to Document
do shell script "echo \"---\" >> \"" & projectFile & "\""
do shell script "echo \"aliases: [" & projectName & "]\" >> \"" & projectFile & "\""
do shell script "echo \"---\" >> \"" & projectFile & "\""
do shell script "echo \"\" >> \"" & projectFile & "\""
do shell script "echo \"# Links\" >> \"" & projectFile & "\""
do shell script "echo \"- " & projectURL & "\" >> \"" & projectFile & "\""

-- Store Project Ref
set projectRef to "* [[" & projectText & "]]"

try
	set fileContents to (read (projectsFile as POSIX file))
on error
	set fileContents to ""
end try

tell application "TextEdit"
	set myDocument to open projectsFile
	set text of myDocument to ("* [[" & projectText & "]]" & return & fileContents)
	save
	quit
end tell

-- Write Back Variable to keyboard maestro
tell application "Keyboard Maestro Engine"
	try
		set value of variable "fullProjectName" to projectText
	on error
		make new variable with properties {name:"fullProjectName", value:projectText}
	end try
end tell