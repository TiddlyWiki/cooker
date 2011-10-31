TiddlyWiki Build Tools
======================

`cook` and `ginsu` are tools to manipulate TiddlyWiki files. `cook` produces TiddlyWiki files from recipes that list the ingredients. `ginsu` takes a TiddlyWiki HTML file and pulls the tiddlers out into separate files.

cook
----

Usage: cook.rb recipename [options]

Specific options:
    -d, --dest DESTINATION           destination directory
    -f, --format FORMAT              tiddler format
    -q, --[no-]quiet                 quiet mode, do not output file names
    -s, --[no-]stripcommets          strip all JavaScript comments
    -h, --help                       display help message
    -v, --version                    display version number

ginsu
-----

Usage: ginsu.rb [tiddlywikiname]

Specific options:
    -h, --help                       Show this message

When used to split a TiddlyWiki file called `index.html`, Ginsu creates a directory named `index.html.0` to contain the tiddlers (The `0` bumps up if the directory already exists). It also includes a file called `split.recipe` that contains the recipe for constituting them. The individual tiddlers are saved either as:

* a `*.tiddler` file for text tiddlers
* a `*.js` and `*.meta` file for tiddlers tagged `systemConfig`

recipe files
------------

To come.

tiddler files
-------------

To come.
