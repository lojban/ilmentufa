/*
 * CAMXES.JS POSTPROCESSOR
 * Created by Ilmen (ilmen.pokebip <at> gmail.com) on 2013-08-16.
 * Last change: 2016-09-02.
 * 
 * Entry point: camxes_postprocessing(input, mode, ptproc, postproc_id)
 * Arguments:
 *    -- input:  [string] camxes' stringified output
 *            OR [array] camxes' parse tree output
 *    -- mode:  [number] output mode flag
 *         If mode > 7, displaying spaces is enabled and mode's value is
 *         truncated so mode <= 7. Then, depending on the value of mode,
 *         the following options are set:
 *         0 = Raw output (no change)
 *         1 = Condensed
 *         2 = Prettified
 *         3 = Prettified + selma'o
 *         4 = Prettified + selma'o + bridi parts
 *         5 = Prettified - famyma'o
 *         6 = Prettified - famyma'o + selma'o
 *         7 = Prettified - famyma'o + selma'o + bridi parts
 *    -- ptproc:  OPTIONAL [function] parse tree processor
 *    -- postproc_id:  OPTIONAL [number] selecter postprocessors
 *         0 = New postprocessor
 *         1 = Old postprocessor
 *         2 = Both
 *         
 * Return value:
 *       [string] postprocessed version of camxes' output
 */

/*
 * Function list:
 *   -- camxes_postprocessing(text, mode, ptproc, postproc_id)
 *   -- new_postprocessor(input, no_morpho, with_selmaho, with_terminator)
 *   -- prune_unwanted_nodes(tree, is_wanted_node)
 *   -- prefix_wordclass(tree, replacements)
 *   -- remove_morphology(pt)
 *   -- is_target_node(n)
 *   -- join_expr(n)
 *   -- among(v, s)
 *   -- is_selmaho(v)
 *   -- old_postprocessor(text, with_selmaho, without_terminator, with_nodes_labels)
 *   -- erase_elided_terminators(str)
 *   -- delete_superfluous_brackets(str)
 *   -- prettify_brackets(str)
 *   -- str_print_uint(val, charset)
 *   -- str_replace(str, pos, len, sub)
 *   -- chr_check(chr, list)
 *   -- is_string(v)
 *   -- is_array(v)
 *   -- dbg_bracket_count(str)
 */


if (typeof alert !== 'function')
    alert = console.log; // For Node.js

/*
 * Version of transition between the older string processing and the newer
 * parse tree processing.
 * The below function's content is temporary and allows choosing which of the
 * two postprocessor (the older, the newer or even both) to use.
 * If the new postprocessor proves satisfactory, the older postprocessor's code
 * will be entirely removed.
 */
