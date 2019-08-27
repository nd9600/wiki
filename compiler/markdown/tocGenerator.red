Red [

]

TocGenerator: context [
    ast: none
    headers: none

    makeHeaderTree: does [
        self/headers: ast/children
            |> [f_filter lambda [?/type == "HeaderNode"]]
            |> [f_map lambda [pickProperties [size text] ?]]
        print prettyFormat self/headers

        headerTree: []
        until [
            currentHeader: first self/headers

            ; 1 2 2 2 1 2 2 3 3 2 1
            ; to
            ; 1
            ; |----2
            ; |----2
            ; |----2

            ; 1
            ; |----2
            ; |----2
            ; |    |----3
            ; |    |----3
            ; |
            ; |----2

            ; 1

            ; current = 1
            ; collectChildren (parentSize)

            ; until tail? headers
            ;   collect childHeaders following currentHeader
            ;   rootHeader: make Node [
            ;       size: currentHeader/size
            ;       text: currentHeader/text
            ;       children: childHeaders
            ;   ]
            ;   append headerTree rootHeader

            childHeaders: collectChildHeaders
            rootHeader: context [
                size: currentHeader/size
                text: currentHeader/text
                children: childHeaders
            ]
            append headerTree rootHeader

            self/headers: next self/headers
            tail? self/headers
        ]
        headerTree
    ]

    collectChildHeaders: does [
        rootHeader: first self/headers
        ; [1   2   2   2    1  2   2  3   3    2    1]
        ; [[1  2   2   2]  [1  2   2  3   3    2]  [1]]
        ; [[1 [2] [2] [2]] [1 [2] [2  3   3]  [2]] [1]]
        ; [[1 [2] [2] [2]] [1 [2] [2  3   3]  [2]] [1]]
        ; [[1 [2] [2] [2]] [1 [2] [2 [3] [3]] [2]] [1]]

        ;                      root
        ;        -------------------------------
        ;        |              |              |
        ;        1              1              1
        ;        |              |              
        ;    ---------      ---------          
        ;    |   |   |      |   |   |              
        ;    2   2   2      2   2   2          
        ;                       |              
        ;                      ---            
        ;                      | |           
        ;                      3 3           
        
        childHeaders: copy []
        until [
            nextHeader: next self/headers
            if all [
                found? nextHeader
                rootHeader/size < nextHeader/size
            ] [
                self/headers: next self/headers
                childrenOfNextHeader: collectChildHeaders
                childHeader: context [
                    size: currentHeader/size
                    text: currentHeader/text
                    children: childrenOfNextHeader
                ]
                append childHeaders 
            ]
            
            nextHeader: next self/headers
            any [
                tail? self/headers
                not found? nextHeader
                nextHeader/size =< rootHeader/size
            ]
        ]
        childHeaders
    ]
]