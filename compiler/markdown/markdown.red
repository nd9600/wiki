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
    "converts an input Markdown string into tokens"
    filename [string!]
    str [string!]
] [
    str

    newTokenizer: make Tokenizer []
    tokenStream: newTokenizer/tokenize str
    ; prettyPrint tokenStream
    ; quit

    newParser: make Parser [
        file: filename
        tokens: tokenStream
    ]
    ast: newParser/parse
    ; prettyPrint ast

    newTocGenerator: make TocGenerator [
        ast: ast
    ]
    headerTree: newTocGenerator/makeHeaderTree
    prettyPrint headerTree

    newCodeGenerator: make CodeGenerator [
        file: filename
    ]
    html: newCodeGenerator/generate ast
    html
]