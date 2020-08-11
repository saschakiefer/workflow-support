tell application "Microsoft Outlook"
	set windwoCollection to windows whose index is 1
	
	if (count of windwoCollection) is not 0 then
		set olObject to object of item 1 of windwoCollection
		if class of olObject is calendar event then
			set thisEvent to olObject
			
			-- Teilnehmer
			set atds to attendees of thisEvent
			set atdsString to ""
			
			repeat with i from 1 to number of items in atds
				set aAtd to item i of atds
				set email to email address of aAtd
				set dName to name of email
				set add to address of email
				set atdsString to atdsString & "" & "#[[" & dName & "]], "
			end repeat
			
			-- delete the trailing ,
			set atdsString to text -3 through 1 of atdsString
			
			set md to "__" & my date_format(start time of thisEvent) & "__ - " & subject of thisEvent & " " & atdsString & " #[[Meeting Minutes]]"
		else
			display notification "Please run the script from within a calender event"
			delay 1
		end if
	else
		display notification "Please open a calender event first"
		delay 1
	end if
end tell


------------------------------
-- HANDLERS
------------------------------
to date_format(old_date) -- Old_date is text, not a date.
	-- set input to old_date
	-- set {year:y, month:m, day:d} to old_date
	-- tell (y * 10000 + m * 100 + d) as string to text 1 thru 4 & "-" & text 5 thru 6 & "-" & text 7 thru 8
	return characters 1 thru 5 of (time string of old_date) as string
end date_format