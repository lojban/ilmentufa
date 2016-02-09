#!/bin/bash

DETRI="`date -u +%Y%m%d`"
awk --assign awk_detri="$DETRI" '
	BEGIN {
	print "\057\057 di\047e ve vimcu lo javaskript zei pagbu la\047o zoi https://raw.githubusercontent.com/lojban/ilmentufa/gh-pages/camxes.js.peg zoi de\047i li " awk_detri " tede\047i UTC fa\047o"
	}
	/^$/ { next }
	/^ *\057/ { next }
	/^\173/,/^\175/ { next }
	{
	sub(/=/, "<-");
	sub(/expr:/, "");
	sub(/ +\173.*$/, "");
	sub(/pre:/, "");
	sub(/post:/, "");
	print }
	' camxes.js.peg > "camxes-"$DETRI".peg"


