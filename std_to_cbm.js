main(process.argv, require("fs"));
process.exit();

function main(argv, fs) {
    if (argv.length < 3) {
        console.log("Not enough parameters.");
        return;
    }
    var srcpath = argv[2];
    var dstpath = srcpath.replace(/^(.*?)(\.[^\\\/]+)?$/g, "$1-cbm$2");
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
    peg = std_to_cbm(peg);
    fs.writeSync(df, peg, 0, peg.length);
    return;
}

function std_to_cbm(peg) {
    peg = peg.replace(/\ntext_part_2 <- \(CMEVLA_clause\+ \/ indicators\?\)/gm, "text_part_2 <- indicators?");
    peg = peg.replace(/(\nterm_start <- .*) LA_clause \//gm, "$1");
    peg = peg.replace(/(\nsumti_6 <- [^\n]*)LA_clause (free\* )?relative_clauses\? CMEVLA_clause\+ (free\* )?\/ \(LA_clause \/ LE_clause\)/gm, "$1LE_clause");
    peg = peg.replace(/(\nfree <- [^\n]*) vocative relative_clauses\? CMEVLA_clause\+ (free\* )?relative_clauses\? DOhU_elidible \//gm, "$1");
    peg = peg.replace(/(\nany_word_SA_handling <- [^\n]*) \/ CMEVLA_pre/gm, "$1");
    peg = peg.replace(/\nCMEVLA_clause <- (?:\r|\n|.)+\nCMEVLA_post <- post_clause/gm, "");
    peg = peg.replace(/\nLA_clause <- (?:\r|\n|.)+\nLA_post <- post_clause/gm, "");
    peg = peg.replace(/(\nBRIVLA <- [^\r\n]+)/gm, "$1 / CMEVLA");
    peg = peg.replace(/(\n# BETA:.*)?\nLA <- [^\r\n]+/gm, "");
    peg = peg.replace(/(\nLE <- &cmavo \( )/gm, "$1l a i / l a h i / l a / ");
    return peg;
}

