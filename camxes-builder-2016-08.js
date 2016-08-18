// // load peg.js and the file system module
var fs = require("fs")
var PEG = require("pegjs")
// // read peg and build a parser
var camxes_peg = fs.readFileSync("camxes.js.peg").toString();
try {
	var camxes = PEG.buildParser(camxes_peg, {
		cache: true,
		trace: false,
		output: "source",
		allowedStartRules: ["text"],
	});
} catch (e) {
	console.log(JSON.stringify(e));
	throw e;
}
// // write to a file
var fd = fs.openSync("camxes-2016-08.js", 'w+');
var buffer = new Buffer('var camxes = ');
fs.writeSync(fd, buffer, 0, buffer.length);
buffer = new Buffer(camxes);
fs.writeSync(fd, buffer, 0, buffer.length);
buffer = new Buffer(`

if (typeof module !== 'undefined') module.exports = camxes;
if (typeof process !== 'undefined') {
  var input = process.argv[2];
  if (Object.prototype.toString.call(input) === '[object String]')
    console.log(JSON.stringify(camxes.parse(input)));
}

`);
fs.writeSync(fd, buffer, 0, buffer.length);
fs.close(fd);

