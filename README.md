la ilmentufa
=========

_[la ilmentufa](http://lojban.org/papri/la_ilmentufa)_ is a collection of formal grammars and syntactical parsers for the Lojban language, as well as related tools and interfaces.

It currently includes five main PEG formal grammars along with their corresponding Javascript parsers (those are automatically generated from the grammar files). The PEG grammar files have the extension `.peg` (e.g. `camxes.peg`), and the parsers have the same name as their corresponding grammar but with a `.js` extension.

* `camxes.peg`: Standard PEG grammar for Lojban.
* `camxes-beta.peg`: Same as camxes.peg, but with the addition of the most popular and backward-compatible experimental cmavo and grammar changes.
* `camxes-beta-cbm.peg`: Same as camxes-beta.peg, but with the Cmevla-Brivla Merger experimental grammar change.
* `camxes-beta-cbm-ckt.peg`: Same as above, but with [Ce-Ki-Tau](https://mw.lojban.org/papri/ce_ki_tau_jau) experimental grammar.
* `camxes-exp.peg`: Experimental grammar sandbox.

Main interfaces to the parsers:
* `camxes.html`: HTML interface with various parsing options and allowing selecting the desired parser.
* `glosser/glosser.htm`: Another HTML interface with different features, most prominently nested boxes output and glosses.
* `run_camxes.js`: Command line interface.
* `ircbot/camxes-bot.js`: IRC bot interface.


### Requirements ###

For generating a PEGJS grammar engine from its PEG grammar file, as well as for running the IRC bot interfaces, you need to have [Node.js](https://nodejs.org/) installed on your machine.

For generating a PEGJS engine, you may need to get the [Node.js module `pegjs`](http://pegjs.org/).
For running the IRC bots, you may need to get the [Node.js module `irc`](https://github.com/martynsmith/node-irc).

However, as the necessary `node_modules` are already included in this project, I think you'll probably not have to download any of the aforementioned modules. ;)


### Building a PEGJS parser ###

For generating a PEGJS parser from a `.peg` grammar file, after having set the Ilmentufa directory as the working directory, run the following commands (we'll take the `camxes.peg` grammar for the example):

```
nodejs pegjs_conv camxes.peg
nodejs build-camxes camxes.pegjs
```

(In some installations, the keyword ``nodejs`` doesn't work and should be replaced with ``node`` instead in the above commands.)

The first command (with `pegjs_conv`) converts the pure PEG grammar file (`*.peg`) to PEGJS format, creating or updating the file `camxes.pegjs` in this example.
The second command (with `build-camxes`) creates or updates the corresponding parser engine, `camxes.js` in this case.

Building the parser can take several dozen seconds.


### Generating CBM and CKT grammars ###

The current `camxes-beta-cbm.peg` and `camxes-beta-cbm-ckt.peg` are generated from `camxes-beta.peg` using a couple scripts.
Here's how to do:

```
nodejs std-to-cbm camxes-beta.peg
nodejs make-ckt camxes-beta-cbm.peg
```


### Running a parser from command line ###

Here's how to parse the Lojban text "coi ro do" with the standard grammar parser from command line:

```
nodejs run_camxes "coi ro do"
```

The standard grammar parser is used by default, but another grammar engine can be specified.
* The `-std` flag selects the standard grammar engine.
* The `-beta` flag selects the Beta grammar engine.
* The `-cbm` flag selects the Cmevla-Brivla Merger grammar engine.
* The `-ckt` flag selects the Ce-Ki-Tau grammar engine.
* The `-exp` flag selects the experimental or sandbox grammar engine.
* `-p PATH` can be used for selecting a parser by giving its file path as a command line argument.

Additionally, `-m MODE` can be used to specify output postprocessing options.
Here, MODE can be any letter string, each letter standing for a specific option.
Here is the list of possible letters and their associated meaning:
* M -> Keep morphology
* S -> Show spaces
* C -> Show word classes (selmaho)
* T -> Show terminators
* N -> Show main node labels
* R -> Raw output, do not prune the tree, except the morphology if 'M' not present.
* J -> JSON output
* G -> Replace words by glosses
* L -> Run the parser in a loop, consume every input line terminated by a newline and output parsed result
* L -> A second 'L' means that run_camxes will expect every input line to begin with a mode string (possibly empty) followed by a space, after which the actual input follows.

Example:
```
nodejs run_camxes -m CTN "coi ro do"
```
This will show terminators, selmaho and main node labels.
 

### Running the IRC bots ###

Nothing easier; after having entered the ilmentufa directory, run the command `nodejs ircbot/camxes-bot` or `nodejs ircbot/cipra-bot` (the latter is for the experimental grammar).
The list of the channels joined by the bot can be found and edited within the bot script.


### How to use one of these parsers in a HTML interface project ###

For using a Javascript Lojban parser in a HTML interface, you'll need to include the desired `.js` parser (e.g. `camxes.js`)
to your HTML interface.
You may also want including `camxes_preproc.js` and `camxes_postproc.js`, which provide useful features. The former does optional preprocessing of Lojban text, such as replacing digits with the corresponding PA cmavo, converting nonstandard spellings or scripts into normal Latin-based Lojban text. The latter script, the postprocessor, provides a function for trimming or prettifying the parse tree generated by the parser in function of the chosen postprocessing options.

Here's a simple example code:

```
<script type="text/javascript" src="camxes.js"></script>
<script type="text/javascript" src="camxes_preproc.js"></script>
<script type="text/javascript" src="camxes_postproc.js"></script>
<script>
function run_camxes(lojban_text) {
    // We preprocess (if desired) the text using the function provided in camxes_preproc.js:
    lojban_text = camxes_preprocessing(lojban_text);
    // We run the Camxes parser and get the parse tree it generated:
    try {
        var parse_tree = camxes.parse(lojban_text);
    } catch (err) {
        DISPLAY(err.toString());
    }
    // We postprocess (if desired) the parse tree using the function provided in camxes_postproc.js:
    var postproc_options = "CTN"; // Those are the same options as those used by run_camxes.js
    var result = camxes_postprocessing(parse_tree, postproc_options);
    // `result` is a string representation of the trimmed parse tree.
    DISPLAY(result);
}
</script>
```

The postproc options are the sames as those of run_camxes.js described earlier in this file; please refer to the section `Running a parser from command line` above for more details.

You can also look into `camxes.html`'s code to see a real example of using the Lojban parsers in a HTML interface.


### Using a Javascript Lojban parser from another program or using a programming language other than Javascript ###

You can run a parser by making your program execute the following example command line:

```
nodejs run_camxes.js -m J camxes.js "jbobau vlamei"
```
(You can adapt it by providing other options flags described in the `Running a parser from command line` section above, but you'll want to keep the J option flag, so `run_camxes.js` outputs a JSON stringified array that will be easy for your program to read.)

`run_camxes.js` will then write the output parse tree in its `stdout`, so you'll need your program to read its `stdout` to get the parse result.

For example, in a Python script, you can execute run_camxes.js with the `subprocess` Python module, and then read its output this way:

```
import subprocess
try:
    import simplejson as json
except (ImportError,):
    import json

command = ['nodejs', 'run_camxes.js', '-m', 'J', 'jbobau vlamei']
output = subprocess.check_output(command)
json_string = output.decode("utf-8")

# Converting the JSON output back to nested lists:
parse_tree = json.loads(json_string)
```
