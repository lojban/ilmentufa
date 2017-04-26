/*
 * CAMXES.JS POSTPROCESSOR
 * 
 * Entry point: camxes_postprocessing(input, mode)
 * 
 * Arguments:
 *    • input: [array]  Camxes' parse tree output.
 *          OR [string] JSON stringified parse tree.
 *    • mode:  [string] Parse tree processing option list (each option is
 *                      symbolized by a letter). See below for details.
 *          OR [number] (Deprecated) Older options representation encoded as
 *                      bit flags on a number.
 * 
 * Return value:
 *       [string] postprocessed version of camxes' output
 * 
 * Details for the `mode´ arguent's values:
 * 
 * The mode argument can be any letter string, each letter stands for a specific
 * option. Here is the list of possible letters and their associated meaning:
 *    'M' -> Keep morphology
 *    'S' -> Show spaces
 *    'T' -> Show terminators
 *    'C' -> Show word classes (selmaho)
 *    'R' -> Raw output, do not trim the parse tree. If this option isn't set,
 *           all the nodes (with the exception of those saved if the 'N' option
 *           is set) are pruned from the tree.
 *    'N' -> Show main node labels
 */

/*
 * Function list:
 *   -- camxes_postprocessing(text, mode)
 *   -- newer_postprocessor(parse_tree, with_morphology, with_spaces,
 *                          with_terminators, with_trimming, with_selmaho,
 *                          with_nodes_labels)
 *   -- process_parse_tree(parse_tree, value_substitution_map,
 *                         name_substitution_map, node_action_for,
 *                         must_prefix_leaf_labels)
 *   -- among(v, s)
 *   -- is_selmaho(v)
 *   -- prettify_brackets(str)
 *   -- str_print_uint(val, charset)
 *   -- str_replace(str, pos, len, sub)
 *   -- is_string(v)
 *   -- is_array(v)
 *   -- is_number(v)
 */


if (typeof alert !== 'function')
    alert = console.log; // For Node.js

/*
 * Main function.
 */
