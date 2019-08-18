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

Header1: make Token [
    type: "Header1"
    value: "#"
]
Header2: make Token [
    type: "Header2"
    value: "##"
]
Header3: make Token [
    type: "Header3"
    value: "###"
]
Header4: make Token [
    type: "Header4"
    value: "####"
]
Header5: make Token [
    type: "Header5"
    value: "#####"
]
Header6: make Token [
    type: "Header6"
    value: "######"
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
]

; conflicts with 'tab in Red
TabToken: make Token [
    type: "Tab"
]

; conflicted with 'newline in Red
NewlineToken: make Token [
    type: "Newline"
]

Text: make Token [
    type: "Text"
]