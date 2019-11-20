Red [
    Title: "Nathan's plugin applier generator"
    Author: "Nathan"
    License: "MIT"
    Description: {
        Makes A-to-Z and tree indexes for a series of filenames
    }
]

PluginApplier: context [
    applyPlugins: function [
        "applies plugins to 'filesData, using *all* files - e.g. a plugin that works out which pages link to a page and which page a page links to"
        pagenames [block!] "a list of pagenames"
        filesData [map!] "pagenames to their tokens, ASTs and HTML"
        return: [object!]
    ] [
        ; for each file
        ;     find all the links in it by walking the AST
        ;     add to map! "'filename links to ['filename2]"

        foreach pagename pagenames [
            fileData: filesData/:pagename
            prettyPrint self/getLinksFromNode fileData/ast
        ]

        filesData
    ]

    getLinksFromNode: function [
        node [object!]
        return: [block!]
    ] [
        if node/type == "LinkNode" [
            prettyPrint node
            return node/url
        ]
        if objectHasKey node 'children [
            return (node/children
            |> [f_map lambda [self/getLinksFromNode ?]]
            |> :flatten)
        ]
        return []
    ]
]