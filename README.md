TiddlyWiki Build Tools
======================

`cook` and `ginsu` are tools to manipulate TiddlyWiki files. `cook` produces TiddlyWiki files from recipes that list the ingredients. `ginsu` takes a TiddlyWiki HTML file and pulls the tiddlers out into separate files.

cook
----

	Usage: cook.rb recipename [...] [options]

	Specific options:
	    -r, --root ROOT                  Root path
	    -c, --compress COMPRESS          Compress javascript, use -c, -cr, -cy or -crp
	    -C, --cplugins CPLUGINS          Compress javascript plugins, use -C, -Cr, -Cy or -Crp
	    -D, --deprecated DEPRECATED      Compress deprecated javascript, use -D, -Dr or -Drp
	    -H, --[no-]HEAD                  Compress jshead, use -H
	    -d, --dest DESTINATION           Destination directory
	    -o, --outputfile OUTPUTFILE      Output file
	    -f, --format FORMAT              Tiddler format
	    -j, --javascriptonly             Generate a file that only contains the javascript
	    -k, --keepallcomments            Keep all javascript comments
	    -i, --[no-]ignorecopy            Ingnore copy command in recipes
	    -q, --[no-]quiet                 Quiet mode, do not output file names
	    -s, --[no-]stripcommets          Strip comments
	    -t, --time                       Time modified from file system
	    -h, --help                       Show this message
	    -v, --version                    Show version


ginsu
-----

	Usage: ginsu.rb tiddlywikiname [...] [options]

	Specific options:
	    -d, --dest DESTINATION           Destination directory
	    -q, --[no-]quiet                 Quiet mode, do not output file names
	    -s, --[no-]subdirectories        Split tidders into subdirectories by type
	    -t, --tag TAGDIRECTORY           Split tidders into subdirectories by type
	    -c, --charset CHARSET            Character set of filesystem.
	    -h, --help                       Show this message
	        --version                    Show version

When used to split a TiddlyWiki file called `index.html`, Ginsu creates a directory named `index.html.0` to contain the tiddler files (The `0` bumps up if the directory already exists). It also includes a file called `split.recipe` that contains the recipe for reconstituting the original TiddlyWiki. The individual tiddlers are saved as:

* a `*.tiddler` file for text tiddlers
* a `*.js` and `*.meta` file for tiddlers tagged `systemConfig`

recipe files
------------

To come.

tiddler files
-------------

To come.
