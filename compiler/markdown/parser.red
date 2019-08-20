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

    peek: function [
        "returns whether the first token has the expected type"
        expectedToken [object!]
    ] [
        firstToken: first self/tokens
        firstToken/isType expectedToken/type
    ]

    consume: function [
        "removes the first token and returns it, if it has the expected type"
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

        make HeaderNode [
            size: 1
            text: textToken/value
        ]
    ]

    parse: function [
        {parses a block! of tokens into a tree that represents the structure of the actual Markdown, something like this:
            [
                Header1 Text Newline Newline 
                Underscore Text Underscore Newline 
                NumberWithDot Text Newline 
                NumberWithDot Text Newline 
                NumberWithDot Asterisk Asterisk Text Asterisk Asterisk
            ] into
            MARKDOWN
                HEADER
                    SIZE: 1
                    TEXT: "EXAMPLE"
                BR
                EMPHASIS
                    TEXT: "EXAMPLE"
                ORDERED_LIST
                    ITEMS: [
                        TEXT
                        TEXT
                        STRONG_EMPHASIS
                            TEXT: "EXAMPLE"
                    ]
        }
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
            markdownContent: copy []
            until [
                case [
                    peek NewlineToken [parseNewline print "parsed newline"]
                    peek Header1 [
                        header1Node: parseHeader1
                        append markdownContent header1Node
                        print "parsed header1"
                    ]
                    true [
                        print rejoin ["can't handle " (objectToString first self/tokens)]
                        return none
                    ]
                ]
                ; ?? self/tokens
                tail? self/tokens
            ]

            make MarkdownNode [
                content: markdownContent
            ]
        ] [
            strError: errorToString tree
            print rejoin [newline "#####" newline "error: " strError]
            ; ?? tokens
        ]

        ?? tree

        quit

        tree
    ] 
]