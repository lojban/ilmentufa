/*
 * USAGE:
 * $ nodejs run_camxes.js -p PARSER_ID -m MODE TEXT
 * or
 * $ nodejs run_camxes.js -p PARSER_ID -m MODE -t TEXT
 * 
 * Possible values for PARSER_ID:
 *    "std", "beta", "cbm", "ckt", "exp"
 * 
 * MODE can be any letter string, each letter stands for a specific option.
 * Here is the list of possible letters and their associated meaning:
 *    'M' -> Keep morphology
 *    'S' -> Show spaces
 *    'C' -> Show word classes (selmaho)
 *    'T' -> Show terminators
 *    'N' -> Show main node labels
 *    'R' -> Raw output, do not prune the tree, except the morphology if 'M' not present.
 * Example:
 *    -m CTN
 *    This will show terminators, selmaho and main node labels.
 */

var camxes = require('./camxes.js');
var camxes_beta = require('./camxes-beta.js');
var camxes_cbm = require('./camxes-beta-cbm.js');
var camxes_ckt = require('./camxes-beta-cbm-ckt.js');
var camxes_exp = require('./camxes-exp.js');
var camxes_pre = require('./camxes_preproc.js');
var camxes_post = require('./camxes_postproc.js');

var parser_id = "";
var mode = "";
var text = "";

var target = '-t';
for (var i = 2; i < process.argv.length; i++) {
    if (process.argv[i].length > 0) {
        var a = process.argv[i];
        if (a[0] == '-') {
            target = a;
        } else {
            switch (target) {
                case '-t':
                    text = a;
                    break;
                case '-p':
                    parser_id = a;
                    break;
                case '-m':
                    mode = a;
            }
            target = '-t';
        }
    }
}

// if (!among(parser_id, ["std", "beta", "cbm", "ckt", "exp"]))
//    parser_id = "std";

console.log("Parser: " + parser_id);
console.log("Mode:   " + mode);
console.log("Text:   " + text);
process.stdout.write(run_camxes(text, mode, "std") + '\n');

function run_camxes(input, mode, engine) {
	var result;
	var syntax_error = false;
	result = camxes_pre.preprocessing(input);
	try {
    switch (engine) {
      case "std":
        result = camxes.parse(result);
        break;
      case "exp":
        result = camxes_exp.parse(result);
        break;
      case "beta":
        result = camxes_beta.parse(result);
        break;
      case "cbm":
        result = camxes_cbm.parse(result);
        break;
      case "ckt":
        result = camxes_ckt.parse(result);
        break;
      default:
        throw "Unrecognized parser";
    }
	} catch (e) {
        var location_info = ' Location: [' + e.location.start.offset + ', ' + e.location.end.offset + ']';
        location_info += ' …' + input.substring(e.location.start.offset, e.location.start.offset + 12) + '…';
		result = e.toString() + location_info;
		syntax_error = true;
	}
	if (!syntax_error) {
		result = camxes_post.postprocessing(result, mode);
	}
	return result;
}

function among(v, s) {
    var i = 0;
    while (i < s.length) if (s[i++] == v) return true;
    return false;
}

