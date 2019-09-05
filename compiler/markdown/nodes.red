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
    size: none
    text: none
]

HorizontalRuleNode: make Node [
    type: "HorizontalRuleNode"
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

ImageNode: make Node [
    type: "ImageNode"
    alt: none
    src: none
]

BlockquoteNode: make Node [
    type: "BlockquoteNode"
    text: none
]

ListNode: make Node [
    type: "ListNode"
    items: none
    isOrdered: false
]
ListItemNode: make Node [
    type: "ListItemNode"
    children: none
    doesntHaveListStyle: false ; is set to true in list items that contain list items
]

InlineCodeNode: make Node [
    type: "InlineCodeNode"
    code: none
]

CodeBlockNode: make Node [
    type: "CodeBlockNode"
    code: none
]
