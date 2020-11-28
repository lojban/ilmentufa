// ================================================================== //

/*
 *  PEGJS INITIALIZATION CODE
 */

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
	
	// === Stack functions === //

  _g_stack = []

  function _push(x) {
    if (is_array(x)) x = join_expr(x);
    else if (!is_string(x)) throw "Invalid argument type: " + typeof x;
    _g_stack.push(x);
    return;
  }

  function _pop() {
    return _g_stack.pop();
  }
	
	  function _peek() {
	  if (_g_stack.length <= 0) return null;
    else return _g_stack[_g_stack.length - 1];
  }
	
	_g_last_pred_val = null;
	
	function _pop_eq(x) {
    if (is_array(x)) x = join_expr(x);
    else if (!is_string(x)) throw "Invalid argument type: " + typeof x;
    /* Keeping spaces in the parse tree seems to result in the absorbtion of
       spaces into the closing delimiter candidate, so we'll remove any space
       character from our input. */
    x = x.replace(/[.\t\n\r?!\u0020]/g, "");
		l = _g_stack.length;
		y = _peek();
		r = x === y;
		_g_last_pred_val = r;
		if (r) _pop();
    return r;
  }
	
	function _peek_eq(x) {
    if (is_array(x)) x = join_expr(x);
    else if (!is_string(x)) throw "Invalid argument type: " + typeof x;
    /* Keeping spaces in the parse tree seems to result in the absorbtion of
       spaces into the closing delimiter candidate, so we'll remove any space
       character from our input. */
    x = x.replace(/[.\t\n\r?!\u0020]/g, "");
		l = _g_stack.length;
		y = _peek();
		r = x === y;
		_g_last_pred_val = r;
    return r;
  }
  
	// === MISC === //
  
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
    return Object.prototype.toString.call(v) === '[object String]';
  }

  function is_array(v) {
    return Object.prototype.toString.call(v) === '[object Array]';
  }
}

// ================================================================== //

