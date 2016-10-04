
/*** MAIN FUNCTION ***/
function camxes_postprocessing(parse_tree) {
    /* Pruning morphology nodes. */
    parse_tree = remove_morphology(parse_tree);
    /* Removing every nodes except for those in the following whitelist. */
    var wanted_nodes = ["dot_star", "sentence", "selbri", "sumti", "prenex"];
    parse_tree = simplify_parse_tree(parse_tree, wanted_nodes);
    /* Building and retreiving the marking game string. */
    return marking_game_format(parse_tree);
}

function simplify_parse_tree(pt, nl) {
    if (is_string(pt)) return pt;
    if (!is_array(pt)) throw "ERROR";
    if (pt.length == 0) return null;
    var no_label = is_array(pt[0]);
    var i = no_label ? 0 : 1;
    while (i < pt.length) {
        if (is_array(pt[i])) {
            var v = simplify_parse_tree(pt[i], nl);
            pt = pt.slice(0, i).concat(v, pt.slice(i + 1));
            if (v == []) i--;
        }
        i++;
    }
    if (no_label) return pt;
    else if (among(pt[0], nl)) return [pt];
    else if (pt.length == 1) return [];
    else return pt.slice(1);
}

function marking_game_format(pt) {
    var s = ""  // Output string
    var i = 0;  // String index
    var b = ""; // Bracket pair
    while (i < pt.length) {
        if (is_string(pt[i])) {
            if (i == 0) {
                b = bracket_from_nodename(pt[i]);
            } else {
                if (s != "") s += " ";
                s += pt[i];
            }
        } else if (is_array(pt[i])) {
            if (s != "") s += " ";
            s += marking_game_format(pt[i]);
        }
        i++;
    }
    if (b.length >= 2)
        s = b[0] + s + b[1];
    return s;
}

function bracket_from_nodename(nodename) {
    switch (nodename) {
        case "prenex":   return "⟦⟧";
        case "sentence": return "{}";
        case "sumti":    return "[]";
        case "selbri":   return "<>";
        default:         return "";
    }
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
    return (among(n[0], ["cmevla", "gismu", "lujvo", "fuhivla", "initial_spaces", "ga_clause", "gu_clause"])
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

function is_string(v) {
    return $.type(v) === "string";
}

function is_array(v) {
    return $.type(v) === "array";
}

if (typeof module !== 'undefined')
    module.exports.postprocessing = camxes_postprocessing;

