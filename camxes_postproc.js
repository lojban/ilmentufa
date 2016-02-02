/*
 * CAMXES.JS POSTPROCESSOR
 * Created by Ilmen (ilmen.pokebip <at> gmail.com) on 2013-08-16.
 * Last change: 2014-01-26.
 * 
 * Entry point: camxes_postprocessing(text, mode)
 * Arguments:
 *    -- text:  [string] camxes' raw output
 *    -- mode:  [uint] output mode flag
 *         0 = Raw output (no change)
 *         1 = Condensed
 *         2 = Prettified
 *         3 = Prettified + selma'o
 *         4 = Prettified + selma'o + bridi parts
 *         5 = Prettified - famyma'o
 *         6 = Prettified - famyma'o + selma'o
 *         7 = Prettified - famyma'o + selma'o + bridi parts
 * Return value:
 *       [string] postprocessed version of camxes' output
 */

/*
 * Function list:
 *   -- camxes_postprocessing(text, mode)
 *   -- erase_elided_terminators(str)
 *   -- delete_superfluous_brackets(str)
 *   -- prettify_brackets(str)
 *   -- is_string(v)
 *   -- str_print_uint(val, charset)
 *   -- str_replace(str, pos, len, sub)
 *   -- chr_check(chr, list)
 *   -- dbg_bracket_count(str)
 */

alert = console.log;

