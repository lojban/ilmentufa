main(process.argv, require("fs"));
process.exit();

function main(argv, fs) {
    if (argv.length < 3) {
        console.log("Not enough parameters.");
        return;
    }
    var srcpath = argv[2];
    var dstpath = srcpath.replace(/^(.*?)(\.[^\\\/]+)?$/g, "$1-ctk$2");
    var peg;
    var df;
    try {
        console.log("Opening " + srcpath);
        peg = fs.readFileSync(srcpath).toString();
        console.log("Opening " + dstpath);
        df = fs.openSync(dstpath, 'w+');
    } catch(e) {
        console.log("Error: " + e);
    }
    peg = make_ctk(peg);
    fs.writeSync(df, peg, 0, peg.length);
    return;
}


function make_ctk(peg) {
    // ce → ce'u
    peg = peg.replace(/(\nJOI <- &cmavo \( [^\n]*)\/ c e (?=\/|\))/gm, "$1");
    peg = peg.replace(/(\nKOhA <- &cmavo \([^\n]*)\)/gm, "$1/ c e )");
    // ki'i → ki → ke'a
    peg = peg.replace(/(\nBAI <- &cmavo \( [^\n]*)\/ k i h i (?=\/|\))/gm, "$1");
    peg = peg.replace(/(\nKI <- &cmavo \() k i \)/gm, "$1 k i h i )");
    peg = peg.replace(/(\nKOhA <- &cmavo \([^\n]*)\)/gm, "$1/ k i )");
    // tau → tu'a
    peg = peg.replace(/(\nLAU <- &cmavo \( [^\n]*)\/ t a u (?=\/|\))/gm, "$1");
    peg = peg.replace(/(\nLAhE <- &cmavo \([^\n]*)\)/gm, "$1/ t a u )");
    // du → du'u
    peg = peg.replace(/(\nGOhA <- &cmavo \( [^\n]*)\/ d u (?=\/|\))/gm, "$1");
    peg = peg.replace(/(\nNU <- &cmavo \([^\n]*)\)/gm, "$1/ d u )");
    // su'u → su → su'o
    peg = peg.replace(/(\nNU <- &cmavo \( [^\n]*)\/ s u h u (?=\/|\))/gm, "$1");
    peg = peg.replace(/(\nSU <- &cmavo \() s u \)/gm, "$1 s u h u )");
    peg = peg.replace(/(\nPA <- &cmavo \([^\n]*)\)/gm, "$1/ s u )");
    // zai → bu'u
    peg = peg.replace(/(\nLAU <- &cmavo \( [^\n]*)\/ z a i (?=\/|\))/gm, "$1");
    peg = peg.replace(/(\nFAhA <- &cmavo \([^\n]*)\)/gm, "$1/ z a i )");
    // koi → ko'oi
    peg = peg.replace(/(\nBAI <- &cmavo \( [^\n]*)\/ k o i (?=\/|\))/gm, "$1");
    peg = peg.replace(/(\nUI <- &cmavo \([^\n]*)\)/gm, "$1/ k o i )");
    // voi → poi'i
    peg = peg.replace(/(\nNOI <- &cmavo \( [^\n]*)\/ v o i (?=\/|\))/gm, "$1");
    peg = peg.replace(/(\nNU <- &cmavo \([^\n]*)\)/gm, "$1/ v o i )");
    return peg;
}

/*
  ce'u  → ce
  ke'a  → ki
  tu'a  → tau
  du'u  → du
  su'o  → su
  bu'u  → zai
  ko'oi → koi
  poi'i → voi
*/
