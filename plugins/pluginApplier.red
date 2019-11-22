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
        "applies plugins to 'filesData, using *all* files - e.g. a plugin that works out which pages a page links to, which you can only work out with all files"
        pagenames [block!] "a list of pagenames"
        filesData [map!] "pagenames to their tokens, ASTs and HTML"
        return: [object!] ; "'filesData, after all plugins have been applied"
    ] [
        filesData
            |> [self/applyForwardAndBackLinksPlugin pagenames]
    ]

    applyForwardAndBackLinksPlugin: function [
        "for each page, inserts a list of pages that it links to, and a list of pages that link to it"
        pagenames [block!] "a list of pagenames"
        filesData [map!] "pagenames to their tokens, ASTs and HTML"
    ] [
        pageToPagesMapTemplate: read %plugins/pageToPagesMap.twig
        pagesToPageMapTemplate: read %plugins/pagesToPageMap.twig

        pageToPagesMap: make map! [] ; what pages does page p link to?
        pagesToPageMap: make map! [] ; what pages link to page p?

        foreach pagename pagenames [
            fileData: filesData/:pagename

            htmlFilename: fileData/htmlFilename
            allLinks: self/getLinksFromNode fileData/ast
            linksToOtherWikiPages: allLinks
                |> [f_filter lambda [startsWith ? "/"]]
                |> [f_map lambda [at ? 2]]

            ; htmlFilename links to each of linksToOtherWikiPages
            put pageToPagesMap htmlFilename linksToOtherWikiPages

            ; each of linksToOtherWikiPages is linked to by htmlFilename
            foreach pageLinkedTo linksToOtherWikiPages [
                either found? pagesToPageMap/:pageLinkedTo [
                    append pagesToPageMap/:pageLinkedTo htmlFilename
                ] [
                    put pagesToPageMap pageLinkedTo reduce [htmlFilename]
                ]
            ]
        ]

        foreach pagename pagenames [
            fileData: filesData/:pagename
            htmlFilename: fileData/htmlFilename
            pagesThisPageLinksTo: pageToPagesMap/:htmlFilename
            pagesThatLinkToThisPage: pagesToPageMap/:htmlFilename

            if all [
                found? pagesThatLinkToThisPage
                not empty? pagesThatLinkToThisPage
            ] [
                variables: make map! reduce [
                    'pagesThatLinkToThisPage pagesThatLinkToThisPage
                ]
                
                pagesToPageMapHtml: templater/compile pagesToPageMapTemplate variables
                insert head fileData/html pagesToPageMapHtml
            ]

            if all [
                found? pagesThisPageLinksTo
                not empty? pagesThisPageLinksTo
            ] [
                variables: make map! reduce [
                    'pagesThisPageLinksTo pagesThisPageLinksTo
                ]
                
                pageToPagesMapHtml: templater/compile pageToPagesMapTemplate variables
                insert head fileData/html pageToPagesMapHtml
            ]            
        ]

        filesData
    ]

    getLinksFromNode: function [
        "returns all the URLs in a node from an AST"
        node [object!]
        return: [block!]
    ] [
        if node/type == "LinkNode" [
            parse node/url [copy urlWithoutAnchorOrQueryString to ["#" | "?" | end]]
            return urlWithoutAnchorOrQueryString
        ]
        if objectHasKey node 'children [
            return node/children
                |> [f_map lambda [self/getLinksFromNode ?]]
                |> :flatten
                |> :unique
        ]
        return []
    ]
]