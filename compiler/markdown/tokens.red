Red [
    Title: "Nathan's markdown tokens"
    Author: "Nathan"
    License: "MIT"
]

Token: make object! [
    type: copy ["Token"]
	isType: function [typeString [string!]] [not none? find self/type typeString]
    value: none ; the plaintext thing you use to type in the token, needed so we can just get the 'value of anything inside `two backticks` to print it out exactly, to store the actual normal text I type in, to store the numbers in ordered lists, and user-escaped characters like `\*`
]

Header: make Token [
    type: "Header"
    size: none
    value: does [
        str: copy ""
        loop self/size [append str "#"]
        str
    ]
]

GreaterThan: make Token [
    type: "GreaterThan"
    value: "&gt;" ; it's the HTML entity so the browser doesn't actually interpret `<b>blah</b>`
]

Asterisk: make Token [
    type: "Asterisk"
    value: "*"
]

Underscore: make Token [
    type: "Underscore"
    value: "_"
]

Tilde: make Token [
    type: "Tilde"
    value: "~"
]

Plus: make Token [
    type: "Plus"
    value: "+"
]

Hyphen: make Token [
    type: "Hyphen"
    value: "-"
]

NumberWithDot: make Token [
    type: "NumberWithDot"
]

ExclamationMark: make Token [
    type: "ExclamationMark"
    value: "!"
]

LeftSquareBracket: make Token [
    type: "LeftSquareBracket"
    value: "["
]

RightSquareBracket: make Token [
    type: "RightSquareBracket"
    value: "]"
]

LeftBracket: make Token [
    type: "LeftBracket"
    value: "("
]

RightBracket: make Token [
    type: "RightBracket"
    value: ")"
]

Backtick: make Token [
    type: "Backtick"
    value: "`"
]

FourSpaces: make Token [
    type: "FourSpaces"
    value: "    "
]

; conflicts with 'tab in Red
TabToken: make Token [
    type: "Tab"
    value: tab
]

; conflicted with 'newline in Red
NewlineToken: make Token [
    type: "Newline"
    value: newline
]

Text: make Token [
    type: "Text"
    value: none
]

; needed to match URLs like this one: [heap](https://en.wikipedia.org/wiki/Heap_\(data_structure\)) - this Token will hold "https://en.wikipedia.org/wiki/Heap_(data_structure)"
UrlToken: make Token [
    type: "UrlToken"
    value: none
]

HorizontalRule: make Token [
    type: "HorizontalRule"
    value: "---"
]