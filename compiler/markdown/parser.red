Red [
    Title: "Nathan's markdown parser"
    Author: "Nathan"
    License: "MIT"
]

parser: function [
    "build an Abstract Syntax Tree of Tokens from a block! of them"
    tokens [block!] "a block! of Tokens from %tokens.red"
] [
    rolledTokens: rollMultipleTextTokens tokens
    print blockToString rolledTokens
    tree: parseIntoTree rolledTokens
    ?? tree
    quit

    tree
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

            ; it wasn't adding the token after a long string of Texts without this
            if (found? currentToken) [
                append newTokens currentToken
            ]

            tokenCursor: next tokenCursor ; we want to jump to the end of all the Text tokens, because we'd go over the same tokens twice otherwise 
        ]
        tail? tokenCursor
    ]
    newTokens
]

parseIntoTree: function [
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
    tokens [block!]
] [
    tokens
]