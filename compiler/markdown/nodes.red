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
    content: []
]

NewlineNode: make Node [
    type: "NewlineNode"
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