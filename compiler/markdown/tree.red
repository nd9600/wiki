Red [
    Title: "Nathan's generic Tree data structure"
    Author: "Nathan"
    License: "MIT"
    Description: {
        Use like 
        ```
        root: make TreeNode [value: 1234]
        n1: make TreeNode [value: 1]
        n2: make TreeNode [value: 2]
        n1/insertNode n2

        n3: make TreeNode [value: 3]

        root/insertNode n1
        root/insertNode n3
        ```
    }   
]

TreeNode: context [
    parent: none
    value: none
    children: []

    isRoot: does [not found? parent]

    insertNode: function [
        "appends a node to the list of children"
        child [object!]
    ] [
        child/parent: self
        append self/children child
    ]

    preOrder: function [
        "does a pre-order traversal of the node, calling 'f with the current node"
        f [any-function!]
    ] [
        f self
        foreach n self/children [
            n/preOrder :f
        ]
    ]

    ; children must be partitioned into left and right sub-trees for an in-order traversal

    postOrder: function [
        "does a post-order traversal of the node, calling 'f with the current node"
        f [any-function!]
    ] [
       foreach n self/children [
            n/postOrder :f
        ]
        f self
    ]
]