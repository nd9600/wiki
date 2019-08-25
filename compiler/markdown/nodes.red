Red [
    Title: "Nathan's markdown parser - tree"
    Author: "Nathan"
    License: "MIT"
]

Node: context [
	isType: function [typeString [string!]] [not none? find self/type typeString]
]

MarkdownNode: make Node [
    type: "MarkdownNode"
    children: []
]

ParagraphNode: make Node [
    type: "ParagraphNode"
    children: []
]

NewlineNode: make Node [
    type: "NewlineNode"
]

TextNode: make Node [
    type: "TextNode"
    text: none
]

HeaderNode: make Node [
    type: "HeaderNode"
    size: 0
    text: none
]

EmphasisNode: make Node [
    type: "EmphasisNode"
    text: none
]

StrongEmphasisNode: make Node [
    type: "StrongEmphasisNode"
    text: none
]

StrikethroughNode: make Node [
    type: "StrikethroughNode"
    text: none
]

LinkNode: make Node [
    type: "LinkNode"
    url: none
    text: none
]

BlockquoteNode: make Node [
    type: "BlockquoteNode"
    text: none
]