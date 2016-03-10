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

var EXTERN_PREDICATE_SYMBOL = "__EXTERN_PREDICATE_SYMBOL__";

main(process.argv, require("fs"));
process.exit();

function main(argv, fs) {
    if (argv.length < 3) {
        console.log("Not enough parameters.");
        return;
    }
    var srcpath = argv[2];
    var is_pegjs = 0 <= srcpath.search(/\.(pegjs)|(js.peg)$/);
    var dstpath = make_dstpath(srcpath, is_pegjs);
    var peg;
    var df;
    try {
        console.log("Opening " + srcpath);
        peg = fs.readFileSync(srcpath).toString();
        console.log("Opening " + dstpath);
        df = fs.openSync(dstpath, 'w+');
    } catch(e) {
        console.log("Error: " + e);
    }
    if (peg.length > 0) {
        // TODO: Here we should maybe replace every "\r\n" and "\r" with "\n".
        if (peg[peg.length - 1] != '\n') peg += '\n';
        peg = is_pegjs ? pegjs_to_peg(peg) : peg_to_pegjs(peg);
        peg = peg.replace(/ +$/gm, "");
    }
    fs.writeSync(df, peg, 0, peg.length);
    return;
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
                replacement = EXTERN_PREDICATE_SYMBOL;
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
    peg = remove_pegjs_javascript(peg);
    var speg = split_peg_code_and_comments(peg, false);
    speg = move_code_middle_comment(speg);
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
    return speg.join("") + "\n" + EXTERN_PREDICATE_SYMBOL + " = (.*)\n";
}

function peg_to_pegjs(peg) {
    var speg = split_peg_code_and_comments(peg, true);
    var i = 1;
    while (i < speg.length) {
        speg[i] = process_peg_comment(speg[i]);
        i += 2;
    }
    i = 0;
    var has_js_initializer_been_added = false;
    while (i < speg.length) {
        if (speg[i].length > 0) {
            speg[i] = process_peg_code(speg[i]);
            if (!has_js_initializer_been_added) {
                if (speg[i].search(/[^\s]/gm) >= 0) {
                    var j = speg[i].search(/[^\r\n]/gm);
                    speg[i] = speg[i].substring(0, j) + js_initializer()
                            + speg[i].substring(j);
                    has_js_initializer_been_added = true;
                }
            }
        }
        i += 2;
    }
    return speg.join("");
}

function move_code_middle_comment(speg) {
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
    // Remove useless parentheses, as in "exp = (r1 r2)".
    peg = remove_superfluous_parentheses(peg);
    return peg;
}

function process_peg_code(peg) {
    peg = peg.replace(/<-/g, "=");
    peg = peg_add_js_parser_action(peg);
    return peg;
}

function remove_superfluous_parentheses(s) {
    var i = null;
    var j, k;
    /* Removing superfluous nested parentheses, as in "((expr))". */
    while (true) {
        k = s.search(/\(\s*\(.*\)\s*\)/gm);
        if (k < 0) break;
        i = k;
        j = i + 1;
        while (s[j] != '(') j++;
        k = closing_bracket_offset(s, j, "()");
        var post_k = s.substring(k + 1);
        if (post_k.search(/^\s*\)/gm) == 0)
            s = s.substring(0, j) + s.substring(j + 1, k) + post_k;
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
    sp.push(peg.substring(lst[0].index, lst[0].end));
    var i = 1;
    while (i < lst.length) {
        sp.push(peg.substring(lst[i-1].end, lst[i].index));
        sp.push(peg.substring(lst[i].index, lst[i].end));
        i++;
    }
    sp.push(peg.substring(lst[i-1].end));
    return sp;
}

function peg_add_js_parser_action(peg) {
    peg = peg.replace(/([0-9a-zA-Z_-]+)_elidible *= *([^ ][^\r\n]+)/gm,
                      '$1_elidible = expr:($2) {return (expr == "") '
                      + '? ["$1"] : _node_empty("$1", expr);}');
    peg = peg.replace(/([0-9a-zA-Z_-]+) *= *([^ ][^:\r\n]+)([\r\n])/gm,
                      '$1 = expr:($2) {return _node("$1", expr);}$3');
    return peg;
}

function js_initializer() {
    return `{
  var _g_zoi_delim;
  
  function _join(arg)
  {
    if (typeof(arg) == "string")
      return arg;
    else if (arg)
    {
      var ret = "";
      for (var v in arg) { if (arg[v]) ret += _join(arg[v]); }
      return ret;
    }
  }

  function _node_empty(label, arg)
  {
    var ret = [];
    if (label) ret.push(label);
    if (arg && typeof arg == "object" && typeof arg[0] == "string" && arg[0])
    {
      ret.push( arg );
      return ret;
    }
    if (!arg)
    {
      return ret;
    }
    return _node_int(label, arg);
  }

  function _node_int(label, arg)
  {
    if (typeof arg == "string")
      return arg;
    if (!arg) arg = [];
    var ret = [];
    if (label) ret.push(label);
    for (var v in arg)
    {
      if (arg[v] && arg[v].length != 0)
        ret.push( _node_int( null, arg[v] ) );
    }
    return ret;
  }
 
  function _node2(label, arg1, arg2)
  {
    return [label].concat(_node_empty(arg1)).concat(_node_empty(arg2));
  }

  function _node(label, arg)
  {
    var _n = _node_empty(label, arg);
    return (_n.length == 1 && label) ? [] : _n;
  }
  var _node_nonempty = _node;
  
  // === ZOI functions === //

  function _zoi_assign_delim(word) {
    var a = word.toString().split(",");
    if (a.length > 0) _g_zoi_delim = a[a.length - 1];
    else _g_zoi_delim = "";
    return word;
  }

  function _zoi_check_quote(word) {
    if (typeof(word) == "object") word = word.toString();
    if (!is_string(word)) {
      throw "ZOI word is not a string";
      return false;
    } else {
      return (word.toLowerCase().replace(/,/gm, "").replace(/h/g, "'") === _g_zoi_delim);
    }
  }
  
  function _zoi_check_delim(word) {
    if (typeof(word) == "object") word = word.toString();
    if (!is_string(word)) {
      throw "ZOI word is not a string";
      return false;
    } else {
      word = word.split(",");
      if (word.length > 0) word = word[word.length - 1];
      else word = "";
      return (word === _g_zoi_delim);
    }
  }
  
  function is_string(v) {
    if (typeof v === 'undefined') return false;
    else return typeof v.valueOf() === 'string';
  }
}

`;
}

