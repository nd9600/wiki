Red [
    Title: "Helper functions"
]

;apply: function [f x][f x] ;monadic argument only
;apply: function [f args][do head insert args 'f]
;apply: function [f args][do append copy [f] args]
apply: function [f args][do compose [f (args)] ]

found?: function [
    x [any-type!]
] [
    not none? x
]
contains?: function [
    "returns if 's contains 'e"
    s [series!] "the series to search in"
    e [any-type!] "the element to search for"
] [
    not none? find s e
]

isOneOf: make op! function [
    "returns if 'e is inside 's"
    e [any-type!] 
    s [series!]
] [
    contains? s e
]

startsWith: function [
    "returns whether 'series starts with 'value"
    series [series!]
    value [any-type!]
] [
    match: find series value
    either all [found? match head? match] [true] [false]
]

endsWith: function [
    "returns whether 'series ends with 'value"
    series [series!]
    value [any-type!]
] [
    match: find/tail series value
    either all [found? match tail? match] [true] [false]
]

flatten: function [
    "flattens a block"
    b [block!]
] [
    flattened: copy []
    while [not tail? b] [
        element: first b
        either block? element [
            append flattened flatten element
        ] [
            append flattened element
        ]
        b: next b
    ]
    flattened
]

encap: function [
    "execute a block as a function! without polluting the global scope" 
    b [block!]
] [
    functionToExecute: function [] :b
    functionToExecute
]
|>: encap [
    pipe: function [
        "Pipes the first argument 'x to the second 'f: does [f x]"
        x [any-type!] "the argument to pass into 'f"
        f [any-function! block!] {the function to call, can be like a function! like ":square", or a block! like "[add 2]" if you want to partially apply something}
    ] [
        fInBlock: either block? :f [
            copy :f
        ] [
            append copy [] :f
        ]    
        fAndArgument: append/only copy fInBlock x
        do fAndArgument
    ]
    make op! :pipe
]

lambda: function [
    "makes lambda functions - call like [lambda [? * 2]]"
    ; https://gist.github.com/draegtun/11b0258377a3b49bfd9dc91c3a1c8c3d"
    block [block!] "the function to make"
    /applyArgs "immediately apply the lambda function to arguments"
        args [any-type!] "the arguments to apply the function to, can be a block!"
] [
    flattenedBlock: flatten block
    spec: make block! 0

    parse flattenedBlock [
        any [
            set word word! (
                if (strict-equal? first to-string word #"?") [
                    append spec word
                    ]
                )
            | skip
        ]
    ]

    spec: unique sort spec
    
    if all [
        (length? spec) > 1
        not none? find spec '?
    ] [ 
        do make error! {cannot match ? with ?name placeholders}
    ]

    f: function spec block
    
    either applyArgs [
        argsAsBlock: either block? args [args] [reduce [args]]
        apply :f argsAsBlock
    ] [
        :f
    ]
]

f_map: function [
    "The functional map"
    f  [function!] "the function to use, as a lambda function" 
    block [block!] "the block to map across"
    /notOnly "insert block! elements as single values (opposite to 'append/only)"
] [
    result: copy []
    while [not tail? block] [
        either notOnly [
            append result f first block
        ] [
            append/only result f first block
        ]
        block: next block
    ]
    result
]

f_fold: function [
    "The functional left fold"
    f [function!] "the function to use, as a lambda function" 
    init [any-type!] "the initial value"
    block [block!] "the block to fold"
] [
    result: init
    while [not tail? block] [
        result: f result first block
        block: next block
    ]
    result
]

f_filter: function [
    "The functional filter"
    condition [function!] "the condition to check, as a lambda function" 
    block [block!] "the block to fold"
] [
    result: copy []
    while [not tail? block] [
        if (condition first block) [
            append result first block
        ]
        block: next block
    ]
    result
]

assert: function [
    "Raises an error if every value in 'conditions doesn't evaluate to true. Enclose variables in brackets to compose them"
    conditions [block!]
] [
    any [
        all conditions
        do [
            e: rejoin [
                "assertion failed for: " mold/only conditions "," 
                newline 
                "conditions: [" mold compose/only conditions "]"
            ] 
            print e 
            do make error! rejoin ["assertion failed for: " mold conditions]
        ]
    ]
]

prettyFormat: function [
    "converts the thing into a nicely formatted string"
    thing [any-type!]
] [
    case [
        object? :thing [objectToString :thing]
        block? :thing [blockToString :thing]
        true [mold :thing]
    ]
]

prettyPrint: function [
    "prints the thing as a nicely formatted string"
    thing [any-type!]
] [
    print prettyFormat thing
]

objectToString: function [
    "converts the object! to a nicely formatted string"
    obj [object!]
    /objectIndent "indent the start and end of the object with a number of tabs"
        objectIndentNumber [integer!]
    /elementIndent "indent each element with a number of tabs"
        elementIndentNumber [integer!]
] [
    objectIndentNumber: either objectIndent [objectIndentNumber] [0]
    elementIndentNumber: either elementIndent [elementIndentNumber] [1]

    objectTabs: copy [] loop objectIndentNumber [append objectTabs "    "]
    keyValueTabs: copy [] loop elementIndentNumber [append keyValueTabs "    "]
    
    either (objectIndentNumber == 0) [
        str: copy "object!: [^/"
    ] [
        str: copy rejoin [objectTabs "object!: [^/"]
    ]

    words: words-of obj
    foreach word words [
        value: get in obj word

        stringifiedValue: case [
            object? :value [objectToString/elementIndent :value (elementIndentNumber + 1)]
            block? :value [blockToString/elementIndent :value (elementIndentNumber + 1)]
            true [mold :value]
        ]

        append str rejoin [keyValueTabs (to-string word) ": " stringifiedValue "^/"]
    ]

    ; the closing bracket is always 1 less indent than the keyValue indent
    append str rejoin [(next keyValueTabs) "]" ]
    
    str
]

blockToString: function [
    "converts the block! to a nicely formatted string"
    block [block!]
    /blockIndent "indent the start and end of the block with a number of tabs"
        blockIndentNumber [integer!]
    /elementIndent "indent each element with a number of tabs"
        elementIndentNumber [integer!]
] [
    blockIndentNumber: either blockIndent [blockIndentNumber] [0]
    elementIndentNumber: either elementIndent [elementIndentNumber] [1]

    blockTabs: copy [] loop blockIndentNumber [append blockTabs "    "]
    elementTabs: copy [] loop elementIndentNumber [append elementTabs "    "]

    either (blockIndentNumber == 0) [
        str: copy "[^/"
    ] [
        str: copy rejoin [blockTabs "[^/"]
    ]

    foreach element block [
        stringifiedValue: case [
            object? :element [objectToString/elementIndent :element (elementIndentNumber + 1)]
            block? :element [blockToString/elementIndent :element (elementIndentNumber + 1)]
            true [mold :element]
        ]

        append str rejoin [elementTabs stringifiedValue "^/"]
    ]

    ; the closing bracket is always 1 less indent than the keyValue indent
    append str rejoin [(next elementTabs) "]" ]
    str
]

errorToString: function [
    "adds the actual error string to the error so you can read it easily"
    error [error!]
] [
    errorIDBlock: get error/id
    arg1: mold error/arg1
    arg2: mold error/arg2
    arg3: mold error/arg3
    usefulError: bind to-block errorIDBlock 'arg1

    ; adds a space in between each thing
    usefulErrorString: form reduce reduce usefulError

    fieldsWeWant: context [
        near: error/near
        where: error/where
    ]

    rejoin [usefulErrorString newline objectToString fieldsWeWant]
]

findFiles: function [
    "find files in a directory (including sub-directories), optionally matching against a condition"
    dir [file!]
    /matching "only find files that match a condition"
        condition [any-function!] "the condition files must match"
] [
    fileList: copy []
    files: sort read dir

    ; get files in this directory
    foreach file files [

        ; so we don't add directories by accident
        if not find file "/" [
            either matching [
                if condition file [append fileList dir/:file]
            ] [
                append fileList dir/:file
            ]
        ]
    ]

    ; get files in sub-directories
    foreach file files [
        if find file "/" [

            ; we have to pass the refinement into the recursive calls too
            either matching [
                append fileList findFiles/matching dir/:file :condition
            ] [
                append fileList findFiles dir/:file
            ]
        ]
    ]
    fileList
]

deleteDir: function [
    "Deletes a directory including all files and subdirectories"
    dir [file!]
    /matching "only find files that match a condition"
        condition [any-function!] "the condition files must match"
][
    if all [
        dir? dir 
        dir: dirize dir 
        attempt [files: read dir]
    ] [
        foreach file files [
            either matching [
                deleteDir/matching dir/:file :condition
            ] [
                deleteDir dir/:file
            ]
            
        ]
    ] 
    attempt [
         either matching [
            if condition dir [delete dir]
        ] [
            delete dir
        ]
        
    ]
]

join: function [
    "Returns a reduced block of values as a string, separated by a separator"
    block [block!]
    sep [string! char!]
] [
    rejoin compose/only flatten 
        f_map lambda [reduce [? copy (to-string sep)]] block
]

pickProperties: function [
    "Pick a list of properties from an object"
    props [block!]
    obj [object!]
] [
    words: words-of obj
    propsAsWords: f_map lambda [to-word ?] props
    propsToPick: intersect words propsAsWords

    newObject: context []
    foreach word propsToPick [
        value: get in obj word
        newObject: make newObject reduce [
            (to-set-word :word) :value
        ]
    ]
    newObject
]