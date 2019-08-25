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
            "MarkdownNode" [
                (f_map lambda [self/generate ?] node/children)
                    |> lambda [join ? newline]
            ]
            "NewlineNode" [
                "<br>"
            ]
            "EmphasisNode" [
                rejoin ["<i>" node/text "</i>"]
            ]
            "StrongEmphasisNode" [
                rejoin ["<b>" node/text "</b>"]
            ]
            "StrikethroughNode" [
                rejoin ["<s>" node/text "</s>"]
            ]
        ] [
            print rejoin ["AST is " prettyFormat node]
            do make error! rejoin ["don't know how to handle " node/type]
        ]
    ]
]