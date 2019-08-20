Red [
    Title: "Nathan's markdown parser"
    Author: "Nathan"
    License: "MIT"
]

do %tree.red

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

Parser: context [
    tokens: [] ; a block! of Tokens from %tokens.red"

    consume: function [
        "removes the first token and returns it"
        expectedToken [object!]
    ] [
        firstToken: first self/tokens
        if (firstToken/isType expectedToken/type) [
            self/tokens: next self/tokens
            return firstToken
        ]
        do make error! rejoin ["expected " expectedToken/type " but got " firstToken/type]
    ]

    parseNewline: does [consume NewlineToken]

    ; Header ----- Newline
    parseHeader1: does [
        consume Header1
        textToken: consume Text
        consume NewlineToken

        n: make Header1Node [text: textToken/value]
        ?? n
        n
    ]

    parse: function [
        "builds an Abstract Syntax Tree of Tokens from a block! of them"
    ] [
        self/tokens: rollMultipleTextTokens self/tokens

        ; print blockToString rolledTokens

        ; tokenCursor: tokens

        ; until [
        ;     currentToken: first tokenCursor


        ;     tokenCursor: next tokenCursor
        ;     tail? tokenCursor
        ; ]

        if error? tree: try [
            parseNewline
            parseNewline
            parseHeader1
        ] [
            strError: errorToString tree
            print rejoin [newline "#####" newline "error: " strError]
            ?? tokens
        ]
        tree

        ?? tree

        quit

        tree
    ] 
]