la ilmentufa
=========

_la ilmentufa_ is a syntactical and not yet semantical parser for the Lojban language.

Read more about it at http://lojban.org/papri/la_ilmentufa


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
* `-p PATH` can be used for select a parser by giving its file path as a command line argument.

Additionally, `-m MODE` can be used to specify output postprocessing options.
Here, MODE can be any letter string, each letter stands for a specific option.
Here is the list of possible letters and their associated meaning:
* 'M' -> Keep morphology
* 'S' -> Show spaces
* 'C' -> Show word classes (selmaho)
* 'T' -> Show terminators
* 'N' -> Show main node labels
* 'R' -> Raw output, do not prune the tree, except the morphology if 'M' not present.

Example:
```
nodejs run_camxes -m CTN "coi ro do"
```
This will show terminators, selmaho and main node labels.
 

### Running the IRC bots ###

Nothing easier; after having entered the ilmentufa directory, run the command `nodejs ircbot/camxes-bot` or `nodejs ircbot/cipra-bot` (the latter is for the experimental grammar).
The list of the channels joined by the bot can be found and edited within the bot script.
