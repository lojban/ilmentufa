const { parseArgs } = require("util");
const fs = require("fs");
const { execSync } = require("child_process");
const http = require("http");
const https = require("https");

const es = require("event-stream");
const jss = require("JSONStream");

const camxes_postproc = require('./camxes_postproc.js');

// lazy-loaded: jsondiffpatch is ESM-only
let jsondiffpatch_diff;
let jsondiffpatch_format;

async function load_jsondiffpatch() {
    const jsondiffpatch = await import("jsondiffpatch");
    const console_formatter = await import("jsondiffpatch/formatters/console");
    jsondiffpatch_diff = jsondiffpatch.diff;
    jsondiffpatch_format = console_formatter.format;
}

//

const STDIO_DASH = "-";
const RE_URL = /^https?:\/\//i;

// tests based on >20k texts used to evaluate the original (java) camxes parser
// https://raw.githubusercontent.com/lojban/camxes-py/refs/heads/master/test/sentences.json
const PATH_CAMXES_TEST = "./camxes.test.json";

const SPECS_ENCODING = "utf8";
const SPECS_INDENT = 4;

const SPECS_PATH_ENV = "env";
const SPECS_PATH_SPECS = "specs";

// failed parses of previous test runs are marked ERROR
const SPECS_OUT_ERROR = "ERROR";
// the original camxes sentences are marked GOOD/BAD/UNKNOWN
const RE_OUT_SENTENCE = /^(GOOD|BAD|UNKNOWN)$/;

const DEFAULT_ENGINE = "camxes-ilmen";
const SPECS_FORMAT = "camxes-json";

const ENGINE_PATHS = {
    "camxes-ilmen":              "./camxes.js",
    "camxes-ilmen-exp":          "./camxes-exp.js",
    "camxes-ilmen-beta":         "./camxes-beta.js",
    "camxes-ilmen-beta-cbm":     "./camxes-beta-cbm.js",
    "camxes-ilmen-beta-cbm-ckt": "./camxes-beta-cbm-ckt.js",
};

const SPECS_SERIALIZATION = "ilmentufa-notrim-json";
const POSTPROCESS_MODE = "RJ";

//

class Reporter {

    _verbose = false;

    results = [];
    _summary = { total: 0, different: 0, failed: 0, oldfail: 0, newfail: 0, fixed: 0 };

    // if running against sentences rather than test results,
    // we can't report differences or count expected failures
    _historical_mode = undefined;

    _start = Date.now();

    constructor(options) {
        this._verbose = !!options.verbose;
    }

    record_result(spec, parse_result) {
        const result = this._build_result(spec, parse_result);
        this.results.push(result);

        this._historical_mode ??= this._has_parse_history(spec);
        this._update_summary(result, spec);
    }

    _has_parse_history(spec) {
        // test results are either a parse or "ERROR"
        if (!spec.out) return false;
        return !RE_OUT_SENTENCE.test(spec.out);
    }

    _build_result(spec, parse_result) {
        return {
            md5: spec.md5,
            txt: spec.txt,
            out: parse_result,
        };
    }

    _update_summary(result, spec) {
        this._summary.total += 1;
        if (result.out === SPECS_OUT_ERROR) {
            this._summary.failed += 1;
        }
        if (this._historical_mode) {
            if (spec.out === SPECS_OUT_ERROR) {
                this._summary.oldfail += 1;
                if (result.out !== SPECS_OUT_ERROR) {
                    this._summary.fixed += 1;
                }
            } else if (spec.out !== result.out) {
                if (result.out === SPECS_OUT_ERROR) {
                    this._summary.newfail += 1;
                } else {
                    this._summary.different += 1;
                }
            }
        }
    }

    report_progress(done) {
        const { total, different, failed, oldfail, newfail, fixed } = this._summary;
        const elapsed = this._elapsed();
        const line = this._historical_mode ?
            `tests: ${total}  different: ${different}  failed: ${failed}/${oldfail} (new: ${newfail} fixed: ${fixed})  elapsed: ${elapsed}s`
            : `tests: ${total}  failed: ${failed}  elapsed: ${elapsed}s`;
        process.stderr.write(`\r${line}${done ? "\n" : ""}`);
    }

    _elapsed() {
        return ((Date.now() - this._start) / 1000).toFixed(1);
    }

    report_detail(spec, parse_result) {
        if (!this._verbose || !this._historical_mode || !spec.out) return;
        if (parse_result === spec.out) return;

        if (parse_result === SPECS_OUT_ERROR) {
            process.stderr.write(`\nFailed parse: ${spec.txt}:\n`);
        } else {
            this._report_json_delta(spec, parse_result);
        }
    }

