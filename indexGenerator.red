Red [
    Title: "Nathan's index generator"
    Author: "Nathan"
    License: "MIT"
    Description: {
        Makes  A-to-Z and tree indexes for a series of filenames
    }
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
    html: rejoin ["<ul class='index__list'>" newline]

    ; pages that are just associated with the tag
    foreach page index/pages [
        htmlFilename: rejoin [(copy slugifyString page) ".html"]
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
        htmlFilename: rejoin [(copy slugifyString page) ".html"]
        rejoin ["<a class='link display-block' href='" htmlFilename "'>" page "</a>" newline]
    ] listOfPages)
    |> :to-string
]