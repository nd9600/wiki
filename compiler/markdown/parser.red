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

        all [
            found? token
            token/isType expectedToken/type
        ]
    ]

    consume: function [
        "removes the first token and returns it, if it has the expected type"
        expectedToken [object!]
    ] [
        currentToken: first self/tokens
        if (currentToken/isType expectedToken/type) [
            print rejoin ["consumed " expectedToken/type]
            if  equal? expectedToken/type "Text" [
                print rejoin ["consumed " mold currentToken]
            ]
            self/tokens: next self/tokens
            return currentToken
        ]
        do make error! rejoin ["expected " expectedToken/type " but got " currentToken/type]
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
        ;   if peek inline token
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
        ;   else
        ;       parse block tokens

        if error? tree: try [
            markdownChildren: copy []
            until [
                maybeParagraphNode: maybeParseParagraph
                if found? maybeParagraphNode [
                    append markdownChildren maybeParagraphNode
                ]

                if (not tail? self/tokens) [
                    maybeBlockNode: maybeParseBlockTokens
                    if found? maybeBlockNode [
                        append markdownChildren maybeBlockNode
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

    ; ####################
    ;  inline nodes
    ; ####################

    ; collects all the consecutive inline tokens into a paragraph, if it should
    maybeParseParagraph: does [
        currentToken: first self/tokens
        isParagraph: all [
            not tail? self/tokens
            found? currentToken
            any [
                currentToken/type isOneOf INLINE_TOKEN_TYPES

                ; two Backticks in a row marks the start of a code block
                all [
                    peek/at Backtick 1
                    not peek/at Backtick 2
                ]

                ; two Newlines in a row marks the start of a new paragraph
                all [
                    peek/at NewlineToken 1
                    not peek/at NewlineToken 2
                ]   
            ]
        ]
        either isParagraph [
            print "parseParagraph"
            parseParagraph
        ] [
            none
        ]
    ]

    ; collects all the consecutive inline tokens into a paragraph
    parseParagraph: does [
        paragraphNodeChildren: copy []
        lastNodeWasInline: true
        while [
            currentToken: first self/tokens
            all [
                not tail? self/tokens
                found? currentToken
                any [
                    currentToken/type isOneOf INLINE_TOKEN_TYPES

                    ; two Backticks in a row marks the start of a code block
                    all [
                        peek/at Backtick 1
                        not peek/at Backtick 2
                    ]
                    
                    ; two Newlines in a row marks the start of a new paragraph
                    all [
                        peek/at NewlineToken 1
                        not peek/at NewlineToken 2
                    ]   

                    ; parseInlineTokens returns 'none if it sees two backtick tokens in a row - this is the start of a code block, which isn't inline
                    not lastNodeWasInline
                ]
            ]
        ] [
            maybeInlineNode: parseInlineTokens
            either found? maybeInlineNode [
                append paragraphNodeChildren maybeInlineNode
            ] [
                lastNodeWasInline: false
            ]
            
        ]
        make ParagraphNode [
            children: paragraphNodeChildren
        ]
    ]

    parseInlineTokens: does [
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
            peek RightSquareBracket [
                parseRightSquareBracket
            ]
            peek LeftBracket [
                parseLeftBracket
            ]
            peek RightBracket [
                parseRightBracket
            ]

            peek Backtick [
                either peek/at Backtick 2 [ ; this is the start of a code block, which isn't inline
                    return none
                ] [
                    parseBacktick
                ]
            ]

            true [
                badToken: first self/tokens
                print rejoin ["stream is " prettyFormat copy/part self/tokens 5]
                print rejoin ["can't handle " badToken/type {Token in file "} self/file {"}]
                quit
            ]
        ]
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

        ; it's a URL; if I want to type a literal LeftSquareBracket, it'll be \[, which is just a Text token
        ; we need to handle the text like this cos it might have Underscores or Asterisks in it, and we don't want to confuse them with Emphasis markers
        if (peek Text) [
            ; the link's text is the value of all the tokens until a RightSquareBracket is peeked
            textValue: copy ""
            until [
                currentToken: first self/tokens
                append textValue currentToken/value 
                self/tokens: next self/tokens

                peek RightSquareBracket
            ]
            consume RightSquareBracket
            consume LeftBracket

            ; the link's url is the value of all the tokens until a RightBracket is peeked
            urlValue: copy ""
            until [
                currentToken: first self/tokens
                append urlValue currentToken/value 
                self/tokens: next self/tokens

                peek RightBracket
            ]
            consume RightBracket

            return make LinkNode [
                url: urlValue
                text: textValue
            ]
        ]
        return make TextNode [
            text: "["
        ]
    ]

    parseRightSquareBracket: does [
        consume RightSquareBracket
        return make TextNode [
            text: "]"
        ]
    ]

    parseLeftBracket: does [
        consume LeftBracket
        make TextNode [
            text: "("
        ]
    ]

    parseRightBracket: does [
        consume RightBracket
        make TextNode [
            text: ")"
        ]
    ]

    parseBacktick: does [
        consume Backtick
        either peek Backtick [ ; the start of a code block, which is 1 by three backticks
            consume Backtick
            consume Backtick

            ; we don't need to include this extra newline
            if (peek NewlineToken) [
                consume NewlineToken
            ]

            codeContent: copy ""
            until [
                currentToken: first self/tokens
                append codeContent currentToken/value 
                self/tokens: next self/tokens

                ; we want to ignore the last newline too
                any [
                    all [
                        peek/at NewlineToken 1
                        peek/at Backtick 2
                        peek/at Backtick 3
                        peek/at Backtick 4
                    ]   
                    all [
                        peek/at Backtick 1
                        peek/at Backtick 2
                        peek/at Backtick 3
                    ]
                ]
            ]

            if (peek NewlineToken) [
                consume NewlineToken
            ]
            consume Backtick
            consume Backtick
            consume Backtick

            ; and we want to ignore the one _after_ the three backticks
            if (peek NewlineToken) [
                consume NewlineToken
            ]

            make CodeBlockNode [
                code: codeContent
            ]

        ] [ ; or inline code, delimited by 1 backtick
            codeContent: copy ""
            until [
                currentToken: first self/tokens
                append codeContent currentToken/value 
                self/tokens: next self/tokens
                print prettyFormat currentToken
                print prettyFormat first self/tokens

                peek Backtick
            ]
            consume Backtick

            make InlineCodeNode [
                code: codeContent
            ]
        ]
    ]

    ; ####################
    ;  block nodes
    ; ####################

    maybeParseBlockTokens: does [
        case [
            all [
                peek/at NewlineToken 1 
                peek/at NewlineToken 2
            ] [
                consume NewlineToken
                consume NewlineToken
                return none
            ]
            
            peek Header1 [
                return parseHeader1
            ]
            peek Header2 [
                return parseHeader2
            ]
            peek Header3 [
                return parseHeader3
            ]
            peek Header4 [
                return parseHeader4
            ]
            peek Header5 [
                return parseHeader5
            ]
            peek Header6 [
                return parseHeader6
            ]
            
            peek GreaterThan [
                return parseGreaterThan
            ]

            peek Hyphen [
                return parseHyphen
            ]

            peek NumberWithDot [
                return parseNumberWithDot
            ]

            peek FourSpaces [
                consume FourSpaces
                return none
            ]

            peek Backtick [
                parseBacktick
            ]

            true [
                badToken: first self/tokens
                print rejoin ["stream is " prettyFormat copy/part self/tokens 5]
                print rejoin ["can't handle " badToken/type {Token in file "} self/file {"}]
                quit
            ]
        ]
    ]

    parseHeader1: does [
        consume Header1
        textToken: consume Text
        if (not tail? self/tokens) [ ; we're at the end of the file
            consume NewlineToken
        ]
        if (peek NewlineToken) [
            consume NewlineToken
        ]

        make HeaderNode [
            size: 1
            text: textToken/value
        ]
    ]
    parseHeader2: does [
        consume Header2
        textToken: consume Text
        if (not tail? self/tokens) [
            consume NewlineToken
        ]
        if (peek NewlineToken) [
            consume NewlineToken
        ]

        make HeaderNode [
            size: 2
            text: textToken/value
        ]
    ]
    parseHeader3: does [
        consume Header3
        textToken: consume Text
        if (not tail? self/tokens) [ ; we're at the end of the file
            consume NewlineToken
        ]
        if (peek NewlineToken) [
            consume NewlineToken
        ]

        make HeaderNode [
            size: 3
            text: textToken/value
        ]
    ]
    parseHeader4: does [
        consume Header4
        textToken: consume Text
        if (not tail? self/tokens) [ ; we're at the end of the file
            consume NewlineToken
        ]
        if (peek NewlineToken) [
            consume NewlineToken
        ]

        make HeaderNode [
            size: 4
            text: textToken/value
        ]
    ]
    parseHeader5: does [
        consume Header5
        textToken: consume Text
        if (not tail? self/tokens) [ ; we're at the end of the file
            consume NewlineToken
        ]
        if (peek NewlineToken) [
            consume NewlineToken
        ]

        make HeaderNode [
            size: 5
            text: textToken/value
        ]
    ]
    parseHeader6: does [
        consume Header6
        textToken: consume Text
        if (not tail? self/tokens) [ ; we're at the end of the file
            consume NewlineToken
        ]
        if (peek NewlineToken) [
            consume NewlineToken
        ]

        make HeaderNode [
            size: 6
            text: textToken/value
        ]
    ]

    parseGreaterThan: does [
        consume GreaterThan
        textToken: consume Text
        make BlockquoteNode [
            text: textToken/value
        ]
    ]

    parseHyphen: does [
        ; add all the list items to a list node
        unorderedListItemNodes: copy []
        until [
            consume Hyphen

            ; add all the inline nodes in the line to an item node
            inlineNodesInListItem: copy []
            until [
                maybeInlineNode: parseInlineTokens
                if found? maybeInlineNode [
                    append inlineNodesInListItem maybeInlineNode
                ]

                any [
                    tail? self/tokens
                    not found? maybeInlineNode
                    peek NewlineToken
                ]
            ]

            ; the list might be at the end of the file
            if (not tail? self/tokens) [
                consume NewlineToken
            ]
            append unorderedListItemNodes make UnorderedListItemNode [
                children: inlineNodesInListItem
            ]

            any [
                tail? self/tokens
                not peek Hyphen
            ]
        ]
        make UnorderedListNode [
            items: unorderedListItemNodes
        ]
    ]

    parseNumberWithDot: does [
        ; add all the list items to a list node
        orderedListItemNodes: copy []
        until [
            consume NumberWithDot

            ; add all the inline nodes in the line to an item node
            inlineNodesInListItem: copy []
            until [
                maybeInlineNode: parseInlineTokens
                if found? maybeInlineNode [
                    append inlineNodesInListItem maybeInlineNode
                ]

                any [
                    tail? self/tokens
                    not found? maybeInlineNode
                    peek NewlineToken
                ]
            ]

            ; the list might be at the end of the file
            if (not tail? self/tokens) [
                consume NewlineToken
            ]
            append orderedListItemNodes make OrderedListItemNode [
                children: inlineNodesInListItem
            ]

            any [
                tail? self/tokens
                not peek NumberWithDot
            ]
        ]
        make OrderedListNode [
            items: orderedListItemNodes
        ]
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