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
                    |> :rejoin
                rejoin [{<p class="paragraph">} newline paragraphContent newline "</p>"]
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
            "ImageNode" [
                rejoin [
                    {<a href="} node/src {" target="_blank">} newline
                        {<img src="} node/src {" alt="} node/alt {" class="img"/>} newline
                    "</a>"
                ]
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
                rejoin [{<ul class="list list--unordered">} newline unorderedListItems "</ul>"]
            ]
            "UnorderedListItemNode" [
                itemContent: (f_map lambda [self/generate ?] node/children)
                    |> :rejoin
                rejoin [{<li class="list__item list__item--unordered">} itemContent "</li>"]
            ]

            "OrderedListNode" [
                orderedListItems: (f_map lambda [self/generate ?] node/items)
                    |> lambda [join ? newline]
                rejoin [{<ol class="list list--ordered">} newline orderedListItems "</ol>"]
            ]
            "OrderedListItemNode" [
                itemContent: (f_map lambda [self/generate ?] node/children)
                    |> :rejoin
                rejoin [{<li class="list__item list__item--unordered">} itemContent "</li>"]
            ]

            "InlineCodeNode" [
                rejoin [{<code class="code code--inline">} node/code "</code>"]
            ]
            "CodeBlockNode" [
                rejoin [{<pre class="pre"><code class="code code--block">} node/code "</code></pre>"]
            ]
        ] [
            print rejoin ["AST is " prettyFormat node]
            do make error! rejoin ["can't handle " node/type { in file "} self/file {"}]
        ]
    ]
]