function camxes_postprocessing(input, mode, postproc_id) {
    var with_spaces = mode & 8;
    var without_morphology = mode & 16;
    mode = mode % 8;
    var with_selmaho = (mode != 2 && mode != 5);
    var with_nodes_labels = (mode == 4 || mode == 7);
    var without_terminator = (mode >= 5);
    var output_1, output_2;
    // Default: older postprocessor.
    if (typeof postproc_id !== 'number') postproc_id = 1;
    if (is_array(input)) {
        if (without_morphology)
            input = remove_morphology(input); // Deleting morphology nodes.
        if (postproc_id > 0 || mode <= 1)
            output_1 = JSON.stringify(input, undefined, mode == 0 ? 2 : 0);
        else output_1 = "";
        if (mode <= 1 || postproc_id == 1) {
            output_2 = "";
        } else {
            input = new_postprocessor(input, without_morphology, with_spaces,
                                      with_selmaho, !without_terminator);
            output_2 = JSON.stringify(input);
            output_2 = output_2.replace(/\"/gm, "");
            output_2 = output_2.replace(/,/gm, " ");
        }
    } else if (is_string(input)) {
        if (input.charAt(0) != '[') return input;
        if (postproc_id == 0)
            return "/!\\ The new postprocessor doesn't support string input.";
        output_1 = input;
        output_2 = "";
        if (mode >= 1) {
            output_1 = output_1.replace(/ +/gm, "");
            output_1 = output_1.replace(/[\r\n]/gm, "");
        }
    } else return "ERROR: Wrong input type.";
    if (output_1 !== "" && mode >= 2)
        output_1 = old_postprocessor(output_1, with_selmaho, without_terminator,
                                     with_nodes_labels);
    var output;
    if (postproc_id == 2 && mode >= 2)
        output = "\n\n=== New postprocessor ===\n\n" + output_2
               + "\n\n=== Old postprocessor ===\n\n" + output_1;
    else output = output_2 + output_1;
    // Replacing "spaces" with "_":
    output = output.replace(/([ \[\],])(initial_)?spaces(?=[ \[\],])/gm, "$1_");
    // Bracket prettification:
    output = prettify_brackets(output);
	return output;
}


// ====== NEW POSTPROCESSOR ====== //

function new_postprocessor(input, no_morpho, with_spaces, with_selmaho, with_terminator) {
    var filter;
    var wanted_nodes = with_spaces ? ["initial_spaces", "dot_star"] : ["dot_star"];
    if (no_morpho) {
        filter = function (v,b) { return (with_selmaho ?
                  among(v, wanted_nodes.concat(["cmevla", "gismu", "lujvo", "fuhivla"]))
                  || (is_selmaho(v) && (with_terminator || !b))
                  : among(v, wanted_nodes)
                  || (is_selmaho(v) && b && with_terminator)); };
    } else {
        filter = function (v,b) { return among(v, wanted_nodes) ||
                  (with_selmaho ? (is_selmaho(v) && (with_terminator || !b))
                  : is_selmaho(v) && b && with_terminator); };
    }
    input = prune_unwanted_nodes(input, filter);
    if (with_selmaho && no_morpho) {
        var replacements = [["cmene", "C"], ["cmevla", "C"], ["gismu", "G"],
                            ["lujvo", "L"], ["fuhivla", "Z"]];
        input = prefix_wordclass(input, replacements);
        if (is_string(input)) input = [input];
    }
    return input;
}

function prune_unwanted_nodes(tree, is_wanted_node) {
    if (is_string(tree)) return tree;
    if (!is_array(tree)) throw "ERR";
    if (tree.length == 0) return null;
    var no_label = is_array(tree[0]);
    var k = 0;
    var i = no_label ? 0 : 1;
    while (i < tree.length) {
        tree[i] = prune_unwanted_nodes(tree[i], is_wanted_node);
        if (tree[i]) {
            k++;
            i++;
        } else tree.splice(i, 1);
    }
    if (!no_label) {
        if (!is_wanted_node(tree[0], tree.length == 1)) tree.splice(0, 1);
        else k++;
    }
    if (k == 1) return tree[0];
    else return (k > 0) ? tree : null;
}

function prefix_wordclass(tree, replacements) {
    if (tree.length == 2 && is_string(tree[0]) && is_string(tree[1])) {
        var i = 0;
        while (i < replacements.length) {
            if (tree[0] == replacements[i][0]) {
                tree[0] = replacements[i][1];
                break;
            }
            i++;
        }
        return tree[0] + ':' + tree[1];
    }
    var i = 0;
    while (i < tree.length) {
        if (is_array(tree[i]))
            tree[i] = prefix_wordclass(tree[i], replacements);
        i++;
    }
    return tree;
}

// ====== MORPHOLOGY REMOVAL ====== //

/*
 * remove_morphology(parse_tree)
 * 
 * This function takes a parse tree, and joins the expressions of the following
 * nodes:
 * "cmevla", "gismu_2", "lujvo", "fuhivla", "spaces"
 * as well as any selmaho node (e.g. "KOhA").
 * 
 * (This is essentially a copy of process_parse_tree.js.)
 */
 
function remove_morphology(pt) {
    if (pt.length < 1) return [];
    var i;
    /* Sometimes nodes have no label and have instead an array as their first
       element. */
    if (is_array(pt[0])) i = 0;
    else { // The first element is a label (node name).
        // Let's check if this node is a candidate for our pruning.
        if (is_target_node(pt)) {
            /* We join recursively all the terminal elements (letters) in this
             * node and its child nodes, and put the resulting string in the #1
             * slot of the array; afterwards we delete all the remaining elements
             * (their terminal values have been concatenated into pt[1]). */
            pt[1] = join_expr(pt);
            // If pt[1] contains an empty string, let's delete it as well:
            pt.splice((pt[1] == "") ? 1 : 2);
            return pt;
        }
        i = 1;
    }
    /* If we've reached here, then this node is not a target for pruning, so let's
       do recursion into its child nodes. */
    while (i < pt.length) {
        remove_morphology(pt[i]);
        i++;
    }
    return pt;
}

/* Checks whether the argument node is a target for pruning. */
function is_target_node(n) {
    return (among(n[0], ["cmevla", "gismu", "lujvo", "fuhivla", "initial_spaces"])
            || is_selmaho(n[0]));
}

/* This function returns the string resulting from the recursive concatenation of
 * all the leaf elements of the parse tree argument (except node names). */
function join_expr(n) {
    if (n.length < 1) return "";
    var s = "";
    var i = is_array(n[0]) ? 0 : 1;
    while (i < n.length) {
        s += is_string(n[i]) ? n[i] : join_expr(n[i]);
        i++;
    }
    return s;
}

function among(v, s) {
    var i = 0;
    while (i < s.length) if (s[i++] == v) return true;
    return false;
}

function is_selmaho(v) {
    if (!is_string(v)) return false;
    return (0 == v.search(/^[IUBCDFGJKLMNPRSTVXZ]?([AEIOUY]|(AI|EI|OI|AU))(h([AEIOUY]|(AI|EI|OI|AU)))*$/g));
}

// ====== OLD POSTPROCESSOR ====== //

function old_postprocessor(text, with_selmaho, without_terminator, with_nodes_labels) {
	/** Prettified forms **/
	text = text.replace(/\"/gm, ""); // Delete every quote marks
	/* Save selmaho and brivla types */
	text = text.replace(/(gismu|lujvo|fuhivla|cmene|cmevla),([A-Za-z']+)/g,
                        "$1:$2");
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
    // Removing stuff like "a:a" that may remain when morphology is kept:
    text = text.replace(/[ \[\]][a-z]:([a-z'])[ \[\]]/gm, "$1");
	text = text.replace(/ +/gm, " ");
	text = text.replace(/^ +/, "");
	return text;
}

function erase_elided_terminators(str) {
	var i, j;
	var parachute = 400;
	str = str.replace(/([a-z']+)`/g, function (v) { return v.toUpperCase(); });
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
		    + "\nstr from i:\n" + str.slice(i).join(""));
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
		    + "\nstr from i:\n" + str.slice(i).join(""));
	return str.join("");
}


/* ================== */
/* ===  Routines  === */
/* ================== */

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

function is_string(v) {
    return $.type(v) === "string";
}

function is_array(v) {
    return $.type(v) === "array";
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

if (typeof module !== 'undefined')
    module.exports.postprocessing = camxes_postprocessing;

