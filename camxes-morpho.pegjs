// camxes.js.peg
// Copyright (c) 2013, 2014 Masato Hagiwara
// https://github.com/mhagiwara/camxes.js
//
// camxes.js can be used, modified, and re-distributed under MIT license.
// See LICENSE for the details.

// This is a Parsing Expression Grammar for Lojban.
// See http://bford.info/packrat/
//
// All rules have the form:
//
//     name = peg_expression
//
// which means that the grammatical construct "name" is parsed using
// "peg_expression".
//
// 1)  Names in lower case are grammatical constructs.
// 2)  Names in UPPER CASE are selma'o (lexeme) names, and are terminals.
// 3)  Concatenation is expressed by juxtaposition with no operator symbol.
// 4)  / represents *ORDERED* alternation (choice).  If the first
//     option succeeds, the others will never be checked.
// 5)  ? indicates that the element to the left is optional.
// 6)  * represents optional repetition of the construct to the left.
// 7)  + represents one_or_more repetition of the construct to the left.
// 8)  () serves to indicate the grouping of the other operators.
//
// Longest match wins.

// How to compile using Node.js: (Added by Masato Hagiwara)

// // load peg.js and the file system module
// > var PEG = require("pegjs")
// > var fs = require("fs")
// // read peg and build a parser
// > var camxes_peg = fs.readFileSync("/path/to/camxes.js.peg").toString();
// > var camxes = PEG.buildParser(camxes_peg, {cache: true});
// // test it
// > camxes.parse("ko'a broda");
// [ 'text',
//   [ 'text_1',
//     [ 'paragraphs', [Object] ] ] ]
// // write to a file
// > fs.writeFileSync("/path/to/camxes.js", camxes.toSource());


// ___ GRAMMAR ___



{
  var _g_zoi_delim;

  function _join(arg) {
    if (typeof(arg) == "string")
      return arg;
    else if (arg) {
      var ret = "";
      for (var v in arg) { if (arg[v]) ret += _join(arg[v]); }
      return ret;
    }
  }

  function _node_empty(label, arg) {
    var ret = [];
    if (label) ret.push(label);
    if (arg && typeof arg == "object" && typeof arg[0] == "string" && arg[0]) {
      ret.push( arg );
      return ret;
    }
    if (!arg)
    {
      return ret;
    }
    return _node_int(label, arg);
  }

  function _node_int(label, arg) {
    if (typeof arg == "string")
      return arg;
    if (!arg) arg = [];
    var ret = [];
    if (label) ret.push(label);
    for (var v in arg) {
      if (arg[v] && arg[v].length != 0)
        ret.push( _node_int( null, arg[v] ) );
    }
    return ret;
  }

  function _node2(label, arg1, arg2) {
    return [label].concat(_node_empty(arg1)).concat(_node_empty(arg2));
  }

  function _node(label, arg) {
    var _n = _node_empty(label, arg);
    return (_n.length == 1 && label) ? [] : _n;
  }
  var _node_nonempty = _node;

  // === Functions for faking left recursion === //

  function _flatten_node(a) {
    // Flatten nameless nodes
    // e.g. [Name1, [[Name2, X], [Name3, Y]]] --> [Name1, [Name2, X], [Name3, Y]]
    if (is_array(a)) {
      var i = 0;
      while (i < a.length) {
        if (!is_array(a[i])) i++;
        else if (a[i].length === 0) // Removing []s
          a = a.slice(0, i).concat(a.slice(i + 1));
        else if (is_array(a[i][0]))
          a = a.slice(0, i).concat(a[i], a.slice(i + 1));
        else i++;
      }
    }
    return a;
  }

  function _group_leftwise(arr) {
    if (!is_array(arr)) return [];
    else if (arr.length <= 2) return arr;
    else return [_group_leftwise(arr.slice(0, -1)), arr[arr.length - 1]];
  }

  // "_lg" for "Leftwise Grouping".
  function _node_lg(label, arg) {
    return _node(label, _group_leftwise(_flatten_node(arg)));
  }

  function _node_lg2(label, arg) {
    if (is_array(arg) && arg.length == 2)
      arg = arg[0].concat(arg[1]);
    return _node(label, _group_leftwise(arg));
  }

  // === ZOI functions === //

  function _assign_zoi_delim(w) {
    if (is_array(w)) w = join_expr(w);
    else if (!is_string(w)) throw "ERROR: ZOI word is of type" + typeof w;
    w = w.toLowerCase().replace(/,/gm,"").replace(/h/g, "'");
    _g_zoi_delim = w;
    return;
  }

  function _is_zoi_delim(w) {
    if (is_array(w)) w = join_expr(w);
    else if (!is_string(w)) throw "ERROR: ZOI word is of type" + typeof w;
    /* Keeping spaces in the parse tree seems to result in the absorbtion of
       spaces into the closing delimiter candidate, so we'll remove any space
       character from our input. */
    w = w.replace(/[.\t\n\r?!\u0020]/g, "");
    w = w.toLowerCase().replace(/,/gm,"").replace(/h/g, "'");
    return w === _g_zoi_delim;
  }

  function join_expr(n) {
    if (!is_array(n) || n.length < 1) return "";
    var s = "";
    var i = is_array(n[0]) ? 0 : 1;
    while (i < n.length) {
      s += is_string(n[i]) ? n[i] : join_expr(n[i]);
      i++;
    }
    return s;
  }

  function is_string(v) {
    // return $.type(v) === "string";
    return Object.prototype.toString.call(v) === '[object String]';
  }

  function is_array(v) {
    // return $.type(v) === "array";
    return Object.prototype.toString.call(v) === '[object Array]';
  }
}

