Red [
    Title: "Nathan's markdown tokenizer"
    Author: "Nathan"
    License: "MIT"
]

do %tokens.red

tokenize: function [
    "converts an input Markdown string into tokens"
    str [string!]
] [
    tokens: []

    ; PARSE rules

    headers: [
            "#" (append tokens make Header1 []) 
        |   "##" (append tokens make Header2 []) 
        |   "###" (append tokens make Header3 []) 
        |   "####" (append tokens make Header4 []) 
        |   "#####" (append tokens make Header5 []) 
        |   "######" (append tokens make Header6 [])
    ]

    non-zero: charset "123456789"
    digit: union non-zero charset "0"
    number: [some digit]

    linkCharacters: [
            "[" (append tokens make LeftSquareBracket [])
        |   "]" (append tokens make RightSquareBracket [])
        |   "(" (append tokens make LeftBracket [])
        |   ")" (append tokens make RightBracket [])
    ]
    codeCharacters: [
            "`" (append tokens make Backtick [])
        |   4 space (append tokens make FourSpaces [])
        |   tab (append tokens make TabToken [])
    ]

    tokenRules: [
        any [
            [
                "\" copy data skip (append tokens make Text [value: data]) ; this needs to go first so that e.g. `\*` matches before `*` 
            |
                headers
            |
                ">" (append tokens make GreaterThan [])
            |
                "*" (append tokens make Asterisk [])
            |
                "_" (append tokens make Underscore [])
            |
                "~" (append tokens make Tilde [])
            |
                "+" (append tokens make Plus [])
            |
                "-" (append tokens make Hyphen [])
            |
                [copy data number "." (append tokens make NumberWithDot [value: data]) ]
            |
                linkCharacters
            |
                "!" (append tokens make ExclamationMark [])
            |
                codeCharacters
            |
                newline (append tokens make NewlineToken [])
            |
                copy data skip (append tokens make Text [value: data])
            ]
        ]
    ]

    parse str tokenRules
    tokens
]