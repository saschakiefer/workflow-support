--================================================================================
--================================================================================
--
-- Zettelkasten aus den markierten Devon Think Zetteln erzeugen
-- Optimierungen für später nicht ausgeschlossen
-- 
-- Annahmen:
--   Titel des Zettel in DevonThink [ID] | [Titel]
--   Jeder Zettel hat in DevonThink genau 1 Tag
--   Die Zettel sind in Markdown verfasst
--   Das Trennzeichen für den Metadatenabschnitt ist --- und wird nur ein mal im Text verwendet
--================================================================================
--================================================================================
use scripting additions
use framework "Foundation"

-------------------------------------------------------------------------------------------------------------------------------------------------
-- Globale Konstanten
-------------------------------------------------------------------------------------------------------------------------------------------------
set containerName to "Prototypes"
set prototypeAuthor to "pAutor"
set prototypeName to "pZettel"
set prototypeNameExt to "pExternalSource"
set keyAttributesStr to "URL;SourceURL;SourceCreated;ZettelID;DTReferences;Authors;Source;Tags"
set keyAttributesStrExt to "URL;SourceURL;SourceCreated"

set mainCategories to {IDXX:"xx Autoren", ID00:"00 Allgemeines", ID01:"01 Technologie", ID02:"02 Spiritualität", ID03:"03 Management", ID04:"04 Gesundheit"}
set catDictionary to current application's NSDictionary's dictionaryWithDictionary:mainCategories

set zettelkastenRecordUUID to "EA459C7B-91B5-4169-B250-C1AD87C92941" -- This is the ID of the Zettelkasten Tinderbox document stored in DevonThink
set dtZettelkastenGroupUUID to "4E773FD4-1314-4F33-ABA9-32E1B6362ABF" -- Zettelkasten Folder in Devon Think

--================================================================================
--================================================================================
--
-- Hauptprogramm
-- 
--================================================================================
--================================================================================

-------------------------------------------------------------------------------------------------------------------------------------------------
-- Check for Selection and Select all Zettel if needed (only when in viewer window)
-------------------------------------------------------------------------------------------------------------------------------------------------
tell application id "DNtp"
	try
		set thisSelection to the selection
		if thisSelection is {} then
			set zettelkastenGroup to get record with uuid dtZettelkastenGroupUUID
			
			set theZettelList to children of zettelkastenGroup
			
			-- Select all Zettel
			set frontmostWindow to think window 1
			set windowClass to (class of frontmostWindow)
			
			if windowClass is equal to viewer window then
				set selection of frontmostWindow to theZettelList
			end if
		end if
	end try
end tell

set zettelkastenGroup to {}

-------------------------------------------------------------------------------------------------------------------------------------------------
-- Open Zettelkasten
-------------------------------------------------------------------------------------------------------------------------------------------------
tell application id "DNtp"
	set zettelkastenRecord to get record with uuid zettelkastenRecordUUID
	set zettelkastenPath to path of zettelkastenRecord
end tell

tell application "Tinderbox 8"
	open zettelkastenPath
end tell

