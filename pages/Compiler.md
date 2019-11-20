tags: [technology/computer/programming/languages/design]
Compilers take code written in one [programming language](/programming_language.html) and translate it to another programming language.  Normally, this is from one high(er)-level language to a lower-level one, like [C](/c.html) to [Assembly](/assembly.html), but occasionally it's from one language to another that's "on the same level", like [Typescript](/typescript.html) to [Javascript](https://en.wikipedia.org/wiki/JavaScript).  

They generally have 3 stages:
1. A tokenizer (aka a lexer), which makes a stream of tokens from the input string
2. A parser, which parses the token stream into an [Abstract Syntax Tree (AST)](/abstract_syntax_tree.html)
3. A code generator, which takes the AST and outputs code in the target language

(Bits stolen from [Gary Bernhardt's wonderful screencast about this](https://www.destroyallsoftware.com/screencasts/catalog/a-compiler-from-scratch).)

I'm going to use the compiler I made for this wiki, which translates [Markdown](https://daringfireball.net/projects/markdown/basics) to HTML, as an example to explain how compilers work.

# Tokenizer

Tokens are the smallest meaningful pieces in a language - for example, in `def f() 1 end`, even though `def` is three characters, `d`, `e` and `f` don't mean anything by themselves, only `def` does, so it's a token.

For the compiler used to make this wiki, we need a few different tokens:
* `######` to `#` for headers, in _that_ order
* `>` for blockquotes
* `*` for bold
* `_` for italics
* `~` for strikethrough
* `*` again, `+`, and `-` for unordered lists
* `{number}.` for ordered lists
* `[`, `]`, `(`, and `)` for links,
* `!` for images
* `\``, `    `, and `{tab}` for code
* `    ` again, for nesting things inside lists
* newlines
* and everything else that isn't one of the above tokens, is a "text" token

Also, we can't just have the above tokens as rules, we need a rule for a `\\` backslash, followed by any character, so the character is included literally (not as part of any other token), and there's another little complication that means I can't just have simple straight rules: URLs have to be handled explicitly in the tokenizer, so that it doesn't mess up with any of the special characters that URLs can have (see [RFC 1738](https://tools.ietf.org/html/rfc1738))

The general idea is you look at the current input, make a specific token based off whatever the current input is (not necessarily only the first character, e.g. `    `), add that token to current stream (it's a `block!` with this wiki, since the compiler's written in Red), and advance to the next bit of the input you haven't matched yet, until you're at the end of the input. If you can't match all the input, something's gone wrong.

For some tokens, I'm storing their actual character representation (so, `*` for an `Asterisk` token), since, if I type in "backtick asterisk backtick", I want that to appear as `*`, but the asterisk will be tokenized as an `Asterisk` token, not as `Text` with the value `*` - doing that would've been too complicated, and now I can just directly read out the value of an `Asterisk` node if it happens to be inside a code block in the parser.

One important note: since [Red's](https://www.red-lang.org/) [PARSE](https://www.red-lang.org/2013/11/041-introducing-parse.html) engine uses [Parsing Expression Grammars](https://en.wikipedia.org/wiki/Parsing_expression_grammar), the order of the rules in the tokenizer is important - if an earlier rule matches, it ignores later alternative rules. So, I wrote the rules in exactly the order the tokens are above: `backslash[CHARACTER]`, then the header rules, etc., so that the literal character rule would be used first - I didn't want `\\*` to be matched as a `\\` and as an `*`, separately.

Just because the standard compiler has 3 stages doesn't mean it can _only_ do those 3 things - this compiler, for example, processes the normal token stream after it makes it; the way I do
> everything else that isn't one of the above tokens, is a "text" token
is like this:
```
copy data skip (append tokens make Text [value: data])
```
and that `skip` advances the input by one character, so a string like `test` will be made into 4 different `Text` tokens, not 1 token with "test" in it, like you'd expect, so I run a while loop over the tokens and put all the consecutive text tokens into one big one.

I made a `Hyphen` token _in the context of it being used for lists_ - the token only exists to be used to start an unordered list item; a hyphen marks an unordered list _if and only if_ it follows a newline and possibly a series of spaces, so, it only needs to make a `Hyphen` token if its just read in a newline and maybe some spaces.
In short, the `Hyphen` rule doesn't only need to have a hyphen in it!

If a tokenizer makes a token for a particular series of characters, like `-`, that token might actually only be a token in the context of other characters, so you can read in other characters beforehand (or after, I suppose), and only _then_ decide to make the `-` or not.
Same goes for the `Asterisk`, `Plus`, and `NumberWithDot` tokens.

# Parser

The parser takes the stream of tokens made in the last step, and turns that into a tree that the code generator will use, e.g. if the token stream (indented for readability) is
```
[
    Header1 Text Newline Newline 
    Underscore Text Underscore Newline 
    Text Newline
    Text
    NumberWithDot Text Newline 
    NumberWithDot Text Newline 
    NumberWithDot Asterisk Asterisk Text Asterisk Asterisk
]
```
it would give you something like
```
MARKDOWN
    HEADER
        SIZE: 1
        TEXT: "EXAMPLE"
    BR
    PARAGRAPH
        EMPHASIS
            TEXT: "EXAMPLE"
        TEXT: EXAMPLE
        BR
        TEXT: EXAMPLE
        BR
    ORDERED_LIST
        ITEMS: [
            TEXT
            TEXT
            STRONG_EMPHASIS
                TEXT: "EXAMPLE"
        ]
```

This is probably the most complicated stage of the whole compiler (for the Markdown one, it's > 700 lines; the tokenizer is \~200, and the code generator \~100).

It does this by using two main functions, `peek` and `consume`; both take 1 argument, which is the token type they expect to see. `peek` looks at the first token in the stream, and returns whether it's the expected type, and `consume`, if the first token has the expected type, removes it from the stream and returns it.

With parsers, they quite often have to look at more than 1 token to decide how to parse the stream; this is what the `k` means in an `LR(k)` parser (the "LR" means "Left-to-right, Rightmost derivation in reverse", which isn't important here) - it's the maximum number of tokens the parser has to peek at before it knows how to parse the stream. Normally, `k` is 1, but here I think it'll need to be more than that - three backticks in a row have  to be treated differently that 1 backtick, so we can't just peek at 1 backtick and decide it's an inline code block, I think.

This parser would be a 4-parser - it peeks at the next 4 tokens when parsing backticks for code blocks.

Once the parser has peeked at a token, if it knows how to parse the start of stream based just off that one token, it consumes the token, optionally transforms it/uses it (and any following tokens, if it needs to) somehow to make somesort of `Node` that it then adds into the AST.

I'll use the `HeaderNode`,  `EmphasisNode` and `StrongEmphasisNode` as examples.
Once the parser peeks at the stream and sees a `Header1` token
```
peek Header1 [
    append markdownContent parseHeader1
    print "parsed header1"
]
```
it calls a function `parseHeader1` that consumes `Header1` token, and, since headers contain all the text up to the next newline (so they're followed by text and newline tokens), consumes the following `Text` and `Newline` tokens, and adds a `Header` node to the AST using the `Text` token's value
```
parseHeader1: does [
    consume Header1
    textToken: consume Text
    consume NewlineToken

    make HeaderNode [
        size: 1
        text: textToken/value
    ]
]
```

Parsing `Asterisk`s is slightly more complicated - since one Asterisk is for emphasis, but 2 are for _strong_ emphasis, once we consume an asterisk, we need to peek at the next token and see if it's `Text` or another `Asterisk`, and make an `EmphasisNode` or a `StrongEmphasisNode` depending on which it is, consuming the text like it does with the header nodes:
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

        true [
            firstToken: first self/tokens
            do make error! rejoin ["expected Asterisk or Text but got " firstToken/type { in file "} self/file {"}]
        ]
    ]
]
```

# Code generator