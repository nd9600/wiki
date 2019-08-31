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
    astToUse: none
    headers: none

    generate: does [
        headerTree: makeHeaderTree

        ; print "preOrder"
        ; headerTree/preOrder function [n] [
        ;     if found? n/value [
        ;         prettyPrint n/value
        ;     ]
        ; ]
        rejoin [
            {<ul class="list list--unordered">}
            generateListForNode headerTree
            "</ul>"
        ]
    ]

    generateListForNode: function [
        n [object!]
    ] [
        header: n/value
        text: either found? header [
            header/text
        ] [
            ""
        ]

        childrenLists: copy ""
        foreach c n/children [
            childHeader: c/value
            childrenContent: (f_map lambda [generateListForNode ?] n/children)
                |> :rejoin
            append childrenLists rejoin [
                {<ul class="list list--unordered">}
                    childrenContent
                "</ul>"
            ]
            
        ]
        rejoin [
            {<li class="list__item list__item--unordered">}
            text
            childrenLists
            "</li>"
        ]
    ]

    makeHeaderTree: does [
        self/headers: astToUse/children
            |> [f_filter lambda [?/type == "HeaderNode"]]
            |> [f_map lambda [pickProperties [size text] ?]]

        headerTree: make TreeNode []
        foreach header self/headers [
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
        ; insert each header as a child of the rightmost node whose header's size is smaller than it - if they're isn't one, it's the root

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
]