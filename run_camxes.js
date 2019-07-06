/*
 * USAGE:
 *   $ nodejs run_camxes -PARSER_ID -m MODE TEXT
 * OR
 *   $ nodejs run_camxes -PARSER_ID -m MODE -t TEXT
 * OR
 *   $ nodejs run_camxes -p PARSER_PATH -m MODE TEXT
 * OR
 *   $ nodejs run_camxes -p PARSER_PATH -m MODE -t TEXT
 * 
 * PARSER_PATH and TEXT being the path of the desired parser engine, and the
 * Lojban text to be parsed, respectively.
 * 
 * Possible values for PARSER_ID:
 *    "std", "beta", "cbm", "ckt", "exp", "morpho"
 * 
 * MODE can be any letter string, each letter stands for a specific option.
 * Here is the list of possible letters and their associated meaning:
 *    'M' -> Keep morphology
 *    'S' -> Show spaces
 *    'T' -> Show terminators
 *    'C' -> Show word classes (selmaho)
 *    'R' -> Raw output, do not trim the parse tree. If this option isn't set,
 *           all the nodes (with the exception of those saved if the 'N' option
 *           is set) are pruned from the tree.
 *    'N' -> Show main node labels
 *    'L' -> Loop
 * Example:
 *    -m CTN
 *    This will show terminators, selmaho and main node labels.
 */

var camxes_preproc = require('./camxes_preproc.js');
var camxes_postproc = require('./camxes_postproc.js');

var engine_path = "./camxes.js";
var mode = "";
var text = "";

var target = '-t';
var p = [["-std","./camxes.js"],["-beta","./camxes-beta.js"],["-cbm","./camxes-beta-cbm.js"],
          ["-ckt","./camxes-beta-cbm-ckt.js"],["-exp","./camxes-exp.js"],["-morpho","./camxes-morpho.js"]];

for (var i = 2; i < process.argv.length; i++) {
    if (process.argv[i].length > 0) {
        var a = process.argv[i];
        if (a[0] == '-') {
            for (j = 0; j < p.length; j++) {
                if (p[j][0] == a) {
                    engine_path = p[j][1];
                    target = '-t';
                    break;
                }
            }
            if (j == p.length)
                target = a;
        } else {
            switch (target) {
                case '-t':
                    text = a;
                    break;
                case '-p':
                    engine_path = a;
                    break;
                case '-m':
                    mode = a;
            }
            target = '-t';
        }
    }
}

if (engine_path.length > 0 && !(engine_path[0] == '/' || engine_path.substring(0, 2) == './'))
    engine_path = './' + engine_path;

try {
    var engine = require(engine_path);
} catch (err) {
    process.stdout.write(err.toString() + '\n');
    process.exit();
}
var mode_loop = among('L', mode);
if (mode_loop) {
    process.stdout.write(run_camxes(text, mode, engine) + '\n');
    run_camxes_loop(mode, engine);
} else {
    process.stdout.write(run_camxes(text, mode, engine) + '\n');
    process.exit();
}

// ================================ //

async function run_camxes_loop(mode, engine) {
    const readline = require('readline')
    const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout,
        prompt: '> '
    });
    rl.prompt();

    rl.on('line', (line) => {
        ret = run_camxes(line, mode, engine);
        process.stdout.write(run_camxes(line, mode, engine)+ '\n');
        rl.prompt();
    }).on('close', () => {
        process.stdout.write("co'o\n");
        process.exit();
    });
}

// ================================ //

function run_camxes(input, mode, engine) {
	var result;
	var syntax_error = false;
	result = camxes_preproc.preprocessing(input);
	try {
        result = engine.parse(result);
	} catch (e) {
        var location_info = ' Location: [' + e.location.start.offset + ', ' + e.location.end.offset + ']';
        location_info += ' …' + input.substring(e.location.start.offset, e.location.start.offset + 12) + '…';
		result = e.toString() + location_info;
		syntax_error = true;
	} finally {
        if (!syntax_error)
            result = camxes_postproc.postprocessing(result, mode);
        return result;
    }
}

// Copied from camxes_postproc

function among(v, s) {
    var i = 0;
    while (i < s.length) if (s[i++] == v) return true;
    return false;
}

