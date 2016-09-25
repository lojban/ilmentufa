var start_t = process.hrtime();
var fs = require("fs")
var pegjs = require("pegjs")
var src = (process.argv.length >= 3) ? process.argv[2] : "camxes.pegjs";
var dst = src.replace(/.js.peg$/g, ".pegjs").replace(/^(.*?)(\.[^\\\/]+)?$/g, "$1.js");
console.log("-> " + dst);
var peg = fs.readFileSync(src).toString();
try {
	var camxes = pegjs.buildParser(peg, {
		cache: true,
		trace: false,
		output: "source",
		allowedStartRules: ["text"],
	});
} catch (e) {
	console.log(JSON.stringify(e));
	throw e;
}
var fd = fs.openSync(dst, 'w+');
var buffer = new Buffer('var camxes = ');
fs.writeSync(fd, buffer, 0, buffer.length);
buffer = new Buffer(camxes);
fs.writeSync(fd, buffer, 0, buffer.length);
buffer = new Buffer(`

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
fs.close(fd);
var diff_t = process.hrtime(start_t);
console.log(`Duration: ${diff_t[0] + diff_t[1] / 1e9} seconds`);

