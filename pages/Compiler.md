tags: [technology/computer/programming/languages/design]
Compilers take code written in one [programming language](programming_language.html) and translate it to another programming language.  Normally, this is from one high(er)-level language to a lower-level one, like [C](c.html) to [Assembly](assembly.html), but occasionally it's from one language to another that's "on the same level", like [Typescript](typescript.html) to [Javascript](javascript.html).  

They generally have 3 stages:
1. A tokenizer (aka a lexer), which makes a stream of tokens from the input string
2. A parser, which parses the token stream into an [Abstract Syntax Tree (AST)](abstract_syntax_tree.html)
3. A code generator, which takes the AST and outputs code in the target language

(Bits stolen from [Gary Bernhardt's wonderful screencast about this](https://www.destroyallsoftware.com/screencasts/catalog/a-compiler-from-scratch).)

I'm going to use the compiler I made for this wiki, which translates [Markdown](https://daringfireball.net/projects/markdown/basics) to HTML, as an example to explain how compilers work.

# Tokenizer

Tokens are the smallest meaningful pieces in a language - for example, in `def f() 1 end`, even though `def` is three characters, `d`, `e` and `f` don't mean anything by themselves, only `def` does, so it's a token.

For the compiler used to make this wiki, we need a few different tokens:
* a `\\` backslash, followed by any character, for it to be included literally (not as part of any other token)
* `#` to `######` for headers
* `>` for blockquotes
* `*` for bold
* `_` for italics
* `~` for strikethrough
* `*` again, `+`, and `-` for unordered lists
* `{number}.` for ordered lists
* `[`, `]`, `(`, and `)` for links,
* `!` for images
* ```, `    `, and `{tab}` for code
* `    ` again, for nesting things inside lists
* newlines, so you know when a header stops,
* and everything else that isn't one of the above tokens, is a "text" token

The general idea is you look at the current input, make a specific token based off whatever the current input is (not necessarily only the first character, e.g. `    `), add that token to current stream (it's a `block!` with this wiki, since the compiler's written in Red), and advance to the next bit of the input you haven't matched yet, until you're at the end of the input. If you can't match all the input, something's gone wrong.

One important note: since [Red's](https://www.red-lang.org/) [PARSE](https://www.red-lang.org/2013/11/041-introducing-parse.html) engine uses [Parsing Expression Grammars](https://en.wikipedia.org/wiki/Parsing_expression_grammar), the order of the rules in the tokenizer is important - if an earlier rule matches, it ignores later alternative rules. So, I wrote the rules in exactly the order the tokens are above: `backslash[CHARACTER]`, then the header rules, etc., so that the literal character rule would be used first - I didn't want `\\*` to be matched as a `\\` and as an `*`, separately.

# Parser

The parser takes the stream of tokens made in the last step, and turns that into a tree that the code generator will use

# Code generator