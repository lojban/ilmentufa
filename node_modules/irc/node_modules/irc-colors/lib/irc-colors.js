var colors = {
  '00': ['white'],
  '01': ['black'],
  '02': ['navy'],
  '03': ['green'],
  '04': ['red'],
  '05': ['brown', 'maroon'],
  '06': ['purple', 'violet'],
  '07': ['olive'],
  '08': ['yellow'],
  '09': ['lightgreen', 'lime'],
  '10': ['teal', 'bluecyan'],
  '11': ['cyan', 'aqua'],
  '12': ['blue', 'royal'],
  '13': ['pink', 'lightpurple', 'fuchsia'],
  '14': ['gray', 'grey'],
  '15': ['lightgray', 'lightgrey', 'silver']
};

var styles = {
  normal    : '\x0F',
  underline : '\x1F',
  bold      : '\x02',
  italic    : '\x16'
};


// Coloring character.
var c = '\x03';
var pos2 = c.length + 2;
var zero = styles.bold + styles.bold;

var allColors = {
  fg: [], bg: [], styles: Object.keys(styles),
};

// Make color functions for both foreground and background.
Object.keys(colors).forEach(function(code) {
  // Foreground.
  var fg = function(str) {
    return c + code + zero + str + c;
  };

  // Background.
  var bg = function(str) {
      var pos = str.indexOf(c);
      if (pos !== 0) {
        return c + '01,' + code + str + c;
      } else {
        return (str.substr(pos, pos2)) + ',' + code + (str.substr(pos2 + 2));
      }
    };

  colors[code].forEach(function(color) {
    allColors.fg.push(color);
    allColors.bg.push('bg' + color);
    exports[color] = fg;
    exports['bg' + color] = bg;
  });
});


// Style functions.
Object.keys(styles).forEach(function(style) {
  var code = styles[style];
  exports[style] = function(str) {
    return code + str + code;
  };
});


// Extras.
var extras = {
  rainbow: function(str, colorArr) {
    var rainbow = ['red', 'olive', 'yellow', 'green',
                   'blue', 'navy', 'violet'];
    colorArr = colorArr || rainbow;
    var l = colorArr.length;
    var i = 0;

    return str
      .split('')
      .map(function(c) {
        return c !== ' ' ? exports[colorArr[i++ % l]](c) : c;
      })
      .join('');
  },

  stripColors: function(str) {
    return str.replace(/\x03\d{0,2}(,\d{0,2}|\x02\x02)?/g, '');
  },

  stripStyle: function(str) {
    return str.replace(/([\x0F\x02\x16\x1F])(.+)\1/g, '$2');
  },

  stripColorsAndStyle: function(str) {
    return exports.stripColors(exports.stripStyle(str));
  },
};

Object.keys(extras).forEach(function(extra) {
  exports[extra] = extras[extra];
});

// Adds all functions to each other so they can be chained.
function addGetters(fn, types) {
  Object.keys(allColors).forEach(function(type) {
    if (types.indexOf(type) > -1) { return; }
    allColors[type].forEach(function(color) {
      fn.__defineGetter__(color, function() {
        var f = function(str) { return exports[color](fn(str)); };
        addGetters(f, [].concat(types, type));
        return f;
      });
    });
  });
}

Object.keys(allColors).forEach(function(type) {
  allColors[type].forEach(function(color) {
    addGetters(exports[color], [type]);
  });
});


// Adds functions to global String object.
exports.global = function() {
  var str, irc = {};

  String.prototype.__defineGetter__('irc', function() {
    str = this;
    return irc;
  });

  for (var type in allColors) {
    allColors[type].forEach(function(color) {
      var fn = function() { return exports[color](str); };
      addGetters(fn, [type]);
      irc[color] = fn;
    });
  }

  Object.keys(extras).forEach(function(extra) {
    irc[extra] = function() {
      return extras[extra](str); };
  });
};
