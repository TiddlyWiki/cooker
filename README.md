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

`.recipe` files are text files that list the components to be assembled into a TiddlyWiki. It links to a simple template file that contains the basic structure of the TiddlyWiki document with additional markers to identify parts of the file where ingredients are inserted.

Each line of the recipe file lists an ingredient, prefixed with a tag that describes what to do with the ingredient. Tags either identify a marker within the template file or are special tags that initiate an action.

The available special tags are:

	recipe: specifies a sub-recipe to be processed
	template: specifies the template file to be used
	copy: specifies an additional file that is to be copied alongside the cooked TiddlyWiki

The default TiddlyWiki template (http://github.com/TiddlyWiki/tiddlywiki/tiddlywiki.template.html) contains the following markers. Some of them invoke special processing as noted.

	version
	copyright
	prehead
	title: automatically filled in from the SiteTitle and SubTitle tiddlers
	style
	posthead
	prebody
	noscript
	shadow
	tiddler: see section on tiddler processing below
	plugin
	posttiddlers
	postbody
	prejs
	js
	postjs
	jsext
	jsdeprecated
	jslib
	jquery
	postscript

Tiddler processing
------------------

The `tiddler` marker can be used to insert text or JavaScript tiddlers:

	tiddler:TiddlerName.[js|tiddler] {optional attributes}

The `TiddlerName` can be a local file path (relative or absolute), or an http/https URL.

The optional attributes can be used to set the title, description, or tags of the tiddler. Additional tags can be added without removing any existing tags:

	tiddler:ClivesThoughts.tiddler tags="blog published"
	tiddler:LegacyStrikeThroughPlugin.js tags+="excludeLists excludeSearch"
	tiddler:temp.tiddler title="The Real Title" Description="Foo bar ear eef"

Note there is no space around `=` or `+=`.

tiddler files
-------------

Tiddler content can be retrieved from a variety of different file types:

	`*.tiddler` - a raw TiddlyWiki <DIV>
	`*.tid` - a plain text tiddler (aka TiddlyWeb format)
	`*.js` - a JavaScript plugin

Additional meta information can be provided with these optional additional filetypes:

	`TiddlerName.meta` - metadata fields like `title`, `modified`,`created`,`tags` etc.
	`TiddlerName.deps` - a listing of dependent tiddlers, useful for plugins
	
Older `*.tiddler` files look like this:

	<div tiddler="AnotherExampleStyleSheet" modifier="JeremyRuston" modified="200508181432" created="200508181432" tags="examples">This is an old-school .tiddler file, without an embedded &lt;pre&gt; tag.\nNote how the body is &quot;HTML encoded&quot; and new lines are escaped to \\n</div>

More recent `*.tiddler` files look like this:

	<div title="AnotherExampleStyleSheet" modifier="blaine" created="201102111106" modified="201102111310" tags="examples" creator="psd">
	<pre>Note that there is now an embedded <pre> tag, and line feeds are not escaped.
	
	But, weirdly, there is no HTML encoding of the body.</pre>
	</div>

These `*.tiddler` files are therefore not quite the same as the tiddlers found inside a TiddlyWiki HTML file, where the body is HTML encoded in the expected way.
