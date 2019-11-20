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

    newTocGenerator: make TocGenerator compact [
        ast
    ]
    tableOfContents: newTocGenerator/generate

    newCodeGenerator: make CodeGenerator compact [
        filename
    ]
    html: newCodeGenerator/generate ast
    ; print html
    ; quit
    rejoin [tableOfContents newline html]
]