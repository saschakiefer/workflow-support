set the_text to "{{[[table]]}}" & return
set today to current date
set time of today to 0
set tomorrow to (today) + 86400 -- seconds
--
-- Here are the calendars I want to check. Yours will be different. Change the following line to match the names of your calendars.
-- If you are going to check ALL of your calendars this script could be simplified. Send me an email and IÕll help you.
-- Christian Boyce, macman@christianboyce.com
set the_calendar_list to {"Kalender", "Privat"}
--
tell application "Calendar"
	-- First we need to tell iCal which calendars are going to be checked. We match the names in "the_calendar_list" to the names of the actual calendars in iCal. The ones that match are added to our "the_calendars" list.
	--
	set the_calendars to {}
	set every_calendar to every calendar
	-- Now we have a list of calendars to check.
	repeat with an_item in the_calendar_list
		try
			set end of the_calendars to (first calendar whose name is an_item)
		end try
	end repeat
	-- Now we check, on a calendar by calendar basis, for appointments on the current day.
	repeat with a_calendar in the_calendars
		tell a_calendar
			set the_events to (every event whose start date > today and start date < tomorrow)
			--
			-- Here we sort the list of events for the day. If we donÕt do this they wonÕt be chronological. iCal sorts them in creation order unless we run this little "sortEvents" routine.
			--
			set the_events to my sortEvents(the_events)
			-- Now we have a sorted list. LetÕs create a string for the Mac to speak. Loop through the events and make that string.
			repeat with an_event in the_events
				set x to properties of an_event
				set the_summary to summary of an_event
				set the_start_date to start date of an_event
				set the_end_date to end date of an_event
				set the_start_time to characters 1 thru 5 of time string of the_start_date
				set the_end_time to characters 1 thru 5 of time string of the_end_date
				--
				-- set the_text to the_text & return & "Appointment number" & i & "." & return & the_start_time & " to " & the_end_time & "." & return & summary of an_event & return & return
				set the_text to the_text & tab & the_start_time & "-" & the_end_time & return & tab & tab & the_summary & return
			end repeat
		end tell
	end repeat
	--	
	quit
end tell

set md to the_text

--
-- This is the sorting subroutine. I found it on MacScripter.net.
on findLeastItem(lst)
	tell application "Calendar"
		set theLeast to start date of item 1 of lst
		set theIndex to 1
		set iterater to 1
		repeat with i in lst
			if start date of i ² theLeast then
				set theLeast to start date of i
				set theIndex to iterater
			end if
			set iterater to iterater + 1
		end repeat
		
		return theIndex
	end tell
end findLeastItem

on removeItemAtIndex(lst, theIndex)
	set newList to {}
	set theLength to length of lst
	if theLength = 1 then
		set newList to {}
	else if theLength = theIndex then
		set newList to items 1 thru (theLength - 1) of lst
	else if theIndex = 1 then
		set newList to items 2 thru theLength of lst
	else
		set newList to items 1 thru (theIndex - 1) of lst & items (theIndex + 1) thru (theLength) of lst
	end if
	return newList
end removeItemAtIndex

on sortEvents(myList)
	set myNewList to {}
	repeat until length of myList = 0
		set leastIndex to findLeastItem(myList)
		set end of myNewList to item leastIndex of myList
		set myList to removeItemAtIndex(myList, leastIndex)
	end repeat
	return myNewList
end sortEvents