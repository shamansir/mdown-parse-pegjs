Markdown parser with PegJS
==========================

A Markdown parser written in JavaScript, generated with PEG grammar. Currently, in progress.

This is a component of [xtd][xtd-md] project, but I plan to finish developing it separately and then merge the result there. (So, the most part of its development history is located there). 

In fact, it is a translation of [PegC Markdown parser][] to JavaScript. But in the end, there are a lot differences in the sources and result.

The both C variant and JS (this) variant build a tree of parsed document elements, including their offsets and additional data required for generating some HTML result or hightlighting a syntax in some JavaScript implementation. 

Sources
-------

* [Markdown][] by [John Gruber][], a great documents' syntax agreement
* [PegJS][] by [David Majda][], a JavaScript parsers generator using PEG-like grammars
* [My Customized PegJS Implementation][] with `chunk` variables inside actions and merged with [PegJS predicate fix][].  
* [PegC GUI-oriented Markdown parser][] by [Ali Rantakari][], the place where I've found a parser and copied it and now I am modifying it for JavaScript
* [PegC Markdown parser][] by [John MacFarlane][], the version the previous author adapted to implement his GUI-oriented version and in fact the actual and the main PegC parser (and I am taking parts from there to include new things here)
* [PegC][] by [Stephan Beal][], itself
* [PegHS Markdown parser][], again by [John MacFarlane][], if you are interested
* [Codemirror 2][], the nerdy JS-written any-language source-code editor I plan to integrate with
* [MDTest 1.1][] by [Michel Fortin][]

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
* Oh, all that stuff except complex lists

Not finished

(They were working some not ideal way, but I am currently refactoring this part)

* Nested lists and blocks inside them
* Different extra syntax
* Search over the new stuff in [PegC Markdown parser][] implementation
* Test over for for [Markdown Syntax][]
* Check out [Markdown Gotchas][]
* Test with [MDTest 1.1][] by [Michel Fortin][]
* Support [Markdown Extra][]

So currently, the *lists* are parsed ok, but I plan to modify their rules to support complex indentations. 

Which Way the Result Looks Like
-------------------------------

When parsing a MarkDown document, you get a JavaScript Object containing the document tree in Markdown terms. I'll make a detailed description when I'll finish an implementation.

Competitors
-----------

Just a JS-ones:

* [Showdown][] by [Corey Innis][]
* [MarkdownJS][] by [Dominic Baggott][]
* [Pagedown][] used at [StackOverflow][]
* [WMDEditor][] used at [StackOverflow][]

To Develop
----------

Install last [node.js][] version (`v0.5.8+`)

Install [npm][]

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

[xtd-md]: https://github.com/shamansir/xtd/tree/master/sources/assets/mdown-parse-pegjs

[Markdown]: http://daringfireball.net/projects/markdown/syntax
[Markdown Syntax]: http://daringfireball.net/projects/markdown/syntax
[Markdown Extra]: http://michelf.com/projects/php-markdown/extra/
[Codemirror 2]: http://codemirror.net/

[PegC]: http://fossil.wanderinghorse.net/repos/pegc/index.cgi/index
[PegJS]: http://pegjs.majda.cz
[My Customized PegJS Implementation]: https://github.com/shamansir/pegjs
[PegJS predicate fix]: https://github.com/jdarpinian/pegjs

[PegC Markdown Parser]: https://github.com/jgm/peg-markdown
[PegC GUI-oriented Markdown parser]: http://hasseg.org/peg-markdown-highlight/
[PegHS Markdown Parser]: https://github.com/jgm/markdown-peg

[John Gruber]: http://daringfireball.net/
[John MacFarlane]: http://johnmacfarlane.net/
[David Majda]: http://majda.cz/en/
[Ali Rantakari]: http://hasseg.org
[Dominic Baggott]: http://www.evilstreak.co.uk/
[Corey Innis]: http://coolerator.net/
[Michel Fortin]: http://michelf.com/
[Stephan Beal]: http://wanderinghorse.net/home/stephan

[Showdown]: https://github.com/coreyti/showdown
[MarkdownJS]: https://github.com/evilstreak/markdown-js/blob/master/lib/markdown.js
[Pagedown]: http://code.google.com/p/pagedown/
[WMDEditor]: http://code.google.com/p/wmd/
[StackOverflow]: http://stackoverflow.com/

[node.js]: http://nodejs.org/#download
[npm]: http://npmjs.org/
[MDTest 1.0]: http://six.pairlist.net/pipermail/markdown-discuss/2007-July/000674.html
[MDTest 1.1]: http://git.michelf.com/mdtest/
