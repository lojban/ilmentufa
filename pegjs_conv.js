/*
 * PEG <-> PEGJS CONVERTER
 * 
 * USAGE: $ nodejs pegjs_conv FILEPATH
 * Example: $ nodejs pegjs_conv camxes.js.peg
 * 
 * • If the input file name ends with ".js.peg" or ".pegjs", it is considered to
 * be of the PEGJS format (i.e. "=" instead of the standard PEG "<-" operator,
 * JS-style comments, and inline Javascript parser actions), and this program
 * will convert it to pure PEG and create a file with the same file name but
 * with a ".peg" ending.
 * • Otherwise (no ".js.peg" or ".pegjs" ending), the file will be considered to
 * be pure PEG, and will be converted to PEGJS; a file with the same name but
 * ending with ".pegjs" will be created.
 * 
 * This program does not touch to the content of comments within the PEG/PEGJS
 * file, except converting the comment marks ("#" for PEG, "//" and slash-dot
 * multiline comments for PEGJS).
 * 
 * Initial author: Ilmen (ilmen.pokebip@gmail.com)
 */

/* TODO: Let's just remove this and completely remove PEGJS predicates
   alltogether. */
//var EXTERN_PREDICATE_SYMBOL = "__EXTERN_PREDICATE_SYMBOL__";

var PEGJS_HEADER = "";


// === FUNCTIONS === //

function convert_file(src_path) {
	var fs = require("fs");
	var pathmod = require("path");
	var this_path = __dirname; // pathmod.dirname(argv[1]);
	PEGJS_HEADER = fs.readFileSync(
	  this_path + pathmod.sep + "pegjs_header.js").toString();
	var is_pegjs = 0 <= src_path.search(/\.(pegjs|js\.peg)$/);
	// ^ TODO: Maybe detect type based on content, mainly by searching for `=` and `<-` outside of comments.
	var dst_path = make_dstpath(src_path, is_pegjs);
	var peg;
	var df;
	try {
		//console.log("Opening " + src_path);
		peg = fs.readFileSync(src_path).toString();
		//console.log("Opening " + dst_path);
		df = fs.openSync(dst_path, 'w+');
	} catch(e) {
		console.log("Error: " + e);
	}
	if (peg.length > 0) {
		peg = is_pegjs ? pegjs_to_peg(peg) : peg_to_pegjs(peg);
	}
	fs.writeSync(df, peg, 0, peg.length);
	return dst_path;
}

function make_dstpath(srcpath, src_is_pegjs) {
	return srcpath.replace(/^(.*?)(\.[^\\\/]+)?$/g, "$1")
			 + (src_is_pegjs ? ".peg" : ".pegjs");
}

// =========================================================================== //

function check_whether_in_comment(s, i, in_comment) {
	if (s[i] == '\n') in_comment.sl = false;
	if (i + 1 < s.length) {
		if (s[i] == '*') {
			if (s[++i] == '/') in_comment.ml = false;
		} else if (s[i] == '/') {
			i++;
			if (s[i] == '*') in_comment.ml = true;
			else if (s[i] == '/') in_comment.sl = true;
		}
	}
	return in_comment;
}

function remove_pegjs_javascript(peg) {
	var i = 0;
	var j;
	var in_comment = {sl: false, ml: false};
	while (true) {
		if (i >= peg.length) return peg;
		in_comment = check_whether_in_comment(peg, i, in_comment);
		if (peg[i] == '{' && !(in_comment.sl || in_comment.ml)) {
			j = i;
			var n = 1;
			while (true) {
				j++;
				if (j >= peg.length) {
					j = -1;
					break;
				}
				in_comment = check_whether_in_comment(peg, j, in_comment);
				if (!(in_comment.sl || in_comment.ml)) {
					if (peg[j] == '{') n++;
					else if (peg[j] == '}') n--;
					if (n == 0) break;
				}
			}
			var replacement = "";
			if (i > 0) if (peg[i - 1] == '&' || peg[i - 1] == '!')
				//replacement = EXTERN_PREDICATE_SYMBOL;
				i--;
			if (j < 0) return peg.substring(0, i) + replacement;
			else {
				peg = peg.substring(0, i) + replacement + peg.substring(j + 1);
				i--;
			}
		}
		i++;
	}
	return peg;
}

