Red [
    Title: "Nathan's markdown tokenizer"
    Author: "Nathan"
    License: "MIT"
]

do %tokens.red

Tokenizer: context [
    tokenize: function [
        "converts an input Markdown string into tokens"
        str [string!]
    ] [
        tokens: []

        ; PARSE rules

        ; this needs to go first so that e.g. `\*` matches before `*`
        literalCharacter: ["\" copy data skip (append tokens make Text [value: data]) ]

        ; we need to handle URLs explicitly so that it doesn't mess up with any of the special characters (see generator.red/slugifyFilename); it shouldn't think that e.g. an underscore is an Underscore token, for the beginning of an Emphasis node
        ; and we want `[Commodotize your complement](https://www.gwern.net/Complement#2)` to have the URL stop at `#2` - it shouldn't include the `)`, so need to exclude that too, and we might as well exclude `(` and `,` while we're at it
        whitespace: [newline | cr | lf | "^(0C)" | tab | space] ; 0C is form feed, see https://www.pcre.org/original/doc/html/pcrepattern.html
        disallowedURLCharacters: ["(" | ")" | "," | whitespace]

        url: [
            "http://" copy data to disallowedURLCharacters (
                    link: rejoin ["http://" data] 
                    append tokens make Text [value: link]
                )
            |   "https://" copy data to disallowedURLCharacters (
                    link: rejoin ["https://" data] 
                    append tokens make Text [value: link]
                )
        ]

        headers: [
                "######" (append tokens make Header6 [])
            |   "#####" (append tokens make Header5 []) 
            |   "####" (append tokens make Header4 []) 
            |   "###" (append tokens make Header3 []) 
            |   "##" (append tokens make Header2 []) 
            |    "#" (append tokens make Header1 []) 
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
                    literalCharacter
                |   
                    url
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
        rollMultipleTextTokens tokens
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
            ] [
                rolledTextValue: copy ""

                ; URLs can also have $-_.+!*(), in them (see generator.red/slugifyFilename) - so we should treat Hyphens, Underscores, NumbersWithDot, Pluses, ExclamationMarks, LeftBracket and RightBrackets as Text too, I think
                while [
                    all [
                        not tail? tokenCursor ; the text might go all the way to the end, and then there won't be an innerCurrentToken
                        found? currentToken
                        currentToken/isType "Text"
                    ]
                ] [
                    append rolledTextValue currentToken/value
                    tokenCursor: next tokenCursor
                    currentToken: first tokenCursor
                ]
                append newTokens make Token [type: "Text" value: rolledTextValue]

                ; it wasn't adding the token after a long string of Texts without this
                if (found? currentToken) [
                    append newTokens currentToken
                ]

                ; we want to jump to the end of all the Text tokens, because we'd go over the same tokens twice otherwise 
            ]

            tokenCursor: next tokenCursor
            tail? tokenCursor
        ]
        newTokens
    ]
]