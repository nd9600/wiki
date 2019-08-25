Red [
    Title: "Nathan's markdown parser"
    Author: "Nathan"
    License: "MIT"
]

do %nodes.red

INLINE_TOKEN_TYPES: [
    "Text"
    "Asterisk"
    "Underscore"
    "Tilde"
    "LeftSquareBracket"
    "RightSquareBracket"
    "LeftBracket"
    "RightBracket"
    "Backtick"
]

Parser: context [
    file: ""
    tokens: [] ; a block! of Tokens from %tokens.red"

    peek: function [
        "returns whether the first token has the expected type"
        expectedToken [object!]
        /at
            offset [integer!]
    ] [
        offset: either at [offset] [1]
        token: pick self/tokens offset
        token/isType expectedToken/type
    ]

    consume: function [
        "removes the first token and returns it, if it has the expected type"
        expectedToken [object!]
    ] [
        currentToken: first self/tokens
        if (currentToken/isType expectedToken/type) [
            print rejoin ["consumed " expectedToken/type]
            self/tokens: next self/tokens
            return currentToken
        ]
        do make error! rejoin ["expected " expectedToken/type " but got " currentToken/type]
    ]

    parseNewline: does [
        consume NewlineToken
        make NewlineNode []
    ]

    parseText: does [
        textToken: consume Text
        make TextNode [
            text: textToken/value
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
                currentToken: first self/tokens
                do make error! rejoin ["expected Asterisk or Text but got " currentToken/type { in file "} self/file {"}]
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
                currentToken: first self/tokens
                do make error! rejoin ["expected Underscore or Text but got " currentToken/type { in file "} self/file {"}]
            ]
        ]
    ]

    parseTilde: does [
        consume Tilde
        case [
            peek Tilde [
                consume Tilde
                textToken: consume Text
                consume Tilde
                consume Tilde
                return make StrikethroughNode [
                    text: textToken/value
                ]
            ]
            peek Text [
                consume Asterisk
                textToken: consume Text
                consume Tilde
                return make StrikethroughNode [
                    text: textToken/value
                ]
            ]

            true [
                currentToken: first self/tokens
                do make error! rejoin ["expected Tilde or Text but got " currentToken/type { in file "} self/file {"}]
            ]
        ]
    ]

    parseLeftSquareBracket: does [
        consume LeftSquareBracket

        ; it's a URL
        if all [
            peek/at Text 1
            peek/at RightSquareBracket 2
            peek/at LeftBracket 3
            peek/at Text 4
            peek/at RightBracket 5
        ] [
            textToken: consume Text
            consume RightSquareBracket
            consume LeftBracket
            urlToken: consume Text
            consume RightBracket
            return make LinkNode [
                url: urlToken/value
                text: textToken/value
            ]
        ]
        return make TextToken [
            value: "["
        ]
    ]

    parseLeftBracket: does [
        consume LeftBracket
        make TextNode [
            value: "["
        ]
    ]

    parseRightBracket: does [
        consume RightBracket
        make TextNode [
            value: "]"
        ]
    ]

    parseInlineTokens: function [
    ] [
        case [
            peek NewlineToken [
                parseNewline
            ]
            peek Text [
                parseText
            ]
            peek Asterisk [
                parseAsterisk
            ]
            peek Underscore [
                parseUnderscore
            ]
            peek Tilde [
                parseTilde
            ]
            peek LeftSquareBracket [
                parseLeftSquareBracket
            ]
            peek LeftBracket [
                parseLeftBracket
            ]
            peek RightBracket [
                parseRightBracket
            ]

             true [
                badToken: first self/tokens
                print rejoin ["stream is " prettyFormat copy/part self/tokens 5]
                print rejoin ["can't handle " badToken/type {Token in file "} self/file {"}]
                quit
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
        ; while not at stream end
        ;   if peek inline node
        ;       make paragraph node
        ;       while any [
        ;           peek inlineNode
        ;           all [
        ;               peek/at NewlineToken 0
        ;               not peek/at NewlineToken 1
        ;           ]
        ;       ] [
        ;           parseInlineTokens
        ;           add node to paragraph node
        ;       ]
        ;       add paragraph node to markdownChildren

        if error? tree: try [
            markdownChildren: copy []
            until [
                currentToken: first self/tokens
                if all [
                    not tail? self/tokens
                    found? currentToken
                    any [
                        currentToken/type isOneOf INLINE_TOKEN_TYPES
                        all [
                            peek/at NewlineToken 1
                            not peek/at NewlineToken 2
                        ]   
                    ]
                ] [
                    newParagraphNodeChildren: copy []
                    while [
                        currentToken: first self/tokens
                        all [
                            not tail? self/tokens
                            found? currentToken
                            any [
                                currentToken/type isOneOf INLINE_TOKEN_TYPES
                                all [
                                    peek/at NewlineToken 1
                                    not peek/at NewlineToken 2
                                ]   
                            ]
                        ]
                    ] [
                        node: parseInlineTokens
                        append newParagraphNodeChildren node
                    ]
                    newParagraphNode: make ParagraphNode [
                        children: newParagraphNodeChildren
                    ]
                    append markdownChildren newParagraphNode
                ]

                if (not tail? self/tokens) [
                    case [
                        all [
                            peek/at NewlineToken 1 
                            peek/at NewlineToken 2
                        ] [
                            consume NewlineToken
                            consume NewlineToken
                        ]
                        peek Header1 [
                            append markdownChildren parseHeader1
                        ]
                        peek Header2 [
                            append markdownChildren parseHeader2
                        ]
                        peek Header3 [
                            append markdownChildren parseHeader3
                        ]
                        peek Header4 [
                            append markdownChildren parseHeader4
                        ]
                        peek Header5 [
                            append markdownChildren parseHeader5
                        ]
                        peek Header6 [
                            append markdownChildren parseHeader6
                        ]

                        true [
                            badToken: first self/tokens
                            print rejoin ["stream is " prettyFormat copy/part self/tokens 5]
                            print rejoin ["can't handle " badToken/type {Token in file "} self/file {"}]
                            quit
                        ]
                    ]
                ]
                tail? self/tokens
            ]

            make MarkdownNode [
                children: markdownChildren
            ]
        ] [
            strError: errorToString tree
            print rejoin ["stream is " prettyFormat copy/part self/tokens 5]
            print rejoin [newline "#####" newline "error: " strError { in file "} self/file {"}]
            quit
        ]
        tree
    ] 
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