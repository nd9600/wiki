# wiki
My wiki

## Usage
This converts all the Markdown files in `pages/` to HTML, and makes an index for them (in `index.html` for once), with an A-to-z list, a tag tree, and a search, all static.

1. [Install Red](https://www.red-lang.org/p/download.html)
2. Copy `env.example` to .`env` and set `wikiLocation` in it to point to the foldre you want the HTML files to be added to (it will remove any existing `*.html` files in it)
3. `red generator.red`

The wiki will be where you want then :) 
