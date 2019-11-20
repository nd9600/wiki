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
    html: newCodeGenerator/generate ast

    htmlWithPlugins: applyPlugins tokens ast html

    ; print htmlWithPlugins
    ; quit
    htmlWithPlugins
]

applyPlugins: function [
    "applies a list of plugins to the compiled HTML from a markdown file - each can use the HTML itself, the AST, and/or the token stream"
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