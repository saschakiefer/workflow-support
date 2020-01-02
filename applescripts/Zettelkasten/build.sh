#!/bin/bash
rm -f "Create  Zettelkasten.scpt"
osacompile -o "Create  Zettelkasten.scpt" CreateZettelkastenInTinderbox.applescript
rm -f ~/Library/Application\ Scripts/com.devon-technologies.think3/Menu/My\ Scripts/Create\ \ Zettelkasten.scpt
mv Create\ \ Zettelkasten.scpt ~/Library/Application\ Scripts/com.devon-technologies.think3/Menu/My\ Scripts/Create\ \ Zettelkasten.scpt


rm -rf ~/Library/Application\ Support/DEVONthink\ 3/Templates.noindex/Zettel.dtTemplate
cp -r ./Zettel.dtTemplate ~/Library/Application\ Support/DEVONthink\ 3/Templates.noindex/Zettel.dtTemplate