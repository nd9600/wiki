Red [
    Title: "Nathan's markdown -> HTML compiler"
    Author: "Nathan"
    License: "MIT"
]

do %compiler/markdown/tokenizer.red
do %compiler/markdown/parser.red
do %compiler/markdown/codeGenerator.red
do %compiler/markdown/tocGenerator.red

compile: function [
    "converts an input Markdown string into HTML"
    filename [string!]
    str [string!]
    return: [object!] ; [tokens: block! ast: object! html: string!]
] [
    str

    newTokenizer: make Tokenizer []
    tokens: newTokenizer/tokenize str
    ; prettyPrint tokenStream
    ; quit

    newParser: make Parser compact [
        filename
        tokens
    ]
    ast: newParser/parse
    ; prettyPrint ast
    ; quit

    newCodeGenerator: make CodeGenerator compact [
        filename
    ]
    compiledHtml: newCodeGenerator/generate ast

    html: applySinglePagePlugins tokens ast compiledHtml

    ; print html
    ; quit
    context compact [
        tokens
        ast
        html
    ]
]

applySinglePagePlugins: function [
    "applies a list of plugins to the compiled HTML from a Markdown file - each can use the HTML itself, the AST, and/or the token stream, *from that one Markdown file only*"
    tokens [block!] "see %tokens.red"
    ast [object!] "see %nodes.red"
    html [string!]
    return: [string!]
] [
    newTocGenerator: make TocGenerator compact [
        ast
    ]
    tableOfContents: newTocGenerator/generate

    rejoin [tableOfContents newline html]
]