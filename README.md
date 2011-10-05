Markdown parser with PegJS
==========================

A Markdown parser written in JavaScript, generated with PEG grammar. Currently, in progress.

This is a component of [xtd](https://github.com/shamansir/xtd/tree/master/sources/assets/mdown-parse-pegjs) project, but I plan to finish developing it separately and then merge the result there. (So, the most part of its development history is located there). 

In fact, it is a translation of [PegC Mardown parser](https://github.com/jgm/peg-markdown) to JavaScript. But in the end, there are a lot differences in the sources and result.

The both C variant and JS (this) variant build a tree of parsed document elements, including their offsets and additional data required for generating some HTML result or hightlighting a syntax in some JavaScript implementation. 

Sources
-------

* [Markdown](http://daringfireball.net/projects/markdown/syntax) by [John Gruber](http://daringfireball.net/), a great documents' syntax agreement
* [PegJS](http://pegjs.majda.cz) by [David Majda](http://majda.cz/en/), a JavaScript parsers generator using PEG-like grammars
* [My Customized PegJS Implementation](https://github.com/shamansir/pegjs) with `chunk` variables inside actions and merged with [this](https://github.com/jdarpinian/pegjs) PegJS predicate fix.  
* [PegC GUI-oriented Markdown parser](http://hasseg.org/peg-markdown-highlight/) by [Ali Rantakari](http://hasseg.org), the place where I've found a parser and copied it and now I am modifying it for JavaScript
* [PegC Markdown parser](https://github.com/jgm/peg-markdown) by [John MacFarlane](http://johnmacfarlane.net/), the version the previous author adapted to implement his GUI-oriented version and in fact the actual and the main PegC parser (and I am taking parts from there to include new things here)
* [PegC](http://fossil.wanderinghorse.net/repos/pegc/index.cgi/index), itself
* [PegHS Markdown parser](https://github.com/jgm/markdown-peg), again by [John MacFarlane](http://johnmacfarlane.net/), if you are interested
* [Codemirror 2](http://codemirror.net/), the nerdy JS-written any-language source-code editor I plan to integrate with

The Development State
---------------------

Finished

* Inlines: Strong, Em, Code
* Html Blocks, Html entities
* Headings
* Horizontal Rules
* Paragraphs
* Top-level Lists
* Top-level verbatims
* Links, all modifications
* Images, all modifications
* Oh, all that stuff except complex lists and blockqoutes

Not finished

(They were working some not ideal way, but I am currently refactoring this part)

* Blockquotes and complex blockquotes
* Nested lists and blocks inside them
* Different extra syntax
* Search over the new stuff in [PegC Markdown parser](https://github.com/jgm/peg-markdown) implementation

So currently, the *lists* are parsed ok, but I plan to modify their rules to support complex indentations. 

Which Way the Result Looks Like
-------------------------------

When parsing a MarkDown document, you get a JavaScript Object containing the document tree in Markdown terms. I'll make a detailed description when I'll finish an implementation.

To Develop
----------

Install last [node.js](http://nodejs.org/#download) version (`v0.5.8+`)

Install [npm](http://npmjs.org/)

Run in node directory (or with `-g`):

    npm install pegjs
    npm install jake@1.7 # or higher

    cd ~/Worktable # (for example)
    git clone git@github.com:shamansir/pegjs.git
    cd ./pegjs
    jake build
    node test/run
    ln -sf ~/Worktable/pegjs <nodejs-location>/lib/node_modules
    ln -s <nodejs-location>/lib/node_modules ./node_modules # optional, if pegjs module not found
    cd ~/Workspace # (for example) 
    git clone git@github.com:shamansir/mdown-parse-pegjs.git
    cd ./mdown-parse-pegjs
    node ./test-mdown-parser-with-node.js