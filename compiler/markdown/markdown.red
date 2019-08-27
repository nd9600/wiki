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

    headerTree: makeHeaderTree ast
    print prettyFormat headerTree
    quit

    newCodeGenerator: make CodeGenerator [
        file: filename
    ]
    html: newCodeGenerator/generate ast
    html
]

makeHeaderTree: function [
    ast [object!]
] [
    headers: ast/children
        |> [f_filter lambda [?/type == "HeaderNode"]]
        |> [f_map lambda [pickProperties [size text] ?]]
    print prettyFormat headers

    headerTree: []
    until [
        header: first headers

        ; 1 2 2 2 1 2 2 3 3 2 1
        ; to
        ; 1
        ; |----2
        ; |----2
        ; |----2

        ; 1
        ; |----2
        ; |----2
        ; |    |----3
        ; |    |----3
        ; |
        ; |----2

        ; 1

        ; if current.size < previous.size
        ;   append current to parent.children      
        ; 

        if header/size == 1 [
            append headerTree header
        ]

        headers: next headers
        tail? headers
    ]
    headerTree
]