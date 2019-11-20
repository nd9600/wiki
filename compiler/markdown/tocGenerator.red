Red [
    Title: "Nathan's markdown -> HTML table of contents maker"
    Author: "Nathan"
    License: "MIT"
    Description: {
        It makes the table using all the headers in a page's AST (you should only pass the AST in) -  header 3's are children of the first header 2 above them, header 2's are children of the first header 1 above _them_, etc.
    }
]

do %tree.red

TocGenerator: context [
    ast: none

    generate: does [
        headerTree: makeHeaderTree
        if not found? headerTree [
            return ""
        ]
        
        childrenContent: (f_map lambda [generateListForNode ?] headerTree/children)
            |> :rejoin

        rejoin [
            {<section class="toc">} newline
                {<p class="toc__header"> Table of contents </p>}
                {<ol class="list list--ordered">} newline
                    childrenContent newline
                "</ol>"
            "</section>"
        ]
    ]

    makeHeaderTree: function [] [
        headers: ast/children
            |> [f_filter lambda [?/type == "HeaderNode"]]
            |> [f_map lambda [pickProperties [size text] ?]]

        if empty? headers [
            return none
        ]

        headerTree: make TreeNode []
        foreach header headers [
            nodeToInsertInto: nodeToInsertHeaderInto headerTree header
            nodeToInsertInto/insertNode make TreeNode [value: header]
        ]
        headerTree
    ]

    nodeToInsertHeaderInto: function [
        "find the node in the tree where the header should be inserted"
        n [object!]
        header [object!]
    ] [
        ; each header is inserted as a child of (the rightmost node whose header's size is smaller than it - if there isn't one, it's the root)
        ; this finds that rightmost node

        ; if this node doesn't have any children, we can only insert it here
        if empty? n/children [
            return n
        ]

        ; if the last child has the same size as the header we want to insert, we actually want to insert it here
        lastChild: last n/children
        lastHeader: lastChild/value
        if lastHeader/size == header/size [
            return n
        ]

        ; otherwise, we recurse into the last child's subtree
        return nodeToInsertHeaderInto lastChild header
    ]

    generateListForNode: function [
        {
            Makes
                <ul>
                    <li>
                        Technology
                        <ul>
                            <li>Boundaries, Gary Bernhardt</li>
                            <li>
                                Radical stuff
                                <ul>
                                    <li>Test 3rd category</li>
                                </ul>
                            </li>
                            <li>AI</li>
                            <li>Guides</li>
                        </ul>
                    </li>
                    <li>Biology</li>
                </ul>
        }
        node [object!]
    ] [
        header: node/value

        childrenLists: either empty? node/children [
            ""
        ] [
            childrenContent: (f_map lambda [generateListForNode ?] node/children)
                |> :rejoin
            rejoin [
                {<ol class="m-0 m-0 list list--ordered m-0">}
                    childrenContent
                "</ol>"
            ]
        ]
            
        if not found? header [ ; this is the root node
            return rejoin [
                {<li class="list__item list__item--ordered">} newline
                    childrenLists newline
                "</li>"
            ]
        ]
        headerId: header/text 
            |> :trim 
            |> :slugifyString

        rejoin [
            {<li class="list__item list__item--ordered">}
                {<a class="link link--index" href="#} headerId {">}
                    header/text
                "</a>"
                childrenLists newline
            "</li>"
        ]
    ]
]