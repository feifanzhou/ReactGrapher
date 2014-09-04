ReactGrapher
============

Generate basic Graphviz diagrams showing relationships between ReactJS components. 

Requires Graphviz to be installed. On OS X, easiest to install through brew: `brew install graphviz`

# Usage
`ruby react_grapher.rb <input> <output>`

`input` is a path to a JS file or a folder containing JS files. Filenames must contain `.js`, and folders are *not* traversed recursively.

`output` is a path to an output file. The script will parse the filename and output in the format you specify — for example, `output.ps` will output a PostScript file while `output.bmp` will output a Bitmap file. See the [Graphviz documentation](http://www.graphviz.org/doc/info/output.html) for supported output formats.
