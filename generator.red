Red [
    Title: "Nathan's wiki generator"
    Author: "Nathan"
    License: "MIT"
]


do %helpers.red
dotenv: context load %dotenv.red
dotenv/loadEnv

wikiLocation: to-file get-env "WIKI_LOCATION"

templater: context load %templater.red
markdownCompiler: context load %compiler/markdown/markdown.red

compileToHTML: function [
    pageContent [string!] "the actual content, excluding the tags at the top"
    extension [string!] 
] [
    switch/default extension [
        "md" [markdownCompiler/compile pageContent]
        "rst" ["CAN'T COMPILE RESTRUCTURED TEXT YET"]
    ] [
        markdownCompiler/compile "# abcdef"
    ]
]

addToIndexFromTags: function [
    {
        adds tags like 'meta test/tag/two' into a tree index, mapping them to a filename. We want to let each tag in the tree have pages associated with it, as well as have other tags inside it
        e.g. with 2 calls to this function,
        first call
        tagBlock: [meta test/tag/two]
        filename: "file.html"

        second call
        tagBlock: [meta]
        filename: "file.html2"

        you'll get a map like
        index: #(
            pages: []
            innerTags: #(
                meta: #(
                    pages: ["file.html" "file2.html"]
                    innerTags: #()
                )
                test: #(
                    pages: []
                    innerTags: #(
                        two: #(
                            pages: ["file.html"]
                            innerTags: #()
                        )
                    )
                )
            )
        )
    }
    index [map!]
    tagsString [string!]
    filename [string!]
] [
    tags: split tagsString space
    foreach tag tags [    
        tagBlock: split tag "/"

        tagCursor: tagBlock
        cursor: index

        isLastTag: tail? tagCursor
        currentTag: first tagCursor
        while [not isLastTag] [
            keyInInnerTags: select cursor/innerTags currentTag

            if (not found? keyInInnerTags) [
                put cursor/innerTags currentTag make map! reduce [
                    'pages copy []
                    'innerTags make map! []
                ]
            ]
            cursor: select cursor/innerTags currentTag

            tagCursor: next tagCursor
            currentTag: first tagCursor
            
            isLastTag: tail? tagCursor
        ]
        append cursor/pages filename
    ]

    index
]

slugifyFilename: function [
    "turns 'File name a£%$' into 'file_name_'"
    filename [string!]
] [
    letters: charset [#"a" - #"z" #"A" - #"Z"]
    slugifiedFilename: copy ""
    parse (lowercase copy filename) [
        any [
            copy letter letters (append slugifiedFilename letter) 
            | space (append slugifiedFilename "_") 
            | skip
        ]
    ]
    slugifiedFilename
]

makeIndexListHTML: function [
    {
        makes HTML like
        <section class='index'>
            <ul class='index__list'>
                <li>tag1
                <ul class='index__list'>
                    <li class='index__item'>
                        <a class='link link--index' href='meta_copy.html'>Meta copy</a>
                    </li>
                    <li class='index__item'>
                        <a class='link link--index' href='meta.html'>Meta</a>
                    </li>
                </ul>
                </li>
            </ul>
            <ul class='index__list'>
                <li>tag2
                <ul class='index__list'>
                    <li class='index__item'>
                        <a class='link link--index' href='meta_copy.html'>Meta copy</a>
                        </li>
                </ul>
                </li>
            </ul>
        </section>
    }
    index [map!]
] [
    html: copy ""

    append html rejoin ["<ul class='index__list'>" newline]

    ; pages that are just associated with the tag
    foreach page index/pages [
        htmlFilename: rejoin [(copy slugifyFilename page) ".html"]
        append html rejoin ["<li class='index__item'><a class='link link--index' href='" htmlFilename "'>" page "</a></li>" newline]
    ]

    ; tags inside the tag
    foreach tag keys-of index/innerTags [
        innerTagsIndex: index/innerTags/:tag
        append html rejoin ["<li>" tag
            newline (makeIndexListHTML innerTagsIndex) newline
            "</li>" newline
        ]
    ]
    append html rejoin ["</ul>" newline]

    html
]

makeAToZIndexListHTML: function [
    listOfPages [block!]
] [
    (f_map function [page] [
        htmlFilename: rejoin [(copy slugifyFilename page) ".html"]
        rejoin ["<a class='link link--block' href='" htmlFilename "'>" page "</a>" newline]
    ] listOfPages)
    |> :to-string
]

main: does [
    wikipages: findFiles/matching %pages/ lambda [endsWith ? ".md"]
    wikiTemplate: read %wikipage.twig

    index: make map! reduce [
        'pages []
        'innerTags make map! []
    ]
    foreach file wikipages [
        filename: (next find/last file "/")
            |> :to-string
        extension: case [
            (find/last filename ".md") ["md"]
            (find/last filename ".rst") ["rst"]
            true ["rst"]
        ]

        filenameWithoutExtension: (find filename ".md")
            |> [copy/part filename]
        htmlFilename: append (copy slugifyFilename filenameWithoutExtension) ".html"

        print rejoin ["compiling " filename]

        fileContent: read file

        parse fileContent [
            opt [ ; the .md file might have tags: [meta test/tag/here] at the start
                "tags:" any space "[" copy tagsString to "]" "]"
            ] 
            copy pageContent to end 
        ]
        index: addToIndexFromTags index tagsString filenameWithoutExtension

        content: compileToHTML pageContent extension

        variables: make map! reduce [
            'title filenameWithoutExtension
            'content content
        ]
        
        wikipageHTML: templater/compile wikiTemplate variables
        filepath: rejoin [wikiLocation htmlFilename]
        write filepath wikipageHTML
    ]

    filenamesWithoutExtension: f_map function [page] [
        filename: (next find/last page "/")
            |> :to-string
        filenameWithoutExtension: (find filename ".md")
            |> [copy/part filename]
    ] wikipages
    listOfPages: sort filenamesWithoutExtension

    indexListHTML: makeIndexListHTML index
    aToZindexHTML: makeAToZIndexListHTML listOfPages

    indexTemplate: read %index.twig
    indexVariables: make map! reduce [
        'indexListHTML indexListHTML
        'aToZindexHTML aToZindexHTML
        'listOfPages listOfPages
    ]
    indexHTML: templater/compile indexTemplate indexVariables
    indexFilepath: rejoin [wikiLocation "index.html"]
    write indexFilepath indexHTML
]

main