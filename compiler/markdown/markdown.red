Red [
    Title: "Nathan's markdown -> HTML compiler"
    Author: "Nathan"
    License: "MIT"
]

do %compiler/markdown/tokenizer.red
do %compiler/markdown/parser.red
do %compiler/markdown/codeGenerator.red

compile: function [
    "converts an input Markdown string into tokens"
    filename [string!]
    str [string!]
] [
    str

    newTokenizer: make Tokenizer []
    tokenStream: newTokenizer/tokenize str
    ; print prettyFormat tokenStream

    newParser: make Parser [
        file: filename
        tokens: tokenStream
    ]
    ast: newParser/parse
    ; print prettyFormat ast

    newCodeGenerator: make CodeGenerator [
        file: filename
    ]
    html: newCodeGenerator/generate ast
    print html
    ; quit
    html
]