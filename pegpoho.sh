#!/bin/bash

DETRI="`date -u +%Y%m%d`"
awk --assign awk_detri="$DETRI" '
	BEGIN {
	print "\057\057 de\047e ve vimcu lo javaskript zei pagbu la\047o zoi https://raw.githubusercontent.com/lojban/ilmentufa/gh-pages/camxes.js.peg zoi de\047i li " awk_detri " tede\047i UTC i lo peg zei velski cu claxu lo zoi zei stura fa\047o"
	}
	/^$/ { next }
	/^ *\057/ { next }
	/^\173/,/^\175/ { next }
	{
	sub(/^zoi_open.*/, "zoi_open = lojban_word");
	sub(/^zoi_word.*/, "zoi_word = (non_space+) spaces ");
	sub(/^zoi_close.*/, "zoi_close = any_word");
	sub(/=/, "<-");
	sub(/expr:/, "");
	sub(/ +\173.*$/, "");
	sub(/pre:/, "");
	sub(/post:/, "");
	print }
	' camxes.js.peg > "camxes-"$DETRI".peg"