-------------------------------------------------------------------------------------------------------------------------------------------------
-- Set Up Tinderbox
-------------------------------------------------------------------------------------------------------------------------------------------------
tell application "Tinderbox 8"
	tell front document
		if not (exists) then error "No Tinderbox document open."
		
		#  create container for prototypes
		if not (exists note containerName) then
			set newNote to make new note
			tell newNote to set name to containerName
		else
			set newNote to note containerName
		end if
		
		#  create prototype with key attributes imported message notes will inherit
		if not (exists note prototypeName in newNote) then
			set theContainer to note containerName --> a reference
			set newPrototype to make new note at theContainer
			
			set newAttribute1 to make new attribute with properties {name:"ZettelID", type:"string", defaultValue:""}
			set newAttribute2 to make new attribute with properties {name:"DTReferences", type:"list", defaultValue:""}
			set newAttribute4 to make new attribute with properties {name:"Source", type:"string", defaultValue:""}
			
			tell newPrototype
				set value of attribute "Name" to prototypeName
				set value of attribute "KeyAttributes" to keyAttributesStr
				set value of attribute "badge" to "paperclip"
				set value of attribute "IsPrototype" to true
				set value of attribute "Color" to "lightest cool gray"
			end tell
		end if
		
		#  create prototype with key attributes imported message notes will inherit
		if not (exists note prototypeNameExt in newNote) then
			set theContainer to note containerName --> a reference
			set newPrototype to make new note at theContainer
			
			tell newPrototype
				set value of attribute "Name" to prototypeNameExt
				set value of attribute "KeyAttributes" to keyAttributesStrExt
				set value of attribute "badge" to "paperclip"
				set value of attribute "IsPrototype" to true
				set value of attribute "Color" to "lightest cool orange"
			end tell
		end if
		
		#  create prototype with key attributes imported message notes will inherit
		if not (exists note prototypeAuthor in newNote) then
			set theContainer to note containerName --> a reference
			set newPrototype to make new note at theContainer
			
			tell newPrototype
				set value of attribute "Name" to prototypeAuthor
				set value of attribute "KeyAttributes" to "FullName"
				set value of attribute "badge" to "person"
				set value of attribute "IsPrototype" to true
				set value of attribute "Color" to "lightest cool green"
				set value of attribute "Shape" to "oval"
			end tell
		end if
		
		-- Create Main Categories
		my createMainCategories()
	end tell
end tell

-------------------------------------------------------------------------------------------------------------------------------------------------
-- 1. Iteration: Alle Zettel aus Devon Think anlegen
-- Note: Kann in Zukunft optimiert werden in einem Durchgang (rekursieves abrabeiten der Referenzen)
-------------------------------------------------------------------------------------------------------------------------------------------------
tell application id "DNtp"
	try
		set this_selection to the selection
		if this_selection is {} then error "Please select some contents."
		
		repeat with this_record in this_selection
			repeat 1 times -- # fake loop see https://stackoverflow.com/questions/1024643/applescript-equivalent-of-continue
				-- Wollen wir dieses Dokument bearbeiten?
				if (my isValidRecord(this_record)) is false then exit repeat -- # simulated `continue`
				
				set this_title to the name of this_record
				set this_creation_date to the creation date of this_record
				set this_devon_url to the reference URL of this_record
				set this_source_url to the URL of this_record
				set this_type to the type of this_record
				set this_path to the path of this_record
				
				set this_tag to tags of this_record
				set this_tag to item 1 of this_tag
				
				-- Inhalt abhängig vom Format auslesen
				if (this_type is markdown) or (this_type is txt) then
					set this_content to the plain text of this_record
				else if (this_type = formatted note) or (this_type = rtf) or (this_type = rtfd) then
					set this_content to the rich text of this_record
				else
					set this_content to ""
				end if
				
				-- Handle Mails
				try
					set this_mime to the MIME type of this_record
					if this_mime is "message/rfc822" then
						set this_source_url to ""
						set this_content to the rich text of this_record
					end if
				end try
				
				set nameArray to my getNameComponents(this_title)
				my createNote(item 1 of nameArray, item 2 of nameArray, this_content, this_devon_url, this_source_url, this_creation_date as string, this_tag, prototypeName)
			end repeat
		end repeat
		
	on error error_message number error_number
		if the error_number is not -128 then display alert "DEVONthink" message error_message as warning
	end try
end tell