function camxes_postprocessing(text, mode) {
	if (!is_string(text)) return "ERROR: Wrong input type.";
	if (mode == 0) return text;
	if (text.charAt(0) != '[') return text;
	/** Condensation **/
	text = text.replace(/ +/gm, "");
	text = text.replace(/\r\n|\n|\r/gm, "");
	if (mode == 1) return text;
	/** Prettified forms **/
	var with_selmaho = (mode >= 3 && mode != 5);
	var with_nodes_labels = (mode == 4 || mode == 7);
	var without_terminator = (mode >= 5);
	text = text.replace(/\"/gm, ""); // Delete every quote marks
	/* Save selmaho and brivla types */
	text = text.replace(/(gismu|lujvo|fuhivla|cmene|cmevla),([A-Za-z']+)/g, "$1:$2");
	text = text.replace(/([A-Za-z_]+),([A-Za-z']+)/g, "$1:$2");
	/* Save a few nodes from deletion (optional) */
	if (with_nodes_labels) {
		text = text.replace(/prenex,/g, "PN");
		text = text.replace(/sentence,\[\[terms,/g, "sentence,[BH[terms,");
		text = text.replace(/bridi_tail_2,/g, "BT");
	}
	/* Delete every remaining node names and commas */
	text = text.replace(/([A-Za-z0-9_]+,)+\[/g, "[");
	text = text.replace(/,/gm, "");
	/* If requested, erase every elided terminators from the output */
	if (without_terminator)
		text = erase_elided_terminators(text);
	/* Cleanup */
	text = delete_superfluous_brackets(text);
	text = text.replace(/\[ +/g, "[");
	text = text.replace(/ +\]/g, "]");
	text = text.replace(/([A-Z] )\[/g, "$1[");
	/* Abbreviations */
	text = text.replace(/(cmene|cmevla):/g, "C:");
	text = text.replace(/gismu:/g, "G:");
	text = text.replace(/lujvo:/g, "L:");
	text = text.replace(/fuhivla/g, "F");
	text = text.replace(/BRIVLA/g, "Z");
	/* Making things easier to read */
	if (!with_selmaho) text = text.replace(/[A-Za-z_]+:/g, "");
	text = text.replace(/\]\[/g, "] [");
	text = prettify_brackets(text);
	text = text.replace(/ +/gm, " ");
	text = text.replace(/^ +/, "");
	return text;
}

function erase_elided_terminators(str) {
	var i, j;
	var parachute = 400;
	str = str.replace(/([a-z']+)`/g, function(v) { return v.toUpperCase(); });
	str = str.replace(/([A-Z]+)'([A-Z]+)`/g,"$1h$2`");
	str = str.replace(/([A-Z]+)H([A-Z]+)`/g,"$1h$2`");
	str = str.replace(/([A-Zh]+)`/g,"$1");
	do {
		i = str.search(/\[[A-Zh`]+\]/);
		if (i < 0) break;
		j = i + str.substr(i).indexOf("]");
		while (i-- > 0 && ++j < str.length)
			if (str[i] != '[' || str[j] != ']') break;
		i++;
		j--;
		//alert("DEL "+str.substr(i,j-i+1));
		str = str_replace(str, i, j-i+1, "");
	} while (parachute--);
	return str;
}

function delete_superfluous_brackets(string) {
	/* RATIONALE:
	 * Here is done the dirty work of removing all those superfluous brackets
	 * left after our earlier intense session of regexp replacements.
	 * Admittedly not quite easy to read, but it does the job. :)
	 */
	str = string.split("");
	var i = 0;
	var parachute = 4000; // Against evil infinite loops.
	if (str.length < 1) {
		alert("ERROR: (str.length < 1) @delete_superfluous_brackets");
		return str;
	}
	// We reach the first word
	while (str[i] == "[") {
		if (i >= str.length) return; // No word found.
		i++;
	}
	/**
		### FIRST CLEANUP: BRACKETS SURROUNDING SINGLE WORD ###
	**/
	do {
		/** erase_surrounding_brackets **/
		var j = i;
		while (str[i].search(/[A-Za-z'_:~]/) == 0 && i < str.length) i++;
		while (str[i] == ']') {
			if (j <= 0) {
				alert("ERROR: right bracket found without left counterpart.");
				break;
			}
			j--;
			while (str[j] == ' ') j--;
			if (str[j] == '[') {
				str[j] = ' ';
				str[i++] = ' ';
			} else break;
		}
		/** reach_next_word **/
		while (str[i] == '[' || str[i] == ']' || str[i] == ' ' && i < str.length)
			i++;
	} while (i < str.length && --parachute > 0);
	if (parachute <= 0)
		alert("@delete_superfluous_brackets #1: INFINITE LOOP\ni = " + i
		    + "\nstr from i:\n" + str.slice(i));
	/**
		### SECOND CLEANUP: BRACKETS SURROUNDING GROUPS OF WORDS ETC. ###
	**/
	i = 0;
	parachute = 4000;
	while (i < str.length && parachute-- > 0) {
		var so, eo, j;
		// FIRST STEP: reaching the next '['.
		while (i < str.length && str[i] != '[') i++;
		so = i;
		while (i < str.length && str[i] == '[') i++;
		eo = i;
		if (i >= str.length) break;
		if (i - so < 2) continue;
		j = i;
		i -= 2;
		do {
			var floor;
			// Now we'll reach the ']' closing the aformentioned '['.
			floor = 1;
			while (j < str.length && floor > 0) {
				if (str[j] == '[') floor++;
				else if (str[j] == ']') floor--;
				j++;
			}
			// We now erase superfluous brackets
			while (str[j] == ']' && i >= so) {
				str[i--] = ' ';
				str[j++] = ' ';
			}
		} while (i >= so && j < str.length && parachute-- > 0);
		i = eo;
	}
	if (parachute <= 0)
		alert("@delete_superfluous_brackets #2: INFINITE LOOP\ni = " + i
		    + "\nstr from i:\n" + str.slice(i));
	return str.join("");
}

function prettify_brackets(str) {
	var open_brackets = ["(", "[", "{", "<"];
	var close_brackets = [")", "]", "}", ">"];
	var brackets_number = 4;
//	var numset = ['0','1','2','3','4','5','6','7','8','9'];
	var numset = ['\u2070','\u00b9','\u00b2','\u00b3','\u2074',
	              '\u2075','\u2076','\u2077','\u2078','\u2079'];
	var i = 0;
	var floor = 0;
	while (i < str.length) {
		if (str[i] == '[') {
			var n = floor % brackets_number;
			var num = (floor && !n) ?
				str_print_uint(floor / brackets_number, numset) : "";
			str = str_replace(str, i, 1, open_brackets[n] + num);
			floor++;
		} else if (str[i] == ']') {
			floor--;
			var n = floor % brackets_number;
			var num = (floor && !n) ?
				str_print_uint(floor / brackets_number, numset) : "";
			str = str_replace(str, i, 1, num + close_brackets[n]);
		}
		i++;
	}
	return str;
}


/* ================== */
/* ===  Routines  === */
/* ================== */

function is_string(v) {
    return typeof v.valueOf() === 'string';
}

function str_print_uint(val, charset) {
	// 'charset' must be a character array.
	var radix = charset.length;
	var str = "";
	val -= val % 1;  // No float allowed
	while (val >= 1) {
		str = charset[val % radix] + str;
		val /= radix;
		val -= val % 1;
	}
	return str;
}

function str_replace(str, pos, len, sub) {
	if (pos < str.length) {
		if (pos + len >= str.length) len -= pos + len - str.length;
		return str.substring(0, pos) + sub + str.substring(pos + len);
	} else return str;
}

function chr_check(chr, list) {
	var i = 0;
	if (!is_string(list)) return false;
	do if (chr == list[i]) return true; while (i++ < list.length);
	return false;
}

function dbg_bracket_count(str) {
	var i = 0;
	var x = 0;
	var y = 0;
	while (i < str.length) {
		if (str[i] == '[') x++;
		else if (str[i] == ']') y++;
		i++;
	}
	alert("Bracket count: open = " + x + ", close = " + y);
}

module.exports.postprocessing = camxes_postprocessing;

