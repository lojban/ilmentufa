var vows   = require('vows');
var assert = require('assert');
var      c = require('..');

// Activate global syntax.
// Modifies the String prototype for a sugary syntax.
c.global();

var txt = 'test me';
var zero = c.bold('');
var tests = {
  'blue': [
    txt,
    '\x0312' + zero + txt + '\x03'
  ],
  'white': [
    txt,
    '\x0300' + zero + txt + '\x03'
  ],
  'bold': [
    txt,
    '\x02' + txt + '\x02'
  ],
  'bold.grey': [
    txt,
    '\x0314' + zero + '\x02'       + txt + '\x02\x03'
  ],
  'underline': [
    txt,
    '\x1F' + txt + '\x1F'
  ],
  'green.underline': [
    txt,
    '\x1F\x0303' + zero + txt + '\x03\x1F'
  ],
  'bold.white': [
    txt,
    '\x0300' + zero + '\x02' + txt + '\x02\x03'
  ],
  'white.italic': [
    txt,
    '\x16\x0300' + zero + txt + '\x03\x16'
  ],
  'bggray': [
    txt,
    '\x0301,14' + txt + '\x03'
  ],
  'blue.bgblack': [
    txt,
    '\x0312,01' + txt + '\x03'
  ],
  'rainbow': [
    'hello u',
    '\x0304' + zero + 'h\x03\x0307' + zero + 'e\x03\x0308' + zero +
    'l\x03\x0303' + zero + 'l\x03\x0312' + zero + 'o\x03 \x0302' + zero +
    'u\x03'
  ],
  'stripColors': [
    '\x0304' + zero + 'h\x03\x0307' + zero + 'e\x03\x0308' + zero +
    'l\x03\x0303' + zero + 'l\x03\x0312' + zero + 'o\x03',
    'hello'],
  'stripStyle': [
    '\x0301' + zero + '\x02' + txt + '\x02\x03',
    '\x0301' + zero + txt + '\x03'
  ],
  'stripColorsAndStyle': [
    '\x02\x0304' + zero + 'h\x03\x0307' + zero + 'e\x03\x0308' + zero +
    'l\x03\x0303' + zero + 'l\x03\x0312' + zero + 'o\x03\x02',
    'hello'
  ]
};

var topicMacro = function(reg) {
  return {
    topic: function() {
      var obj = {};

      for (var key in tests) {
        if (tests.hasOwnProperty(key)) {
          var fn = reg ? c : tests[key][0].irc;
          var s = key.split('.');

          for (var i in s) {
            if (s.hasOwnProperty(i)) {
              fn = fn[s[i]];
            }
          }

          obj[key] = reg ? fn(tests[key][0]) : fn();
        }
      }
      return obj;
    }
  };
};

var regular = topicMacro(true);
var globalSyntax = topicMacro(false);

function equal(expectedStr, gotStr) {
  var expectedBuf = new Buffer(expectedStr, 'utf8');
  var gotBuf = new Buffer(gotStr, 'utf8');
  assert.deepEqual(expectedBuf, gotBuf);
}

function test(key) {
  regular[key] = function(topic) {
    equal(topic[key], tests[key][1]);
  };
  globalSyntax[key] = function(topic) {
    equal(topic[key], tests[key][1]);
  };
}

for (var key in tests) {
  if (tests.hasOwnProperty(key)) {
    test(key);
  }
}

vows.describe('Test').addBatch({
  'Using regular syntax': regular,
  'Using global syntax': globalSyntax
}).export(module);
