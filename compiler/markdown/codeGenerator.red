Red [
    Title: "Nathan's markdown -> HTML code generator"
    Author: "Nathan"
    License: "MIT"
]

CodeGenerator: context [
    file: ""

    generate: function [
        "recursively generates the HTML for a node in %nodes.red"
        node [object!]
    ] [
        switch/default node/type [
            "MarkdownNode" [
                (f_map lambda [self/generate ?] node/children)
                    |> lambda [join ? newline]
            ]
            "ParagraphNode" [
                paragraphContent: (f_map lambda [self/generate ?] node/children)
                    |> lambda [join ? newline]
                rejoin [{<p class="paragraph">} newline paragraphContent "</p>"]
            ]

            "NewlineNode" [
                "<br>"
            ]
            "TextNode" [
                node/text
            ]
            "EmphasisNode" [
                rejoin [{<i class="italic">} node/text "</i>"]
            ]
            "StrongEmphasisNode" [
                rejoin [{<b class="bold">} node/text "</b>"]
            ]
            "StrikethroughNode" [
                rejoin [{<s class="strikethrough">} node/text "</s>"]
            ]

            "UnorderedListNode" [
                unorderedListItems: (f_map lambda [self/generate ?] node/items)
                    |> lambda [join ? newline]
                rejoin [{<ul class="unorderedList">} newline unorderedListItems "</ul>"]
            ]
            "UnorderedListItemNode" [
                itemContent: (f_map lambda [self/generate ?] node/children)
                    |> [rejoin]
                rejoin [{<li class="unorderedList--item">} itemContent "</li>"]
            ]
        ] [
            print rejoin ["AST is " prettyFormat node]
            do make error! rejoin ["can't handle " node/type { in file "} self/file {"}]
        ]
    ]
]