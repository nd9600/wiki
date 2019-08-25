Red [
    Title: "Nathan's markdown -> HTML code generator"
    Author: "Nathan"
    License: "MIT"
]

CodeGenerator: context [
    generate: function [
        "recursively generates the HTML for a node in %nodes.red"
        node [object!]
    ] [
        switch/default node/type [

        ] [
            print rejoin ["AST is " prettyFormat node]
            do make error! rejoin ["don't know how to handle " node/type]
        ]
    ]
]