tags: [meta]
Hello

# Why

I made this after I read [this interview with Ceasar Bautista](https://superorganizers.substack.com/p/why-ceasar-bautista-wrote-his-own), and I liked the idea:
* I read a fair amount of stuff, and I can't really remember the little details of most of it. I hope I will if I write them down here
* Writing what I think about things and how I understand they work should help my understand things properly  - I might _think_ I know how a compiler works, but do I really? Writing [an article](/compiler.html) should make me actually understand it
* I'm planning on making everything I need to make the wiki myself - so, the static-site generator, the Markdown -> HTML compiler, hosting the website, etc, which hopefully should make me a better programmer. If I want to have the pages be dynamic in the future, I've got [a little framework](https://github.com/nd9600/framework) I can use, too.

# How it all works
If you want to look at the code, see `https://www.github.com/[XXX.download]/wiki`.

It uses [Red](https://www.red-lang.org/) - I was lucky not to need to use [Rebol](http://www.rebol.com/), since there's only file IO, no network stuff; Red can't do that yet.

When we run `red generator.red` in the terminal, this happens:
Every file in the `pages` folder that ends in `.md` is found
```
wikipages: findFiles/matching %pages/ lambda [endsWith ? ".md"]
```
then we/I load the wikipage [Twig](https://twig.symfony.com/) template, and get each file's name and extension, and [slugify](https://en.wikipedia.org/wiki/Clean_URL#Slug) the filename.
We load the actual file's content, then parse the space-separated tags at the very top (they need to be _immediately_ at the top)
```
tags: [technology/computer/programming/languages/design]
```
with the help of Red's [PARSE](https://www.red-lang.org/2013/11/041-introducing-parse.html) [DSL](http://en.wikipedia.org/wiki/Domain-specific_language).
We add the filename to the index-tree you see on the [homepage](index.html) (for once, `index.html` is actually the index!) with a slightly nasty while loop, then there's the very tiny job of compiling the actual Markdown bit of the file.

Since I wanted the wiki to be completely static, even the search (and I mean "no-HTTP-requests-static"), I made it in a bit of a funky way:
The list of article names is put into JS like this:
```
const ARTICLES = [
{% for page in listOfPages %}
    "{{ page }}",
{% endfor %}
];
```
I've an event listener that triggers whenever the search input changes, which filters the above articles by the trimmed lowercase version of the input, giving me a list of articles whose titles include the input somewhere (not necessarily at the start), then I go through that list, slugify it with a regex - `article.replace(/./g, function(char) { return REPLACED_CHAR; }`, in JS, apparently you can put a regex as the first argument to `.replace`, and the second as a function of the matched character - and then add that list to the page with a `searchResults.append(searchResult);`

Then, we compile the wikipage Twig template I mentioned above with the templater from the `%templater.red` file (again heavily using the PARSE DSL) - right now, it only supports a _very_ limited subset of Twig: simple `{{ variables }}` that only accept plain `word!s` (no arrays/objects), for loops, and ifs, ifs in fors, and fors in ifs. Not even for loops inside for loops, or ifs inside ifs. That's because it recognises the start and ends of Twig ifs, which look like `{% if CONDITION %} TEXT {% endif %}`
```
"{%" any whitespace "if" some whitespace 
    copy ifCondition to "%}" "%}"
copy stringToCompile to
["{%" any whitespace "endif" any whitespace "%}"]
```
or, better to say, since once it reads the start, it jumps with a `to` to the first ending bit it sees, it can't recognise nested ifs or loops, and I don't think you can ever use a `to` to do it. I _was_ able to do it with a stupidly complicated selfmade stack:
```
; when you get to the start of an array, push a lit-word! onto the stack
; when at a digit, append to the peeked value - append (get to-word outputStack/peek) digit
; when you get to the end of an array, pop from the stack and append/only the value to the peeked value if stack not empty
this is just the comment
```
it was particularly stupid because PARSE itself uses a stack internally - I should just do it the simple-ish way, and call a new function (so it makes a new stack frame) each time I see the start of an if or a for loop. I think if I do that though, I won't be able to keep using PARSE for it, I'll need to switch to using a function-based approach (pretty much a simple compiler, I think).

Anyway, once the wikipage is compiled, we write it to `slugified_filename.html`, then compile and write the `index.twig` template the same way.

Now the fun bit, the actual Markdown compiler!
It's a pretty standard [compiler](/compiler.html), as far as I know. I stole the basic design from [Gary Bernhardt's very very good screencast about it](https://www.destroyallsoftware.com/screencasts/catalog/a-compiler-from-scratch) - the three stages, the tokenizer that takes in the string and makes a stream of tokens, the parser that turns the token stream into an Abstract Syntax Tree, and the code generator that takes the AST and outputs the HTML. Have a look at the `compiler` link for more details.

Nice things to note:
I made heavy use of the [pipe operator]() I wrote, since Red doesn't have one, [but you can make your own operators]() - it let me turn this function
```
escapeString: function [
    "converts iffy text to HTML entities"
    str
] [
    ampersandsReplaced: replace/all str "&" "&amp;" 
    lessThansReplaced: replace/all ampersandsReplaced "<" "&lt;"
    greaterThansReplaced: replace/all lessThansReplaced ">" "&gt;"
    doubleQuotesReplaced: replace/all greaterThansReplaced {"} "&quot;"
    singleQuotesReplaced: replace/all doubleQuotesReplaced {'} "&#x27;"
    forwardSlashesReplaced: replace/all singleQuotesReplaced  "/" "&#x2F;"
    return forwardSlashesReplaced
]
```
into this, much much easier to read, function
```
escapeString: function [
    "converts iffy text to HTML entities"
    str
] [
    str
        |> [lambda/applyArgs [replace/all ? "&" "&amp;"]] ; we need to escape this first so that it doesn't escape "<" into "&lt;", then into "&amp;lt;"
        |> [lambda/applyArgs [replace/all ? "<" "&lt;"]]
        |> [lambda/applyArgs [replace/all ? ">" "&gt;"]]
        |> [lambda/applyArgs [replace/all ? {"} "&quot;"]]
        |> [lambda/applyArgs [replace/all ? {'} "&#x27;"]]
        |> [lambda/applyArgs [replace/all ? "/" "&#x2F;"]]
]
```

Once all the content has been written into the HTML pages, we still need to serve them. For that, I use [Caddy](https://caddyserver.com/), since it only allows [HTTPS](https://en.wikipedia.org/wiki/HTTPS) and is really easy to setup.
I write all the files into a folder that's specified in a `.env` file (I need to follow at least 1 of the [12 factors](https://12factor.net/)!) - that folder is a different [Git](https://12factor.net/) repo, hosted on an [Amazon EC2](https://aws.amazon.com/ec2/) server, and push that repo up to the remote. After it's received, it runs a post-receive [hook](https://git-scm.com/docs/githooks) that copies the working directory (so, all the HTML files/the wiki) to the folder that Caddy serves, like the first line [here](https://gist.github.com/zanematthew/4597331).
Finally, the new files are live!

# Todos
* Let Table of contents go H2 H2 H1 H2 - it doesn't work right now
* Let Asterisks, Underscores, Tildes work with Emphasis, Strikethrough, links, and inline code, not just text
* Site web/graph
* Copy templater tests over from the framework
* Write system/integration tests
* Let unordered lists start with Asterisks (might be hard/conflict with how the Emphasis nodes are parsed)
* Let lists be the last thing in a file
* Allow verbatim sections, where the compiler just echos the input

## Done
* ~Handle backslashes inside code blocks~ just use two backslashes when you want a literal one
* ~Change slugifiers to work with ASCII letters, numbers and `$-_.+!*'()`~ browsers don't handle `'` in URLs
* ~Delete existing pages before making new ones!~
* ~Add indent parameter to `objectToString`~
* ~Make a new ParagraphNode when we read in two NewlineTokens in a row, 1 NewlineToken is a NewlineNode~
* ~Handle spaces before list markers (see day 8)~
* ~Let Headers work with Asterisks, Underscores, Tildes, Links, and Code, as well as just Text~
* ~Let URLs include escaped characters (see day 11)~
* ~Handle sub-lists (see day 8)~
* ~Build a table of contents from headers~



# Construction report

## Day 1
\* = done

1. \*Make Twig template for wikipage
2. For each .md file in pages/
    1. Compile Markdown into HTML
        1. \*Read tags at the start from `tags: [technology/programming/languages/red etc/another/tag]`
        2. \*Compile rest of the file normally, using normal Red PARSE if it works, or mal-style thingy if it doesn't
    2. \*Output HTML as file_name_slugified.html in site/wiki/ folder
    3. \*Add index: map\! from tag -> HTML file name
        1. \*to-block tag, then map to-string, then `append/only [block-tag filename.html]` to `index: block!`
3. \*Compile index.twig into index.html, using `index block!`
    1. \*Has the actual index at the top
    2. \*JS search, using static compiled array of filenames

## Day 2
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
* `\``, `    `, and `{tab}` for code
* newlines, so you know when a header stops
* and everything else that isn't one of the above tokens, is a "text" token

I forgot that the index tree needed to be able to handle tags having pages _and_ other tags inside it. It broke horribly when I put actually nested tags in (the programming section). Weirdly, fixing it actually seemed to simplify how I make the tree (the `addToIndexFromTags` function). Though, I really should make a Tree `object!`, with Nodes, Branches and Leaves, rather than just this ghetto version I have right now. Visiting the tree in a [DFS](https://en.wikipedia.org/wiki/Depth-first_search) shouldn't have been as hard as it was.

I'm not sure this "tokenizer-parser-code generator" approach is the right one right now; tokenizing the Markdown _seems_ to work ok now, but I'm 99% sure it'll break when I try to run it on something that isn't `# Abstract Syntax Tree` - mainly because I don't know how to tokenize text, everything that isn't in the Markdown syntax, something you just want to pass straight through to the output.
Hmm, maybe just read the input in and immediately output it with transformations? No, too complicated, and how do you know when you're supposed to switch to e.g. bold mode? 
That's also the issue I'm having with the current way - for example, say you read in an `Asterisk` token; if you read in `Asterisk`, then `some text`, then another `Asterisk`, you know you should output `<b>some text</b>` in the end, but what about if you just get `Asterisk some text`? How do you know not to output `<b>some text</b>`. Say, on Github, if you type `* Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. *Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum` - the two asterisks are just there (one at the start of the last sentence) to mark something, like a footnote or whatever, _not_ to bold the entire text, how does it know not to? Should I tokenize a `\\` so I don't output a giant bolded section, and require the user to type `\\* Lorem ipsum \\*`?
Well, off to Github to check..
`<1 minutes later>`
So Github actually uses 2 asterisks for bold, but, yes, they _do_ bold the entire section, as long as you but them at the ends of a word, not the beginning on the RHS asterisk (or in between words; in the middle of a word is fine)

One more benefit of construction logs I didn't think of - you can think through how your method works, and come up with a new one while you write!

Oops that `<b></b>` wasn't escaped before so now this whole thing is bold. Ok I _will_ need to escape any raw HTML.

It's looking pretty good right now (this isn't formatted great, I know):
```
compiling Abstract Syntax Tree.md
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
value: none
```

## Day 3
Escaping everything was pretty easy - I don't really need to worry about XSS attacks, since I'm the one writing all the content, and there's nothing stored here apart from the HTML/Markdown files anyway. One thing I didn't think about, though: if I escape `>` into `&gt;`, and _then_ `&` into `&amp;`, I'll actually end up with `&amp;gt;` for `>`. Not what I want. So I had to escape all the `&`s first. Precedence matters ([Gary Bernhardt](https://www.destroyallsoftware.com/screencasts/catalog/a-compiler-from-scratch) mentioned that in his screencast, I guess that's why I realised.)

About the stray `#`, `*`, `_`, , `+`, `-`, `[`, `]`, `(`, `)`, `!` that I talked about above; I think I'll just handle them by escaping them if I type in `\\*` etc, putting that in as a `Text` token with value `*`. I'm not gonna put in any fancy rules like "the second asterisk must not be at the start of a word" or anything like that, it's too complicated for what I need.

So, the tokens I think I'll need now,

* `#` to `######` for headers
* `>` for blockquotes
* `*` for bold
* `_` for italics
* `*` again, `+`, and `-` for unordered lists
* `{number}.` for ordered lists
* `[`, `]`, `(`, and `)` for links,
* `!` for images
* `\``, `    `, and `{tab}` for code
* newlines, so you know when a header stops
* "user-escaped" versions of `#` , `*`, `_`, , `+`, `-`, `[`, `]`, `(`, `)`, `!`, `\``, like `\\\*`
* and everything else that isn't one of the above tokens, is a "text" token

Maybe I can just handle the "user-escaped" ones by, when I read in a `\\`, just putting the next character in as a `Text` token straightaway?

Oh, I can't forget to not do anything with the stuff that's surrounded by two \\'s in the code generator.

The tokenizer makes tokens like this:
```
Token: make object! [
    type: copy ["Token"]
	isType: function [typeString [string!]] [not none? find self/type typeString]
    value: none
]

Header1: make Token [
    type: "Header1"
]
```

Pretty nasty, hacking class-inheritance into a prototype-based inheritance. I need a better way.

A possible improvement for the "I don't know how to tokenize text, everything that isn't in the Markdown syntax" issue above: just using [skip](https://www.red-lang.org/2013/11/041-introducing-parse.html) from Red's PARSE, like
`copy data skip (append tokens make Text [value: data])`

I'll definitely need to roll multiple `Text` tokens in a row into one big one though. Something for the parser.
That was easy to do! The two cursors in a while loop was fun!

## Day 4
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

## Day 5
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

## Day 6
I should read in environment variables from a .env file and set them with `set-env`, so I can just read them with `get-env` anywhere I want, avoid these nasty global variables
Adding that in was a lot easier than I thought, now I can use .env files like a proper dev!

I should be able to use [Prism](https://prismjs.com/) as a lightweight highlighter for my code blocks

For future reference, Eli Bendersky's blog seems very very good:
https://eli.thegreenplace.net/2009/02/16/abstract-vs-concrete-syntax-trees/
https://eli.thegreenplace.net/2011/01/23/how-debuggers-work-part-1s
https://eli.thegreenplace.net/2018/type-inference/

Also, maybe I should parse links into `<a>s` automatically

## Day 7
Making the initial parser was easy enough (I've only done headers and emphasis right now), but I've run into a pretty big snag: the Markdown syntax says this about paragraphs and line breaks
> A paragraph is simply one or more consecutive lines of text, separated by one or more blank lines. (A blank line is any line that looks like a blank line — a line containing nothing but spaces or tabs is considered blank.) Normal paragraphs should not be indented with spaces or tabs.
> 
> The implication of the “one or more consecutive lines of text” rule is that Markdown supports “hard-wrapped” text paragraphs. This differs significantly from most other text-to-HTML formatters (including Movable Type’s “Convert Line Breaks” option) which translate every line break character in a paragraph into a `<br />` tag.
> 
> When you do want to insert a `<br />` break tag using Markdown, you end a line with two or more spaces, then type return.
> 
> Yes, this takes a tad more effort to create a `<br />`, but a simplistic “every line break is a `<br />`” rule wouldn’t work for Markdown. Markdown’s email-style blockquoting and multi-paragraph list items work best — and look better — when you format them with hard breaks.
and I don't really understand how to handle that properly. I think it means anytime you see two `\\n`s in a row, that means you start a new `<p>`, closing the existing one (if there _is_ one), and `  \\n` at the end of a line becomes a `<br>`, but what about one newline by itself? It must become a `<br>` too.

I guess I'll need to make some sort of text-y Paragraph node that can include plain Text, Emphasis, Strikethrough, links, and inline code (anything inline, basically) for each string of inline tokens, and make each texty node become a `<p>` in the code generator? Consuming inline tokens until I get to a block one (headers, pluses, hyphens, numbersWithDots, exclamation marks, three backticks, four spaces, and tabs), then putting that into a Paragraph node?
One more point to writing things down!

A nice code feature I didn't realise in advance: you can tell pretty easily from the `parse_` functions what each Node matches
```
parseAsterisk: does [
        consume Asterisk
        case [
            peek Text [
                textToken: consume Text
                consume Asterisk
                return make EmphasisNode [
                    text: textToken/value
                ]
            ]
            peek Asterisk [
                consume Asterisk
                textToken: consume Text
                consume Asterisk
                consume Asterisk
                return make StrongEmphasisNode [
                    text: textToken/value
                ]
            ]
            ...
        ]
    ]
```

So, an Emphasis node is an Asterisk, some text, and another Asterisk, and a StrongEmphasis node is Asterisk, Asterisk, some text, Asterisk, Asterisk

I think I might not do the Paragraphy bits for now, do the code generation for the Headers, Emphasis and Strikethrough, so I can see some results soon. Maybe get to crank out a proper Tree visitor thingy

## Day 8
I think I'll need a `Space` token too - you nest items inside lists by using 4 spaces. Nope, that's already handled by the `FourSpaces` token used for the code blocks. 
But, there's another space-related issue - you can write a list like `\\n* LIST ITEM`, `\\n * LIST ITEM`, all the way up to 3 spaces, and still have a normal list item (4 spaces makes a sub-list), so I've a decision to make - do I handle this in the tokenizer, or in the code generator?
I can either make a `Space` token like I thought, and roll it into any surrounding `Text` tokens, like I already do with `Text` tokens (before the code generator gets the stream of tokens), or, when I'm parsing the token stream, if I see a Newline, followed by Text, followed by an Asterisk (or Hyphen, etc.), I can check if the Text is only a series of spaces, and make a list. The 2nd way seems more complicated.
Nah, there's a 3rd way. In the tokenizer, when I read in a series of spaces, I can check what comes after it - if it's an Asterisk (etc.), I can output the right list token, and ignore the spaces if there are < 4, and output the `FourSpace` token otherwise (maybe output `numberOfSpaces / 4` tokens, since both arguments are integers). Yeah, that's better.
But, I'll put that in the todos, and do it later. No need to complicate it yet, when there isn't even a working code generator yet.

Ambiguity I've just thought of - how do I handle an asterisk, followed by a backslash and another asterisk? It should be output as an inline code block with just a backslash in it, not as an emphasis marker and a literal asterisk, that would be really surprising and not make sense.
Nope, it's the more general, harder to sort, case: backslashes inside code blocks.
~I think I might need another property inside the `Text` tokens that says whether or not it was escaped~
I'm just going to make my life easy and always use two backslashes, so I'll type `\\\\` (I had to type 4 for 2 to appear)

## Day 9
Code generation seems easy enough so far, you pretty much just `switch` on the node type and recursively call the generating function:
```
generate: function [
    "recursively generates the HTML for a node in %nodes.red"
    node [object!]
] [
    switch/default node/type [
        "MarkdownNode" [
            (f_map lambda [self/generate ?] node/children)
                |> lambda [join ? newline]
        ]
        "NewlineNode" [
            "<br>"
        ]
        "EmphasisNode" [
            rejoin ["<i>" node/text "</i>"]
        ]
        "StrongEmphasisNode" [
            rejoin ["<b>" node/text "</b>"]
        ]
        "StrikethroughNode" [
            rejoin ["<s>" node/text "</s>"]
        ]
    ] [
        print rejoin ["AST is " prettyFormat node]
        do make error! rejoin ["don't know how to handle " node/type]
    ]
]
```

I completely messed up the order of the Header rules in the tokenizer:
```
headers: [
        "#" (append tokens make Header1 []) 
    |   "##" (append tokens make Header2 []) 
    |   "###" (append tokens make Header3 []) 
    |   "####" (append tokens make Header4 []) 
    |   "#####" (append tokens make Header5 []) 
    |   "######" (append tokens make Header6 [])
]
```
it should be the other way round - this way, it always matches two `Header1`s, rather than one `Header2`, which is exactly not what I want it to do.
(this was really annoying to figure out - it was the parser that was complaining when it was trying to consume a `Text` token after getting a `Header1` token, which is what it _should_ be doing, so I thought that that was the bug, but the bug was _actually_ in the tokenizer, way upstream! so, like how when you look really hard for something you've lost in one place, and don't think how it could be in another place, I didn't find the bug for ages. Kinda reminds me of what's the context and what's the form you're designing, in [Notes on the Synthesis of Form](/notes_on_the_synthesis_of_form.html)).

I need to handle URLs explicitly so that it doesn't mess up with any of the special characters (see generator.red/slugifyFilename); it shouldn't think that e.g. an underscore is an Underscore token, for the beginning of an Emphasis node.

This "collecting inline nodes into paragraph nodes" thing is _hard_. I'm trying to do in the main `parse` function and every way I can think of doesn't work.
Maybe I should just make the AST as normal, then go over it aferwards and group each consecutive run of inline nodes & 1 NewlineNode as a ParagraphNode?

Now the URL parsing from 2 paragraphs ago is failing on `[Commodotize your complement](https://www.gwern.net/Complement#2)`, because I read in the URL until I see a space, but the delimiter here is a right bracket, not a space! This is https://blog.codinghorror.com/the-problem-with-urls in code form :(
Ok I'm going to disallow `)` in URLs. `(` and `,` too - for consistency, and I like to put URLs in the middle of sentences.

I've made a fair amount of progress there, once the URL thingy was fixed: it gets down to `[If correlation doesn’t imply causation, then what does? - Michael Nielsen](http://www.michaelnielsen.org/ddi/if-correlation-doesnt-imply-causation-then-what-does/)` in [Articles I'll like](articles_ill_like.html) now!

Turns out I can't _not_ handle lists right now (look at the start of day 8) - that link I have in the above paragraph completely breaks the parser, because it has a `Hyphen` token in it, not a hyphen as part of a `Text` node, which I guessed I assumed would happen.
I was thinking about it by accident on the way back from a barbeque with one side of my family, and I've thought of a _fourth_, even simpler, way of handling it.
So, I made a `Hyphen` token _in the context of it being used for lists_ - the token only exists to be used to start an unordered list item; a hyphen marks an unordered list _if and only if_ it follows a newline and possibly a series of spaces (not caring about tabs here, I'm the only one writing the Markdown, and my tab key puts in spaces), so, I only need to make a `Hyphen` token if I've just read in a newline and maybe some spaces.
My `Hyphen` rule doesn't only need to have a hyphen in it!!

I think this is a big insight - if a tokenizer makes a token for a particular series of characters, like `-`, that token might actually only be a token in the context of other characters, so you can read in other characters beforehand (or after, I guess), and only _then_ decide to make the `-` or not.
Same goes for the `Asterisk`, `Plus`, and `NumberWithDot` tokens.

Yet another benefit of notes here - they're like comments that are tied to a time, rather than to a place in the code, so I can go back and re-read what I thought yesterday, soemthing I definitely needed to just do to see what the space issue was and how I thought it fix it. I don't even think we kid ourselves that we'll go back and look at the comments in past Git commits.

I forgot about relative URLs :(

## Day 10
I've had to write a bit of a hack to fix relative URLs not being recognised :/
It just consumes all the tokens after a LeftSquareBracket until the RightSquareBracket, taking them all as the link's text, and all the tokens between the LeftBracket and RightBracket as the actual URL:
```
; the link's text is the value of all the tokens until a RightSquareBracket is peeked
textValue: copy ""
until [
    currentToken: first self/tokens
    append textValue currentToken/value 
    self/tokens: next self/tokens

    peek RightSquareBracket
]
consume RightSquareBracket
consume LeftBracket

; the link's url is the value of all the tokens until a RightBracket is peeked
urlValue: copy ""
until [
    currentToken: first self/tokens
    append urlValue currentToken/value 
    self/tokens: next self/tokens

    peek RightBracket
]
consume RightBracket
```

After fixing some bugs, it get's down to [the Compiler page](compiler.html) now (the ordered list, specifically)!

Ok there's aproblem with starting a list with asterisks - it thinks they're marking emphasis, so it tries to look for another asterisk after a `Text` token, which will obviously break.
I'm going to do the same as I did with the hyphens - treat a newline, any spaces, and an asterisk as the start of a list by outputting `Newline` and `Hyphen` tokens - not an `Asterisk`, cos that would just being this problem back again! Lists with hyphens are already handled in the parser.
Lists with pluses _aren't_ though..
And doing _that_ broke this: `\n* hello world *` because the token stream is `[newline, hyphen, text, asterisk]` now. I'm not sure how I can tell "a list starting with an asterisk & arbitrary inline nodes & a newline" and "emphasis started by an asterisk & arbitrary inline nodes & an asterisk & a newline" easily. I guess I'll just not start a line with emphasis made with an asterisk, only an underscore.

I forgot that header's don't necessarily end with a newline, they can be at the end of the file .

## Day 11
I need to disallow `\`` in URLs too - if I write `[BACKTICK]https//www.example.com[BACKTICK]`, the last backtick is marking the end of the inline code, it shouldn't be included as part of the URL.
I can't actually escape backticks in URLs it seems, the URL will end at the escaped backtick and include the `\\` because I jump with a `to` again:
```
url: [
    "http://" copy data to disallowedURLCharacters (
            link: rejoin ["http://" data] 
            append tokens make Text [value: link]
        )
    |   "https://" copy data to disallowedURLCharacters (
            link: rejoin ["https://" data] 
            append tokens make Text [value: link]
        )
]
```
I _really_ shouldn't use `to` if I don't absolutely need to - maybe I can check for an escaped character, or a disallowed character (and fail), or copy `skip` like I do with the normal `Text` tokens.
Something to go into the todos.

Just managed to delete > 100 lines by using 1 type of `Header`, rather than 1 for each size! That's the good type of refactor, where you just _know_ that it was the right thing to do. Pretty rare.

Letting Headers work with all inline tokens was really once, since I'd already made a function to `parseInlineTokens`

Blockquotes were very annoying to get working compared to how simple they are to type - handling the empty lines like
```
> a
>
> c
```
was hard to get right.

But, on the bright side, everything seems to work now!

Now I'm trying to make the tables of contents, by using the headers' sizes: header 3's are children of the first header 2 above them, header 2's are children of the first header 1 above _them_, and it just isn't working. Too much recursion.
I have the headers like this in a list:
```
[
    object!: [
        size: 1
        text: "Technology"
    ]
    object!: [
        size: 2
        text: "Boundaries, Gary Bernhardt"
    ]
    object!: [
        size: 2
        text: "Radical stuff"
    ]
    object!: [
        size: 2
        text: "AI"
    ]
    object!: [
        size: 2
        text: "Guides"
    ]
    object!: [
        size: 1
        text: "Biology"
    ]
    object!: [
        size: 1
        text: "Politics"
    ]
    object!: [
        size: 1
        text: "Education"
    ]
    object!: [
        size: 1
        text: "Rationality"
    ]
    object!: [
        size: 1
        text: "Quanta"
    ]
]
```
and what I want is basically this (I've only put the numbers in for simplicity)
```
; 1 2 2 2 1 2 2 3 3 2 1
; to
; 1
; |----2
; |----2
; |----2

; 1
; |----2
; |----2
; |    |----3
; |    |----3
; |
; |----2

; 1
```
Do I while over all the headers until the end, and store the current header, the previous one, and the nearest parent? No, that won't work, I might need to do header 1 - 2 - 3 - 4 - 5 - 6, and I can't store 5 parents in a nice way

This is VERY hard. Nothing I do works.
I might need to make a proper Tree data structure; this is what I actually want in the end:
```
; [1   2   2   2    1  2   2  3   3    2    1]
; [[1  2   2   2]  [1  2   2  3   3    2]  [1]]
; [[1 [2] [2] [2]] [1 [2] [2  3   3]  [2]] [1]]
; [[1 [2] [2] [2]] [1 [2] [2  3   3]  [2]] [1]]
; [[1 [2] [2] [2]] [1 [2] [2 [3] [3]] [2]] [1]]

;                      root
;        -------------------------------
;        |              |              |
;        1              1              1
;        |              |              
;    ---------      ---------          
;    |   |   |      |   |   |          
;    2   2   2      2   2   2          
;                       |              
;                      ---             
;                      | |             
;                      3 3             
```

## Day 12
It might just be "insert each number as a child of the rightmost node that's smaller than it (the root if they're isn't one)". I think I was too stuck on transforming an array with a while loop to see it, until I made an ASCII tree.
Yeah this is a [min heap](https://en.wikipedia.org/wiki/Heap_\(data_structure\)), just not a binary one.

WIKIPEDIA WHY DO YOU HAVE BRACKETS IN URLS!!!
That URL won't work because I don't allow `(` or `)` in URLs, and I can't escape them right now. Another thing to fix.
Yet another point for these notes - my day 11 notes told me how I thought I could fix the problem yesterday
> I _really_ shouldn't use `to` if I don't absolutely need to - maybe I can check for an escaped character, or a disallowed character (and fail), or copy `skip` like I do with the normal `Text` tokens.
and I still think that'll work, a whole day later.

Yeah that _did_ work, it was just really annoying to do (I had to make a new `UrlToken`):
```
disallowedURLCharacter: ["(" | ")" | "," | "`" | whitespace]
literalURLCharacter: ["\" copy data disallowedURLCharacter (append tokens make urlToken [value: data]) ]
urlCharacter: [
        literalURLCharacter 
    |   "(" reject ; reject makes the "some urlCharacter" fail, so it will stop matching the url
    |   ")" (append tokens make RightBracket []) reject ; this is actually the RightBracket token used to mark the end of URL for a link, so we want to record that it's a RightBracket
    |   "," reject
    |   "`" (append tokens make Backtick []) reject
    |   [newline copy spaces any space "*" not "*"] ( ; we need to check for this specifically, because we are consuming the newline here, so the "newlineAndAsterisk" rule will never be matched with "http://www.example.com\n*"
            append tokens make NewlineToken []
            loop ((length? spaces) / 4) [ ; 4 spaces marks a sub-list
                append tokens make FourSpaces []
            ]
            append tokens make Hyphen []
        ) reject 
    |   newline (append tokens make NewlineToken []) reject 
    |   space (append tokens make Text [value: " "]) reject 
    |   whitespace reject
    |   copy data skip (append tokens make urlToken [value: data]) 
]

url: [
        "http://" (append tokens make urlToken [value: "http://"]) some urlCharacter
    |   "https://" (append tokens make urlToken [value: "https://"]) some urlCharacter
]
```

## Day 13
I've completely forgot to do [horizontal rules](https://daringfireball.net/projects/markdown/syntax#hr); they look very easy to do.
They _were_ very easy to do, once I remembered to make a `Token` `object!`, not just a `block!`.

> It might just be "insert each number as a child of the rightmost node that's smaller than it (the root if they're isn't one)".
worked perfectly! This is what the algorithm looks like:
```
headerTree: make TreeNode []
foreach header headers [ // a list of headers
    nodeToInsertInto: nodeToInsertHeaderInto headerTree header
    nodeToInsertInto/insertNode make TreeNode [value: header]
]

nodeToInsertHeaderInto: function [
    "find the node in the tree where the header should be inserted"
    n [object!]
    header [object!]
] [
    ; each header is inserted as a child of (the rightmost node whose header's size is smaller than it - if there isn't one, it's the root)
    ; this finds that rightmost node

    ; if this node doesn't have any children, we can only insert it here
    if empty? n/children [
        return n
    ]

    ; if the last child has the same size as the header we want to insert, we actually want to insert it here
    lastChild: last n/children
    lastHeader: lastChild/value
    if lastHeader/size == header/size [
        return n
    ]

    ; otherwise, we recurse into the last child's subtree
    return nodeToInsertHeaderInto lastChild header
]
```

Though I can't actually print out the tree, since a child links to its parent, and the parent to each of its children, so the stack overflows. I *can* use a [pre-order traversal](https://en.wikipedia.org/wiki/Tree_traversal#Pre-order_\(NLR\)) instead though.

Table of contents is done! Looks pretty good, too.

Some cross-pollination from the day job: the search should be at the top of [the homepage](index.html) - if it's at the bottom, you need to scroll to see the results.

## Day 14
I'm trying to handle sub-lists now, and it's pretty awkward; the parsing was easy enough (when you're parsing a hyphen, consume as many `FourSpaces` tokens as you can immediately after, count how many there were, and rather than inserting a plain `ListItemNode`, once for each `FourSpaces` token, insert that inside a `ListNode` which itself is inside another `ListItemNode`), but the actual markup it generates now is _nasty_
```
<ul>
    <li>a</li>
    <li>
        <ul>
            <li>b</li>
        </ul>
    </li>
    <li>
        <ul>
        <li>
            <ul>
                <li>c</li>
            </ul>
        </li>
        </ul>
    </li>
</ul>
```
all to nest `b` inside `a`, and `c` inside `a` with 2 indents.
It'd make more sense if it looked like this instead:
```
<ul>
    <li>a</li>
    <li>
        <ul>
            <li>
                b
                <ul>
                    <li>c</li>
                    <li>d</li>
                </ul>
            </li>
        </ul>
    </li>
</ul>
```
but that's quite a bit harder to do - I might need to postprocess the AST.

Ooh. Rather than have 2 different List nodes, I can just have 1, and store whatever type of list it is in the node. Should be able to remove some code.

The _real_ problem is it looks like this:
![nested lists have wrong list styles](static/images/nestedListsBadListStyle.png)
those `b` and `c` list items shouldn't have the list markers to the left of them.

Only the last list item in the tree should have a marker, and that's the first one I add, so I think I'll be able to sort it out by setting something in the `ListItemNode`s that means "add the `list__item--noListStyle` class"

Ok that works for `<ul>`s, but definitely not `<ol>`s, because of the badly shaped AST:
![the ordered lists have the wrong numbers](static/images/orderedListsBadNumbers.png)

Actually it's not just because of the AST - the numbers will stop be wrong if I fix it, since there's a `ListNode` that's being hidden by the `--noListStyle` class, so the outer lists will jump from 1 to 3, or 2 to 4, etc. Ah well. I don't think that's fixable.

## Day 15
Back and forwardlinks (gonna call them the linkmap) today (copying [Roam](https://roamresearch.com/) here)!
Quite fun to do, once I got the refactoring I had to do first out of the way (makes me think of essential vs. incidental complexity).
I needed to make bi-directional maps of "what pages does this page link to?" and "what pages link to this page?", and it turned out to be _really_ simple:
```
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
```

The only annoying thing was, to do that, I needed to have the [AST](/abstract_syntax_tree.html) for each `.md` file inside the root script that "manages" the whole compilation of the wiki, since to work out which pages link to a specific page, you need to _have_ all the different pages ASTs already.
And I was returning the compiled-Markdown HTML only, so I had to rejig it to return the AST (and the tokens, for good measure), as well. Reminds me a bit of Fred Brooks [No Silver Bullet](https://en.wikipedia.org/wiki/No_Silver_Bullet) paper on accidental and essential complexity.

## Day 16
I've made the forward and backlinks, now to actually put them on the page

![back and forwardlink](static/images/backlinks.png)
Easy

---

# Commonly needed code

## Footnotes
```
footnote
<sup id="fnref:1">[1](#fn:1)</sup>

footnote backreference
<span id="fn:1"></span> The other 5, if you're curious <sup>[\[return\]](#fnref:1)</sup>:
```