    _report_json_delta(spec, parse_result) {
        const old_parse_json = JSON.parse(spec.out);
        const new_parse_json = JSON.parse(parse_result);
        const delta = jsondiffpatch_diff(old_parse_json, new_parse_json);
        if (!delta) return;

        process.stderr.write(`\nNew parse (${spec.txt}):\n`);
        process.stderr.write(jsondiffpatch_format(delta, old_parse_json));
        process.stderr.write("\n");
    }

}

function run_specs(engine, options) {
    const { specs_in: specs_in_path, specs_out: specs_out_path, specs_env, verbose } = options;

    const specs_in = build_specs_reader(specs_in_path);
    const reporter = new Reporter({ verbose });
    specs_in
        .pipe(es.mapSync((spec) => run_spec(engine, spec, reporter)))
        .on("end", () => {
            reporter.report_progress(true);
            emit_specs(specs_out_path, specs_env, reporter.results);
        })
        .on("error", (err) => console.warn(err));
}

function build_specs_reader(specs_path) {
    const selecter = jss.parse(`${SPECS_PATH_SPECS}.*`);
    if (specs_path && is_url(specs_path)) {
        build_remote_specs_reader(specs_path, selecter);
        return selecter;
    }
    return build_local_specs_reader(specs_path, selecter);
}

function is_url(path) {
    return RE_URL.test(path);
}

function build_remote_specs_reader(specs_path, selecter) {
    const client = specs_path.startsWith("https") ? https : http;
    client.get(specs_path, (res) => {
        res.setEncoding(SPECS_ENCODING);
        res.pipe(selecter);
    }).on("error", (err) => selecter.emit("error", err));
}

function build_local_specs_reader(specs_path, selecter) {
    const fstream_in = (specs_path && specs_path !== STDIO_DASH) ?
        fs.createReadStream(specs_path, { encoding: SPECS_ENCODING })
        : process.stdin;
    return fstream_in.pipe(selecter);
}

function run_spec(engine, spec, reporter) {
    let spec_result;
    try {
        const parsed = engine.parse(spec.txt);
        spec_result = camxes_postproc.postprocessing(parsed, POSTPROCESS_MODE);
    } catch {
        spec_result = SPECS_OUT_ERROR;
    }
    reporter.record_result(spec, spec_result);
    reporter.report_progress();
    reporter.report_detail(spec, spec_result);
}

function emit_specs(specs_out_path, specs_env, specs) {
    const specs_out = {};
    specs_out[SPECS_PATH_ENV] = specs_env;
    specs_out[SPECS_PATH_SPECS] = specs;

    const fstream_out = (specs_out_path && specs_out_path !== STDIO_DASH) ?
        fs.createWriteStream(specs_out_path, { encoding: SPECS_ENCODING })
        : process.stdout;
    fstream_out.write(JSON.stringify(specs_out, null, SPECS_INDENT));
}

//

async function main(argv) {
    const options = parse_cli_options(argv.slice(2));
    if (options.help) {
        print_usage();
        process.exit(0);
    }

    const engine_name = options.engine;
    if (!ENGINE_PATHS[engine_name]) {
        console.error(`unknown engine "${engine_name}"; expected one of: ${Object.keys(ENGINE_PATHS).join(", ")}`);
        process.exit(1);
    }

    const verbose = options.verbose;
    if (verbose) {
        await load_jsondiffpatch();
    }

    const engine_version = read_git_version();
    const specs_env = {
        engine: engine_name,
        version: engine_version,
        format: SPECS_FORMAT,
        serialization: SPECS_SERIALIZATION,
    };

    const specs_in = options.in || PATH_CAMXES_TEST;
    const specs_out = options.out;

    const engine_path = ENGINE_PATHS[engine_name];
    const engine = require(engine_path);
    run_specs(engine, { specs_in, specs_out, specs_env, verbose });
}

function parse_cli_options(argv) {
    const { values } = parseArgs({
        args: argv,
        options: {
            engine:  { type: "string", short: "e", default: DEFAULT_ENGINE },
            in:      { type: "string", short: "i" },
            out:     { type: "string", short: "o" },
            verbose: { type: "boolean", short: "v" },
            help:    { type: "boolean", short: "h" },
        },
    });
    return values;
}

function print_usage() {
    console.log(`usage: node run_tests.js [options]

options:
  -e, --engine <name>  engine to test against (default: ${DEFAULT_ENGINE})
                        one of: ${Object.keys(ENGINE_PATHS).join(", ")}
  -i, --in <path>       specs input: a local path, a URL, or - for stdin
                        (default: ${PATH_CAMXES_TEST})
  -o, --out <path>      specs output: a local path, or - for stdout (default)
  -v, --verbose         when a spec parses but doesn't match history, print a jsondiff
  -h, --help            show this help message`);
}

function read_git_version() {
    return execSync("git rev-parse --short=7 HEAD").toString().trim();
}

//

main(process.argv).catch((err) => {
    console.error(err);
    process.exit(1);
});
