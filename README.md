la ilmentufa
=========

'la ilmentufa' is a syntactical and not yet semantical parser for the Lojban language.

Read more about it at http://lojban.org/papri/la_ilmentufa


=== Requirements ===

For generating a PEGJS grammar engine from its PEG grammar file, as well as for running the IRC bot interfaces, you need to have Node.js installed on your machine.

For generating PEGJS engine, you may need to get the Node.js module 'pegjs'.
For running the IRC bots, you may need to get the Node.js module 'irc'.

However, as the necessary node_modules are already included in this project, I think you'll probably not have to download any of the aforementioned modules. ;)


=== Building a PEGJS engine ===

After having entered the ilmentufa directory, run the following command:

$ node [builder-filename]

For example, "node camxes-builder" for building the standard grammar engine or "node camxes-exp-builder" for experimental grammar.

Now, the grammar engine should have been created/updated, and be ready for use. :)


=== Running the IRC bots ===

Nothing easier; after having entered the ilmentufa directory, run the command "node ircbot/camxes-bot" or "node ircbot/cipra-bot" (the latter is for the experimental grammar).
The list of the channels joined by the bot can be found and edited within the bot script.
