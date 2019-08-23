tags: [meta]
Hello

# Why

I made this after I read [this interview with Ceasar Bautista](https://superorganizers.substack.com/p/why-ceasar-bautista-wrote-his-own), and I liked the idea:
* I read a fair amount of stuff, and I can't really remember the little details of most of it. I hope I will if I write them down here
* Writing what I think about things and how I understand they work should help my understand things properly  - I might _think_ I know how a compiler works, but do I really? Writing [an article](compiler.html) should make me actually understand it
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
It's a pretty standard [compiler](compiler.html), as far as I know. I stole the basic design from [Gary Bernhardt's very very good screencast about it](https://www.destroyallsoftware.com/screencasts/catalog/a-compiler-from-scratch) - the three stages, the tokenizer that takes in the string and makes a stream of tokens, the parser that turns the token stream into an Abstract Syntax Tree, and the code generator that takes the AST and outputs the HTML. Have a look at the `compiler` link for more details.

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
* Let Headers work with Asterisks, Underscores, Tildes, Links, and Code, as well as just Text
* A new ParagraphNode is made when we read in two NewlineTokens in a row, 1 NewlineToken is a NewlineNode
* Handle spaces before list markers (see day 8)
* Handle sub-lists (see above)
* Site web/graph
* Build a table of contents from headers
* Copy templater tests over from the framework
* Write system/integration tests

## Done
* ~Handle backslashes inside code blocks~ just use two backslashes when you want a literal one
* ~Change slugifiers to work with ASCII letters, numbers and `$-_.+!*'()`~ browsers don't handle `'` in URLs
* ~Delete existing pages before making new ones!~



# Construction report

## Day 1

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
* ```, `    `, and `{tab}` for code
* newlines, so you know when a header stops
* and everything else that isn't one of the above tokens, is a "text" token

I forgot that the index tree needed to be able to handle tags having pages _and_ other tags inside it. It broke horribly when I put actually nested tags in (the programming section). Weirdly, fixing it actually seemed to simplify how I make the tree (the `addToIndexFromTags` function). Though, I really should make a Tree `object!`, with Nodes, Branches and Leaves, rather than just this ghetto version I have right now. Visiting the tree in a [DFS](dfs.html) shouldn't have been as hard as it was.

I'm not sure this "tokenizer-parser-code generator" approach is the right one right now; tokenizing the Markdown _seems_ to work ok now, but I'm 99% sure it'll break when I try to run it on something that isn't `# Abstract Syntax Tree` - mainly because I don't know how to tokenize text, everything that isn't in the Markdown syntax, something you just want to pass straight through to the output.
Hmm, maybe just read the input in and immediately output it with transformations? No, too complicated, and how do you know when you're supposed to switch to e.g. bold mode? 
That's also the issue I'm having with the current way - for example, say you read in an `Asterisk` token; if you read in `Asterisk`, then `some text`, then another `Asterisk`, you know you should output `<b>some text</b>` in the end, but what about if you just get `Asterisk some text`? How do you know not to output `<b>some text</b>`. Say, on Github, if you type `* Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. *Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum` - the two asterisks are just there (one at the start of the last sentence) to mark something, like a footnote or whatever, _not_ to bold the entire text, how does it know not to? Should I tokenize a `\\` so I don't output a giant bolded section, and require the user to type `\\* Lorem ipsum \\*`?
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

## Day 3

Escaping everything was easy enough - I don't relly need to  worry about XSS attacks, since I'm the one writing all the content, and there's nothing stored here apart from the HTML/Markdown files anyway. One thing I didn't think about, though: if I escape `>` into `&gt;`, and _then_ `&` into `&amp;`, I'll actually end up with `&amp;gt;` for `>`. Not what I want. So I had to escape all the `&`s first. Precedence matters ([Gary Bernhardt](https://www.destroyallsoftware.com/screencasts/catalog/a-compiler-from-scratch) mentioned that in his screencast, I guess that's why I realised.)

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
* ```, `    `, and `{tab}` for code
* newlines, so you know when a header stops
* "user-escaped" versions of `#` , `*`, `_`, , `+`, `-`, `[`, `]`, `(`, `)`, `!`, `\\``, like `\\*`
* and everything else that isn't one of the above tokens, is a "text" token

Maybe I can just handle the "user-escaped" ones by, when I read in a `\\`, just putting the next character in as a `Text` token straightaway?

Oh, I can't forget to not do anything with the stuff that's surrounded by two \\`s in the code generator.

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

> The implication of the “one or more consecutive lines of text” rule is that Markdown supports “hard-wrapped” text paragraphs. This differs significantly from most other text-to-HTML formatters (including Movable Type’s “Convert Line Breaks” option) which translate every line break character in a paragraph into a `<br />` tag.

> When you do want to insert a `<br />` break tag using Markdown, you end a line with two or more spaces, then type return.

> Yes, this takes a tad more effort to create a `<br />`, but a simplistic “every line break is a `<br />`” rule wouldn’t work for Markdown. Markdown’s email-style blockquoting and multi-paragraph list items work best — and look better — when you format them with hard breaks.

and I don't really understand how to handle that properly. I think it means anytime you see two `\\n`s in a row, that means you start a new `<p>`, closing the existing one (if there _is_ one), and `  \\n` at the end of a line becomes a `<br>`, but what about one newline by itself? It must become a `<br>` too.

I guess I'll need to make some sort of ~~text-y~~ Paragraph node that can include plain Text, Emphasis, Strikethrough, links, and inline code (anything inline, basically) for each string of inline tokens, and make each ~~texty~~ node become a `<p>` in the code generator? Consuming inline tokens until I get to a block one (headers, pluses, hyphens, numbersWithDots, exclamation marks, three backticks, four spaces, and tabs), then putting that into a Paragraph node?
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
Nah, there's a 3rd way. In the tokenizer, when I read in a series of spaces, I can check what comes after it - if it's an Asterisk (etc.),I can output the right list token, and ignore the spaces if there are < 4, and output the `FourSpace` token otherwise (maybe output `numberOfSpaces / 4` tokens, since both arguments are integers). Yeah, that's better.
But, I'll put that in the todos, and do it later. No need to complicate it yet, when there isn't even a working code generator yet.

Ambiguity I've just thought of - how do I handle an asterisk, followed by a backslash and another asterisk? It should be output as an inline code block with just a backslash in it, not as an emphasis marker and a literal asterisk, that would be really surprising and not make sense.
Nope, it's the more general, harder to sort, case: backslashes inside code blocks.
~I think I might need another property inside the `Text` tokens that says whether or not it was escaped~
I'm just going to make my life easy and always use two backslashes, so I'll type `\\\\` (I had to type 4 for 2 to appear)