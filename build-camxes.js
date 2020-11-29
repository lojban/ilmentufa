var start_t = process.hrtime();
var fs = require("fs");
var pathmod = require("path");
var pegjs = require("pegjs");
var src = (process.argv.length >= 3) ? process.argv[2] : "camxes.pegjs";
if (pathmod.extname(src) === ".peg") {
	  var pegjs_conv = require("./pegjs_conv.js");
		var peg_src = src;
		// src = pathmod.dirname(peg_src) + pathmod.sep + pathmod.basename(peg_src) + ".pegjs";
		src = pegjs_conv.convert_file(peg_src);
		console.log("-> " + src);
}
var dst = src.replace(/.js.peg$/g, ".pegjs").replace(/^(.*?)(\.[^\\\/]+)?$/g, "$1.js");
console.log("-> " + dst);
var peg = fs.readFileSync(src).toString();
try {
    var param = {
		cache: true,
		trace: false,
		output: "source",
		allowedStartRules: ["text"],
	}
    if (typeof pegjs.generate === 'function')
        var parser_code = pegjs.generate(peg, param);
    else if (typeof pegjs.buildParser === 'function')
        var parser_code = pegjs.buildParser(peg, param);
    else throw "ERROR: No parser generator method found in the PEGJS module.";
} catch (e) {
	console.log(JSON.stringify(e));
	throw e;
}
var fd = fs.openSync(dst, 'w+');
var buffer = new Buffer.from('var camxes = ');
fs.writeSync(fd, buffer, 0, buffer.length);
buffer = new Buffer.from(parser_code);
fs.writeSync(fd, buffer, 0, buffer.length);
buffer = new Buffer.from(`

if (typeof module !== 'undefined') {
	module.exports = camxes;
	if (typeof process !== 'undefined' && require !== 'undefined' && require.main === module) {
		var input = process.argv[2];
		if (Object.prototype.toString.call(input) === '[object String]')
			console.log(JSON.stringify(camxes.parse(input)));
	}
}

`);
fs.writeSync(fd, buffer, 0, buffer.length);
fs.closeSync(fd);
var diff_t = process.hrtime(start_t);
console.log(`Duration: ${diff_t[0] + diff_t[1] / 1e9} seconds`);

