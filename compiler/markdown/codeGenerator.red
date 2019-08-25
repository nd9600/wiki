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
            "LinkNode" [
                rejoin [{<a href="} node/url {" class="link">} node/text "</a>"]
            ]

            "HeaderNode" [
                rejoin ["<h" node/size { class="header header--} node/size {">} (node/text) "</h" node/size ">"]
            ]
            "BlockquoteNode" [
                rejoin [
                    {<blockquote class="quote">} newline
                    {<p class="quote__content">} node/text "</p>" newline
                    "</blockquote>"
                ]
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