/* Maybe to be generalized to "matching_bracket_offset(
   str, pos, brackets, is_rightwards)". */
function closing_bracket_offset(s, i, b) {
	i++;
	var n = 1;
	while (true) {
		if (i >= s.length) return -1;
		if (s[i] == b[0]) n++;
		else if (s[i] == b[1]) n--;
		if (n == 0) return i;
		i++;
	}
}

function pegjs_to_peg(peg) {
  // TODO: Here we should maybe replace every "\r\n" and "\r" with "\n".
  if (peg[peg.length - 1] != '\n') peg += '\n';
	peg = remove_pegjs_javascript(peg);
	var speg = split_peg_code_and_comments(peg, false);
	speg = move_comments_in_the_middle_of_a_rule(speg);
	var i = 1;
	while (i < speg.length) {
		speg[i] = process_pegjs_comment(speg[i]);
		i += 2;
	}
	i = 0;
	while (i < speg.length) {
		speg[i] = process_pegjs_code(speg[i]);
		i += 2;
	}
	peg = speg.join("");
	//return speg.join("") + "\n" + EXTERN_PREDICATE_SYMBOL + " = (.*)\n";
	peg = peg.replace(/ +$/gm, "");
	return peg;
}

function among(v, s) {
	var i = 0;
	while (i < s.length) if (s[i++] == v) return true;
	return false;
}

