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

UnorderedListNode: make Node [
    type: "UnorderedListNode"
    items: none
]

UnorderedListItemNode: make Node [
    type: "UnorderedListItemNode"
    children: none
]

OrderedListNode: make Node [
    type: "OrderedListNode"
    items: none
]

OrderedListItemNode: make Node [
    type: "OrderedListItemNode"
    children: none
]

InlineCodeNode: make Node [
    type: "InlineCodeNode"
    code: none
]

CodeBlockNode: make Node [
    type: "CodeBlockNode"
    code: none
]
