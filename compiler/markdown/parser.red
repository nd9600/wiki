Red [
    Title: "Nathan's markdown parser"
    Author: "Nathan"
    License: "MIT"
]

do %nodes.red

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

    parseNewline: does [
        consume NewlineToken
        either (peek NewlineToken) [
            consume NewlineToken
            make NewlineNode []
        ] [
            none
        ]
    ]

    parseHeader1: does [
        consume Header1
        textToken: consume Text
        consume NewlineToken

        make HeaderNode [
            size: 1
            text: textToken/value
        ]
    ]
    parseHeader2: does [
        consume Header2
        textToken: consume Text
        consume NewlineToken

        make HeaderNode [
            size: 2
            text: textToken/value
        ]
    ]
    parseHeader3: does [
        consume Header3
        textToken: consume Text
        consume NewlineToken

        make HeaderNode [
            size: 3
            text: textToken/value
        ]
    ]
    parseHeader4: does [
        consume Header4
        textToken: consume Text
        consume NewlineToken

        make HeaderNode [
            size: 4
            text: textToken/value
        ]
    ]
    parseHeader5: does [
        consume Header5
        textToken: consume Text
        consume NewlineToken

        make HeaderNode [
            size: 5
            text: textToken/value
        ]
    ]
    parseHeader6: does [
        consume Header6
        textToken: consume Text
        consume NewlineToken

        make HeaderNode [
            size: 6
            text: textToken/value
        ]
    ]

    parseAsterisk: does [
        consume Asterisk
        case [
            peek Text [
                textToken: consume Text
                consume Asterisk
                return make EmphasisNode [
                    text: textToken/value
                ]
            ]
            peek Asterisk [
                consume Asterisk
                textToken: consume Text
                consume Asterisk
                consume Asterisk
                return make StrongEmphasisNode [
                    text: textToken/value
                ]
            ]

            true [
                firstToken: first self/tokens
                do make error! rejoin ["expected Asterisk or Text but got " firstToken/type]
            ]
        ]
    ]

    parseUnderscore: does [
        consume Underscore
        case [
            peek Text [
                textToken: consume Text
                consume Underscore
                return make EmphasisNode [
                    text: textToken/value
                ]
            ]
            peek Underscore [
                consume Underscore
                textToken: consume Text
                consume Underscore
                consume Underscore
                return make StrongEmphasisNode [
                    text: textToken/value
                ]
            ]

            true [
                firstToken: first self/tokens
                do make error! rejoin ["expected Underscore or Text but got " firstToken/type]
            ]
        ]
    ]

    parse: function [
        {parses a block! of tokens into a tree that represents the structure of the actual Markdown, something like this:
            [
                Header1 Text Newline Newline 
                Underscore Text Underscore Newline 
                Text Newline
                Text
                NumberWithDot Text Newline 
                NumberWithDot Text Newline 
                NumberWithDot Asterisk Asterisk Text Asterisk Asterisk
            ] into
            MARKDOWN
                HEADER
                    SIZE: 1
                    TEXT: "EXAMPLE"
                BR
                PARAGRAPH
                    EMPHASIS
                        TEXT: "EXAMPLE"
                    TEXT: EXAMPLE
                    BR
                    TEXT: EXAMPLE
                    BR
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
        if error? tree: try [
            markdownContent: copy []
            until [
                case [
                    peek NewlineToken [
                        maybeNewlineNode: parseNewline
                        if (found? maybeNewlineNode) [
                            append markdownContent maybeNewlineNode
                        ]
                        print "parsed newline"
                    ]
                    peek Header1 [
                        append markdownContent parseHeader1
                        print "parsed header1"
                    ]
                    peek Header2 [
                        append markdownContent parseHeader2
                        print "parsed header2"
                    ]
                    peek Header3 [
                        append markdownContent parseHeader3
                        print "parsed header3"
                    ]
                    peek Header4 [
                        append markdownContent parseHeader4
                        print "parsed header4"
                    ]
                    peek Header5 [
                        append markdownContent parseHeader5
                        print "parsed header5"
                    ]
                    peek Header6 [
                        append markdownContent parseHeader6
                        print "parsed header6"
                    ]

                    peek Asterisk [
                        append markdownContent parseAsterisk
                        print "parsed asterisk"
                    ]
                    peek Underscore [
                        append markdownContent parseUnderscore
                        print "parsed underscore"
                    ]

                    true [
                        print rejoin ["can't handle " (objectToString first self/tokens)]
                        return none
                    ]
                ]
                tail? self/tokens
            ]

            make MarkdownNode [
                content: markdownContent
            ]
        ] [
            strError: errorToString tree
            print rejoin [newline "#####" newline "error: " strError]
        ]
        tree
    ] 
]