function peg_to_pegjs(peg) {
  // TODO: Here we should maybe replace every "\r\n" and "\r" with "\n".
  if (peg[peg.length - 1] != '\n') peg += '\n';
	peg = peg.replace(/^(\s*)(?!#\s*)([^#]*[^#\s])\s+#:\s*(.*)/gm, '$1$2\x1B$3');
	var speg = split_peg_code_and_comments(peg, true);
	var i = 1;
	while (i < speg.length) {
		speg[i] = process_peg_comment(speg[i]);
		i += 2;
	}
	i = 0;
	var has_pegjs_header_been_added = false;
	while (i < speg.length) {
		if (speg[i].length > 0) {
			speg[i] = process_peg_code(speg[i]);
			if (!has_pegjs_header_been_added) {
				if (speg[i].search(/[^\s]/gm) >= 0) {
					var j = speg[i].search(/[^\r\n]/gm);
					speg[i] = speg[i].substring(0, j) + PEGJS_HEADER
									+ speg[i].substring(j);
					has_pegjs_header_been_added = true;
				}
			}
		}
		if (speg.length - i >= 2) {
			/* process_peg_code() tends to delete whitespaces before comments
			   following PEG code on a same line, so we'll make sure to add
				 these whitespaces back for the sake of readability. */
			var l = speg[i].length;
			if (l > 0 && !among(speg[i][l - 1], "\r\n\t "))
			  speg[i] += " ";
		}
		i += 2;
	}
	peg = speg.join("");
	peg = peg.replace(/ +$/gm, "");
	return peg;
}

function move_comments_in_the_middle_of_a_rule(speg) {
	/* RATIONALE: Moving any multiline comment in the middle of a line of code to
		 the end thereof. */
	// Unimplemented.
	return speg;
}

function str_replace(str, pos, len, sub) {
	if (pos < str.length) {
		if (pos + len >= str.length) len -= pos + len - str.length;
		return str.substring(0, pos) + sub + str.substring(pos + len);
	} else return str;
}

function process_pegjs_comment(cs) {
	if (!(cs.length >= 2 && cs[0] == '/')) console.log("ERR [" + cs + "]");
	console.assert(cs.length >= 2 && cs[0] == '/');
	if (cs[1] == '*') {
		cs = "# " + cs;
		cs = cs.replace(/([\r\n])/g, "$1# ");
	} else {
		var i = cs.indexOf("//");
		if (i >= 0) cs = str_replace(cs, i, 2, "#");
	}
	return cs;
}

function process_peg_comment(cs) {
	console.assert(cs.length >= 1 && cs[0] == '#');
	var i = cs.indexOf("#");
	if (i >= 0) cs = str_replace(cs, i, 1, "//");
	return cs;
}

function process_pegjs_code(peg) {
	peg = peg.replace(/=/g, "<-");
	peg = peg.replace(/[a-zA-Z0-9_-]+:/g, ""); // Removing "expr:" and such.
	// Removing useless parentheses, as in "expr = (r1 r2)" or "((expr))".
	peg = remove_superfluous_parentheses(peg);
	peg = peg.replace(/ {2,}/g, " ");
	return peg;
}

function process_peg_code(peg) {
//  var re = new RegExp(" *[\\&\\!]" + EXTERN_PREDICATE_SYMBOL, "g");
//  peg = peg.replace(re, "");
	peg = peg.replace(/<-/g, "=");
	// peg = peg.replace(/((?<![a-zA-Z0-9_\-\x1B])(?!\x1B)[a-zA-Z0-9_]+)-(?=[a-zA-Z0-9_])/gm, "$1_");
	// ↑ Replacing `-` with `_` except within action tags.
	// ↑ For some reason that regexp doesn't work when there are more than one dash in a single label.
	peg = peg.replace(/ {2,}/g, " ");
	peg = peg_add_js_parser_actions(peg);
	peg = peg.replace(/\x1B/gm, ' //: ');
	peg = peg.replace(/(?<![\[])\-(?![\w\s\-]*[\]])/g, "_");
  /* ↑ Replacing dashes with underscores in identifiers, but not within regular
       expressions such as `[a-z]`. */
  /* ↑ TODO: Handle the unlikely cases of escaped bracket expressions, such as
       `\[a-z\]`. */
  /* ↑ WARNING: If the PEG grammar has two identifiers differing only on `-` VS `_`,
       the above replacement operation may break the grammar by merging the two 
       identifiers into a single one. */
	return peg;
}

function remove_superfluous_parentheses(s) {
	var p = 0;
	var i = null;
	var j, k;
	/* Removing superfluous nested parentheses, as in "((expr))". */
	while (true) {
		k = s.substring(p).search(/\(\s*\(.*\)\s*\)/gm);
		if (k < 0) break;
		i = k;
		j = i + 1;
		while (s[j] != '(') j++;
		k = closing_bracket_offset(s, j, "()");
		var post_k = s.substring(k + 1);
		if (post_k.search(/^\s*\)/gm) == 0)
			s = s.substring(0, j) + s.substring(j + 1, k) + post_k;
		else p = j;
	}
	/* Removing unnecessary parentheses enclosing the whole PEG expression. */
	while (true) {
		i = s.search(/<-\s*\(.*\)\s*$/gm);
		if (i < 0) break;
		while (s[i] != "(") i++;
		j = closing_bracket_offset(s, i, "()");
		console.assert(j > 0);
		if (s.substring(j).search(/\)\s*$/gm) == 0)
			s = s.substring(0, i) + s.substring(i + 1, j) + s.substring(j + 1);
	}
	return s;
}