function camxes_postprocessing(input, mode) {
    /* Checking the input */
    if (is_string(input)) input = JSON.parse(input);
    if (!is_array(input))
        return "Postprocessor error: invalid input type for the first argument. "
             + "It should be either an array or a JSON stringified array, but "
             + "the argument given is of type '" + typeof input + "'.";
    /* Reading the options */
    if (is_number(mode)) mode = mode_from_number_code(mode);
    if (is_string(mode)) {
        var with_spaces         = among('S', mode);
        var with_morphology     = among('M', mode);
        var with_terminators    = among('T', mode);
        var with_trimming       = !among('R', mode);
        var with_selmaho        = among('C', mode);
        var with_nodes_labels   = among('N', mode);
        var with_json_format    = among('J', mode);
        var without_leaf_prefix = among('!', mode);
    } else throw "camxes_postprocessing(): Invalid mode argument type!";
    /* Calling the postprocessor */
    var output = newer_postprocessor(input, with_morphology, with_spaces,
                                     with_terminators, with_trimming,
                                     with_selmaho, with_nodes_labels,
                                     without_leaf_prefix);
    if (output === null) output = [];
    /* Converting the parse tree into JSON format */
    output = JSON.stringify(output);
    if (with_json_format) return output;
    /* Getting rid of ⟨"⟩ and ⟨,⟩ characters */
    output = output.replace(/\"/gm, "");
    if (with_selmaho)
        output = output.replace(/\[([a-zA-Z0-9_-]+),\[/gm, "[$1: [");
    output = output.replace(/,/gm, " ");
    /* Bracket prettification */
	return prettify_brackets(output);
}

/* Function for translating the legacy option encoding to the new format. */
/* For backward compatibility. */
function mode_from_number_code(legacy_mode) {
    var mode = "";
    if (legacy_mode & 8) mode += 'S';
    if (legacy_mode & 16) mode += 'M';
    legacy_mode = legacy_mode % 8;
    if (legacy_mode == 0) mode += 'J';
    if (legacy_mode <= 1) mode += 'R';
    if (legacy_mode > 2 && legacy_mode != 5) mode += 'C';
    if (legacy_mode == 4 || legacy_mode == 7) mode += 'N';
    if (legacy_mode < 5) mode += 'T';
    return mode;
}

// ========================================================================== //

/*
 * This function adapts the options passed as arguments into a format adapted
 * to the more generalized 'process_parse_tree' function, and then calls this
 * latter.
 */
function newer_postprocessor(
    parse_tree,
    with_morphology,
    with_spaces,
    with_terminators,
    with_trimming,
    with_selmaho,
    with_nodes_labels,
    without_leaf_prefix
) {
    if (!is_array(parse_tree)) return null;
    /* Building a map of node names to node value replacements */
    if (with_spaces)
         var value_substitution_map = {"spaces": "_", "initial_spaces": "_"};
    else var value_substitution_map = {};
    /* Building a map of node names to name replacements */
    var name_substitution_map = {
        "cmene": "C", "cmevla": "C", "gismu": "G", "lujvo": "L",
        "fuhivla": "Z", "prenex": "PRENEX", "sentence": "BRIDI",
        "selbri": "SELBRI", "sumti": "SUMTI"
    };
    if (!with_trimming) name_substitution_map = {};
    var special_selmaho = ["cmevla", "gismu", "lujvo", "fuhivla", "ga_clause",
                           "gu_clause"];
    /** Building a node_action_for() function from the selected options **/
    if (with_morphology)
         var is_flattening_target = function (tree) { return false; };
    else var is_flattening_target = function (tree) {
        var targets = special_selmaho;
        return (among(tree[0], targets) || is_selmaho(tree[0]));
    };
    var is_branch_removal_target = function (tree) {
        if (!with_spaces && among(tree[0], ["spaces", "initial_spaces"]))
            return true;
        return (!with_terminators && is_selmaho(tree[0]) && tree.length == 1);
    };
    var whitelist = [];
    if (with_selmaho)
        whitelist = whitelist.concat(special_selmaho);
    if (with_nodes_labels)
        whitelist = whitelist.concat(["prenex", "sentence", "selbri", "sumti"]);
    var is_node_trimming_target = function (tree) {
        if (!with_trimming) return false;
        if (with_terminators && is_selmaho(tree[0]) && tree.length == 1)
            return false;
        if (with_selmaho && is_selmaho(tree[0])) return false;
        return !among(tree[0], whitelist);
    };
    var node_action_for = function (node) {
        if (is_branch_removal_target(node)) return 'DEL';
        var ft = is_flattening_target(node);
        var tt = is_node_trimming_target(node);
        if (ft && tt) return "TRIMFLAT";
        if (ft)       return 'FLAT';
        if (tt)       return 'TRIM';
        if (with_trimming && node.length == 1) return 'UNBOX';
        return 'PASS';
    };
    /* Calling process_parse_tree() with the arguments we've built for it */
    return process_parse_tree(
        parse_tree, value_substitution_map, name_substitution_map,
        node_action_for,
        (with_nodes_labels || with_selmaho) && !without_leaf_prefix
    );
}

/*
 * Recursive function for editing a parse tree. Performs a broad range of
 * editions depending on the given arguments. Returns the edited parse tree.
 * 
 * • value_substitution_map [Map]:
 *     A map of node names to node value replacements. Used to override the
 *     content of specific leaf nodes.
 * • name_substitution_map [Map]:
 *     A map of node names to node name replacements. Used to rename specific
 *     nodes.
 * • node_action_for [Function: Array -> String]:
 *     A function for deriving the appropriate edition action for the argument
 *     parse tree node; returns an action name, whose possible values are:
 *     • 'DEL':  Triggers deletion of the current tree branch.
 *     • 'TRIM': Triggers pruning of the current node; the node name is erased
 *               and if it has only one child node, this child node replaces it.
 *     • 'FLAT': Triggers flattening of the current tree branch; all its
 *               terminal leaves values are concatenated and the concatenation
 *               results replaces the content of the branch.
 *     • 'TRIMFLAT': Same as 'FLAT' but also removes the current node.
 *     • 'UNBOX':    If the current node contains only one element, this element
 *                   replaces the current node.
 *     • 'PASS':     Does nothing.
 * • must_prefix_leaf_labels [Boolean]:
 *     If true, remaining node names get a colon appended to them, and if they
 *     contain a single leaf value, they get concatenated with their value, and
 *     the concatenation result would replace the node itself.
 *     For example, a terminal node ["UI","ui"] would become "UI:ui" (note that
 *     the brackets disappeared).
 */
function process_parse_tree(
    parse_tree,
    value_substitution_map,
    name_substitution_map,
    node_action_for,
    must_prefix_leaf_labels
) {
    if (parse_tree.length == 0) return null;
    var action = node_action_for(parse_tree);
    if (action == 'DEL') return null;  // Deleting the current branch.
    var has_name = is_string(parse_tree[0]);
    // Getting the value replacement for this node, if any.
    var substitution_value = (has_name) ? value_substitution_map[parse_tree[0]]
                                        : undefined;
    if (has_name) {
        if (action == 'TRIM') {
            /* If there's a value replacement for this node, we return it
               instead of the node's content. */
            if (typeof substitution_value !== 'undefined')
                return substitution_value;
            /* Otherwise the first step of a trim action is to remove the node
               name. */
            parse_tree.splice(0, 1);
            has_name = false;
        } else {
            /* No trimming, so let's see if the node name is in the renaming
               list. If so, let's rename it accordingly. */
            var v = name_substitution_map[parse_tree[0]];
            if (typeof v !== 'undefined') parse_tree[0] = v;
            /* If there's a value replacement for this node, it becomes the
               unique value for the node. */
            if (typeof substitution_value !== 'undefined')
                return [parse_tree[0], substitution_value];
        }
    }
    if (action == 'FLAT') {
        /* Flattening action. All the terminal nodes of the branch are
           concatenated, and the concatenation result replaces the branch's
           content, alongside the node name if any. If the concatenation
           result is empty, the branch becomes empty. */
        var r = join_expr(parse_tree);
        if (has_name && r != "") {
            if (must_prefix_leaf_labels) return parse_tree[0] + ':' + r;
            else return [parse_tree[0], r];
        } else if (has_name) return parse_tree[0];
        else return r;
    } else if (action == 'TRIMFLAT') return join_expr(parse_tree);
    /* Now we'll iterate over all the other elements of the current node. */
    var i = has_name ? 1 : 0;
    while (i < parse_tree.length) {
        if (is_array(parse_tree[i])) {
            /* Recursion */
            parse_tree[i] = process_parse_tree(
                parse_tree[i],
                value_substitution_map,
                name_substitution_map,
                node_action_for,
                must_prefix_leaf_labels
            );
        }
        /* The recursion call on the current element might have set it to null
           as a request for deletion. */
        if (parse_tree[i] === null)
            parse_tree.splice(i, 1);
        else i++;  // No deletion, so let's go to the next element.
    }
    /* Now we've finished iterating over the node elements. Let's proceed to
       the final steps. */
    /* If 'must_prefix_leaf_labels' is set and the node has a name and contains
       at least one other element, we append ':' to its name. */
//    if (has_name && parse_tree.length >= 2 && must_prefix_leaf_labels) {
//        parse_tree[0] += ':';
//    }
    /* If the node is empty, we return null as a signal for deletion. */
    if (i == 0) return null;
    /* If the node contains only one element and we want to trim the node,
       it gets replaced by its content. */ 
    else if (i == 1 && action != 'PASS') return parse_tree[0];
    /* If 'must_prefix_leaf_labels' is set and the node is a pair of string,
       we return the concatenation of both strings separated with a colon. */
    else if (must_prefix_leaf_labels && i == 2 && has_name
             && is_string(parse_tree[1])) {
        if (!parse_tree[1].includes(":"))
            return parse_tree[0] + ':' + parse_tree[1];
        else parse_tree[0] += ":";
    }
    return parse_tree;
}

// ========================================================================== //


/* This function returns the string resulting from the recursive concatenation
 * of all the leaf elements of the parse tree argument (except node names). */
// "join_leaves" or "flatten_tree" might be better names.
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

// ========================================================================== //

/*
 * Bracket prettification for textual rendering of parse trees.
 */
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
    return Object.prototype.toString.call(v) === '[object String]';
}

function is_array(v) {
    return Object.prototype.toString.call(v) === '[object Array]';
}

function is_number(v) {
    return Object.prototype.toString.call(v) === '[object Number]';
}

if (typeof module !== 'undefined') {
    module.exports.postprocessing = camxes_postprocessing;
    module.exports.postprocess = camxes_postprocessing;  // Alias
    module.exports.process_parse_tree = process_parse_tree;
    module.exports.prettify_brackets = prettify_brackets;
}