-------------------------------------------------------------------------------------------------------------------------------------------------
-- 2. Iteration: Links zwischen den Zettel anlegen und weitere Metadaten updaten
-------------------------------------------------------------------------------------------------------------------------------------------------
tell application id "DNtp"
	set theSelection to the selection
	
	repeat with theRecord in theSelection
		repeat 1 times -- # fake loop see https://stackoverflow.com/questions/1024643/applescript-equivalent-of-continue
			-- Wollen wir dieses Dokument bearbeiten?
			if (my isValidRecord(theRecord)) is false then exit repeat -- # simulated `continue`
			
			set theAuthors to {}
			set theSource to {}
			set theReferences to {}
			
			set currentZettel to {}
			
			set currentBlock to ""
			
			set theContent to the plain text of theRecord
			set theParagraphs to paragraphs of theContent
			
			-- Parse the Metadata
			set inMetadataBlock to false
			repeat with theParagraph in theParagraphs
				if (my trimText(theParagraph, " ", "both") as text) is "---" then
					set inMetadataBlock to true
				end if
				
				if inMetadataBlock is true then
					if (my trimText(theParagraph, " ", "both") as text) is "Referenzen:" then
						set currentBlock to "Referenzen"
					end if
					
					if (my trimText(theParagraph, " ", "both") as text) is "Quelle:" then
						set currentBlock to "Quelle"
					end if
					
					if (my trimText(theParagraph, " ", "both") as text) is "Autoren:" then
						set currentBlock to "Autoren"
					end if
				end if
				
				if theParagraph starts with "*" then
					set theText to (my trimText(theParagraph, "* ", "beginning") as text)
					set theText to (my trimText(theText, " ", "both") as text)
					
					if theText is not "" then
						if currentBlock is "Referenzen" then
							copy theText to the end of theReferences
						else if currentBlock is "Quelle" then
							copy theText to the end of theSource
						else if currentBlock is "Autoren" then
							copy theText to the end of theAuthors
						end if
					end if
				end if
			end repeat
			
			-- Create the Links
			if theReferences is not {} then
				set theZettelName to item 2 of my getNameComponents(name of theRecord)
				
				repeat with theReference in theReferences
					set localReference to my getReference(theReference)
					
					if (item 1 of localReference) is "link" then
						set thisTag to tags of theRecord
						set thisTag to item 1 of thisTag -- create missing refs in the same category
						
						tell front document of application "Tinderbox 8"
							set theTarget to find note in it with path (item 2 of localReference)
							
							if theTarget is missing value then
								-- Finde the original document in DevonThink
								
								tell application id "DNtp"
									set theResults to {}
									set theURL to ""
									
									set theResults to search "name:Telefonnummern"
									
									if theResults is not {} then
										set theSearchResult to item 1 of theResults -- always take the first one. That is good enough
										set theURL to reference URL of theSearchResult
									end if
								end tell
								
								set theTarget to my createNote("", (item 2 of localReference), "", theURL, "", "", thisTag, prototypeNameExt)
							end if
						end tell
					end if
					
					tell front document of application "Tinderbox 8"
						set currentZettel to find note in it with path theZettelName
						
						if currentZettel is missing value then -- that should not happen
							error "Could not find the Note for the current Zettel: " & theZettelName
						end if
						
						my linkFromNoteToNote("", currentZettel, theTarget)
					end tell
				end repeat
			end if
			
			-- Set the Authors
			if theAuthors is not {} then
				set theZettelName to item 2 of my getNameComponents(name of theRecord)
				
				tell front document of application "Tinderbox 8"
					set currentZettel to find note in it with path theZettelName
					
					if currentZettel is missing value then -- that should not happen
						error "Could not find the Note for the current Zettel: " & theZettelName
					end if
					repeat with theAuthor in theAuthors
						if not (exists note theAuthor in note prototypeAuthor) then
							set newAuthor to my createNote("", theAuthor, "", "", "", "", "XX", prototypeAuthor)
							tell newAuthor to set attribute "FullName"'s value to theAuthor
							tell newAuthor to set attribute "Width"'s value to 5
							tell newAuthor to set attribute "Height"'s value to 5
						else
							set newAuthor to find note in it with path theAuthor
						end if
						
						my linkFromNoteToNote("", newAuthor, currentZettel)
					end repeat
					
					set oldDelimiters to AppleScript's text item delimiters
					set AppleScript's text item delimiters to ";"
					
					tell currentZettel to set attribute "Authors"'s value to (theAuthors as string)
					
					set AppleScript's text item delimiters to oldDelimiters
				end tell
			end if
			
			
			-- Set the Source
			if theSource is not {} then
				set theZettelName to item 2 of my getNameComponents(name of theRecord)
				
				set localReference to my getReference(item 1 of theSource)
				
				tell front document of application "Tinderbox 8"
					set currentZettel to find note in it with path theZettelName
					
					tell currentZettel
						set attribute "Source"'s value to (item 3 of localReference)
						
						if (item 1 of localReference) is not "others" then
							if (attribute "SourceURL"'s value) is "" then
								set attribute "SourceURL"'s value to (item 3 of localReference)
							end if
						end if
					end tell
				end tell
			end if
		end repeat
	end repeat
end tell

display notification "Zettelkasten erfolgreich angelegt."

--================================================================================
--================================================================================
--
-- Subroutienen und Funktionen
--
--================================================================================
--================================================================================

-------------------------------------------------------------------------------------------------------------------------------------------------
-- Prüfen, ob das ein Record ist, der im Zettelkasten bearbeitet werden soll (keine Gruppe und startet nicht mit _)
-------------------------------------------------------------------------------------------------------------------------------------------------
on isValidRecord(theRecord)
	tell application id "DNtp"
		set theTitle to the name of theRecord
		set theType to the type of theRecord
		
		if (theType is group) or (theType is smart group) then return false
		if theTitle starts with "_" then return false
		
		return true
	end tell
end isValidRecord

-------------------------------------------------------------------------------------------------------------------------------------------------
-- Links anlegen
-------------------------------------------------------------------------------------------------------------------------------------------------
on linkFromNoteToNote(typeName, fromNote, toNote)
	tell application "Tinderbox 8"
		if typeName ≠ "" then
			set strType to typeName
		else
			set strType to "*untitled"
		end if
		set strID to value of (attribute "ID" of toNote)
		evaluate fromNote with "linkTo(" & strID & "," & strType & ")"
	end tell
end linkFromNoteToNote

-------------------------------------------------------------------------------------------------------------------------------------------------
-- Referenz konvertieren
-- verarbeitet Wiki Links mit [[]] und Markdown URLs mit []()
-------------------------------------------------------------------------------------------------------------------------------------------------
on getReference(rawData)
	log rawData
	set theReturnObject to {}
	
	if rawData contains "[[" then
		set theType to "link"
		set theReference to trimText(rawData, "[[", "beginning")
		set theReference to trimText(theReference, "]]", "end")
		set nameArray to my getNameComponents(theReference)
		
		try
			set theReturnObject to {theType, item 2 of nameArray, ""} -- Crashes if it's not a Zettel
		on error
			set theReturnObject to {theType, theReference, ""}
		end try
	else if rawData contains "](" then
		set theType to "url"
		
		set oldDelimiters to AppleScript's text item delimiters
		set AppleScript's text item delimiters to "]("
		
		set theArray to every text item of rawData
		
		set AppleScript's text item delimiters to oldDelimiters
		
		set theReference to (item 2 of theArray)
		set theReference to trimText(theReference, ")", "end")
		
		set theReturnObject to {theType, theReference, theReference}
	else
		set theType to "others"
		set theReturnObject to {theType, rawData, rawData}
	end if
	
	return theReturnObject
end getReference

-------------------------------------------------------------------------------------------------------------------------------------------------
-- Text trimmen
-------------------------------------------------------------------------------------------------------------------------------------------------
on trimText(theText, theCharactersToTrim, theTrimDirection)
	set theTrimLength to length of theCharactersToTrim
	if theTrimDirection is in {"beginning", "both"} then
		repeat while theText begins with theCharactersToTrim
			try
				set theText to characters (theTrimLength + 1) thru -1 of theText as string
			on error
				-- text contains nothing but trim characters
				return ""
			end try
		end repeat
	end if
	if theTrimDirection is in {"end", "both"} then
		repeat while theText ends with theCharactersToTrim
			try
				set theText to characters 1 thru -(theTrimLength + 1) of theText as string
			on error
				-- text contains nothing but trim characters
				return ""
			end try
		end repeat
	end if
	return theText
end trimText

-------------------------------------------------------------------------------------------------------------------------------------------------
-- Zettel anlegen
-------------------------------------------------------------------------------------------------------------------------------------------------
to createNote(theID, theName, theText, theURL, theSource, createdAt, theTag, thePrototype)
	tell application "Tinderbox 8"
		tell front document
			set newNote to find note in it with path theName
			
			if newNote is missing value then
				set parentNote to note (my getCategoryNoteNameByTag(theTag))
				set newNote to make new note at parentNote
				tell newNote
					set name to theName
					set attribute "Text"'s value to theText
					set attribute "URL"'s value to theURL
					set attribute "SourceURL"'s value to theSource
					set attribute "SourceCreated"'s value to createdAt
					set attribute "Prototype"'s value to thePrototype as string
					set attribute "Width"'s value to 7
					set attribute "Height"'s value to 3
					set attribute "ZettelID"'s value to theID
					set attribute "Tags"'s value to theTag
				end tell
			else
				tell newNote to set attribute "Text"'s value to theText -- Update the text in any case
			end if
		end tell
	end tell
	
	return newNote
end createNote

-------------------------------------------------------------------------------------------------------------------------------------------------
-- Kategorie Hauptgruppen ID aus dem Tag ableiten
-------------------------------------------------------------------------------------------------------------------------------------------------
to getCategoryNoteNameByTag(theTag)
	-- save delimiters to restore old settings
	set oldDelimiters to AppleScript's text item delimiters
	
	if theTag contains "," then
		set AppleScript's text item delimiters to ","
	else
		set AppleScript's text item delimiters to " " -- main category
	end if
	-- set delimiters to delimiter to be used
	
	
	-- create the array
	set theArray to every text item of theTag
	
	-- restore the old setting
	set AppleScript's text item delimiters to oldDelimiters
	
	set theID to "ID" & (item 1 of theArray as text)
	
	return (my (catDictionary's valueForKey:theID)) as text
end getCategoryNoteNameByTag

-------------------------------------------------------------------------------------------------------------------------------------------------
-- Hauptkategorien anlegen (basierend auf dem Array)
-------------------------------------------------------------------------------------------------------------------------------------------------
to createMainCategories()
	set allKeys to my catDictionary's allKeys()
	
	set sortedKeys to {}
	repeat with theKey in allKeys
		set sortedKeys to sortedKeys & theKey
	end repeat
	set sortedKeys to simpleSort(sortedKeys)
	
	set counter to 0
	repeat with theKey in sortedKeys
		set counter to counter + 1
		log counter
		set catName to getCatByID(theKey as text)
		tell front document of application "Tinderbox 8"
			if not (exists note catName) then
				
				--if counter is 1 then
				set newNote to make new note
				--else
				--set newNote to make new note at before first note
				--end if
				
				tell newNote to set name to catName
				tell newNote to set attribute "Width"'s value to 6
			end if
		end tell
	end repeat
end createMainCategories

-------------------------------------------------------------------------------------------------------------------------------------------------
-- Simple List Sorter
-------------------------------------------------------------------------------------------------------------------------------------------------
on simpleSort(my_list)
	set the index_list to {}
	set the sorted_list to {}
	repeat (the number of items in my_list) times
		set the low_item to ""
		repeat with i from 1 to (number of items in my_list)
			if i is not in the index_list then
				set this_item to item i of my_list as text
				if the low_item is "" then
					set the low_item to this_item
					set the low_item_index to i
				else if this_item comes before the low_item then
					set the low_item to this_item
					set the low_item_index to i
				end if
			end if
		end repeat
		set the end of sorted_list to the low_item
		set the end of the index_list to the low_item_index
	end repeat
	return the sorted_list
end simpleSort

-------------------------------------------------------------------------------------------------------------------------------------------------
-- Kategorie Name aus der ID auslesen
-------------------------------------------------------------------------------------------------------------------------------------------------
to getCatByID(id)
	return (my (catDictionary's valueForKey:id)) as text
end getCatByID

-------------------------------------------------------------------------------------------------------------------------------------------------
-- Titel von Devon Think in Namen und Zettel ID aufsplitten 
-------------------------------------------------------------------------------------------------------------------------------------------------
to getNameComponents(title)
	-- save delimiters to restore old settings
	set oldDelimiters to AppleScript's text item delimiters
	
	-- set delimiters to delimiter to be used
	set AppleScript's text item delimiters to " | "
	
	-- create the array
	set theArray to every text item of title
	
	-- restore the old setting
	set AppleScript's text item delimiters to oldDelimiters
	
	-- return the result
	return theArray
end getNameComponents
