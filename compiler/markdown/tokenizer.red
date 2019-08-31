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

        newlineAndPlus: [
            [newline copy spaces any space "+"] (
                append tokens make NewlineToken []
                loop ((length? spaces) / 4) [ ; 4 spaces marks a sub-list
                    append tokens make FourSpaces []
                ]
                append tokens make Plus []
            )
        ]
        newlineAndHyphen: [
            [newline copy spaces any space "-"] (
                append tokens make NewlineToken []
                loop ((length? spaces) / 4) [ ; 4 spaces marks a sub-list
                    append tokens make FourSpaces []
                ]
                append tokens make Hyphen []
            )
        ]
        newlineAndAsterisk: [
            [newline copy spaces any space "*" not "*"] ( ; this is the start of a list, not emphasis; we want to allow "**" because that's strong emphasis
                append tokens make NewlineToken []
                loop ((length? spaces) / 4) [ ; 4 spaces marks a sub-list
                    append tokens make FourSpaces []
                ]
                append tokens make Hyphen []
            )
        ]
        newlineAndNumberWithDot: [
            [newline copy spaces any space copy data number "."] (
                append tokens make NewlineToken []
                loop ((length? spaces) / 4) [ ; 4 spaces marks a sub-list
                    append tokens make FourSpaces []
                ]
                append tokens make NumberWithDot [value: data]
            )
        ]

        hrRule: [
            [
                newline any space [
                    "***" any "*"
                |   "---" any "-"
                |   "___" any "_"
                ] newline
            ] (
                append tokens make HorizontalRule []
            )
        ]

        ; we need to handle URLs explicitly so that it doesn't mess up with any of the special characters (see generator.red/slugifyFilename); it shouldn't think that e.g. an underscore is an Underscore token, for the beginning of an Emphasis node
        ; and we want `[Commodotize your complement](https://www.gwern.net/Complement#2)` to have the URL stop at `#2` - it shouldn't include the `)`, so need to exclude that too, and we might as well exclude `(` and `,` while we're at it
        whitespace: [newline | cr | lf | "^(0C)" | tab | space] ; 0C is form feed, see https://www.pcre.org/original/doc/html/pcrepattern.html

        disallowedURLCharacter: ["(" | ")" | "," | "`" | whitespace]
        literalURLCharacter: ["\" copy data disallowedURLCharacter (append tokens make urlToken [value: data]) ]
        urlCharacter: [
                literalURLCharacter 
            |   "(" reject ; reject makes the "some urlCharacter" fail, so it will stop matching the url
            |   ")" (append tokens make RightBracket []) reject ; this is actually the RightBracket token used to mark the end of URL for a link, so we want to record that it's a RightBracket
            |   "," reject
            |   "`" (append tokens make Backtick []) reject
            |   newlineAndAsterisk reject ; we need to check for this specifically, because we are consuming the newline in the line below (it counts as whitespace), so the "newlineAndAsterisk" rule below will never be matched with "http://www.example.com\n*"
            |   newline (append tokens make NewlineToken []) reject 
            |   space (append tokens make Text [value: " "]) reject 
            |   whitespace reject
            |   copy data skip (append tokens make urlToken [value: data]) 
        ]

        url: [
                "http://" (append tokens make urlToken [value: "http://"]) some urlCharacter
            |   "https://" (append tokens make urlToken [value: "https://"]) some urlCharacter
        ]

        headers: [
                "######" (append tokens make Header [size: 6])
            |   "#####" (append tokens make Header [size: 5]) 
            |   "####" (append tokens make Header [size: 4]) 
            |   "###" (append tokens make Header [size: 3]) 
            |   "##" (append tokens make Header [size: 2]) 
            |    "#" (append tokens make Header [size: 1]) 
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
                    literalCharacter
                |   
                    url
                |
                    headers
                |
                    [newline copy spaces any space ">"] ( ; ">" is only a quote marker if it's at the start of a line
                        append tokens make NewlineToken []
                        append tokens make GreaterThan []
                    )
                |
                    hrRule
                |
                    "*" (append tokens make Asterisk [])
                |
                    "_" (append tokens make Underscore [])
                |
                    "~" (append tokens make Tilde [])
                |
                    newlineAndPlus
                |
                    newlineAndHyphen
                |
                    newlineAndAsterisk
                |
                    newlineAndNumberWithDot
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

        parse str tokenRules
        rollMultipleTextTokens tokens
    ]

    rollMultipleTextTokens: function [
        "we want to roll multiple `Text` tokens in a row into one big `Text` Token (same with `urlTokens`), there's no point having a thousand separate ones in a row"
        tokens [block!]
    ] [
        if (empty? tokens) [
            return []
        ]
        
        newTokens: copy []
        tokenCursor: tokens

        until [
            currentToken: first tokenCursor
            case [
                currentToken/isType "Text" [
                    rolledTextValue: copy ""
                    while [
                        all [
                            not tail? tokenCursor ; the text might go all the way to the end, and then there won't be an currentToken
                            found? currentToken
                            currentToken/isType "Text"
                        ]
                    ] [
                        append rolledTextValue currentToken/value
                        tokenCursor: next tokenCursor
                        currentToken: first tokenCursor
                    ]
                    append newTokens make Text [value: rolledTextValue]
                ]
                currentToken/isType "UrlToken" [
                    rolledUrlValue: copy ""
                    while [
                        all [
                            not tail? tokenCursor
                            found? currentToken
                            currentToken/isType "UrlToken"
                        ]
                    ] [
                        append rolledUrlValue currentToken/value
                        tokenCursor: next tokenCursor
                        currentToken: first tokenCursor
                    ]
                    append newTokens make UrlToken [value: rolledUrlValue]
                ]
                true [
                    append newTokens currentToken
                    tokenCursor: next tokenCursor
                ]
            ]
            tail? tokenCursor
        ]
        newTokens
    ]
]