function split_peg_code_and_comments(peg, is_peg_to_pegjs) {
	/* This function splits the PEG file into an alternating array of code and
	 * comments, so PEG code and comments can be processed separatly and safely
	 * (comments won't be affected by the PEG code processing, and vice versa).
	 */
	var lst = [];
	var re = (is_peg_to_pegjs) ? /(#.*?$)/gm : /(\/\*.*?\*\/)|(^.*?(\/\/.*$))/gm;
	var r;
	do {
		r = re.exec(peg);
		if (r === null) break;
		if (!is_peg_to_pegjs && r[0].substring(0, 2) != "/*") {
			// Double-slash comment
			var i = peg.indexOf("//", r.index);
			// 
			lst.push({index: i, end: r.index + r[0].length});
		} else {
			lst.push({index: r.index, end: r.index + r[0].length});
		}
	} while (true);
	/* Now we should have a list of associative arrays {index, end} showing the
	 * beginning and end boundaries indexes of all the comments within the file.
	 */
	if (lst.length < 1) return [peg];
	var sp = []; // splitted PEG chain, with code and comments alternated.
	sp.push(peg.substring(0, lst[0].index));
	// ↑ Initial potion of code before the first comment.
	sp.push(peg.substring(lst[0].index, lst[0].end));
	var i = 1;
	while (i < lst.length) {
		sp.push(peg.substring(lst[i-1].end, lst[i].index));
		sp.push(peg.substring(lst[i].index, lst[i].end));
		i++;
	}
	sp.push(peg.substring(lst[i-1].end));
	// ↑ Final portion of code after the last comment.
	return sp;
}


function rule_replace(peg, name, flag, replacement) {
	name = name.replace("~", "[a-zA-Z0-9_-]+");
	var s = "(?:^|[[\r\n][ \t]*)(" + name + ")[ \t]*=[ \t]*"
	      + "([^=\r\n{}]+([\r\n]+[^=\r\n{}]+)*)(?<=[^ ])" + flag
			  + "[ \t]*(?=[\r\n \t]*($|[\r\n][a-zA-Z0-9_-]+[ \t]*=))";
	var re = new RegExp(s, "g");
	return peg.replace(re, "\n" + replacement);
}


function peg_add_js_parser_actions(peg) {
	peg = peg.split("((non_space+))").join("(non_space+)");
	/* Parser actions for faking left recursion */
	peg = rule_replace(peg, "~_leaf", "",
	                   '$1 = expr:($2) {return ["$1", _join(expr)];}');
	peg = rule_replace(peg, "~", "\x1BLEAF",
	                   '$1 = expr:($2) {return ["$1", _join(expr)];}');
	peg = rule_replace(peg, "~", "\x1BLEAF: ?([0-9a-zA-Z_-]+)", '$1 = expr:($2)'
					                     + ' {return ["$1", _join("$3")];}');
	peg = rule_replace(peg, "~", "\x1BNLEAF",
	                   '$1 = expr:($2) {return ["$1", "$1"];}');
	peg = rule_replace(peg, "~", "\x1BLR",
	                   '$1 = expr:($2) {return _node_lg("$1", expr);}');
	peg = rule_replace(peg, "~", "\x1BLR2",
	                   '$1 = expr:($2) {return _node_lg2("$1", expr);}');
	/* STACK handling parser actions */
	peg = rule_replace(peg, "~", "\x1BPUSH",
										 '$1 = expr:($2) { _push(expr);'
										 + ' return _node("$1", expr); }');
	peg = rule_replace(peg, "~", "\x1BPEEK-DIFF",
										 '$1 = expr:($2) !{ return _peek_eq(expr); } '
										 + '{ return _node("$1", expr); }');
									// + '{ return ["$1", join_expr(expr)]; }');
	peg = rule_replace(peg, "~", "\x1BPOP-EQ",
										 '$1 = expr:($2) &{ return _peek_eq(expr); } '
										 + '{ if (_g_last_pred_val) _pop(); return _node("$1", expr); }');
	/* Parser action for elidible terminators */
	rep = ('$2_elidible = expr:($3) {return (expr === "" || !expr)'
				 + ' ? ["$2"] : _node_empty("$2_elidible", expr);}');
	peg = rule_replace(peg, "(~)_elidible", "", rep);
	peg = rule_replace(peg, "~", "\x1BE(L|LIDIBLE)?", rep);
	/* Others */
	peg = rule_replace(peg, "~", "\x1BJOIN",
										 '$1 = expr:($2) {return _join(expr);}');
	/* Default parser action */
	peg = peg.replace(/\x1B[^\r\n]*/g, "");
	peg = rule_replace(peg, "~", "(\x1B[^\r\n]*)?",
										 '$1 = expr:($2) {return _node("$1", expr);}');
	/* ↑ TODO: "(\x1B[^\r\n]*)?" doesn't seem to work, so I add to remove manually
	   the \x1B tags with the peg.replace() line above. Investigate why. */
	return peg;
}


// === EXECUTABLE CODE === //

if (typeof module !== 'undefined') {
    module.exports.convert_file = convert_file;
		module.exports.peg_to_pegjs = peg_to_pegjs;
		module.exports.pegjs_to_peg = pegjs_to_peg;
    if (typeof process !== 'undefined' && typeof require !== 'undefined'
		    && require.main === module) {
			if (process.argv.length < 3) {
				console.log("pegjs_conv.js: Not enough parameters.");
				return;
			}
      convert_file(process.argv[2]);
			process.exit();
    }
}

