Red [
    Title: "Nathan's markdown -> HTML table of contents maker"
    Author: "Nathan"
    License: "MIT"
    Description: {
        It makes the table using all the headers in a page's AST (you should only pass the AST in) -  header 3's are children of the first header 2 above them, header 2's are children of the first header 1 above _them_, etc.
    }
]

TocGenerator: context [
    ast: none
    headers: none

    makeHeaderTree: does [
        self/headers: ast/children
            |> [f_filter lambda [?/type == "HeaderNode"]]
            |> [f_map lambda [pickProperties [size text] ?]]
        print prettyFormat self/headers

        root: make TreeNode []
        foreach header self/headers [
            nodeToInsertInto: nodeToInsertHeaderInto root header
            nodeToInsertInto/insertNode make TreeNode [value: header]
        ]

        root/preOrder function [n] [
            if found? n/value [
                print n/value/size
            ]
        ]
        quit
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

    ; hs: reduce [
    ;     make HeaderNode [size: 1]
    ;     make HeaderNode [size: 2]
    ;     make HeaderNode [size: 2]
    ;     make HeaderNode [size: 2]

    ;     make HeaderNode [size: 1]
    ;     make HeaderNode [size: 2]
    ;     make HeaderNode [size: 2]
    ;     make HeaderNode [size: 3]
    ;     make HeaderNode [size: 3]
    ;     make HeaderNode [size: 2]

    ;     make HeaderNode [size: 1]
    ; ]
]