text = expr:(spaces? ((foreign_word / foreign_characters / lojban_word)+ spaces?)* EOF?) {return _node("text", expr);}

foreign_word = !(lojban_word+) expr:([a-zA-Z']+) {return ["foreign_word", _join(expr)];}

foreign_characters = expr:(foreign_character+) {return ["foreign_characters", _join(expr)];}

foreign_character = !lojban_phoneme !digit !spaces expr:(.) {return expr;}

lojban_phoneme = expr:([aeiouylmnrbdgvjzscxkfpt'AEIOUYLMNRBDGVJZSCXKFPTh]) {return _node("lojban_phoneme", expr);}


// ___ MORPHOLOGY ___

CMEVLA = expr:(cmevla) {return _node("CMEVLA", expr);}
BRIVLA = expr:(gismu / lujvo / fuhivla) {return _node("BRIVLA", expr);}

// BETA: GOhOI / KUhAU / LEhAI / LOhAI / LOhOI / NOIhA / ZOhOI / MEhOI / IAU
CMAVO = expr:(A / BAI / BAhE / BE / BEI / BEhO / BIhE / BIhI / BO / BOI / BU / BY / CAhA / CAI / CEI / CEhE / CO / COI / CU / CUhE / DAhO / DOI / DOhU / FA / FAhA / FAhO / FEhE / FEhU / FIhO / FOI / FUhA / FUhE / FUhO / GA / GAhO / GEhU / GI / GIhA / GOI / GOhA / GOhOI / GUhA / I / IAU / JA / JAI / JOhI / JOI / KE / KEhE / KEI / KI / KOhA / KU / KUhAU / KUhE / KUhO / LA / LAU / LAhE / LE / LEhAI / LEhU / LI / LIhU / LOhAI / LOhO / LOhOI / LOhU / LU / LUhU / MAhO / MAI / ME / MEhOI / MEhU / MOhE / MOhI / MOI / NA / NAI / NAhE / NAhU / NIhE / NIhO / NOI / NOIhA / NU / NUhA / NUhI / NUhU / PA / PEhE / PEhO / PU / RAhO / ROI / SA / SE / SEI / SEhU / SI / SOI / SU / TAhE / TEhU / TEI / TO / TOI / TUhE / TUhU / UI / VA / VAU / VEI / VEhO / VUhU / VEhA / VIhA / VUhO / XI / ZAhO / ZEhA / ZEI / ZI / ZIhE / ZO / ZOI / ZOhOI / ZOhU / cmavo) {return _node("CMAVO", expr);}

// This is a Parsing Expression Grammar for the morphology of Lojban.
// See http://www.pdos.lcs.mit.edu/~baford/packrat/
//
// All rules have the form
//
// name = peg_expression
//
// which means that the grammatical construct "name" is parsed using
// "peg_expression".
//
// 1) Concatenation is expressed by juxtaposition with no operator symbol.
// 2) / represents *ORDERED* alternation (choice). If the first
// option succeeds, the others will never be checked.
// 3) ? indicates that the element to the left is optional.
// 4) * represents optional repetition of the construct to the left.
// 5) + represents one_or_more repetition of the construct to the left.
// 6) () serves to indicate the grouping of the other operators.
// 7) & indicates that the element to the right must follow (but the
// marked element itself does not absorb anything).
// 8) ! indicates that the element to the right must not follow (the
// marked element itself does not absorb anything).
// 9) . represents any character.
// 10) ' ' or " " represents a literal string.
// 11) [] represents a character class.
//
// Repetitions grab as much as they can.
//
//
// ___ GRAMMAR ___
// This grammar classifies words by their morphological class (cmevla,
// gismu, lujvo, fuhivla, cmavo, and non_lojban_word).
//
//The final section sorts cmavo into grammatical classes (A, BAI, BAhE, ..., ZOhU).
//
// mi'e ((xorxes))

//___________________________________________________________________

// words = expr:(pause? (word pause?)*) { return _join(expr); }

// word = expr:lojban_word / non_lojban_word { return expr; }

// lojban_word = expr:(cmevla / cmavo / brivla) { return expr; }
lojban_word = expr:(CMEVLA / CMAVO / BRIVLA) {return _node("lojban_word", expr);}

any_word = expr:(lojban_word spaces?) {return _node("any_word", expr);}

// === ZOI quote handling ===

// Pure PEG cannot handle ZOI quotes, because it cannot check whether the closing
// delimiter is the same as the opening one.
// ZOI quote handling is the only part of Lojban's grammar that needs mechanisms
// external to the pure PEG grammar to be implemented properly; those mechanisms
// are implementation-specific.

zoi_open = expr:(lojban_word) { _assign_zoi_delim(expr); return _node("zoi_open", expr); }
// Non-PEG: Remember the value matched by this zoi_open.

zoi_word = expr:(non_space+) !{ return _is_zoi_delim(expr); } { return ["zoi_word", join_expr(expr)]; }
// Non-PEG: Match successfully only if different from the most recent zoi_open.

zoi_close = expr:(any_word) &{ return _is_zoi_delim(expr); } { return _node("zoi_close", expr); }
// Non-PEG: Match successfully only if identical to the most recent zoi_open.

// BETA: ZOhOI, MEhOI
zohoi_word = expr:(non_space+) {return _node("zohoi_word", expr);}

//___________________________________________________________________

cmevla = expr:(jbocme / zifcme) {return _node("cmevla", expr);}

zifcme = expr:(!h (nucleus / glide / h / consonant !pause / digit)* consonant &pause) {return _node("zifcme", expr);}

jbocme = expr:(&zifcme (any_syllable / digit)* &pause) {return _node("jbocme", expr);}

//cmevla = !h cmevla_syllable* &consonant coda? consonantal_syllable* onset &pause

//cmevla_syllable = !doi_la_lai_lahi coda? consonantal_syllable* onset nucleus / digit

//doi_la_lai_lahi = (d o i / l a (h? i)?) !h !nucleus

//___________________________________________________________________

cmavo = expr:(!cmevla !CVCy_lujvo cmavo_form &post_word) {return _node("cmavo", expr);}

CVCy_lujvo = expr:(CVC_rafsi y h? initial_rafsi* brivla_core / stressed_CVC_rafsi y short_final_rafsi) {return _node("CVCy_lujvo", expr);}

cmavo_form = expr:(!h !cluster onset (nucleus h)* (!stressed nucleus / nucleus !cluster) / y+ / digit) {return _node("cmavo_form", expr);}

//___________________________________________________________________

brivla = expr:(!cmavo initial_rafsi* brivla_core) {return _node("brivla", expr);}

brivla_core = expr:(fuhivla / gismu / CVV_final_rafsi / stressed_initial_rafsi short_final_rafsi) {return _node("brivla_core", expr);}

stressed_initial_rafsi = expr:(stressed_extended_rafsi / stressed_y_rafsi / stressed_y_less_rafsi) {return _node("stressed_initial_rafsi", expr);}

initial_rafsi = expr:(extended_rafsi / y_rafsi / !any_extended_rafsi y_less_rafsi !any_extended_rafsi) {return _node("initial_rafsi", expr);}

//___________________________________________________________________

any_extended_rafsi = expr:(fuhivla / extended_rafsi / stressed_extended_rafsi) {return _node("any_extended_rafsi", expr);}

fuhivla = expr:(fuhivla_head stressed_syllable consonantal_syllable* final_syllable) {return _node("fuhivla", expr);}

stressed_extended_rafsi = expr:(stressed_brivla_rafsi / stressed_fuhivla_rafsi) {return _node("stressed_extended_rafsi", expr);}

extended_rafsi = expr:(brivla_rafsi / fuhivla_rafsi) {return _node("extended_rafsi", expr);}

stressed_brivla_rafsi = expr:(&unstressed_syllable brivla_head stressed_syllable h y) {return _node("stressed_brivla_rafsi", expr);}

brivla_rafsi = expr:(&(syllable consonantal_syllable* syllable) brivla_head h y h?) {return _node("brivla_rafsi", expr);}

stressed_fuhivla_rafsi = expr:(fuhivla_head stressed_syllable consonantal_syllable* !h onset y) {return _node("stressed_fuhivla_rafsi", expr);}

fuhivla_rafsi = expr:(&unstressed_syllable fuhivla_head !h onset y h?) {return _node("fuhivla_rafsi", expr);}

fuhivla_head = expr:(!rafsi_string brivla_head) {return _node("fuhivla_head", expr);}

brivla_head = expr:(!cmavo !slinkuhi !h &onset unstressed_syllable*) {return _node("brivla_head", expr);}

slinkuhi = expr:(!rafsi_string consonant rafsi_string) {return _node("slinkuhi", expr);}

rafsi_string = expr:(y_less_rafsi* (gismu / CVV_final_rafsi / stressed_y_less_rafsi short_final_rafsi / y_rafsi / stressed_y_rafsi / stressed_y_less_rafsi? initial_pair y / hy_rafsi / stressed_hy_rafsi)) {return _node("rafsi_string", expr);}

//___________________________________________________________________

gismu = expr:((initial_pair stressed_vowel / consonant stressed_vowel consonant) &final_syllable consonant vowel &post_word) {return _node("gismu", expr);}

CVV_final_rafsi = expr:(consonant stressed_vowel h &final_syllable vowel &post_word) {return _node("CVV_final_rafsi", expr);}

short_final_rafsi = expr:(&final_syllable (consonant diphthong / initial_pair vowel) &post_word) {return _node("short_final_rafsi", expr);}

stressed_y_rafsi = expr:((stressed_long_rafsi / stressed_CVC_rafsi) y) {return _node("stressed_y_rafsi", expr);}

stressed_y_less_rafsi = expr:(stressed_CVC_rafsi !y / stressed_CCV_rafsi / stressed_CVV_rafsi) {return _node("stressed_y_less_rafsi", expr);}

stressed_long_rafsi = expr:(initial_pair stressed_vowel consonant / consonant stressed_vowel consonant consonant) {return _node("stressed_long_rafsi", expr);}

stressed_CVC_rafsi = expr:(consonant stressed_vowel consonant) {return _node("stressed_CVC_rafsi", expr);}

stressed_CCV_rafsi = expr:(initial_pair stressed_vowel) {return _node("stressed_CCV_rafsi", expr);}

stressed_CVV_rafsi = expr:(consonant (unstressed_vowel h stressed_vowel / stressed_diphthong) r_hyphen?) {return _node("stressed_CVV_rafsi", expr);}

y_rafsi = expr:((long_rafsi / CVC_rafsi) y h?) {return _node("y_rafsi", expr);}

y_less_rafsi = expr:(!y_rafsi !stressed_y_rafsi !hy_rafsi !stressed_hy_rafsi (CVC_rafsi / CCV_rafsi / CVV_rafsi) !h) {return _node("y_less_rafsi", expr);}

hy_rafsi = expr:((long_rafsi vowel / CCV_rafsi / CVV_rafsi) h y h?) {return _node("hy_rafsi", expr);}

stressed_hy_rafsi = expr:((long_rafsi stressed_vowel / stressed_CCV_rafsi / stressed_CVV_rafsi) h y) {return _node("stressed_hy_rafsi", expr);}

long_rafsi = expr:(initial_pair unstressed_vowel consonant / consonant unstressed_vowel consonant consonant) {return _node("long_rafsi", expr);}

CVC_rafsi = expr:(consonant unstressed_vowel consonant) {return _node("CVC_rafsi", expr);}

CCV_rafsi = expr:(initial_pair unstressed_vowel) {return _node("CCV_rafsi", expr);}

CVV_rafsi = expr:(consonant (unstressed_vowel h unstressed_vowel / unstressed_diphthong) r_hyphen?) {return _node("CVV_rafsi", expr);}

r_hyphen = expr:(r &consonant / n &r) {return _node("r_hyphen", expr);}

//___________________________________________________________________

final_syllable = expr:(onset !y !stressed nucleus !cmevla &post_word) {return _node("final_syllable", expr);}

stressed_syllable = expr:(&stressed syllable / syllable &stress) {return _node("stressed_syllable", expr);}

stressed_diphthong = expr:(&stressed diphthong / diphthong &stress) {return _node("stressed_diphthong", expr);}

stressed_vowel = expr:(&stressed vowel / vowel &stress) {return _node("stressed_vowel", expr);}

unstressed_syllable = expr:(!stressed syllable !stress / consonantal_syllable) {return _node("unstressed_syllable", expr);}

unstressed_diphthong = expr:(!stressed diphthong !stress) {return _node("unstressed_diphthong", expr);}

unstressed_vowel = expr:(!stressed vowel !stress) {return _node("unstressed_vowel", expr);}

//// FIX: Xorxes' fix for fu'ivla rafsi stress
stress = expr:((consonant / glide)* h? y? syllable pause) {return _node("stress", expr);}

stressed = expr:(onset comma* [AEIOU]) {return _node("stressed", expr);}

any_syllable = expr:(onset nucleus coda? / consonantal_syllable) {return _node("any_syllable", expr);}

syllable = expr:(onset !y nucleus coda?) {return _node("syllable", expr);}

//// FIX: preventing {bla'ypre} from being a valid lujvo
consonantal_syllable = expr:(consonant &syllabic coda) {return _node("consonantal_syllable", expr);}

coda = expr:(!any_syllable consonant &any_syllable / syllabic? consonant? &pause) {return _node("coda", expr);}

onset = expr:(h / glide / initial) {return _node("onset", expr);}

nucleus = expr:(vowel / diphthong / y !nucleus) {return _node("nucleus", expr);}

//_________________________________________________________________

glide = expr:((i / u) &nucleus) {return _node("glide", expr);}

diphthong = expr:((a i !i / a u !u / e i !i / o i !i) !nucleus) {return _node("diphthong", expr);}

vowel = expr:((a / e / i / o / u) !nucleus) {return _node("vowel", expr);}

a = expr:(comma* [aA]) {return _node("a", expr);}

e = expr:(comma* [eE]) {return _node("e", expr);}

i = expr:(comma* [iI]) {return _node("i", expr);}

o = expr:(comma* [oO]) {return _node("o", expr);}

u = expr:(comma* [uU]) {return _node("u", expr);}

y = expr:(comma* [yY] !(!y nucleus)) {return _node("y", expr);}



//___________________________________________________________________

cluster = expr:(consonant consonant+) {return _node("cluster", expr);}

initial_pair = expr:(&initial consonant consonant !consonant) {return _node("initial_pair", expr);}

initial = expr:((affricate / sibilant? other? liquid?) !consonant !glide) {return _node("initial", expr);}

affricate = expr:(t c / t s / d j / d z) {return _node("affricate", expr);}

liquid = expr:(l / r) {return _node("liquid", expr);}

other = expr:(p / t !l / k / f / x / b / d !l / g / v / m / n !liquid) {return _node("other", expr);}

sibilant = expr:(c / s !x / (j / z) !n !liquid) {return _node("sibilant", expr);}

consonant = expr:(voiced / unvoiced / syllabic) {return _node("consonant", expr);}

syllabic = expr:(l / m / n / r) {return _node("syllabic", expr);}

voiced = expr:(b / d / g / j / v / z) {return _node("voiced", expr);}

unvoiced = expr:(c / f / k / p / s / t / x) {return _node("unvoiced", expr);}

l = expr:(comma* [lL] !h !glide !l) {return _node("l", expr);}

m = expr:(comma* [mM] !h !glide !m !z) {return _node("m", expr);}

n = expr:(comma* [nN] !h !glide !n !affricate) {return _node("n", expr);}

r = expr:(comma* [rR] !h !glide !r) {return _node("r", expr);}

b = expr:(comma* [bB] !h !glide !b !unvoiced) {return _node("b", expr);}

d = expr:(comma* [dD] !h !glide !d !unvoiced) {return _node("d", expr);}

g = expr:(comma* [gG] !h !glide !g !unvoiced) {return _node("g", expr);}

v = expr:(comma* [vV] !h !glide !v !unvoiced) {return _node("v", expr);}

j = expr:(comma* [jJ] !h !glide !j !z !unvoiced) {return _node("j", expr);}

z = expr:(comma* [zZ] !h !glide !z !j !unvoiced) {return _node("z", expr);}

s = expr:(comma* [sS] !h !glide !s !c !voiced) {return _node("s", expr);}

c = expr:(comma* [cC] !h !glide !c !s !x !voiced) {return _node("c", expr);}

x = expr:(comma* [xX] !h !glide !x !c !k !voiced) {return _node("x", expr);}

k = expr:(comma* [kK] !h !glide !k !x !voiced) {return _node("k", expr);}

f = expr:(comma* [fF] !h !glide !f !voiced) {return _node("f", expr);}

p = expr:(comma* [pP] !h !glide !p !voiced) {return _node("p", expr);}

t = expr:(comma* [tT] !h !glide !t !voiced) {return _node("t", expr);}

h = expr:(comma* ['h] &nucleus) {return _node("h", expr);}

//___________________________________________________________________

digit = expr:(comma* [0123456789] !h !nucleus) {return _node("digit", expr);}

post_word = expr:(pause / !nucleus lojban_word) {return _node("post_word", expr);}

pause = expr:(comma* space_char+ / foreign_characters / EOF) {return _node("pause", expr);}

EOF = expr:(comma* !.) {return _node("EOF", expr);}

comma = expr:([,]) {return ",";}

// This is an orphan rule.
non_lojban_word = expr:(!lojban_word non_space+) {return _node("non_lojban_word", expr);}

non_space = expr:(!space_char .) {return _node("non_space", expr);}

//Unicode_style and escaped chars not compatible with cl_peg
space_char = expr:([.\t\n\r?!\u0020]) {return _join(expr);}

// space_char = [.?! ] / space_char1 / space_char2
// space_char1 = '    '
// space_char2 = ''

//___________________________________________________________________

spaces = expr:(!Y initial_spaces) {return _node("spaces", expr);}

initial_spaces = expr:((comma* space_char / !ybu Y)+ EOF? / EOF) {return _join(expr);}

ybu = expr:(Y space_char* BU) {return _node("ybu", expr);}

lujvo = expr:(!gismu !fuhivla brivla) {return _node("lujvo", expr);}

//___________________________________________________________________

A = expr:(&cmavo ( a / e / j i / o / u ) &post_word) {return _node("A", expr);}

BAI = expr:(&cmavo ( d u h o / s i h u / z a u / k i h i / d u h i / c u h u / t u h i / t i h u / d i h o / j i h u / r i h a / n i h i / m u h i / k i h u / v a h u / k o i / c a h i / t a h i / p u h e / j a h i / k a i / b a i / f i h e / d e h i / c i h o / m a u / m u h u / r i h i / r a h i / k a h a / p a h u / p a h a / l e h a / k u h u / t a i / b a u / m a h i / c i h e / f a u / p o h i / c a u / m a h e / c i h u / r a h a / p u h a / l i h e / l a h u / b a h i / k a h i / s a u / f a h e / b e h i / t i h i / j a h e / g a h a / v a h o / j i h o / m e h a / d o h e / j i h e / p i h o / g a u / z u h e / m e h e / r a i ) &post_word) {return _node("BAI", expr);}

BAhE = expr:(&cmavo ( b a h e / z a h e ) &post_word) {return _node("BAhE", expr);}

BE = expr:(&cmavo ( b e ) &post_word) {return _node("BE", expr);}

BEI = expr:(&cmavo ( b e i ) &post_word) {return _node("BEI", expr);}

BEhO = expr:(&cmavo ( b e h o ) &post_word) {return _node("BEhO", expr);}

BIhE = expr:(&cmavo ( b i h e ) &post_word) {return _node("BIhE", expr);}

BIhI = expr:(&cmavo ( m i h i / b i h o / b i h i ) &post_word) {return _node("BIhI", expr);}

BO = expr:(&cmavo ( b o ) &post_word) {return _node("BO", expr);}

BOI = expr:(&cmavo ( b o i ) &post_word) {return _node("BOI", expr);}

BU = expr:(&cmavo ( b u ) &post_word) {return _node("BU", expr);}

// BETA: a'y, e'y, i'y, o'y, u'y, iy, uy
BY = expr:(&cmavo ( ybu / j o h o / r u h o / g e h o / j e h o / l o h a / n a h a / s e h e / t o h a / g a h e / y h y / a h y / e h y / i h y / o h y / u h y / i y / u y / b y / c y / d y / f y / g y / j y / k y / l y / m y / n y / p y / r y / s y / t y / v y / x y / z y ) &post_word) {return _node("BY", expr);}

// BETA: bi'ai
CAhA = expr:(&cmavo ( b i h a i / c a h a / p u h i / n u h o / k a h e ) &post_word) {return _node("CAhA", expr);}

CAI = expr:(&cmavo ( p e i / c a i / c u h i / s a i / r u h e ) &post_word) {return _node("CAI", expr);}

CEI = expr:(&cmavo ( c e i ) &post_word) {return _node("CEI", expr);}

CEhE = expr:(&cmavo ( c e h e ) &post_word) {return _node("CEhE", expr);}

CO = expr:(&cmavo ( c o ) &post_word) {return _node("CO", expr);}

// BETA: di'ai, jo'au, co'oi, da'oi, ki'ai, sa'ei
COI = expr:(&cmavo ( d i h a i / j o h a u / c o h o i / d a h o i / k i h a i / s a h e i / j u h i / c o i / f i h i / t a h a / m u h o / f e h o / c o h o / p e h u / k e h o / n u h e / r e h i / b e h e / j e h e / m i h e / k i h e / v i h o ) &post_word) {return _node("COI", expr);}

CU = expr:(&cmavo ( c u ) &post_word) {return _node("CU", expr);}

CUhE = expr:(&cmavo ( c u h e / n a u ) &post_word) {return _node("CUhE", expr);}

DAhO = expr:(&cmavo ( d a h o ) &post_word) {return _node("DAhO", expr);}

DOI = expr:(&cmavo ( d o i ) &post_word) {return _node("DOI", expr);}

DOhU = expr:(&cmavo ( d o h u ) &post_word) {return _node("DOhU", expr);}

FA = expr:(&cmavo ( f a i / f a / f e / f o / f u / f i h a / f i ) &post_word) {return _node("FA", expr);}

FAhA = expr:(&cmavo ( d u h a / b e h a / n e h u / v u h a / g a h u / t i h a / n i h a / c a h u / z u h a / r i h u / r u h u / r e h o / t e h e / b u h u / n e h a / p a h o / n e h i / t o h o / z o h i / z e h o / z o h a / f a h a ) &post_word &post_word) {return _node("FAhA", expr);}

FAhO = expr:(&cmavo ( f a h o ) &post_word) {return _node("FAhO", expr);}

FEhE = expr:(&cmavo ( f e h e ) &post_word) {return _node("FEhE", expr);}

FEhU = expr:(&cmavo ( f e h u ) &post_word) {return _node("FEhU", expr);}

FIhO = expr:(&cmavo ( f i h o ) &post_word) {return _node("FIhO", expr);}

FOI = expr:(&cmavo ( f o i ) &post_word) {return _node("FOI", expr);}

FUhA = expr:(&cmavo ( f u h a ) &post_word) {return _node("FUhA", expr);}

FUhE = expr:(&cmavo ( f u h e ) &post_word) {return _node("FUhE", expr);}

FUhO = expr:(&cmavo ( f u h o ) &post_word) {return _node("FUhO", expr);}

GA = expr:(&cmavo ( g e h i / g e / g o / g a / g u ) &post_word) {return _node("GA", expr);}

GAhO = expr:(&cmavo ( k e h i / g a h o ) &post_word) {return _node("GAhO", expr);}

GEhU = expr:(&cmavo ( g e h u ) &post_word) {return _node("GEhU", expr);}

GI = expr:(&cmavo ( g i ) &post_word) {return _node("GI", expr);}

GIhA = expr:(&cmavo ( g i h e / g i h i / g i h o / g i h a / g i h u ) &post_word) {return _node("GIhA", expr);}

GOI = expr:(&cmavo ( n o h u / n e / g o i / p o h u / p e / p o h e / p o ) &post_word) {return _node("GOI", expr);}

GOhA = expr:(&cmavo ( m o / n e i / g o h u / g o h o / g o h i / n o h a / g o h e / g o h a / d u / b u h a / b u h e / b u h i / c o h e ) &post_word) {return _node("GOhA", expr);}

GUhA = expr:(&cmavo ( g u h e / g u h i / g u h o / g u h a / g u h u ) &post_word) {return _node("GUhA", expr);}

I = expr:(&cmavo ( i ) &post_word) {return _node("I", expr);}

JA = expr:(&cmavo ( j e h i / j e / j o / j a / j u ) &post_word) {return _node("JA", expr);}

JAI = expr:(&cmavo ( j a i ) &post_word) {return _node("JAI", expr);}

JOhI = expr:(&cmavo ( j o h i ) &post_word) {return _node("JOhI", expr);}

JOI = expr:(&cmavo ( f a h u / p i h u / j o i / c e h o / c e / j o h u / k u h a / j o h e / j u h e ) &post_word) {return _node("JOI", expr);}

KE = expr:(&cmavo ( k e ) &post_word) {return _node("KE", expr);}

KEhE = expr:(&cmavo ( k e h e ) &post_word) {return _node("KEhE", expr);}

KEI = expr:(&cmavo ( k e i ) &post_word) {return _node("KEI", expr);}

KI = expr:(&cmavo ( k i ) &post_word) {return _node("KI", expr);}

// BETA: xai, zu'ai
KOhA = expr:(&cmavo ( z u h a i / d a h u / d a h e / d i h u / d i h e / d e h u / d e h e / d e i / d o h i / m i h o / m a h a / m i h a / d o h o / k o h a / f o h u / k o h e / k o h i / k o h o / k o h u / f o h a / f o h e / f o h i / f o h o / v o h a / v o h e / v o h i / v o h o / v o h u / r u / r i / r a / t a / t u / t i / z i h o / k e h a / m a / z u h i / z o h e / c e h u / x a i / d a / d e / d i / k o / m i / d o ) &post_word) {return _node("KOhA", expr);}

KU = expr:(&cmavo ( k u ) &post_word) {return _node("KU", expr);}

KUhE = expr:(&cmavo ( k u h e ) &post_word) {return _node("KUhE", expr);}

KUhO = expr:(&cmavo ( k u h o ) &post_word) {return _node("KUhO", expr);}

// BETA: la'ei
LA = expr:(&cmavo ( l a h e i / l a i / l a h i / l a ) &post_word) {return _node("LA", expr);}

LAU = expr:(&cmavo ( c e h a / l a u / z a i / t a u ) &post_word) {return _node("LAU", expr);}

// BETA: zo'ei
LAhE = expr:(&cmavo ( z o h e i / t u h a / l u h a / l u h o / l a h e / v u h i / l u h i / l u h e ) &post_word) {return _node("LAhE", expr);}

// BETA: me'ei, mo'oi, ri'oi
LE = expr:(&cmavo ( m e h e i / m o h o i / r i h o i / l e i / l o i / l e h i / l o h i / l e h e / l o h e / l o / l e ) &post_word) {return _node("LE", expr);}

LEhU = expr:(&cmavo ( l e h u ) &post_word) {return _node("LEhU", expr);}

LI = expr:(&cmavo ( m e h o / l i ) &post_word) {return _node("LI", expr);}

LIhU = expr:(&cmavo ( l i h u ) &post_word) {return _node("LIhU", expr);}

LOhO = expr:(&cmavo ( l o h o ) &post_word) {return _node("LOhO", expr);}

LOhU = expr:(&cmavo ( l o h u ) &post_word) {return _node("LOhU", expr);}

// BETA: la'au
LU = expr:(&cmavo ( l a h a u / l u ) &post_word) {return _node("LU", expr);}

LUhU = expr:(&cmavo ( l u h u ) &post_word) {return _node("LUhU", expr);}

MAhO = expr:(&cmavo ( m a h o ) &post_word) {return _node("MAhO", expr);}

// BETA: ju'ai
MAI = expr:(&cmavo ( m o h o / m a i / j u h a i ) &post_word) {return _node("MAI", expr);}

// BETA: me'au
ME = expr:(&cmavo (m e h a u / m e) &post_word) {return _node("ME", expr);}

MEhU = expr:(&cmavo ( m e h u ) &post_word) {return _node("MEhU", expr);}

MOhE = expr:(&cmavo ( m o h e ) &post_word) {return _node("MOhE", expr);}

MOhI = expr:(&cmavo ( m o h i ) &post_word) {return _node("MOhI", expr);}

MOI = expr:(&cmavo ( m e i / m o i / s i h e / c u h o / v a h e ) &post_word) {return _node("MOI", expr);}

NA = expr:(&cmavo ( j a h a / n a ) &post_word) {return _node("NA", expr);}

// BETA: ja'ai
NAI = expr:(&cmavo ( n a i / j a h a i ) &post_word) {return _node("NAI", expr);}

NAhE = expr:(&cmavo ( t o h e / j e h a / n a h e / n o h e ) &post_word) {return _node("NAhE", expr);}

// BETA: ji'oi
NAhU = expr:(&cmavo ( n a h u / j i h o i ) &post_word) {return _node("NAhU", expr);}

NIhE = expr:(&cmavo ( n i h e ) &post_word) {return _node("NIhE", expr);}

NIhO = expr:(&cmavo ( n i h o / n o h i ) &post_word) {return _node("NIhO", expr);}

NOI = expr:(&cmavo ( v o i / n o i / p o i ) &post_word) {return _node("NOI", expr);}

// BETA: poi'i, kai'u
NU = expr:(&cmavo ( p o i h i / k a i h u / n i / d u h u / s i h o / n u / l i h i / k a / j e i / s u h u / z u h o / m u h e / p u h u / z a h i ) &post_word) {return _node("NU", expr);}

NUhA = expr:(&cmavo ( n u h a ) &post_word) {return _node("NUhA", expr);}

NUhI = expr:(&cmavo ( n u h i ) &post_word) {return _node("NUhI", expr);}

NUhU = expr:(&cmavo ( n u h u ) &post_word) {return _node("NUhU", expr);}

// BETA: xo'e, su'oi, ro'oi
PA = expr:(&cmavo ( s u h o i / r o h o i / x o h e / d a u / f e i / g a i / j a u / r e i / v a i / p i h e / p i / f i h u / z a h u / m e h i / n i h u / k i h o / c e h i / m a h u / r a h e / d a h a / s o h a / j i h i / s u h o / s u h e / r o / r a u / s o h u / s o h i / s o h e / s o h o / m o h a / d u h e / t e h o / k a h o / c i h i / t u h o / x o / p a i / n o h o / n o / p a / r e / c i / v o / m u / x a / z e / b i / s o / digit ) &post_word) {return _node("PA", expr);}

PEhE = expr:(&cmavo ( p e h e ) &post_word) {return _node("PEhE", expr);}

PEhO = expr:(&cmavo ( p e h o ) &post_word) {return _node("PEhO", expr);}

PU = expr:(&cmavo ( b a / p u / c a ) &post_word) {return _node("PU", expr);}

RAhO = expr:(&cmavo ( r a h o ) &post_word) {return _node("RAhO", expr);}

// BETA: mu'ei
ROI = expr:(&cmavo ( r e h u / r o i / m u h e i ) &post_word) {return _node("ROI", expr);}

SA = expr:(&cmavo ( s a ) &post_word) {return _node("SA", expr);}

SE = expr:(&cmavo ( s e / t e / v e / x e ) &post_word) {return _node("SE", expr);}

SEI = expr:(&cmavo ( s e i / t i h o ) &post_word) {return _node("SEI", expr);}

SEhU = expr:(&cmavo ( s e h u ) &post_word) {return _node("SEhU", expr);}

// BETA: ze'ei
SI = expr:(&cmavo ( z e h e i / s i ) &post_word) {return _node("SI", expr);}

// BETA: New-SOI, soi, xoi
SOI = expr:(&cmavo ( s o i / x o i ) &post_word) {return _node("SOI", expr);}

SU = expr:(&cmavo ( s u ) &post_word) {return _node("SU", expr);}

TAhE = expr:(&cmavo ( r u h i / t a h e / d i h i / n a h o ) &post_word) {return _node("TAhE", expr);}

TEhU = expr:(&cmavo ( t e h u ) &post_word) {return _node("TEhU", expr);}

TEI = expr:(&cmavo ( t e i ) &post_word) {return _node("TEI", expr);}

TO = expr:(&cmavo ( t o h i / t o ) &post_word) {return _node("TO", expr);}

TOI = expr:(&cmavo ( t o i ) &post_word) {return _node("TOI", expr);}

TUhE = expr:(&cmavo ( t u h e ) &post_word) {return _node("TUhE", expr);}

TUhU = expr:(&cmavo ( t u h u ) &post_word) {return _node("TUhU", expr);}

// BETA: ko'oi, si'au, o'ai, xe'e, xo'o
UI = expr:(&cmavo ( k o h o i / s i h a u / a h o i / o h a i / x e h e / x o h o / i h a / i e / a h e / u h i / i h o / i h e / a h a / i a / o h i / o h e / e h e / o i / u o / e h i / u h o / a u / u a / a h i / i h u / i i / u h a / u i / a h o / a i / a h u / i u / e i / o h o / e h a / u u / o h a / o h u / u h u / e h o / i o / e h u / u e / i h i / u h e / b a h a / j a h o / c a h e / s u h a / t i h e / k a h u / s e h o / z a h a / p e h i / r u h a / j u h a / t a h o / r a h u / l i h a / b a h u / m u h a / d o h a / t o h u / v a h i / p a h e / z u h u / s a h e / l a h a / k e h u / s a h u / d a h i / j e h u / s a h a / k a u / t a h u / n a h i / j o h a / b i h u / l i h o / p a u / m i h u / k u h i / j i h a / s i h a / p o h o / p e h a / r o h i / r o h e / r o h o / r o h u / r o h a / r e h e / l e h o / j u h o / f u h i / d a i / g a h i / z o h o / b e h u / r i h e / s e h i / s e h a / v u h e / k i h a / x u / g e h e / b u h o ) &post_word) {return _node("UI", expr);}

VA = expr:(&cmavo ( v i / v a / v u ) &post_word) {return _node("VA", expr);}

VAU = expr:(&cmavo ( v a u ) &post_word) {return _node("VAU", expr);}

VEI = expr:(&cmavo ( v e i ) &post_word) {return _node("VEI", expr);}

VEhO = expr:(&cmavo ( v e h o ) &post_word) {return _node("VEhO", expr);}

VUhU = expr:(&cmavo ( g e h a / f u h u / p i h i / f e h i / v u h u / s u h i / j u h u / g e i / p a h i / f a h i / t e h a / c u h a / v a h a / n e h o / d e h o / f e h a / s a h o / r e h a / r i h o / s a h i / p i h a / s i h i ) &post_word) {return _node("VUhU", expr);}

VEhA = expr:(&cmavo ( v e h u / v e h a / v e h i / v e h e ) &post_word) {return _node("VEhA", expr);}

VIhA = expr:(&cmavo ( v i h i / v i h a / v i h u / v i h e ) &post_word) {return _node("VIhA", expr);}

VUhO = expr:(&cmavo ( v u h o ) &post_word) {return _node("VUhO", expr);}

XI = expr:(&cmavo ( x i ) &post_word) {return _node("XI", expr);}

Y = expr:(&cmavo ( y+ ) &post_word) {return _node("Y", expr);}

// BETA: xa'o
ZAhO = expr:(&cmavo ( c o h i / p u h o / c o h u / m o h u / c a h o / c o h a / d e h a / b a h o / d i h a / z a h o / x a h o ) &post_word) {return _node("ZAhO", expr);}

ZEhA = expr:(&cmavo ( z e h u / z e h a / z e h i / z e h e ) &post_word) {return _node("ZEhA", expr);}

ZEI = expr:(&cmavo ( z e i ) &post_word) {return _node("ZEI", expr);}

ZI = expr:(&cmavo ( z u / z a / z i ) &post_word) {return _node("ZI", expr);}

ZIhE = expr:(&cmavo ( z i h e ) &post_word) {return _node("ZIhE", expr);}

// BETA: ma'oi
ZO = expr:(&cmavo ( z o / m a h o i ) &post_word) {return _node("ZO", expr);}

ZOI = expr:(&cmavo ( z o i / l a h o ) &post_word) {return _node("ZOI", expr);}

// BETA: ce'ai
ZOhU = expr:(&cmavo ( c e h a i / z o h u ) &post_word) {return _node("ZOhU", expr);}

// BEGIN BETA: Experimental selmaho

GOhOI = expr:(&cmavo ( g o h o i ) &post_word) {return _node("GOhOI", expr);}
IAU = expr:(&cmavo ( i a u ) &post_word) {return _node("IAU", expr);}
KUhAU = expr:(&cmavo ( k u h a u ) &post_word) {return _node("KUhAU", expr);}
LEhAI = expr:(&cmavo ( l e h a i ) &post_word) {return _node("LEhAI", expr);}
LOhAI = expr:(&cmavo ( l o h a i / s a h a i ) &post_word) {return _node("LOhAI", expr);}
LOhOI = expr:(&cmavo ( l o h o i / x u h u ) &post_word) {return _node("LOhOI", expr);}
NOIhA = expr:(&cmavo ( n o i h o h a / p o i h o h a / n o i h a / p o i h a / s o i h a ) &post_word) {return _node("NOIhA", expr);}
ZOhOI = expr:(&cmavo ( z o h o i / l a h o i / r a h o i ) &post_word) {return _node("ZOhOI", expr);}
MEhOI = expr:(&cmavo ( m e h o i ) &post_word) {return _node("MEhOI", expr);}

// END BETA: Experimental selmaho

