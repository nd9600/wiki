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

        pageToPagesMap: make map! [] ; what pages does page p link to?
        pagesFromPageMap: make map! [] ; what pages link to page p?

        foreach pagename pagenames [
            fileData: filesData/:pagename

            htmlFilename: fileData/htmlFilename
            allLinks: self/getLinksFromNode fileData/ast
            linksToOtherWikiPages: allLinks
                |> [f_filter lambda [startsWith ? "/"]]
                |> [f_map lambda [at ? 2]]
            prettyPrint linksToOtherWikiPages

            ; htmlFilename links to each of linksToOtherWikiPages
            put pageToPagesMap htmlFilename linksToOtherWikiPages

            ; each of linksToOtherWikiPages is linked to by htmlFilename
            foreach pageLinkedTo linksToOtherWikiPages [
                either found? pagesFromPageMap/:pageLinkedTo [
                    append pagesFromPageMap/:pageLinkedTo htmlFilename
                ] [
                    put pagesFromPageMap pageLinkedTo reduce [htmlFilename]
                ]
            ]
        ]
        prettyPrint pageToPagesMap
        prettyPrint pagesFromPageMap

        filesData
    ]

    getLinksFromNode: function [
        "returns all the URLs in a node from an AST"
        node [object!]
        return: [block!]
    ] [
        if node/type == "LinkNode" [
            return node/url ; todo: need to handle anchors
        ]
        if objectHasKey node 'children [
            return node/children
                |> [f_map lambda [self/getLinksFromNode ?]]
                |> :flatten
        ]
        return []
    ]
]