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
] [
    result: copy/deep block
    while [not tail? result] [
        replacement: f first result
        result: change/part result replacement 1
    ]
    head result
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

objectToString: function [
    obj [object!]
] [
    words: words-of obj
    values: values-of obj
    str: copy ""
    repeat i length? words [
        append str rejoin [words/(i) ": " values/(i) "^/"]
    ]
    str
]

errorToString: function [
    "adds the actual error string to the error so you can read it easily"
    error [error!]
] [
    errorIDBlock: get error/id
    arg1: to-string error/arg1
    arg2: to-string error/arg2
    arg3: to-string error/arg3
    usefulError: bind to-block errorIDBlock 'arg1

    ; adds a space in between each thing
    usefulErrorString: form reduce reduce usefulError

    fieldsWeWant: context [
        near: error/near
        where: error/where
    ]

    rejoin [usefulErrorString newline form errorIDBlock newline newline objectToString fieldsWeWant]
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

sepJoin: function [
    "Returns a reduced block of values as a string, separated by a separator"
    block [block!]
    sep [string! char!]
] [
    rejoin compose/only flatten 
        f_map lambda [reduce [? copy (sep)]] block
]