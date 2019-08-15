Red [
    Title: "Nathan's markdown -> HTML compiler"
    Author: "Nathan Douglas"
    License: "MIT"
]

do %compiler/tokens.red

compile: function [
    "converts an input Markdown string into tokens"
    str [string!]
] [
    tokens: tokenizer str
    ; ast: parser tokens
    ; ?? ast
    ; quit

    str
]

tokenizer: function [
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

parser: function [
    "build an Abstract Syntax Tree of Tokens from a block! of them"
    tokens [block!] "a block! of Tokens from %tokens.red"
] [
    rolledTokens: rollMultipleTextTokens tokens
    rolledTokens
]

rollMultipleTextTokens: function [
    "we want to roll multiple `Text` tokens in a row into one big Token, there's no point having a thousand separate ones in a row"
    tokens [block!]
] [
    newTokens: copy []
    tokenCursor: tokens

    until [
        currentToken: first tokenCursor

        either (not currentToken/isType "Text") [
            append newTokens currentToken
            tokenCursor: next tokenCursor
        ] [
            rolledTextValue: copy ""

            while [
                all [
                    not tail? tokenCursor ; the text might go all the way to the end, and then there won't be an innerCurrentToken
                    currentToken/isType "Text"
                ]
            ] [
                append rolledTextValue currentToken/value
                tokenCursor: next tokenCursor
                currentToken: first tokenCursor
            ]
            append newTokens make Token [type: "Text" value: rolledTextValue]

            tokenCursor: next tokenCursor ; we want to jump to the end of all the Text tokens, because we'd go over the same tokens twice otherwise 
        ]

        tail? tokenCursor
    ]
    newTokens
]

escapeString: function [
    "converts iffy text to HTML entities"
    str
] [
    str
        |> [lambda/applyArgs [replace/all ? "&" "&amp;"]] ; we need to escape this first so that it doesn't escape "<" into "&lt;", then into "&amp;lt;"
        |> [lambda/applyArgs [replace/all ? "<" "&lt;"]]
        |> [lambda/applyArgs [replace/all ? ">" "&gt;"]]
        |> [lambda/applyArgs [replace/all ? {"} "&quot;"]]
        |> [lambda/applyArgs [replace/all ? {'} "&#x27;"]]
        |> [lambda/applyArgs [replace/all ? "/" "&#x2F;"]]
]