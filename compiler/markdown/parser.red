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
    "ExclamationMark"
    "UrlToken"
]

Parser: context [
    filename: ""
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
                    CHILDREN: [
                        TEXT
                        TEXT
                        STRONG_EMPHASIS
                            TEXT: "EXAMPLE"
                    ]
        }
    ] [        
        ; while not at stream end
        ;   maybeParseParagraph, add to markdownChildren
        ;   if not at stream end
        ;       parse block tokens, add to markdownChildren

        if error? tree: try/all [
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
            print rejoin [newline "#####" newline "error: " strError { in file "} self/filename {"}]
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

                    ; maybeParseInlineTokens returns 'none if it sees two backtick tokens in a row - this is the start of a code block, which isn't inline
                    not lastNodeWasInline
                ]
            ]
        ] [
            maybeInlineNode: maybeParseInlineTokens
            either found? maybeInlineNode [
                if any [ ; we don't want to include a blank line at the start of a paragraph, it looks bad
                    not empty? paragraphNodeChildren
                    maybeInlineNode/type <> "NewlineNode"
                ] [
                    append paragraphNodeChildren maybeInlineNode
                ]
            ] [
                lastNodeWasInline: false
            ]  
        ]

        ; we don't want newlines at the end of paragraphs, either
        if empty? paragraphNodeChildren [
            return none
        ]
        lastNodeInParagraph: last paragraphNodeChildren
        if (lastNodeInParagraph/type == "NewlineNode") [
            remove back tail paragraphNodeChildren
        ]

        make ParagraphNode [
            children: paragraphNodeChildren
        ]
    ]

    maybeParseInlineTokens: does [
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

            ; it's inline if it's just a !
            peek ExclamationMark [
                parseExclamationMark
            ]

            peek UrlToken [
                parseUrlToken
            ]

            true [
                badToken: first self/tokens
                print rejoin ["stream is " prettyFormat copy/part self/tokens 5]
                print rejoin ["can't handle " badToken/type {Token in file "} self/filename {", maybeParseInlineTokens}]
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
                do make error! rejoin ["expected Asterisk or Text but got " currentToken/type { in file "} self/filename {"}]
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
                do make error! rejoin ["expected Underscore or Text but got " currentToken/type { in file "} self/filename {"}]
            ]
        ]
    ]

    parseTilde: does [
        consume Tilde
        if peek Tilde [
            consume Tilde
        ]

        strikethroughText: copy ""
        until [
            currentToken: first self/tokens
            if (found? currentToken) [
                append strikethroughText currentToken/value 
            ]
            self/tokens: next self/tokens

            peek Tilde
            any [
                tail? self/tokens
                not found? currentToken
                peek Tilde
            ]
        ]
        consume Tilde
        if peek Tilde [
            consume Tilde
        ]

        return make StrikethroughNode [
            text: strikethroughText
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
                ; empty text
                if peek RightSquareBracket [
                    break
                ]

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
                ; empty link
                if peek RightBracket [
                    break
                ]

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
                code: escapeString codeContent
            ]

        ] [ ; or inline code, delimited by 1 backtick
            codeContent: copy ""
            until [
                currentToken: first self/tokens
                append codeContent currentToken/value 
                self/tokens: next self/tokens

                peek Backtick
            ]
            consume Backtick

            make InlineCodeNode [
                code: escapeString codeContent
            ]
        ]
    ]

    parseExclamationMark: does [
        consume ExclamationMark
        if (peek LeftSquareBracket) [
            linkNode: parseLeftSquareBracket
            return make ImageNode [
                alt: linkNode/text
                src: linkNode/url
            ]
        ]
        return make TextNode [
            text: "!"
        ]
    ]
    parseHorizontalRule: does [
        consume HorizontalRule
        return make HorizontalRuleNode []
    ]

    parseUrlToken: does [
        token: consume UrlToken
        make LinkNode [
            text: token/value
            url: token/value
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
            
            peek Header [
                return parseHeader
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

            peek ExclamationMark [
                parseExclamationMark
            ]

            peek HorizontalRule [
                parseHorizontalRule
            ]

            true [
                badToken: first self/tokens
                print rejoin ["stream is " prettyFormat copy/part self/tokens 5]
                print rejoin ["can't handle " badToken/type {Token in file "} self/filename {", maybeParseBlockTokens}]
                quit
            ]
        ]
    ]

    parseHeader: does [
        headerToken: consume Header

        headerText: copy ""
        until [
            currentToken: first self/tokens
            if found? currentToken [
                append headerText currentToken/value
            ]
            self/tokens: next self/tokens
            
            any [
                tail? self/tokens
                not found? currentToken
                peek NewlineToken
            ]
        ]
        if (not tail? self/tokens) [ ; we're at the end of the file
            consume NewlineToken
        ]

        if (peek NewlineToken) [
            consume NewlineToken
        ]

        make HeaderNode [
            size: headerToken/size
            text: headerText 
                |> :trim
        ]
    ]

    parseGreaterThan: does [
        blockquoteContentNodes: copy []
        until [
            if peek GreaterThan [
                consume GreaterThan
            ]

            maybeInlineNode: maybeParseInlineTokens
            if found? maybeInlineNode [
                append blockquoteContentNodes maybeInlineNode
            ]

            any [
                tail? self/tokens
                not found? maybeInlineNode
                all [
                    peek/at NewlineToken 1
                    not peek/at GreaterThan 2
                ]
            ]
        ]
        if peek NewlineToken [
            consume NewlineToken
        ]

        make BlockquoteNode [
            children: blockquoteContentNodes
        ]
    ]

    parseList: function [
        isOrderedList [logic!]
    ] [

        listMarkerToken: either isOrderedList [NumberWithDot] [Hyphen]

        ; add all the list items to a list node
        listItemNodes: copy []
        until [
            if peek listMarkerToken [
                consume listMarkerToken
            ]

            numberOfIndents: 0
            ; if it's the start of a sub-list
            if peek FourSpaces [
                numberOfIndents: numberOfIndents + 1
                consume FourSpaces

                while [peek FourSpaces] [
                    numberOfIndents: numberOfIndents + 1
                    consume FourSpaces
                ]
                consume listMarkerToken
            ]

            ; add all the inline nodes in the line to an item node
            inlineNodesInListItem: copy []
            until [
                maybeInlineNode: maybeParseInlineTokens
                if found? maybeInlineNode [

                    ; if there's 1 indent, we want to surround the inlineNodes by an UnorderedListNode
                    ; if there's 2 indents, we want to surround the inlineNodes by an 2 UnorderedListNodes, etc
                    ; 1 UnorderedListNode per indent
                    nodeToAppend: maybeInlineNode
                    repeat indentNumber numberOfIndents [
                        innerListItemNode: make ListItemNode compose/deep [
                            children: [(nodeToAppend)]
                            doesntHaveListStyle: (indentNumber <> 1)
                        ]
                        nodeToAppend: make ListNode compose/deep [
                            children: [(innerListItemNode)]
                            isOrdered: isOrderedList
                        ]
                    ]

                    append inlineNodesInListItem nodeToAppend
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

            append listItemNodes make ListItemNode [
                children: inlineNodesInListItem
                doesntHaveListStyle: numberOfIndents > 0
            ]

            any [
                tail? self/tokens
                all [
                    not peek listMarkerToken
                    not peek FourSpaces ; the start of a sub-list
                ]
            ]
        ]

        ; we don't want this extra newline
        if (peek NewlineToken) [
            consume NewlineToken
        ]

        make ListNode [
            children: listItemNodes
            isOrdered: isOrderedList
        ]
    ]

    parseHyphen: does [
        return parseList false
    ]

    parseNumberWithDot: does [
        return parseList true
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