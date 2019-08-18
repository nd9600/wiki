tags: [meta]

# My wiki

Hello

## Why

I made this after I read [this interview with Ceasar Bautista](https://superorganizers.substack.com/p/why-ceasar-bautista-wrote-his-own), and I liked the idea:
* I read a fair amount of stuff, and I can't really remember the little details of most of it. I hope I will if I write them down here
* Writing what I think about things and how I understand they work should help my understand things properly  - I might _think_ I know how a compiler works, but do I really? Writing [an article](compiler.html) should make me actually understand it
* I'm planning on making everything I need to make the wiki myself - so, the static-site generator, the Markdown -> HTML compiler, hosting the website, etc, which hopefully should make me a better programmer. If I want to have the pages be dynamic in the future, I've got [a little framework](https://github.com/nd9600/framework) I can use, too.

## How it all works
It uses Red

## Construction report

### Day 1

* = done

1. *Make Twig template for wikipage
2. For each .md file in pages/
    1. Compile Markdown into HTML
        1. *Read tags at the start from "tags: [technology/programming/languages/red etc/another/tag]"
        2. Compile rest of the file normally, using normal Red PARSE if it works, or mal-style thingy if it doesn't
    2. *Output HTML as file_name_slugified.html in site/wiki/ folder
    3. *Add index: map! from tag -> HTML file name
        1. *to-block tag, then map to-string, then append/only [block-tag filename.html] to index: block!
3. *Compile index.twig into index.html, using index block!
    1. *Has the actual index at the top
    2. *JS search, using static compiled array of filenames

### Day 2

DAY 2 IN THE ~BIG BROTHER HOUSE~ WIKI CONSTRUCTION REPORT

I'm pretending I planned to make a construction report from the start. I didn't. But I was thinking it might be fun slash useful to read back through my notes/thought process in the future, once/if this is all done and works ("the future" might be next week, if I'm lucky). Also, people get impressed when they see the final product (sometimes!), but they don't see the slog you go through to make it, and how annoying it can be at times. Now, you will (hi people in the future,  you time-archaeologists!).

I think I'll need these tokens:
* `#` to `######` for headers
* `>` for blockquotes
* `*` for bold
* `_` for italics
* `*` again, `+`, and `-` for unordered lists
* `{number}.` for ordered lists
* `[`, `]`, `(`, and `)` for links,
* `!` for images
* ```, `    `, and `{tab}` for code
* newlines, so you know when a header stops
* and everything else that isn't one of the above tokens, is a "text" token

I forgot that the index tree needed to be able to handle tags having pages _and_ other tags inside it. It broke horribly when I put actually nested tags in (the programming section). Weirdly, fixing it actually seemed to simplify how I make the tree (the `addToIndexFromTags` function). Though, I really should make a Tree `object!`, with Nodes, Branches and Leaves, rather than just this ghetto version I have right now. Visiting the tree in a [DFS](dfs.html) shouldn't have been as hard as it was.

I'm not sure this "tokenizer-parser-code generator" approach is the right one right now; tokenizing the Markdown _seems_ to work ok now, but I'm 99% sure it'll break when I try to run it on something that isn't `# Abstract Syntax Tree` - mainly because I don't know how to tokenize text, everything that isn't in the Markdown syntax, something you just want to pass straight through to the output.
Hmm, maybe just read the input in and immediately output it with transformations? No, too complicated, and how do you know when you're supposed to switch to e.g. bold mode? 
That's also the issue I'm having with the current way - for example, say you read in an `Asterisk` token; if you read in `Asterisk`, then `some text`, then another `Asterisk`, you know you should output `<b>some text</b>` in the end, but what about if you just get `Asterisk some text`? How do you know not to output `<b>some text</b>`. Say, on Github, if you type `* Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. *Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum` - the two asterisks are just there (one at the start of the last sentence) to mark something, like a footnote or whatever, _not_ to bold the entire text, how does it know not to? Should I tokenize a `\` so I don't output a giant bolded section, and require the user to type `\* Lorem ipsum \*`?
Well, off to Github to check..
`<1 minutes later>`
So Github actually uses 2 asterisks for bold, but, yes, they _do_ bold the entire section, as long as you but them at the ends of a word, not the beginning on the RHS asterisk (or in between words; in the middle of a word is fine)

One more benefit of construction logs I didn't think of - you can think through how your method works, and come up with a new one while you write!

Oops that `<b></b>` wasn't escaped before so now this whole thing is bold. Ok I _will_ need to escape any raw HTML.

It's looking pretty good right now (this isn't formatted great, I know):
`compiling Abstract Syntax Tree.md
escapedStr: {^/^/# Abstract Syntax Tree^/^/* hello world *^/^/_ italic_}
compiled:
type: "Newline"
isType: func [typeString [string!]][not none? find self/type typeString]
value: none type: "Newline"
isType: func [typeString [string!]][not none? find self/type typeString]
value: none type: "Header1"
isType: func [typeString [string!]][not none? find self/type typeString]
value: none type: "Text"
isType: func [typeString [string!]][not none? find self/type typeString]
value: " Abstract Syntax Tree" type: "Newline"
isType: func [typeString [string!]][not none? find self/type typeString]
value: none type: "Newline"
isType: func [typeString [string!]][not none? find self/type typeString]
value: none type: "Asterisk"
isType: func [typeString [string!]][not none? find self/type typeString]
value: none type: "Text"
isType: func [typeString [string!]][not none? find self/type typeString]
value: " hello world " type: "Asterisk"
isType: func [typeString [string!]][not none? find self/type typeString]
value: none type: "Newline"
isType: func [typeString [string!]][not none? find self/type typeString]
value: none type: "Newline"
isType: func [typeString [string!]][not none? find self/type typeString]
value: none type: "Underscore"
isType: func [typeString [string!]][not none? find self/type typeString]
value: none type: "Text"
isType: func [typeString [string!]][not none? find self/type typeString]
value: " italic" type: "Underscore"
isType: func [typeString [string!]][not none? find self/type typeString]
value: none`

### Day 3

Escaping everything was easy enough - I don't relly need to  worry about XSS attacks, since I'm the one writing all the content, and there's nothing stored here apart from the HTML/Markdown files anyway. One thing I didn't think about, though: if I escape `>` into `&gt;`, and _then_ `&` into `&amp;`, I'll actually end up with `&amp;gt;` for `>`. Not what I want. So I had to escape all the `&`s first. Precedence matters ([Gary Bernhardt](https://www.destroyallsoftware.com/screencasts/catalog/a-compiler-from-scratch) mentioned that in his screencast, I guess that's why I realised.)

About the stray `#`, `*`, `_`, , `+`, `-`, `[`, `]`, `(`, `)`, `!` that I talked about above; I think I'll just handle them by escaping them if I type in `\*` etc, putting that in as a `Text` token with value `*`. I'm not gonna put in any fancy rules like "the second asterisk must not be at the start of a word" or anything like that, it's too complicated for what I need.

So, the tokens I think I'll need now,

* `#` to `######` for headers
* `>` for blockquotes
* `*` for bold
* `_` for italics
* `*` again, `+`, and `-` for unordered lists
* `{number}.` for ordered lists
* `[`, `]`, `(`, and `)` for links,
* `!` for images
* ```, `    `, and `{tab}` for code
* newlines, so you know when a header stops
* "user-escaped" versions of `#` , `*`, `_`, , `+`, `-`, `[`, `]`, `(`, `)`, `!`, `\``, like `\*`
* and everything else that isn't one of the above tokens, is a "text" token

Maybe I can just handle the "user-escaped" ones by, when I read in a `\`, just putting the next character in as a `Text` token straightaway?

Oh, I can't forget to not do anything with the stuff that's surrounded by two \`s in the code generator.

The tokenizer makes tokens like this:
`Token: make object! [
    type: copy ["Token"]
	isType: function [typeString [string!]] [not none? find self/type typeString]
    value: none
]

Header1: make Token [
    type: "Header1"
]`

Pretty nasty, hacking class-inheritance into a prototype-based inheritance. I need a better way.

A possible improvement for the "I don't know how to tokenize text, everything that isn't in the Markdown syntax" issue above: just using [skip](https://www.red-lang.org/2013/11/041-introducing-parse.html) from Red's PARSE, like
`copy data skip (append tokens make Text [value: data])`

I'll definitely need to roll multiple `Text` tokens in a row into one big one though. Something for the parser.
That was easy to do! The two cursors in a while loop was fun!

### Day 4

No update in Day 4 - 1, I was off seeing the incredible This is the Kit!

All my links between wikipages will be broken when I get them working :(. The links in the index are ok, since they include `wiki/pages/[PAGE].html` at the start, but I want the links in the pages to be just `[PAGE].html`. Obviously, if they're different, it won't work. I still want the flat links, so I'll need to do it like `wiki.[DOMAIN].[TLD]/[PAGE].html`. Off to [Caddy](https://caddyserver.com/) again, and it's great, simple configs.

Also, I should only escape HTML tags like `<b>blah</b>` when they're in backticks, like that, since Markdown [lets](https://daringfireball.net/projects/markdown/syntax#html) you put inline HTML in. I really should support backticks inside link texts, and titles, stuff like that, too, but I'm not sure I will (at least in v1).

The Caddyfile was really easy:
```
wiki.[DOMAIN].[TLD] {
    root [FOLDER]
    tls [EMAIL]
    gzip
    log [LOGFILE]
    errors [ERROR_LOGFILE]

    ext .html

    header / {
        Cache-Control: max-age=180
    }
}
```

Oh yeah, I need to support 3 backticks in a row, not just 1.

I realised I can just use the exact same `tokenCursor` my while loop to go through the list of tokens, no need to make a new cursor to do exactly the same thing, so it looks like this now:
```
rollMultipleTextTokens: function [
    "we want to roll multiple `Text` tokens in a row into one big Token, there's no point having a thousand separate ones in a row"
    tokens [block!]
] [
    newTokens: copy []
    tokenCursor: tokens

    until [
        currentToken: first tokenCursor

        either (not currentToken/isType "Text") [
            append newTokens currentToken
            tokenCursor: next tokenCursor
        ] [
            rolledTextValue: copy ""

            while [
                all [
                    not tail? tokenCursor ; the text might go all the way to the end, and then there won't be an innerCurrentToken
                    currentToken/isType "Text"
                ]
            ] [
                append rolledTextValue currentToken/value
                tokenCursor: next tokenCursor
                currentToken: first tokenCursor
            ]
            append newTokens make Token [type: "Text" value: rolledTextValue]

            tokenCursor: next tokenCursor ; we want to jump to the end of all the Text tokens, because we'd go over the same tokens twice otherwise 
        ]

        tail? tokenCursor
    ]
    newTokens
]
```
Pretty simple

### Day 5

I might like a dark theme like
```
:root {
    --bg-colour: #700b0b;
    --text-colour: #fefefe;
    --title-colour: #363636;
    --accent-colour: #dadada;
    --hover-colour: white;
}
```

### Day 6

I should read in environment variables from a .env file and set them with `set-env`, so I can just read them with `get-env` anywhere I want, avoid these nasty global variables
Adding that in was a lot easier than I thought, now I can use .env files like a proper dev!