Red [
    Title: "Nathan's wiki generator"
    Author: "Nathan"
    License: "MIT"
]


do %helpers.red
dotenv: context load %dotenv.red
dotenv/loadEnv

do %indexGenerator.red

wikiLocation: (get-env "WIKI_LOCATION")
    |> :dirize
    |> :to-file

templater: context load %templater.red
markdownCompiler: context load %compiler/markdown/markdown.red

compileToHTML: function [
    filename [string!]
    pageContent [string!] "the actual content, excluding the tags at the top"
    extension [string!] 
] [
    switch extension [
        "md" [markdownCompiler/compile filename pageContent]
        "rst" ["CAN'T COMPILE RESTRUCTURED TEXT YET"]
    ]
]

slugifyString: function [
    "turns 'File name a£%$' into 'file_name_'"
    str [string!]
] [
    digits: charset "0123456789"
    letters: charset [#"a" - #"z" #"A" - #"Z"]

    ; https://tools.ietf.org/html/rfc1738
    ; "only alphanumerics, the special characters "$-_.+!*'(),", and [...] may be used    unencoded within a URL" but Firefox splits the URL in half if you put in a ', so we can't use that
    specialChars: charset "$-_.+!*(),"
    alphanumeric: union letters digits 
    acceptableChars: union alphanumeric specialChars
    slugifiedString: copy ""
    parse (lowercase copy str) [
        any [
            copy char acceptableChars (append slugifiedString char) 
            | space (append slugifiedString "_") 
            | skip
        ]
    ]
    slugifiedString
]

main: does [
    deleteDir/matching wikiLocation lambda [endsWith ? ".html"]

    wikipages: findFiles/matching %pages/ lambda [endsWith ? ".md"]
    wikiTemplate: read %wikipage.twig

    index: make map! reduce [
        'pages []
        'innerTags make map! []
    ]
    foreach file wikipages [
        tagsString: ""
        filename: (next find/last file "/")
            |> :to-string
        extension: case [
            (find/last filename ".md") ["md"]
            (find/last filename ".rst") ["rst"]
            true ["md"]
        ]

        filenameWithoutExtension: (find filename ".md")
            |> [copy/part filename]
        htmlFilename: append (copy slugifyString filenameWithoutExtension) ".html"

        print rejoin ["compiling " filename]

        fileContent: read file

        parse fileContent [
            opt [ ; the .md file might have tags: [meta test/tag/here] at the start
                "tags:" any space "[" copy tagsString to "]" "]"
            ] 
            copy pageContent to end 
        ]
        if not empty? tagsString [
            index: addToIndexFromTags index tagsString filenameWithoutExtension
        ]

        content: compileToHTML filename pageContent extension

        variables: make map! reduce [
            'title filenameWithoutExtension
            'content content
        ]
        
        wikipageHTML: templater/compile wikiTemplate variables
        filepath: rejoin [wikiLocation htmlFilename]
        write filepath wikipageHTML
    ]

    print "compiling index"
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
