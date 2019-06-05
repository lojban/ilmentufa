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
    else if (!is_string(w)) throw "ERROR: ZOI word is of type " + typeof w;
    w = w.toLowerCase().replace(/,/gm,"").replace(/h/g, "'");
    _g_zoi_delim = w;
    return;
  }

  function _is_zoi_delim(w) {
    if (is_array(w)) w = join_expr(w);
    else if (!is_string(w)) throw "ERROR: ZOI word is of type " + typeof w;
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

text = expr:(intro_null NAI_clause* text_part_2 (!gek joik_jek)? text_1? faho_clause EOF?) {return _node("text", expr);}

intro_null = expr:(initial_spaces? su_clause* intro_si_clause) {return _node("intro_null", expr);}

text_part_2 = expr:((CMEVLA_clause+ / indicators?) free*) {return _node("text_part_2", expr);}

//; intro_sa_clause = SA_clause+ / any_word_SA_handling !(ZEI_clause SA_clause) intro_sa_clause
intro_si_clause = expr:(si_clause? SI_clause*) {return _node("intro_si_clause", expr);}
faho_clause = expr:((FAhO_clause dot_star)?) {return _node("faho_clause", expr);}

// Please note that the "text_1" item in the text_1 production does
// *not* match the BNF. This is due to a bug in the BNF.  The change
// here was made to match grammar.300
text_1 = expr:(I_clause (jek / joik)? (stag? BO_clause)? free* text_1? / NIhO_clause+ free* su_clause* paragraphs? / paragraphs) {return _node("text_1", expr);}

paragraphs = expr:(paragraph? (NIhO_clause+ free* su_clause* paragraphs)?) {return _node("paragraphs", expr);}

paragraph = expr:((statement / fragment) (I_clause !jek !joik !joik_jek free* (statement / fragment)?)*) {return _node("paragraph", expr);}

// BEGIN BETA: IAU
statement = expr:(statement_0 IAU_elidible free* terms?) {return _node("statement", expr);}

statement_0 = expr:(statement_1 / prenex statement) {return _node("statement_0", expr);}
// END BETA: IAU

statement_1 = expr:(statement_2 (I_clause joik_jek statement_2?)*) {return _node("statement_1", expr);}

statement_2 = expr:(statement_3 (I_clause (jek / joik)? stag? BO_clause free* statement_2?)?) {return _node("statement_2", expr);}

statement_3 = expr:(sentence / tag? TUhE_clause free* text_1 TUhU_elidible free*) {return _node("statement_3", expr);}

// BETA: NA sequence fragments
fragment = expr:(prenex / terms VAU_elidible free* / ek free* / gihek free* / quantifier / (NA_clause !JA_clause free*)+ / relative_clauses / links / linkargs) {return _node("fragment", expr);}

prenex = expr:(terms ZOhU_clause free*) {return _node("prenex", expr);}

//; sentence = (terms CU_clause? free*)? bridi_tail / bridi_tail

// BETA: JACU, JE.I
sentence = expr:(terms? bridi_tail_t1 (joik_jek bridi_tail / joik_jek stag? KE_clause free* bridi_tail KEhE_elidible free*)* (joik_jek I_clause free* subsentence)*) {return _node("sentence", expr);}
// sentence = expr:(((terms bridi_tail_sa*)? CU_elidible free*)? bridi_tail_sa* bridi_tail) {return _node("sentence", expr);}

// BETA: JACU
bridi_tail_t1 = expr:(bridi_tail_t2 (joik_jek stag? KE_clause free* bridi_tail KEhE_elidible free*)?) {return _node("bridi_tail_t1", expr);}

// BETA: JACU
bridi_tail_t2 = expr:(bridi_tail (joik_jek stag? BO_clause free* bridi_tail)?) {return _node("bridi_tail_t2", expr);}


sentence_sa = expr:(sentence_start (!sentence_start (sa_word / SA_clause !sentence_start ) )* SA_clause &text_1) {return _node("sentence_sa", expr);}

sentence_start = expr:(I_pre / NIhO_pre) {return _node("sentence_start", expr);}

subsentence = expr:(sentence / prenex subsentence) {return _node("subsentence", expr);}

// BETA: JACU
bridi_tail = expr:(bridi_tail_1 ((gihek / joik_jek) stag? KE_clause free* bridi_tail KEhE_elidible free* tail_terms)?) {return _node("bridi_tail", expr);}

bridi_tail_sa = expr:(bridi_tail_start (term / !bridi_tail_start (sa_word / SA_clause !bridi_tail_start ) )* SA_clause &bridi_tail) {return _node("bridi_tail_sa", expr);}

bridi_tail_start = expr:(ME_clause / NUhA_clause / NU_clause / NA_clause !KU_clause / NAhE_clause !BO_clause / selbri / tag bridi_tail_start / KE_clause bridi_tail_start / bridi_tail) {return _node("bridi_tail_start", expr);}

// BETA: JACU
bridi_tail_1 = expr:(bridi_tail_2 ((gihek / joik_jek) !(stag? BO_clause) !(stag? KE_clause) free* bridi_tail_2 tail_terms)*) {return _node_lg2("bridi_tail_1", expr);} // !LR2

// BETA: JACU
bridi_tail_2 = expr:(CU_elidible free* bridi_tail_3 ((gihek / joik_jek) stag? BO_clause free* bridi_tail_2 tail_terms)?) {return _node("bridi_tail_2", expr);}

// BETA: JACU
bridi_tail_3 = expr:((terms CU_elidible)* selbri tail_terms / gek_sentence) {return _node("bridi_tail_3", expr);}

gek_sentence = expr:(gek subsentence gik subsentence tail_terms / tag* KE_clause free* gek_sentence KEhE_elidible free* / NA_clause free* gek_sentence) {return _node("gek_sentence", expr);}

tail_terms = expr:(terms? VAU_elidible free*) {return _node("tail_terms", expr);}

terms = expr:(terms_1+) {return _node("terms", expr);}

//; terms_1 = terms_2 (PEhE_clause free* joik_jek terms_2)*

//; terms_2 = term (CEhE_clause free* term)*

terms_1 = expr:(terms_2 (pehe_sa* PEhE_clause free* joik_jek terms_2)*) {return _node("terms_1", expr);}

terms_2 = expr:(term (cehe_sa* CEhE_clause free* nonabs_term)*) {return _node("terms_2", expr);}

pehe_sa = expr:(PEhE_clause (!PEhE_clause (sa_word / SA_clause !PEhE_clause))* SA_clause) {return _node("pehe_sa", expr);}

cehe_sa = expr:(CEhE_clause (!CEhE_clause (sa_word / SA_clause !CEhE_clause))* SA_clause) {return _node("cehe_sa", expr);}

//;term = sumti / ( !gek (tag / FA_clause free*) (sumti / KU_elidible free*) ) / termset / NA_clause KU_clause free*

term = expr:(term_sa* term_1) {return _node("term", expr);}

// BEGIN BETA: TERM JA TERM
term_1 = expr:(term_2 (joik_ek term_2)*) {return _node("term_1", expr);}

term_2 = expr:(term_3 (joik_ek? stag? BO_clause term_3)*) {return _node("term_2", expr);}

term_3 = expr:(sumti / tag_term / nontag_adverbial / termset) {return _node("term_3", expr);}

tag_term = expr:(!gek (tag !(!tag selbri) / FA_clause free*) (sumti / KU_elidible free*)) {return _node("tag_term", expr);}

nonabs_term = expr:(term_sa* nonabs_term_1) {return _node("nonabs_term", expr);}

nonabs_term_1 = expr:(nonabs_term_2 (joik_ek term_2)*) {return _node("nonabs_term_1", expr);}

nonabs_term_2 = expr:(nonabs_term_3 (joik_ek? stag? BO_clause term_3)*) {return _node("nonabs_term_2", expr);}

nonabs_term_3 = expr:(sumti / nonabs_tag_term / nontag_adverbial / termset) {return _node("nonabs_term_3", expr);}

nonabs_tag_term = expr:(!gek (tag !(!tag selbri) / FA_clause free*) (sumti / KU_elidible free*)) {return _node("nonabs_tag_term", expr);}

// BETA: NOIhA, New-SOI
nontag_adverbial = expr:(NA_clause free* KU_clause free* / NOIhA_clause free* sumti_tail SEhU_elidible free* / SOI_clause free* subsentence SEhU_elidible free*) {return _node("nontag_adverbial", expr);}
// END BETA: TERM JA TERM

term_sa = expr:(term_start (!term_start (sa_word / SA_clause !term_start ) )* SA_clause &term_1) {return _node("term_sa", expr);}

term_start = expr:(term_1 / LA_clause / LE_clause / LI_clause / LU_clause / LAhE_clause / quantifier term_start / gek sumti gik / FA_clause / tag term_start) {return _node("term_start", expr);}

// BETA: KE-termset
termset = expr:(gek_termset / NUhI_clause free* gek terms NUhU_elidible free* gik terms NUhU_elidible free* / NUhI_clause free* terms NUhU_elidible free* / KE_clause terms KEhE_elidible) {return _node("termset", expr);}

gek_termset = expr:(gek terms_gik_terms) {return _node("gek_termset", expr);}

terms_gik_terms = expr:(nonabs_term (gik / terms_gik_terms) nonabs_term) {return _node("terms_gik_terms", expr);}

// BETA: Enhanced VUhO
sumti = expr:(sumti_1 (VUhO_clause free* (relative_clauses (joik_ek sumti)?)?)?) {return _node("sumti", expr);}

sumti_1 = expr:(sumti_2 (joik_ek stag? KE_clause free* sumti KEhE_elidible free*)?) {return _node("sumti_1", expr);}

sumti_2 = expr:(sumti_3 (joik_ek sumti_3)*) {return _node_lg2("sumti_2", expr);} // !LR2

sumti_3 = expr:(sumti_4 (joik_ek stag? BO_clause free* sumti_3)?) {return _node("sumti_3", expr);}

sumti_4 = expr:(sumti_5 / gek sumti gik sumti_4) {return _node("sumti_4", expr);}

sumti_5 = expr:(quantifier? sumti_6 relative_clauses? / quantifier selbri KU_elidible free* relative_clauses?) {return _node("sumti_5", expr);}

// BETA: NAhE+SUMTI, LAhE+TERM, ZOhOI, LOhOI
sumti_6 = expr:(ZO_clause free* / ZOI_clause free* / ZOhOI_clause free* / LOhU_clause free* / lerfu_string !MOI_clause BOI_elidible free* / LU_clause text LIhU_elidible free* / (LAhE_clause free* / NAhE_clause BO_clause? free*) (relative_clauses? sumti / term) LUhU_elidible free* / KOhA_clause free* / LA_clause free* relative_clauses? CMEVLA_clause+ free* / (LA_clause / LE_clause) free* sumti_tail KU_elidible free* / li_clause / LOhOI_clause free* subsentence KUhAU_clause free*) {return _node("sumti_6", expr);}

li_clause = expr:(LI_clause free* mex LOhO_elidible free*) {return _node("li_clause", expr);}

sumti_tail = expr:((sumti_6 relative_clauses?)? sumti_tail_1 / relative_clauses sumti_tail_1) {return _node("sumti_tail", expr);}

sumti_tail_1 = expr:(selbri relative_clauses? / quantifier selbri relative_clauses? / quantifier sumti) {return _node("sumti_tail_1", expr);}

// BETA: JAPOI
relative_clauses = expr:(relative_clause ((ZIhE_clause / joik_jek) free* relative_clause)* / gek relative_clauses gik relative_clauses) {return _node("relative_clauses", expr);}

//; relative_clause = GOI_clause free* term GEhU_clause? free* / NOI_clause free* subsentence KUhO_clause? free*

relative_clause = expr:(relative_clause_sa* relative_clause_1) {return _node("relative_clause", expr);}

relative_clause_sa = expr:(relative_clause_start (!relative_clause_start (sa_word / SA_clause !relative_clause_start ) )* SA_clause &relative_clause_1) {return _node("relative_clause_sa", expr);}

relative_clause_1 = expr:(GOI_clause free* nonabs_term GEhU_elidible free* / NOI_clause free* subsentence KUhO_elidible free*) {return _node("relative_clause_1", expr);}

relative_clause_start = expr:(GOI_clause / NOI_clause) {return _node("relative_clause_start", expr);}

selbri = expr:(tag? selbri_1) {return _node("selbri", expr);}

selbri_1 = expr:(selbri_2 / NA_clause free* selbri) {return _node("selbri_1", expr);}

selbri_2 = expr:(selbri_3 (CO_clause free* selbri_2)?) {return _node("selbri_2", expr);}

selbri_3 = expr:(selbri_4+) {return _node_lg("selbri_3", expr);} // !LR

selbri_4 = expr:(selbri_5 (joik_jek selbri_5 / joik stag? KE_clause free* selbri_3 KEhE_elidible free*)*) {return _node_lg2("selbri_4", expr);} // !LR2

selbri_5 = expr:(selbri_6 ((jek / joik) stag? BO_clause free* selbri_5)?) {return _node("selbri_5", expr);}

selbri_6 = expr:(tanru_unit (BO_clause free* selbri_6)? / NAhE_clause? free* guhek selbri gik selbri_6) {return _node("selbri_6", expr);}

tanru_unit = expr:(tanru_unit_1 (CEI_clause free* tanru_unit_1)*) {return _node("tanru_unit", expr);}

tanru_unit_1 = expr:(tanru_unit_2 linkargs?) {return _node("tanru_unit_1", expr);}

// ** zei is part of BRIVLA_clause

// BETA: Bare MEX, NUhA+opeator, GOhOI, MEhOI
tanru_unit_2 = expr:(BRIVLA_clause free* / GOhA_clause RAhO_clause? free* / KE_clause free* selbri_3 KEhE_elidible free* / ME_clause free* (sumti / lerfu_string) MEhU_elidible free* MOI_clause? free* / mex MOI_clause free* / NUhA_clause free* operator / SE_clause free* tanru_unit_2 / JAI_clause free* tag? tanru_unit_2 / NAhE_clause free* tanru_unit_2 / NU_clause NAI_clause? free* (joik_jek NU_clause NAI_clause? free*)* subsentence KEI_elidible free* / GOhOI_clause free* / MEhOI_clause free*) {return _node("tanru_unit_2", expr);}

//; linkargs = BE_clause free* term links? BEhO_clause? free*

linkargs = expr:(linkargs_sa* linkargs_1) {return _node("linkargs", expr);}

linkargs_1 = expr:(BE_clause free* nonabs_term links? BEhO_elidible free*) {return _node("linkargs_1", expr);}

linkargs_sa = expr:(linkargs_start (!linkargs_start (sa_word / SA_clause !linkargs_start ) )* SA_clause &linkargs_1) {return _node("linkargs_sa", expr);}

linkargs_start = expr:(BE_clause) {return _node("linkargs_start", expr);}

//; links = BEI_clause free* term links?

links = expr:(links_sa* links_1) {return _node("links", expr);}

links_1 = expr:(BEI_clause free* nonabs_term links?) {return _node("links_1", expr);}

links_sa = expr:(links_start (!links_start (sa_word / SA_clause !links_start ) )* SA_clause &links_1) {return _node("links_sa", expr);}

links_start = expr:(BEI_clause) {return _node("links_start", expr);}

// BEGIN BETA: MEX simplification
quantifier = expr:(!selbri !sumti_6 mex) {return _node("quantifier", expr);}

//;mex = mex_1 (operator mex_1)* / rp_clause

mex = expr:(mex_1 (operator mex_1)*) {return _node("mex", expr);}

mex_1 = expr:(mex_2 (operator stag? BO_clause free* mex_1)?) {return _node("mex_1", expr);}

mex_2 = expr:(number BOI_elidible free* / lerfu_string BOI_elidible free* / VEI_clause free* mex VEhO_elidible free* / NIhE_clause free* selbri TEhU_elidible free* / MOhE_clause sumti TEhU_elidible free* / gek mex gik mex_2 / (LAhE_clause free* / NAhE_clause free* BO_clause? free*) mex LUhU_elidible free* / PEhO_clause free* operator mex+ KUhE_elidible free* / FUhA_clause rp_expression) {return _node("mex_2", expr);}

rp_expression = expr:(mex_1 (rp_expression operator)*) {return _node("rp_expression", expr);}

// END BETA: MEX simplification

//; operator = operator_1 (joik_jek operator_1 / joik stag? KE_clause free* operator KEhE_clause? free*)*

operator = expr:(operator_sa* operator_0) {return _node("operator", expr);}

operator_0 = expr:(operator_1 (joik_jek operator_1 / joik stag? KE_clause free* operator KEhE_elidible free*)*) {return _node("operator_0", expr);}

operator_sa = expr:(operator_start (!operator_start (sa_word / SA_clause !operator_start) )* SA_clause &operator_0) {return _node("operator_sa", expr);}

operator_start = expr:(guhek / KE_clause / SE_clause? NAhE_clause / SE_clause? MAhO_clause / SE_clause? VUhU_clause) {return _node("operator_start", expr);}

// BETA: MEX simplification
operator_1 = expr:(guhek operator_1 gik operator_2 / operator_2 (jek / joik) stag? BO_clause free* operator_1 / operator_2) {return _node("operator_1", expr);}

operator_2 = expr:(mex_operator / KE_clause free* operator KEhE_elidible free*) {return _node("operator_2", expr);}

// BETA: MEX simplification
mex_operator = expr:(SE_clause free* mex_operator / NAhE_clause free* mex_operator / MAhO_clause free* mex TEhU_elidible free* / NAhU_clause free* selbri TEhU_elidible free* / VUhU_clause free* / joik_jek free* / ek free*) {return _node("mex_operator", expr);}

//; operand = operand_1 (joik_ek stag? KE_clause free* operand KEhE_clause? free*)?

operand = expr:(operand_sa* operand_0) {return _node("operand", expr);}

operand_0 = expr:(operand_1 (joik_ek stag? KE_clause free* operand KEhE_elidible free*)?) {return _node("operand_0", expr);}

operand_sa = expr:(operand_start (!operand_start (sa_word / SA_clause !operand_start) )* SA_clause &operand_0) {return _node("operand_sa", expr);}

operand_start = expr:(quantifier / lerfu_word / NIhE_clause / MOhE_clause / JOhI_clause / gek / LAhE_clause / NAhE_clause) {return _node("operand_start", expr);}

operand_1 = expr:(operand_2 (joik_ek operand_2)*) {return _node("operand_1", expr);}

operand_2 = expr:(operand_3 (joik_ek stag? BO_clause free* operand_2)?) {return _node("operand_2", expr);}

// BETA: NAhE+SUMTI
operand_3 = expr:(quantifier / lerfu_string !MOI_clause BOI_elidible free* / NIhE_clause free* selbri TEhU_elidible free* / MOhE_clause free* sumti TEhU_elidible free* / JOhI_clause free* mex_2+ TEhU_elidible free* / gek operand gik operand_3 / (LAhE_clause free* / NAhE_clause BO_clause? free*) operand LUhU_elidible free*) {return _node("operand_3", expr);}

// BETA: MEX simplification
// FIXME: forethought mex not possible anymore without pe'o. BIhE_clause isn't referenced anymore.
number = expr:((PA_clause / (NIhE_clause free* selbri TEhU_elidible free*) / (MOhE_clause free* sumti TEhU_elidible free*)) (PA_clause / (NIhE_clause free* selbri TEhU_elidible free*) / (MOhE_clause free* sumti TEhU_elidible free*))*) {return _node("number", expr);}

lerfu_string = expr:(lerfu_word (PA_clause / lerfu_word)*) {return _node("lerfu_string", expr);}

// ** BU clauses are part of BY_clause
lerfu_word = expr:(BY_clause / LAU_clause lerfu_word / TEI_clause lerfu_string FOI_clause) {return _node("lerfu_word", expr);}

ek = expr:(NA_clause? SE_clause? A_clause NAI_clause?) {return _node("ek", expr);}

//; gihek = NA_clause? SE_clause? GIhA_clause NAI_clause?
gihek = expr:(gihek_sa* gihek_1) {return _node("gihek", expr);}

gihek_1 = expr:(NA_clause? SE_clause? GIhA_clause NAI_clause?) {return _node("gihek_1", expr);}

gihek_sa = expr:(gihek_1 (!gihek_1 (sa_word / SA_clause !gihek_1 ) )* SA_clause &gihek) {return _node("gihek_sa", expr);}

// BETA: NAhU included in jek
jek = expr:(NA_clause? SE_clause? (JA_clause / NAhU_clause free* selbri TEhU_elidible free*) NAI_clause?) {return _node("jek", expr);}

joik = expr:(SE_clause? JOI_clause NAI_clause? / interval / GAhO_clause interval GAhO_clause) {return _node("joik", expr);}

interval = expr:(SE_clause? BIhI_clause NAI_clause?) {return _node("interval", expr);}

//; joik_ek = joik free* / ek free*
joik_ek = expr:(joik_ek_sa* joik_ek_1) {return _node("joik_ek", expr);}

// BETA: A/JA/JOI/VUhU Merger
joik_ek_1 = expr:(joik_jek) {return _node("joik_ek_1", expr);}

joik_ek_sa = expr:(joik_ek_1 (!joik_ek_1 (sa_word / SA_clause !joik_ek_1 ) )* SA_clause &joik_ek) {return _node("joik_ek_sa", expr);}

// BETA: A/JA/JOI/VUhU Merger
joik_jek = expr:(joik free* / ek free* / jek free* / VUhU_clause free*) {return _node("joik_jek", expr);}

// BETA: gaJA
gek = expr:(gak SE_clause? joik_jek / SE_clause? GA_clause free* / joik GI_clause free* / stag gik) {return _node("gek", expr);}

// BETA: gaJA
gak = expr:(ga_clause !gek free*) {return _node("gak", expr);}

// BETA: guJA
guhek = expr:(guk SE_clause? joik_jek / SE_clause? GUhA_clause NAI_clause? free*) {return _node("guhek", expr);}

// BETA: guJA
guk = expr:(gu_clause !gek free*) {return _node("guk", expr);}

gik = expr:(GI_clause NAI_clause? free*) {return _node("gik", expr);}

tag = expr:(tense_modal (joik_jek tense_modal)*) {return _node("tag", expr);}

//stag = simple_tense_modal ((jek / joik) simple_tense_modal)*

// BETA: Tag simplification
stag = expr:(tense_modal (joik_jek tense_modal)*) {return _node("stag", expr);}

// BETA: Tag simplification (dependency: NAI ∈ indicator)
// FIXME: Cannot use bare MEX with ROI.
tense_modal = expr:(((NAhE_clause? SE_clause? (BAI_clause / CAhA_clause / CUhE_clause / KI_clause / ZI_clause / PU_clause / VA_clause / MOhI_clause? FAhA_clause / ZEhA_clause / VEhA_clause / VIhA_clause / FEhE_clause? (VEI_clause free* mex VEhO_elidible free* / number) ROI_clause / FEhE_clause? TAhE_clause / FEhE_clause? ZAhO_clause / FIhO_clause free* selbri FEhU_elidible free* / FA_clause) free*)+)) {return _node("tense_modal", expr);}

// BETA: Bare MEX, LOhAI, Removal of Old-SOI
free = expr:(SEI_clause free* (terms CU_elidible free*)? selbri SEhU_elidible / vocative relative_clauses? selbri relative_clauses? DOhU_elidible / vocative relative_clauses? CMEVLA_clause+ free* relative_clauses? DOhU_elidible / vocative sumti? DOhU_elidible / mex_2 MAI_clause free* / TO_clause text TOI_elidible / xi_clause / LOhAI_clause) {return _node("free", expr);}

// BETA: Bare MEX
xi_clause = expr:(XI_clause free* mex_2 / XI_clause free* VEI_clause free* mex VEhO_elidible) {return _node("xi_clause", expr);}

vocative = expr:((COI_clause NAI_clause?)+ DOI_clause / (COI_clause NAI_clause?) (COI_clause NAI_clause?)* / DOI_clause) {return _node("vocative", expr);}

indicators = expr:(FUhE_clause? indicator+) {return _node("indicators", expr);}

// BETA: NAI ∈ indicator
indicator = expr:(((UI_clause / CAI_clause) NAI_clause? / NAI_clause / DAhO_clause / FUhO_clause) !BU_clause) {return _node("indicator", expr);}


// ****************
// Magic Words
// ****************

zei_clause = expr:(pre_clause zei_clause_no_pre) {return _node("zei_clause", expr);}
zei_clause_no_pre = expr:(pre_zei_bu (zei_tail? BU_clause+)* zei_tail post_clause) {return _node_lg("zei_clause_no_pre", expr);} // !LR
// zei_clause_no_SA = pre_zei_bu_no_SA (zei_tail? bu_tail)* zei_tail

bu_clause = expr:(pre_clause bu_clause_no_pre) {return _node("bu_clause", expr);}
bu_clause_no_pre = expr:(pre_zei_bu (BU_clause* zei_tail)* BU_clause+ post_clause) {return _node_lg("bu_clause_no_pre", expr);} // !LR
// bu_clause_no_SA = pre_zei_bu_no_SA (bu_tail? zei_tail)* bu_tail

zei_tail = expr:((ZEI_clause any_word)+) {return _node("zei_tail", expr);}
bu_tail = expr:(BU_clause+) {return _node("bu_tail", expr);} // Obsolete: please use BU_clause+ instead for allowing later left-grouping faking.

pre_zei_bu = expr:(!ZOI_start !BU_clause !ZEI_clause !SI_clause !SA_clause !SU_clause !FAhO_clause any_word_SA_handling si_clause?) {return _node("pre_zei_bu", expr);}
// LOhU_pre / ZO_pre / ZOI_pre / !ZEI_clause !BU_clause !FAhO_clause !SI_clause !SA_clause !SU_clause any_word_SA_handling si_clause?
// pre_zei_bu_no_SA = LOhU_pre / ZO_pre / ZOI_pre / !ZEI_clause !BU_clause !FAhO_clause !SI_clause !SA_clause !SU_clause any_word si_clause?

dot_star = expr:(.*) {return ["dot_star", _join(expr)];}

// __ General Morphology Issues
//
// 1.  Spaces (including '.y') and UI are eaten *after* a word.
//
// 3.  BAhE is eaten *before* a word.

// Handling of what can go after a cmavo
post_clause = expr:(spaces? si_clause? !ZEI_clause !BU_clause indicators*) {return _node("post_clause", expr);}

pre_clause = expr:(BAhE_clause*) {return _node_lg("pre_clause", expr);} // !LR

//any_word_SA_handling = BRIVLA_pre / known_cmavo_SA / !known_cmavo_pre CMAVO_pre / CMEVLA_pre
any_word_SA_handling = expr:(BRIVLA_pre / known_cmavo_SA / CMAVO_pre / CMEVLA_pre) {return _node("any_word_SA_handling", expr);}

known_cmavo_SA = expr:(A_pre / BAI_pre / BAhE_pre / BE_pre / BEI_pre / BEhO_pre / BIhE_pre / BIhI_pre / BO_pre / BOI_pre / BU_pre / BY_pre / CAI_pre / CAhA_pre / CEI_pre / CEhE_pre / CO_pre / COI_pre / CU_pre / CUhE_pre / DAhO_pre / DOI_pre / DOhU_pre / FA_pre / FAhA_pre / FEhE_pre / FEhU_pre / FIhO_pre / FOI_pre / FUhA_pre / FUhE_pre / FUhO_pre / GA_pre / GAhO_pre / GEhU_pre / GI_pre / GIhA_pre / GOI_pre / GOhA_pre / GUhA_pre / I_pre / JA_pre / JAI_pre / JOI_pre / JOhI_pre / KE_pre / KEI_pre / KEhE_pre / KI_pre / KOhA_pre / KU_pre / KUhE_pre / KUhO_pre / LA_pre / LAU_pre / LAhE_pre / LE_pre / LEhU_pre / LI_pre / LIhU_pre / LOhO_pre / LOhU_pre / LU_pre / LUhU_pre / MAI_pre / MAhO_pre / ME_pre / MEhU_pre / MOI_pre / MOhE_pre / MOhI_pre / NA_pre / NAI_pre / NAhE_pre / NAhU_pre / NIhE_pre / NIhO_pre / NOI_pre / NU_pre / NUhA_pre / NUhI_pre / NUhU_pre / PA_pre / PEhE_pre / PEhO_pre / PU_pre / RAhO_pre / ROI_pre / SA_pre / SE_pre / SEI_pre / SEhU_pre / SI_clause / SOI_pre / SU_pre / TAhE_pre / TEI_pre / TEhU_pre / TO_pre / TOI_pre / TUhE_pre / TUhU_pre / UI_pre / VA_pre / VAU_pre / VEI_pre / VEhA_pre / VEhO_pre / VIhA_pre / VUhO_pre / VUhU_pre / XI_pre / ZAhO_pre / ZEI_pre / ZEhA_pre / ZI_pre / ZIhE_pre / ZO_pre / ZOI_pre / ZOhU_pre) {return _node("known_cmavo_SA", expr);}

// Handling of spaces and things like spaces.
// ___ SPACE ___
// Do *NOT* delete the line above!

// SU clauses
su_clause = expr:((erasable_clause / su_word)* SU_clause) {return _node("su_clause", expr);}

// Handling of SI and interactions with zo and lo'u...le'u

si_clause = expr:(((erasable_clause / si_word / SA_clause) si_clause? SI_clause)+) {return _node("si_clause", expr);}

erasable_clause = expr:(bu_clause_no_pre !ZEI_clause !BU_clause / zei_clause_no_pre !ZEI_clause !BU_clause) {return _node("erasable_clause", expr);}

sa_word = expr:(pre_zei_bu) {return _node("sa_word", expr);}

si_word = expr:(pre_zei_bu) {return _node("si_word", expr);}

su_word = expr:(!ZOI_start !NIhO_clause !LU_clause !TUhE_clause !TO_clause !SU_clause !FAhO_clause any_word_SA_handling) {return _node("su_word", expr);}


// ___ ELIDIBLE TERMINATORS ___

// BETA: IAU
BEhO_elidible = expr:(BEhO_clause?) {return (expr == "" || !expr) ? ["BEhO"] : _node_empty("BEhO_elidible", expr);}
BOI_elidible = expr:(BOI_clause?) {return (expr == "" || !expr) ? ["BOI"] : _node_empty("BOI_elidible", expr);}
CU_elidible = expr:(CU_clause?) {return (expr == "" || !expr) ? ["CU"] : _node_empty("CU_elidible", expr);}
DOhU_elidible = expr:(DOhU_clause?) {return (expr == "" || !expr) ? ["DOhU"] : _node_empty("DOhU_elidible", expr);}
FEhU_elidible = expr:(FEhU_clause?) {return (expr == "" || !expr) ? ["FEhU"] : _node_empty("FEhU_elidible", expr);}
// FOI and FUhO are never elidible
GEhU_elidible = expr:(GEhU_clause?) {return (expr == "" || !expr) ? ["GEhU"] : _node_empty("GEhU_elidible", expr);}
IAU_elidible = expr:(IAU_clause?) {return (expr == "" || !expr) ? ["IAU"] : _node_empty("IAU_elidible", expr);}
KEI_elidible = expr:(KEI_clause?) {return (expr == "" || !expr) ? ["KEI"] : _node_empty("KEI_elidible", expr);}
KEhE_elidible = expr:(KEhE_clause?) {return (expr == "" || !expr) ? ["KEhE"] : _node_empty("KEhE_elidible", expr);}
KU_elidible = expr:(KU_clause?) {return (expr == "" || !expr) ? ["KU"] : _node_empty("KU_elidible", expr);}
KUhE_elidible = expr:(KUhE_clause?) {return (expr == "" || !expr) ? ["KUhE"] : _node_empty("KUhE_elidible", expr);}
KUhO_elidible = expr:(KUhO_clause?) {return (expr == "" || !expr) ? ["KUhO"] : _node_empty("KUhO_elidible", expr);}
// LEhU is never elidible
LIhU_elidible = expr:(LIhU_clause?) {return (expr == "" || !expr) ? ["LIhU"] : _node_empty("LIhU_elidible", expr);}
LOhO_elidible = expr:(LOhO_clause?) {return (expr == "" || !expr) ? ["LOhO"] : _node_empty("LOhO_elidible", expr);}
LUhU_elidible = expr:(LUhU_clause?) {return (expr == "" || !expr) ? ["LUhU"] : _node_empty("LUhU_elidible", expr);}
MEhU_elidible = expr:(MEhU_clause?) {return (expr == "" || !expr) ? ["MEhU"] : _node_empty("MEhU_elidible", expr);}
NUhU_elidible = expr:(NUhU_clause?) {return (expr == "" || !expr) ? ["NUhU"] : _node_empty("NUhU_elidible", expr);}
SEhU_elidible = expr:(SEhU_clause?) {return (expr == "" || !expr) ? ["SEhU"] : _node_empty("SEhU_elidible", expr);}
TEhU_elidible = expr:(TEhU_clause?) {return (expr == "" || !expr) ? ["TEhU"] : _node_empty("TEhU_elidible", expr);}
TOI_elidible = expr:(TOI_clause?) {return (expr == "" || !expr) ? ["TOI"] : _node_empty("TOI_elidible", expr);}
TUhU_elidible = expr:(TUhU_clause?) {return (expr == "" || !expr) ? ["TUhU"] : _node_empty("TUhU_elidible", expr);}
VAU_elidible = expr:(VAU_clause?) {return (expr == "" || !expr) ? ["VAU"] : _node_empty("VAU_elidible", expr);}
VEhO_elidible = expr:(VEhO_clause?) {return (expr == "" || !expr) ? ["VEhO"] : _node_empty("VEhO_elidible", expr);}


// ___ SELMAHO ___
// Do *NOT* delete the line above!

BRIVLA_clause = expr:(BRIVLA_pre BRIVLA_post / zei_clause) {return _node("BRIVLA_clause", expr);}
BRIVLA_pre = expr:(pre_clause BRIVLA spaces?) {return _node("BRIVLA_pre", expr);}
BRIVLA_post = expr:(post_clause) {return _node("BRIVLA_post", expr);}
// BRIVLA_no_SA_handling = pre_clause BRIVLA post_clause / zei_clause_no_SA

CMEVLA_clause = expr:(CMEVLA_pre CMEVLA_post) {return _node("CMEVLA_clause", expr);}
CMEVLA_pre = expr:(pre_clause CMEVLA spaces?) {return _node("CMEVLA_pre", expr);}
CMEVLA_post = expr:(post_clause) {return _node("CMEVLA_post", expr);}
// CMEVLA_no_SA_handling = pre_clause CMEVLA post_clause

CMAVO_clause = expr:(CMAVO_pre CMAVO_post) {return _node("CMAVO_clause", expr);}
CMAVO_pre = expr:(pre_clause CMAVO spaces?) {return _node("CMAVO_pre", expr);}
CMAVO_post = expr:(post_clause) {return _node("CMAVO_post", expr);}
// CMAVO_no_SA_handling = pre_clause CMAVO post_clause

//         eks; basic afterthought logical connectives
A_clause = expr:(A_pre A_post) {return _node("A_clause", expr);}
A_pre = expr:(pre_clause A spaces?) {return _node("A_pre", expr);}
A_post = expr:(post_clause) {return _node("A_post", expr);}
// A_no_SA_handling = pre_clause A post_clause


//         modal operators
BAI_clause = expr:(BAI_pre BAI_post) {return _node("BAI_clause", expr);}
BAI_pre = expr:(pre_clause BAI spaces?) {return _node("BAI_pre", expr);}
BAI_post = expr:(post_clause) {return _node("BAI_post", expr);}
// BAI_no_SA_handling = pre_clause BAI post_clause

//         next word intensifier
BAhE_clause = expr:(BAhE_pre BAhE_post) {return _node("BAhE_clause", expr);}
BAhE_pre = expr:(BAhE spaces?) {return _node("BAhE_pre", expr);}
BAhE_post = expr:(si_clause? !ZEI_clause !BU_clause) {return _node("BAhE_post", expr);}
// BAhE_no_SA_handling = BAhE spaces? BAhE_post

//         sumti link to attach sumti to a selbri
BE_clause = expr:(BE_pre BE_post) {return _node("BE_clause", expr);}
BE_pre = expr:(pre_clause BE spaces?) {return _node("BE_pre", expr);}
BE_post = expr:(post_clause) {return _node("BE_post", expr);}
// BE_no_SA_handling = pre_clause BE post_clause

//         multiple sumti separator between BE, BEI
BEI_clause = expr:(BEI_pre BEI_post) {return _node("BEI_clause", expr);}
BEI_pre = expr:(pre_clause BEI spaces?) {return _node("BEI_pre", expr);}
BEI_post = expr:(post_clause) {return _node("BEI_post", expr);}
// BEI_no_SA_handling = pre_clause BEI post_clause

//         terminates BEBEI specified descriptors
BEhO_clause = expr:(BEhO_pre BEhO_post) {return _node("BEhO_clause", expr);}
BEhO_pre = expr:(pre_clause BEhO spaces?) {return _node("BEhO_pre", expr);}
BEhO_post = expr:(post_clause) {return _node("BEhO_post", expr);}
// BEhO_no_SA_handling = pre_clause BEhO post_clause

//         prefix for high_priority MEX operator
BIhE_clause = expr:(BIhE_pre BIhE_post) {return _node("BIhE_clause", expr);}
BIhE_pre = expr:(pre_clause BIhE spaces?) {return _node("BIhE_pre", expr);}
BIhE_post = expr:(post_clause) {return _node("BIhE_post", expr);}
// BIhE_no_SA_handling = pre_clause BIhE post_clause

//         interval component of JOI
BIhI_clause = expr:(BIhI_pre BIhI_post) {return _node("BIhI_clause", expr);}
BIhI_pre = expr:(pre_clause BIhI spaces?) {return _node("BIhI_pre", expr);}
BIhI_post = expr:(post_clause) {return _node("BIhI_post", expr);}
// BIhI_no_SA_handling = pre_clause BIhI post_clause

//         joins two units with shortest scope
BO_clause = expr:(BO_pre BO_post) {return _node("BO_clause", expr);}
BO_pre = expr:(pre_clause BO spaces?) {return _node("BO_pre", expr);}
BO_post = expr:(post_clause) {return _node("BO_post", expr);}
// BO_no_SA_handling = pre_clause BO post_clause

//         number or lerfu_string terminator
BOI_clause = expr:(BOI_pre BOI_post) {return _node("BOI_clause", expr);}
BOI_pre = expr:(pre_clause BOI spaces?) {return _node("BOI_pre", expr);}
BOI_post = expr:(post_clause) {return _node("BOI_post", expr);}
// BOI_no_SA_handling = pre_clause BOI post_clause

//         turns any word into a BY lerfu word
BU_clause = expr:(BU_pre BU_post) {return _node("BU_clause", expr);}
// BU_clause_no_SA = BU_pre_no_SA BU BU_post
BU_pre = expr:(pre_clause BU spaces?) {return _node("BU_pre", expr);}
// BU_pre_no_SA = pre_clause
BU_post = expr:(spaces?) {return _node("BU_post", expr);}
// BU_no_SA_handling = pre_clause BU spaces?

//         individual lerfu words
BY_clause = expr:(BY_pre BY_post / bu_clause) {return _node("BY_clause", expr);}
BY_pre = expr:(pre_clause BY spaces?) {return _node("BY_pre", expr);}
BY_post = expr:(post_clause) {return _node("BY_post", expr);}
// BY_no_SA_handling = pre_clause BY post_clause / bu_clause_no_SA


//         specifies actualitypotentiality of tense
CAhA_clause = expr:(CAhA_pre CAhA_post) {return _node("CAhA_clause", expr);}
CAhA_pre = expr:(pre_clause CAhA spaces?) {return _node("CAhA_pre", expr);}
CAhA_post = expr:(post_clause) {return _node("CAhA_post", expr);}
// CAhA_no_SA_handling = pre_clause CAhA post_clause

//         afterthought intensity marker
CAI_clause = expr:(CAI_pre CAI_post) {return _node("CAI_clause", expr);}
CAI_pre = expr:(pre_clause CAI spaces?) {return _node("CAI_pre", expr);}
CAI_post = expr:(post_clause) {return _node("CAI_post", expr);}
// CAI_no_SA_handling = pre_clause CAI post_clause

//         pro_bridi assignment operator
CEI_clause = expr:(CEI_pre CEI_post) {return _node("CEI_clause", expr);}
CEI_pre = expr:(pre_clause CEI spaces?) {return _node("CEI_pre", expr);}
CEI_post = expr:(post_clause) {return _node("CEI_post", expr);}
// CEI_no_SA_handling = pre_clause CEI post_clause

//         afterthought term list connective
CEhE_clause = expr:(CEhE_pre CEhE_post) {return _node("CEhE_clause", expr);}
CEhE_pre = expr:(pre_clause CEhE spaces?) {return _node("CEhE_pre", expr);}
CEhE_post = expr:(post_clause) {return _node("CEhE_post", expr);}
// CEhE_no_SA_handling = pre_clause CEhE post_clause

//         names; require consonant end, then pause no

//                                    LA or DOI selma'o embedded, pause before if

//                                    vowel initial and preceded by a vowel

//         tanru inversion
CO_clause = expr:(CO_pre CO_post) {return _node("CO_clause", expr);}
CO_pre = expr:(pre_clause CO spaces?) {return _node("CO_pre", expr);}
CO_post = expr:(post_clause) {return _node("CO_post", expr);}
// CO_no_SA_handling = pre_clause CO post_clause

COI_clause = expr:(COI_pre COI_post) {return _node("COI_clause", expr);}
COI_pre = expr:(pre_clause COI spaces?) {return _node("COI_pre", expr);}
COI_post = expr:(post_clause) {return _node("COI_post", expr);}
// COI_no_SA_handling = pre_clause COI post_clause

//         vocative marker permitted inside names; must

//                                    always be followed by pause or DOI

//         separator between head sumti and selbri
CU_clause = expr:(CU_pre CU_post) {return _node("CU_clause", expr);}
CU_pre = expr:(pre_clause CU spaces?) {return _node("CU_pre", expr);}
CU_post = expr:(post_clause) {return _node("CU_post", expr);}
// CU_no_SA_handling = pre_clause CU post_clause

//         tensemodal question
CUhE_clause = expr:(CUhE_pre CUhE_post) {return _node("CUhE_clause", expr);}
CUhE_pre = expr:(pre_clause CUhE spaces?) {return _node("CUhE_pre", expr);}
CUhE_post = expr:(post_clause) {return _node("CUhE_post", expr);}
// CUhE_no_SA_handling = pre_clause CUhE post_clause


//         cancel anaphoracataphora assignments
DAhO_clause = expr:(DAhO_pre DAhO_post) {return _node("DAhO_clause", expr);}
DAhO_pre = expr:(pre_clause DAhO spaces?) {return _node("DAhO_pre", expr);}
DAhO_post = expr:(post_clause) {return _node("DAhO_post", expr);}
// DAhO_no_SA_handling = pre_clause DAhO post_clause

//         vocative marker
DOI_clause = expr:(DOI_pre DOI_post) {return _node("DOI_clause", expr);}
DOI_pre = expr:(pre_clause DOI spaces?) {return _node("DOI_pre", expr);}
DOI_post = expr:(post_clause) {return _node("DOI_post", expr);}
// DOI_no_SA_handling = pre_clause DOI post_clause

//         terminator for DOI_marked vocatives
DOhU_clause = expr:(DOhU_pre DOhU_post) {return _node("DOhU_clause", expr);}
DOhU_pre = expr:(pre_clause DOhU spaces?) {return _node("DOhU_pre", expr);}
DOhU_post = expr:(post_clause) {return _node("DOhU_post", expr);}
// DOhU_no_SA_handling = pre_clause DOhU post_clause


//         modifier head generic case tag
FA_clause = expr:(FA_pre FA_post) {return _node("FA_clause", expr);}
FA_pre = expr:(pre_clause FA spaces?) {return _node("FA_pre", expr);}
FA_post = expr:(post_clause) {return _node("FA_post", expr);}
// FA_no_SA_handling = pre_clause FA post_clause

//         superdirections in space
FAhA_clause = expr:(FAhA_pre FAhA_post) {return _node("FAhA_clause", expr);}
FAhA_pre = expr:(pre_clause FAhA spaces?) {return _node("FAhA_pre", expr);}
FAhA_post = expr:(post_clause) {return _node("FAhA_post", expr);}
// FAhA_no_SA_handling = pre_clause FAhA post_clause


//         normally elided 'done pause' to indicate end
//                                    of utterance string

FAhO_clause = expr:(pre_clause FAhO spaces?) {return _node("FAhO_clause", expr);}

//         space interval mod flag
FEhE_clause = expr:(FEhE_pre FEhE_post) {return _node("FEhE_clause", expr);}
FEhE_pre = expr:(pre_clause FEhE spaces?) {return _node("FEhE_pre", expr);}
FEhE_post = expr:(post_clause) {return _node("FEhE_post", expr);}
// FEhE_no_SA_handling = pre_clause FEhE post_clause

//         ends bridi to modal conversion
FEhU_clause = expr:(FEhU_pre FEhU_post) {return _node("FEhU_clause", expr);}
FEhU_pre = expr:(pre_clause FEhU spaces?) {return _node("FEhU_pre", expr);}
FEhU_post = expr:(post_clause) {return _node("FEhU_post", expr);}
// FEhU_no_SA_handling = pre_clause FEhU post_clause

//         marks bridi to modal conversion
FIhO_clause = expr:(FIhO_pre FIhO_post) {return _node("FIhO_clause", expr);}
FIhO_pre = expr:(pre_clause FIhO spaces?) {return _node("FIhO_pre", expr);}
FIhO_post = expr:(post_clause) {return _node("FIhO_post", expr);}
// FIhO_no_SA_handling = pre_clause FIhO post_clause

//         end compound lerfu
FOI_clause = expr:(FOI_pre FOI_post) {return _node("FOI_clause", expr);}
FOI_pre = expr:(pre_clause FOI spaces?) {return _node("FOI_pre", expr);}
FOI_post = expr:(post_clause) {return _node("FOI_post", expr);}
// FOI_no_SA_handling = pre_clause FOI post_clause

//         reverse Polish flag
FUhA_clause = expr:(FUhA_pre FUhA_post) {return _node("FUhA_clause", expr);}
FUhA_pre = expr:(pre_clause FUhA spaces?) {return _node("FUhA_pre", expr);}
FUhA_post = expr:(post_clause) {return _node("FUhA_post", expr);}
// FUhA_no_SA_handling = pre_clause FUhA post_clause

//         open long scope for indicator
FUhE_clause = expr:(FUhE_pre FUhE_post) {return _node("FUhE_clause", expr);}
FUhE_pre = expr:(pre_clause FUhE spaces?) {return _node("FUhE_pre", expr);}
FUhE_post = expr:(!BU_clause spaces? !ZEI_clause !BU_clause) {return _node("FUhE_post", expr);}
// FUhE_no_SA_handling = pre_clause FUhE post_clause

//         close long scope for indicator
FUhO_clause = expr:(FUhO_pre FUhO_post) {return _node("FUhO_clause", expr);}
FUhO_pre = expr:(pre_clause FUhO spaces?) {return _node("FUhO_pre", expr);}
FUhO_post = expr:(post_clause) {return _node("FUhO_post", expr);}
// FUhO_no_SA_handling = pre_clause FUhO post_clause


//         geks; forethought logical connectives
GA_clause = expr:(GA_pre GA_post) {return _node("GA_clause", expr);}
GA_pre = expr:(pre_clause GA spaces?) {return _node("GA_pre", expr);}
GA_post = expr:(post_clause) {return _node("GA_post", expr);}
// GA_no_SA_handling = pre_clause GA post_clause

//         openclosed interval markers for BIhI
GAhO_clause = expr:(GAhO_pre GAhO_post) {return _node("GAhO_clause", expr);}
GAhO_pre = expr:(pre_clause GAhO spaces?) {return _node("GAhO_pre", expr);}
GAhO_post = expr:(post_clause) {return _node("GAhO_post", expr);}
// GAhO_no_SA_handling = pre_clause GAhO post_clause

//         marker ending GOI relative clauses
GEhU_clause = expr:(GEhU_pre GEhU_post) {return _node("GEhU_clause", expr);}
GEhU_pre = expr:(pre_clause GEhU spaces?) {return _node("GEhU_pre", expr);}
GEhU_post = expr:(post_clause) {return _node("GEhU_post", expr);}
// GEhU_no_SA_handling = pre_clause GEhU post_clause

//         forethought medial marker
GI_clause = expr:(GI_pre GI_post) {return _node("GI_clause", expr);}
GI_pre = expr:(pre_clause GI spaces?) {return _node("GI_pre", expr);}
GI_post = expr:(post_clause) {return _node("GI_post", expr);}
// GI_no_SA_handling = pre_clause GI post_clause

//         logical connectives for bridi_tails
GIhA_clause = expr:(GIhA_pre GIhA_post) {return _node("GIhA_clause", expr);}
GIhA_pre = expr:(pre_clause GIhA spaces?) {return _node("GIhA_pre", expr);}
GIhA_post = expr:(post_clause) {return _node("GIhA_post", expr);}
// GIhA_no_SA_handling = pre_clause GIhA post_clause

//         attaches a sumti modifier to a sumti
GOI_clause = expr:(GOI_pre GOI_post) {return _node("GOI_clause", expr);}
GOI_pre = expr:(pre_clause GOI spaces?) {return _node("GOI_pre", expr);}
GOI_post = expr:(post_clause) {return _node("GOI_post", expr);}
// GOI_no_SA_handling = pre_clause GOI post_clause

//         pro_bridi
GOhA_clause = expr:(GOhA_pre GOhA_post) {return _node("GOhA_clause", expr);}
GOhA_pre = expr:(pre_clause GOhA spaces?) {return _node("GOhA_pre", expr);}
GOhA_post = expr:(post_clause) {return _node("GOhA_post", expr);}
// GOhA_no_SA_handling = pre_clause GOhA post_clause

//         GEK for tanru units, corresponds to JEKs
GUhA_clause = expr:(GUhA_pre GUhA_post) {return _node("GUhA_clause", expr);}
GUhA_pre = expr:(pre_clause GUhA spaces?) {return _node("GUhA_pre", expr);}
GUhA_post = expr:(post_clause) {return _node("GUhA_post", expr);}
// GUhA_no_SA_handling = pre_clause GUhA post_clause


//         sentence link
I_clause = expr:(sentence_sa* I_pre I_post) {return _node("I_clause", expr);}
I_pre = expr:(pre_clause I spaces?) {return _node("I_pre", expr);}
I_post = expr:(post_clause) {return _node("I_post", expr);}
// I_no_SA_handling = pre_clause I post_clause


//         jeks; logical connectives within tanru
JA_clause = expr:(JA_pre JA_post) {return _node("JA_clause", expr);}
JA_pre = expr:(pre_clause JA spaces?) {return _node("JA_pre", expr);}
JA_post = expr:(post_clause) {return _node("JA_post", expr);}
// JA_no_SA_handling = pre_clause JA post_clause

//         modal conversion flag
JAI_clause = expr:(JAI_pre JAI_post) {return _node("JAI_clause", expr);}
JAI_pre = expr:(pre_clause JAI spaces?) {return _node("JAI_pre", expr);}
JAI_post = expr:(post_clause) {return _node("JAI_post", expr);}
// JAI_no_SA_handling = pre_clause JAI post_clause

//         flags an array operand
JOhI_clause = expr:(JOhI_pre JOhI_post) {return _node("JOhI_clause", expr);}
JOhI_pre = expr:(pre_clause JOhI spaces?) {return _node("JOhI_pre", expr);}
JOhI_post = expr:(post_clause) {return _node("JOhI_post", expr);}
// JOhI_no_SA_handling = pre_clause JOhI post_clause

//         non_logical connectives
JOI_clause = expr:(JOI_pre JOI_post) {return _node("JOI_clause", expr);}
JOI_pre = expr:(pre_clause JOI spaces?) {return _node("JOI_pre", expr);}
JOI_post = expr:(post_clause) {return _node("JOI_post", expr);}
// JOI_no_SA_handling = pre_clause JOI post_clause


//         left long scope marker
KE_clause = expr:(KE_pre KE_post) {return _node("KE_clause", expr);}
KE_pre = expr:(pre_clause KE spaces?) {return _node("KE_pre", expr);}
KE_post = expr:(post_clause) {return _node("KE_post", expr);}
// KE_no_SA_handling = pre_clause KE post_clause

//         right terminator for KE groups
KEhE_clause = expr:(KEhE_pre KEhE_post) {return _node("KEhE_clause", expr);}
KEhE_pre = expr:(pre_clause KEhE spaces?) {return _node("KEhE_pre", expr);}
KEhE_post = expr:(post_clause) {return _node("KEhE_post", expr);}
// KEhE_no_SA_handling = pre_clause KEhE post_clause

//         right terminator, NU abstractions
KEI_clause = expr:(KEI_pre KEI_post) {return _node("KEI_clause", expr);}
KEI_pre = expr:(pre_clause KEI spaces?) {return _node("KEI_pre", expr);}
KEI_post = expr:(post_clause) {return _node("KEI_post", expr);}
KEI_no_SA_handling = expr:(pre_clause KEI post_clause) {return _node("KEI_no_SA_handling", expr);}

//         multiple utterance scope for tenses
KI_clause = expr:(KI_pre KI_post) {return _node("KI_clause", expr);}
KI_pre = expr:(pre_clause KI spaces?) {return _node("KI_pre", expr);}
KI_post = expr:(post_clause) {return _node("KI_post", expr);}
// KI_no_SA_handling = pre_clause KI post_clause

//         sumti anaphora
KOhA_clause = expr:(KOhA_pre KOhA_post) {return _node("KOhA_clause", expr);}
KOhA_pre = expr:(pre_clause KOhA spaces?) {return _node("KOhA_pre", expr);}
KOhA_post = expr:(post_clause) {return _node("KOhA_post", expr);}
// KOhA_no_SA_handling = pre_clause KOhA spaces?

//         right terminator for descriptions, etc.
KU_clause = expr:(KU_pre KU_post) {return _node("KU_clause", expr);}
KU_pre = expr:(pre_clause KU spaces?) {return _node("KU_pre", expr);}
KU_post = expr:(post_clause) {return _node("KU_post", expr);}
// KU_no_SA_handling = pre_clause KU post_clause

//         MEX forethought delimiter
KUhE_clause = expr:(KUhE_pre KUhE_post) {return _node("KUhE_clause", expr);}
KUhE_pre = expr:(pre_clause KUhE spaces?) {return _node("KUhE_pre", expr);}
KUhE_post = expr:(post_clause) {return _node("KUhE_post", expr);}
// KUhE_no_SA_handling = pre_clause KUhE post_clause

//         right terminator, NOI relative clauses
KUhO_clause = expr:(KUhO_pre KUhO_post) {return _node("KUhO_clause", expr);}
KUhO_pre = expr:(pre_clause KUhO spaces?) {return _node("KUhO_pre", expr);}
KUhO_post = expr:(post_clause) {return _node("KUhO_post", expr);}
// KUhO_no_SA_handling = pre_clause KUhO post_clause


//         name descriptors
LA_clause = expr:(LA_pre LA_post) {return _node("LA_clause", expr);}
LA_pre = expr:(pre_clause LA spaces?) {return _node("LA_pre", expr);}
LA_post = expr:(post_clause) {return _node("LA_post", expr);}
// LA_no_SA_handling = pre_clause LA post_clause

//         lerfu prefixes
LAU_clause = expr:(LAU_pre LAU_post) {return _node("LAU_clause", expr);}
LAU_pre = expr:(pre_clause LAU spaces?) {return _node("LAU_pre", expr);}
LAU_post = expr:(post_clause) {return _node("LAU_post", expr);}
// LAU_no_SA_handling = pre_clause LAU post_clause

//         sumti qualifiers
LAhE_clause = expr:(LAhE_pre LAhE_post) {return _node("LAhE_clause", expr);}
LAhE_pre = expr:(pre_clause LAhE spaces?) {return _node("LAhE_pre", expr);}
LAhE_post = expr:(post_clause) {return _node("LAhE_post", expr);}
// LAhE_no_SA_handling = pre_clause LAhE post_clause

//         sumti descriptors
LE_clause = expr:(LE_pre LE_post) {return _node("LE_clause", expr);}
LE_pre = expr:(pre_clause LE spaces?) {return _node("LE_pre", expr);}
LE_post = expr:(post_clause) {return _node("LE_post", expr);}
// LE_no_SA_handling = pre_clause LE post_clause


//         possibly ungrammatical text right quote
LEhU_clause = expr:(LEhU_pre LEhU_post) {return _node("LEhU_clause", expr);}
LEhU_pre = expr:(pre_clause LEhU spaces?) {return _node("LEhU_pre", expr);}
LEhU_post = expr:(spaces?) {return _node("LEhU_post", expr);}
// LEhU_clause_no_SA = LEhU_pre_no_SA LEhU_post
// LEhU_pre_no_SA = pre_clause LEhU spaces?
// LEhU_no_SA_handling = pre_clause LEhU post_clause

//         convert number to sumti
LI_clause = expr:(LI_pre LI_post) {return _node("LI_clause", expr);}
LI_pre = expr:(pre_clause LI spaces?) {return _node("LI_pre", expr);}
LI_post = expr:(post_clause) {return _node("LI_post", expr);}
// LI_no_SA_handling = pre_clause LI post_clause

//         grammatical text right quote
LIhU_clause = expr:(LIhU_pre LIhU_post) {return _node("LIhU_clause", expr);}
LIhU_pre = expr:(pre_clause LIhU spaces?) {return _node("LIhU_pre", expr);}
LIhU_post = expr:(post_clause) {return _node("LIhU_post", expr);}
// LIhU_no_SA_handling = pre_clause LIhU post_clause

//         elidable terminator for LI
LOhO_clause = expr:(LOhO_pre LOhO_post) {return _node("LOhO_clause", expr);}
LOhO_pre = expr:(pre_clause LOhO spaces?) {return _node("LOhO_pre", expr);}
LOhO_post = expr:(post_clause) {return _node("LOhO_post", expr);}
// LOhO_no_SA_handling = pre_clause LOhO post_clause

//         possibly ungrammatical text left quote
LOhU_clause = expr:(LOhU_pre LOhU_post) {return _node("LOhU_clause", expr);}
LOhU_pre = expr:(pre_clause LOhU spaces? (!LEhU any_word)* LEhU_clause spaces?) {return _node("LOhU_pre", expr);}
LOhU_post = expr:(post_clause) {return _node("LOhU_post", expr);}
// LOhU_no_SA_handling = pre_clause LOhU spaces? (!LEhU any_word)* LEhU_clause spaces?

//         grammatical text left quote
LU_clause = expr:(LU_pre LU_post) {return _node("LU_clause", expr);}
LU_pre = expr:(pre_clause LU spaces?) {return _node("LU_pre", expr);}
LU_post = expr:(spaces? si_clause? !ZEI_clause !BU_clause) {return _node("LU_post", expr);}
// LU_post isn't post_clause for avoiding indicators to attach to LU in the parse tree.
// LU_no_SA_handling = pre_clause LU post_clause

//         LAhE close delimiter
LUhU_clause = expr:(LUhU_pre LUhU_post) {return _node("LUhU_clause", expr);}
LUhU_pre = expr:(pre_clause LUhU spaces?) {return _node("LUhU_pre", expr);}
LUhU_post = expr:(post_clause) {return _node("LUhU_post", expr);}
// LUhU_no_SA_handling = pre_clause LUhU post_clause


//         change MEX expressions to MEX operators
MAhO_clause = expr:(MAhO_pre MAhO_post) {return _node("MAhO_clause", expr);}
MAhO_pre = expr:(pre_clause MAhO spaces?) {return _node("MAhO_pre", expr);}
MAhO_post = expr:(post_clause) {return _node("MAhO_post", expr);}
// MAhO_no_SA_handling = pre_clause MAhO post_clause

//         change numbers to utterance ordinals
MAI_clause = expr:(MAI_pre MAI_post) {return _node("MAI_clause", expr);}
MAI_pre = expr:(pre_clause MAI spaces?) {return _node("MAI_pre", expr);}
MAI_post = expr:(post_clause) {return _node("MAI_post", expr);}
// MAI_no_SA_handling = pre_clause MAI post_clause

//         converts a sumti into a tanru_unit
ME_clause = expr:(ME_pre ME_post) {return _node("ME_clause", expr);}
ME_pre = expr:(pre_clause ME spaces?) {return _node("ME_pre", expr);}
ME_post = expr:(post_clause) {return _node("ME_post", expr);}
// ME_no_SA_handling = pre_clause ME post_clause

//         terminator for ME
MEhU_clause = expr:(MEhU_pre MEhU_post) {return _node("MEhU_clause", expr);}
MEhU_pre = expr:(pre_clause MEhU spaces?) {return _node("MEhU_pre", expr);}
MEhU_post = expr:(post_clause) {return _node("MEhU_post", expr);}
// MEhU_no_SA_handling = pre_clause MEhU post_clause

//         change sumti to operand, inverse of LI
MOhE_clause = expr:(MOhE_pre MOhE_post) {return _node("MOhE_clause", expr);}
MOhE_pre = expr:(pre_clause MOhE spaces?) {return _node("MOhE_pre", expr);}
MOhE_post = expr:(post_clause) {return _node("MOhE_post", expr);}
// MOhE_no_SA_handling = pre_clause MOhE post_clause

//         motion tense marker
MOhI_clause = expr:(MOhI_pre MOhI_post) {return _node("MOhI_clause", expr);}
MOhI_pre = expr:(pre_clause MOhI spaces?) {return _node("MOhI_pre", expr);}
MOhI_post = expr:(post_clause) {return _node("MOhI_post", expr);}
// MOhI_no_SA_handling = pre_clause MOhI post_clause

//         change number to selbri
MOI_clause = expr:(MOI_pre MOI_post) {return _node("MOI_clause", expr);}
MOI_pre = expr:(pre_clause MOI spaces?) {return _node("MOI_pre", expr);}
MOI_post = expr:(post_clause) {return _node("MOI_post", expr);}
// MOI_no_SA_handling = pre_clause MOI post_clause


//         bridi negation
NA_clause = expr:(NA_pre NA_post) {return _node("NA_clause", expr);}
NA_pre = expr:(pre_clause NA spaces?) {return _node("NA_pre", expr);}
NA_post = expr:(post_clause) {return _node("NA_post", expr);}
// NA_no_SA_handling = pre_clause NA post_clause

//         attached to words to negate them
NAI_clause = expr:(NAI_pre NAI_post) {return _node("NAI_clause", expr);}
NAI_pre = expr:(pre_clause NAI spaces?) {return _node("NAI_pre", expr);}
NAI_post = expr:(post_clause) {return _node("NAI_post", expr);}
// NAI_no_SA_handling = pre_clause NAI post_clause

//         scalar negation
NAhE_clause = expr:(NAhE_pre NAhE_post) {return _node("NAhE_clause", expr);}
NAhE_pre = expr:(pre_clause NAhE spaces?) {return _node("NAhE_pre", expr);}
NAhE_post = expr:(post_clause) {return _node("NAhE_post", expr);}
// NAhE_no_SA_handling = pre_clause NAhE post_clause

//         change a selbri into an operator
NAhU_clause = expr:(NAhU_pre NAhU_post) {return _node("NAhU_clause", expr);}
NAhU_pre = expr:(pre_clause NAhU spaces?) {return _node("NAhU_pre", expr);}
NAhU_post = expr:(post_clause) {return _node("NAhU_post", expr);}
// NAhU_no_SA_handling = pre_clause NAhU post_clause

//         change selbri to operand; inverse of MOI
NIhE_clause = expr:(NIhE_pre NIhE_post) {return _node("NIhE_clause", expr);}
NIhE_pre = expr:(pre_clause NIhE spaces?) {return _node("NIhE_pre", expr);}
NIhE_post = expr:(post_clause) {return _node("NIhE_post", expr);}
// NIhE_no_SA_handling = pre_clause NIhE post_clause

//         new paragraph; change of subject
NIhO_clause = expr:(sentence_sa* NIhO_pre NIhO_post) {return _node("NIhO_clause", expr);}
NIhO_pre = expr:(pre_clause NIhO spaces?) {return _node("NIhO_pre", expr);}
NIhO_post = expr:(su_clause* post_clause) {return _node("NIhO_post", expr);}
// NIhO_no_SA_handling = pre_clause NIhO su_clause* post_clause

//         attaches a subordinate clause to a sumti
NOI_clause = expr:(NOI_pre NOI_post) {return _node("NOI_clause", expr);}
NOI_pre = expr:(pre_clause NOI spaces?) {return _node("NOI_pre", expr);}
NOI_post = expr:(post_clause) {return _node("NOI_post", expr);}
// NOI_no_SA_handling = pre_clause NOI post_clause

//         abstraction
NU_clause = expr:(NU_pre NU_post) {return _node("NU_clause", expr);}
NU_pre = expr:(pre_clause NU spaces?) {return _node("NU_pre", expr);}
NU_post = expr:(post_clause) {return _node("NU_post", expr);}
// NU_no_SA_handling = pre_clause NU post_clause

//         change operator to selbri; inverse of MOhE
NUhA_clause = expr:(NUhA_pre NUhA_post) {return _node("NUhA_clause", expr);}
NUhA_pre = expr:(pre_clause NUhA spaces?) {return _node("NUhA_pre", expr);}
NUhA_post = expr:(post_clause) {return _node("NUhA_post", expr);}
// NUhA_no_SA_handling = pre_clause NUhA post_clause

//         marks the start of a termset
NUhI_clause = expr:(NUhI_pre NUhI_post) {return _node("NUhI_clause", expr);}
NUhI_pre = expr:(pre_clause NUhI spaces?) {return _node("NUhI_pre", expr);}
NUhI_post = expr:(post_clause) {return _node("NUhI_post", expr);}
// NUhI_no_SA_handling = pre_clause NUhI post_clause

//         marks the middle and end of a termset
NUhU_clause = expr:(NUhU_pre NUhU_post) {return _node("NUhU_clause", expr);}
NUhU_pre = expr:(pre_clause NUhU spaces?) {return _node("NUhU_pre", expr);}
NUhU_post = expr:(post_clause) {return _node("NUhU_post", expr);}
// NUhU_no_SA_handling = pre_clause NUhU post_clause


//         numbers and numeric punctuation
PA_clause = expr:(PA_pre PA_post) {return _node("PA_clause", expr);}
PA_pre = expr:(pre_clause PA spaces?) {return _node("PA_pre", expr);}
PA_post = expr:(post_clause) {return _node("PA_post", expr);}
// PA_no_SA_handling = pre_clause PA post_clause

//         afterthought termset connective prefix
PEhE_clause = expr:(PEhE_pre PEhE_post) {return _node("PEhE_clause", expr);}
PEhE_pre = expr:(pre_clause PEhE spaces?) {return _node("PEhE_pre", expr);}
PEhE_post = expr:(post_clause) {return _node("PEhE_post", expr);}
// PEhE_no_SA_handling = pre_clause PEhE post_clause

//         forethought (Polish) flag
PEhO_clause = expr:(PEhO_pre PEhO_post) {return _node("PEhO_clause", expr);}
PEhO_pre = expr:(pre_clause PEhO spaces?) {return _node("PEhO_pre", expr);}
PEhO_post = expr:(post_clause) {return _node("PEhO_post", expr);}
// PEhO_no_SA_handling = pre_clause PEhO post_clause

//         directions in time
PU_clause = expr:(PU_pre PU_post) {return _node("PU_clause", expr);}
PU_pre = expr:(pre_clause PU spaces?) {return _node("PU_pre", expr);}
PU_post = expr:(post_clause) {return _node("PU_post", expr);}
// PU_no_SA_handling = pre_clause PU post_clause


//         flag for modified interpretation of GOhI
RAhO_clause = expr:(RAhO_pre RAhO_post) {return _node("RAhO_clause", expr);}
RAhO_pre = expr:(pre_clause RAhO spaces?) {return _node("RAhO_pre", expr);}
RAhO_post = expr:(post_clause) {return _node("RAhO_post", expr);}
// RAhO_no_SA_handling = pre_clause RAhO post_clause

//         converts number to extensional tense
ROI_clause = expr:(ROI_pre ROI_post) {return _node("ROI_clause", expr);}
ROI_pre = expr:(pre_clause ROI spaces?) {return _node("ROI_pre", expr);}
ROI_post = expr:(post_clause) {return _node("ROI_post", expr);}
// ROI_no_SA_handling = pre_clause ROI post_clause

SA_clause = expr:(SA_pre SA_post) {return _node("SA_clause", expr);}
SA_pre = expr:(pre_clause SA spaces?) {return _node("SA_pre", expr);}
SA_post = expr:(spaces?) {return _node("SA_post", expr);}

//         metalinguistic eraser to the beginning of

//                                    the current utterance

//         conversions
SE_clause = expr:(SE_pre SE_post) {return _node("SE_clause", expr);}
SE_pre = expr:(pre_clause SE spaces?) {return _node("SE_pre", expr);}
SE_post = expr:(post_clause) {return _node("SE_post", expr);}
// SE_no_SA_handling = pre_clause SE post_clause

//         metalinguistic bridi insert marker
SEI_clause = expr:(SEI_pre SEI_post) {return _node("SEI_clause", expr);}
SEI_pre = expr:(pre_clause SEI spaces?) {return _node("SEI_pre", expr);}
SEI_post = expr:(post_clause) {return _node("SEI_post", expr);}
// SEI_no_SA_handling = pre_clause SEI post_clause

//         metalinguistic bridi end marker
SEhU_clause = expr:(SEhU_pre SEhU_post) {return _node("SEhU_clause", expr);}
SEhU_pre = expr:(pre_clause SEhU spaces?) {return _node("SEhU_pre", expr);}
SEhU_post = expr:(post_clause) {return _node("SEhU_post", expr);}
// SEhU_no_SA_handling = pre_clause SEhU post_clause

//         metalinguistic single word eraser
SI_clause = expr:(spaces? SI spaces?) {return _node("SI_clause", expr);}

// BETA: bridi relative clause
SOI_clause = expr:(SOI_pre SOI_post) {return _node("SOI_clause", expr);}
SOI_pre = expr:(pre_clause SOI spaces?) {return _node("SOI_pre", expr);}
SOI_post = expr:(post_clause) {return _node("SOI_post", expr);}
// SOI_no_SA_handling = pre_clause SOI post_clause

//         metalinguistic eraser of the entire text
SU_clause = expr:(SU_pre SU_post) {return _node("SU_clause", expr);}
SU_pre = expr:(pre_clause SU spaces?) {return _node("SU_pre", expr);}
SU_post = expr:(post_clause) {return _node("SU_post", expr);}


//         tense interval properties
TAhE_clause = expr:(TAhE_pre TAhE_post) {return _node("TAhE_clause", expr);}
TAhE_pre = expr:(pre_clause TAhE spaces?) {return _node("TAhE_pre", expr);}
TAhE_post = expr:(post_clause) {return _node("TAhE_post", expr);}
// TAhE_no_SA_handling = pre_clause TAhE post_clause

//         closing gap for MEX constructs
TEhU_clause = expr:(TEhU_pre TEhU_post) {return _node("TEhU_clause", expr);}
TEhU_pre = expr:(pre_clause TEhU spaces?) {return _node("TEhU_pre", expr);}
TEhU_post = expr:(post_clause) {return _node("TEhU_post", expr);}
// TEhU_no_SA_handling = pre_clause TEhU post_clause

//         start compound lerfu
TEI_clause = expr:(TEI_pre TEI_post) {return _node("TEI_clause", expr);}
TEI_pre = expr:(pre_clause TEI spaces?) {return _node("TEI_pre", expr);}
TEI_post = expr:(post_clause) {return _node("TEI_post", expr);}
// TEI_no_SA_handling = pre_clause TEI post_clause

//         left discursive parenthesis
TO_clause = expr:(TO_pre TO_post) {return _node("TO_clause", expr);}
TO_pre = expr:(pre_clause TO spaces?) {return _node("TO_pre", expr);}
TO_post = expr:(post_clause) {return _node("TO_post", expr);}
// TO_no_SA_handling = pre_clause TO post_clause

//         right discursive parenthesis
TOI_clause = expr:(TOI_pre TOI_post) {return _node("TOI_clause", expr);}
TOI_pre = expr:(pre_clause TOI spaces?) {return _node("TOI_pre", expr);}
TOI_post = expr:(post_clause) {return _node("TOI_post", expr);}
// TOI_no_SA_handling = pre_clause TOI post_clause

//         multiple utterance scope mark
TUhE_clause = expr:(TUhE_pre TUhE_post) {return _node("TUhE_clause", expr);}
TUhE_pre = expr:(pre_clause TUhE spaces?) {return _node("TUhE_pre", expr);}
TUhE_post = expr:(su_clause* post_clause) {return _node("TUhE_post", expr);}
// TUhE_no_SA_handling = pre_clause TUhE su_clause* post_clause

//         multiple utterance end scope mark
TUhU_clause = expr:(TUhU_pre TUhU_post) {return _node("TUhU_clause", expr);}
TUhU_pre = expr:(pre_clause TUhU spaces?) {return _node("TUhU_pre", expr);}
TUhU_post = expr:(post_clause) {return _node("TUhU_post", expr);}
// TUhU_no_SA_handling = pre_clause TUhU post_clause


//         attitudinals, observationals, discursives
UI_clause = expr:(UI_pre UI_post) {return _node("UI_clause", expr);}
UI_pre = expr:(pre_clause UI spaces?) {return _node("UI_pre", expr);}
UI_post = expr:(post_clause) {return _node("UI_post", expr);}
// UI_no_SA_handling = pre_clause UI post_clause


//         distance in space_time
VA_clause = expr:(VA_pre VA_post) {return _node("VA_clause", expr);}
VA_pre = expr:(pre_clause VA spaces?) {return _node("VA_pre", expr);}
VA_post = expr:(post_clause) {return _node("VA_post", expr);}
// VA_no_SA_handling = pre_clause VA post_clause

//         end simple bridi or bridi_tail
VAU_clause = expr:(VAU_pre VAU_post) {return _node("VAU_clause", expr);}
VAU_pre = expr:(pre_clause VAU spaces?) {return _node("VAU_pre", expr);}
VAU_post = expr:(post_clause) {return _node("VAU_post", expr);}
// VAU_no_SA_handling = pre_clause VAU post_clause

//         left MEX bracket
VEI_clause = expr:(VEI_pre VEI_post) {return _node("VEI_clause", expr);}
VEI_pre = expr:(pre_clause VEI spaces?) {return _node("VEI_pre", expr);}
VEI_post = expr:(post_clause) {return _node("VEI_post", expr);}
// VEI_no_SA_handling = pre_clause VEI post_clause

//         right MEX bracket
VEhO_clause = expr:(VEhO_pre VEhO_post) {return _node("VEhO_clause", expr);}
VEhO_pre = expr:(pre_clause VEhO spaces?) {return _node("VEhO_pre", expr);}
VEhO_post = expr:(post_clause) {return _node("VEhO_post", expr);}
// VEhO_no_SA_handling = pre_clause VEhO post_clause

//         MEX operator
VUhU_clause = expr:(VUhU_pre VUhU_post) {return _node("VUhU_clause", expr);}
VUhU_pre = expr:(pre_clause VUhU spaces?) {return _node("VUhU_pre", expr);}
VUhU_post = expr:(post_clause) {return _node("VUhU_post", expr);}
// VUhU_no_SA_handling = pre_clause VUhU post_clause

//         space_time interval size
VEhA_clause = expr:(VEhA_pre VEhA_post) {return _node("VEhA_clause", expr);}
VEhA_pre = expr:(pre_clause VEhA spaces?) {return _node("VEhA_pre", expr);}
VEhA_post = expr:(post_clause) {return _node("VEhA_post", expr);}
// VEhA_no_SA_handling = pre_clause VEhA post_clause

//         space_time dimensionality marker
VIhA_clause = expr:(VIhA_pre VIhA_post) {return _node("VIhA_clause", expr);}
VIhA_pre = expr:(pre_clause VIhA spaces?) {return _node("VIhA_pre", expr);}
VIhA_post = expr:(post_clause) {return _node("VIhA_post", expr);}
// VIhA_no_SA_handling = pre_clause VIhA post_clause

VUhO_clause = expr:(VUhO_pre VUhO_post) {return _node("VUhO_clause", expr);}
VUhO_pre = expr:(pre_clause VUhO spaces?) {return _node("VUhO_pre", expr);}
VUhO_post = expr:(post_clause) {return _node("VUhO_post", expr);}
// VUhO_no_SA_handling = pre_clause VUhO post_clause

// glue between logically connected sumti and relative clauses


//         subscripting operator
XI_clause = expr:(XI_pre XI_post) {return _node("XI_clause", expr);}
XI_pre = expr:(pre_clause XI spaces?) {return _node("XI_pre", expr);}
XI_post = expr:(post_clause) {return _node("XI_post", expr);}
// XI_no_SA_handling = pre_clause XI post_clause


//         hesitation
// Very very special case.  Handled in the morphology section.
// Y_clause = spaces? Y spaces?


//         event properties _ inchoative, etc.
ZAhO_clause = expr:(ZAhO_pre ZAhO_post) {return _node("ZAhO_clause", expr);}
ZAhO_pre = expr:(pre_clause ZAhO spaces?) {return _node("ZAhO_pre", expr);}
ZAhO_post = expr:(post_clause) {return _node("ZAhO_post", expr);}
// ZAhO_no_SA_handling = pre_clause ZAhO post_clause

//         time interval size tense
ZEhA_clause = expr:(ZEhA_pre ZEhA_post) {return _node("ZEhA_clause", expr);}
ZEhA_pre = expr:(pre_clause ZEhA spaces?) {return _node("ZEhA_pre", expr);}
ZEhA_post = expr:(post_clause) {return _node("ZEhA_post", expr);}
// ZEhA_no_SA_handling = pre_clause ZEhA post_clause

//         lujvo glue
ZEI_clause = expr:(ZEI_pre ZEI_post) {return _node("ZEI_clause", expr);}
// ZEI_clause_no_SA = ZEI_pre_no_SA ZEI ZEI_post
ZEI_pre = expr:(pre_clause ZEI spaces?) {return _node("ZEI_pre", expr);}
// ZEI_pre_no_SA = pre_clause
ZEI_post = expr:(spaces?) {return _node("ZEI_post", expr);}
// ZEI_no_SA_handling = pre_clause ZEI post_clause

//         time distance tense
ZI_clause = expr:(ZI_pre ZI_post) {return _node("ZI_clause", expr);}
ZI_pre = expr:(pre_clause ZI spaces?) {return _node("ZI_pre", expr);}
ZI_post = expr:(post_clause) {return _node("ZI_post", expr);}
// ZI_no_SA_handling = pre_clause ZI post_clause

//         conjoins relative clauses
ZIhE_clause = expr:(ZIhE_pre ZIhE_post) {return _node("ZIhE_clause", expr);}
ZIhE_pre = expr:(pre_clause ZIhE spaces?) {return _node("ZIhE_pre", expr);}
ZIhE_post = expr:(post_clause) {return _node("ZIhE_post", expr);}
// ZIhE_no_SA_handling = pre_clause ZIhE post_clause

//         single word metalinguistic quote marker
ZO_clause = expr:(ZO_pre ZO_post) {return _node("ZO_clause", expr);}
ZO_pre = expr:(pre_clause ZO spaces? any_word spaces?) {return _node("ZO_pre", expr);}
ZO_post = expr:(post_clause) {return _node("ZO_post", expr);}
// ZO_no_SA_handling = pre_clause ZO spaces? any_word spaces?

//         delimited quote marker
ZOI_clause = expr:(ZOI_pre ZOI_post) {return _node("ZOI_clause", expr);}
ZOI_pre = expr:(pre_clause ZOI spaces? zoi_open spaces? (zoi_word spaces)* zoi_close spaces?) {return _node("ZOI_pre", expr);}
ZOI_post = expr:(post_clause) {return _node("ZOI_post", expr);}
ZOI_start = expr:(!ZOI_pre ZOI) {return _node("ZOI_start", expr);}
// ZOI_no_SA_handling = pre_clause ZOI spaces? zoi_open zoi_word* zoi_close spaces?

//         prenex terminator (not elidable)
ZOhU_clause = expr:(ZOhU_pre ZOhU_post) {return _node("ZOhU_clause", expr);}
ZOhU_pre = expr:(pre_clause ZOhU spaces?) {return _node("ZOhU_pre", expr);}
ZOhU_post = expr:(post_clause) {return _node("ZOhU_post", expr);}
// ZOhU_no_SA_handling = pre_clause ZOhU post_clause

// BEGIN BETA: gaJA, guJA
ga_clause = expr:(ga_pre ga_post) {return _node("ga_clause", expr);}
ga_pre = expr:(pre_clause ga_word spaces?) {return _node("ga_pre", expr);}
ga_post = expr:(post_clause) {return _node("ga_post", expr);}
ga_word = expr:(&cmavo ( g a ) &post_word) {return _node("ga_word", expr);}

gu_clause = expr:(gu_pre gu_post) {return _node("gu_clause", expr);}
gu_pre = expr:(pre_clause gu_word spaces?) {return _node("gu_pre", expr);}
gu_post = expr:(post_clause) {return _node("gu_post", expr);}
gu_word = expr:(&cmavo ( g u ) &post_word) {return _node("gu_word", expr);}
// END BETA: gaJA, guJA

// BEGIN BETA: Experimental selmaho

GOhOI_clause = expr:(GOhOI_pre GOhOI_post) {return _node("GOhOI_clause", expr);}
GOhOI_pre = expr:(pre_clause GOhOI spaces? any_word spaces?) {return _node("GOhOI_pre", expr);}
GOhOI_post = expr:(post_clause) {return _node("GOhOI_post", expr);}

IAU_clause = expr:(IAU_pre IAU_post) {return _node("IAU_clause", expr);}
IAU_pre = expr:(pre_clause IAU spaces?) {return _node("IAU_pre", expr);}
IAU_post = expr:(post_clause) {return _node("IAU_post", expr);}

// BETA: Attempt to formalize lo'ai..sa'ai..le'ai replacement expressions.
//       Possibly ungrammatical replacement expressions.
LOhAI_clause = expr:(LOhAI_pre LOhAI_post) {return _node("LOhAI_clause", expr);}
LOhAI_pre = expr:(pre_clause (LOhAI spaces? (!LOhAI !LEhAI any_word)*)? (LOhAI spaces? (!LOhAI !LEhAI any_word)*)? LEhAI spaces?) {return _node("LOhAI_pre", expr);}
LOhAI_post = expr:(post_clause) {return _node("LOhAI_post", expr);}

LOhOI_clause = expr:(LOhOI_pre LOhOI_post) {return _node("LOhOI_clause", expr);}
LOhOI_pre = expr:(pre_clause LOhOI spaces?) {return _node("LOhOI_pre", expr);}
LOhOI_post = expr:(post_clause) {return _node("LOhOI_post", expr);}

MEhOI_clause = expr:(MEhOI_pre MEhOI_post) {return _node("MEhOI_clause", expr);}
MEhOI_pre = expr:(pre_clause MEhOI spaces? zohoi_word spaces?) {return _node("MEhOI_pre", expr);}
MEhOI_post = expr:(post_clause) {return _node("MEhOI_post", expr);}

NOIhA_clause = expr:(NOIhA_pre NOIhA_post) {return _node("NOIhA_clause", expr);}
NOIhA_pre = expr:(pre_clause NOIhA spaces?) {return _node("NOIhA_pre", expr);}
NOIhA_post = expr:(post_clause) {return _node("NOIhA_post", expr);}

KUhAU_clause = expr:(KUhAU_pre KUhAU_post) {return _node("KUhAU_clause", expr);}
KUhAU_pre = expr:(pre_clause KUhAU spaces?) {return _node("KUhAU_pre", expr);}
KUhAU_post = expr:(post_clause) {return _node("KUhAU_post", expr);}

ZOhOI_clause = expr:(ZOhOI_pre ZOhOI_post) {return _node("ZOhOI_clause", expr);}
ZOhOI_pre = expr:(pre_clause ZOhOI spaces? zohoi_word spaces?) {return _node("ZOhOI_pre", expr);}
ZOhOI_post = expr:(post_clause) {return _node("ZOhOI_post", expr);}

// END BETA: Experimental selmaho


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

jbocme = expr:(&zifcme (any_syllable / digit)+ &pause) {return _node("jbocme", expr);}

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

pause = expr:(comma* space_char+ / EOF) {return _node("pause", expr);}

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

initial_spaces = expr:((comma* space_char / !ybu Y)+ EOF? / EOF) {return ["initial_spaces", _join(expr)];}

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

// BETA: va'ei, mu'ei
ROI = expr:(&cmavo ( r e h u / r o i / v a h e i / m u h e i ) &post_word) {return _node("ROI", expr);}

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

