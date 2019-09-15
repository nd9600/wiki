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
        /innerList "if the node is a list inside another list"
    ] [
        switch/default node/type [
            "MarkdownNode" [
                if empty? node/children [
                    return ""
                ]
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
                headerId: node/text 
                    |> :trim 
                    |> :slugifyString
                rejoin [{<h} node/size 
                    { class="header header--} node/size {"} 
                    { id="} headerId {"} 
                    {>} 
                        node/text
                        {<a class="link header__link" href="#} headerId {" >#</a>}
                    {</h} node/size {>}
                ]
            ]
            "BlockquoteNode" [
                content: (f_map lambda [self/generate ?] node/children)
                    |> :rejoin
                rejoin [
                    {<blockquote class="quote">} newline
                    {<p class="quote__content">} content "</p>" newline
                    "</blockquote>"
                ]
            ]

            "ListNode" [
                listItems: either innerList [
                    (f_map lambda [self/generate/innerList ?] node/items)
                        |> lambda [join ? newline]
                ] [
                    (f_map lambda [self/generate ?] node/items)
                        |> lambda [join ? newline]
                ]

                listTag: either node/isOrdered ["ol"] ["ul"]
                listModifierClass: either node/isOrdered ["list--ordered"] ["list--unordered"]

                either innerList [
                    rejoin ["<" listTag { class="list } listModifierClass { list--inner">} newline listItems "</" listTag ">"]
                ] [
                    rejoin ["<" listTag { class="list } listModifierClass {">} newline listItems "</" listTag ">"]
                ]
            ]
            "ListItemNode" [
                itemContent: (f_map lambda [self/generate/innerList ?] node/children)
                    |> :rejoin
                either node/doesntHaveListStyle [
                    rejoin [{<li class="list__item list__item--noListStyle">} itemContent "</li>"]
                ] [
                    rejoin [{<li class="list__item">} itemContent "</li>"]
                ]
            ]

            "InlineCodeNode" [
                rejoin [{<code class="code code--inline">} node/code "</code>"]
            ]
            "CodeBlockNode" [
                rejoin [{<pre class="pre"><code class="code code--block">} node/code "</code></pre>"]
            ]

            "HorizontalRuleNode" [
                {<hr class="hr">}
            ]
        ] [
            print rejoin ["AST is " prettyFormat node]
            do make error! rejoin ["can't handle " node/type { in file "} self/file {"}]
        ]
    ]
]