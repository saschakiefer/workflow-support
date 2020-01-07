-- UUID of the Project List Document in DevonThink
property projectsFileID : "CAF138E1-73AE-4CF3-86A6-F37E201F6084"
property databaseID : "1A52BDC9-1453-47A2-8E5F-0BC85D5C298B"

-- Get the Last Project
tell application id "DNtp"
	set projectDB to get database with uuid databaseID
	set projectsDoc to get record with uuid projectsFileID
	set projectsText to plain text of projectsDoc
	set lastProject to first item of paragraphs of projectsText
end tell

if lastProject is not equal to "" then
	set oldDelimiters to AppleScript's text item delimiters
	set AppleScript's text item delimiters to " | "
	set dateCode to first text item of projectsText
	set AppleScript's text item delimiters to "-"
	set existingYear to text 4 thru 7 of (first text item of dateCode)
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

set projectText to newCode & " | " & projectName

-- Create Devon Think Documents
tell application id "DNtp"
	-- Create Devon Think Folder
	set theRoot to create location "/" in projectDB
	set theFolder to create record with {name:projectText, type:group} in theRoot
	set theFolderUUID to uuid of theFolder
	
	-- Create Notes Document
	set theNotes to create record with {name:"_Notes for " & projectText, type:markdown, content:"# " & projectText} in theFolder
	set theNotesUUID to uuid of theNotes
	set theNotesFile to path of theNotes
	set theNotesFileEncoded to do shell script "perl -MURI::Escape -lne 'print uri_escape($_)' <<<" & quoted form of theNotesFile
end tell

-- Create and upload Tinderbox document
tell application id "DNtp"
	set tinderboxFile to import "~/git/workflow-support/templates/TinderboxTemplate.tbx" from "Finder" name ("Research for " & projectText) to theFolder
end tell

-- Create Omni Focus Project
tell application "OmniFocus"
	tell front document
		set theProject to make new project with properties {name:projectText, sequential:false}
		set projectID to the id of theProject
		set projectURL to "[OmniFocus Project](omnifocus://task/" & projectID & ")"
		-- set note of theProject to ("x-devonthink-item://" & theFolderUUID & return & return & "x-devonthink-item://" & theNotesUUID & return & return & "ia-writer://open?path=" & theNotesFileEncoded)
		set note of theProject to ("x-devonthink-item://" & theFolderUUID & return & return & "x-devonthink-item://" & theNotesUUID)
	end tell
end tell

tell application id "DNtp"
	-- Write Back to File
	set plain text of projectsDoc to ("* [" & projectText & "](x-devonthink-item://" & theFolderUUID & ")" & return & projectsText)
	
	-- Update notes doc with OmniFocus Ref
	set plain text of theNotes to ("# " & projectText & return & return & "## Links" & return & return & "* " & projectURL & return & return & "## Notes" & return)
end tell

-- Write Back Variable to keyboard maestro
tell application "Keyboard Maestro Engine"
	try
		set value of variable "fullProjectName" to projectText
	on error
		make new variable with properties {name:"fullProjectName", value:projectText}
	end try
end tell