tags: [technology/computer/programming/languages/design]

# Compilers

Compilers take code written in one [programming language](programming_language.html) and translate it to another programming language.  Normally, this is from one high(er)-level language to a lower-level one, like [C](c.html) to [Assembly](assembly.html), but occasionally it's from one language to another that's "on the same level", like [Typescript](typescript.html) to [Javascript](javascript.html).  

They generally have 3 stages:
1. A tokenizer (aka a lexer), which makes a stream of tokens from the input string
2. A parser, which parses the token stream into an [Abstract Syntax Tree (AST)](abstract_syntax_tree.html)
3. A code generator, which takes the AST and outputs code in the target language

(Bits stolen from [Gary Bernhardt's wonderful screencast about this](https://www.destroyallsoftware.com/screencasts/catalog/a-compiler-from-scratch).)

## Tokenizer

Tokens are the smallest meaningful pieces in a language - for example, in `def f() 1 end`, even though `def` is three characters, `d`, `e` and `f` don't mean anything by themselves, only `def` does, so it's a token.

For the [Markdown](https://daringfireball.net/projects/markdown/basics) -> HTML compiler used to make this wiki, we need a few different tokens:
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
* and everything else that one of the above tokens, is a "text" token

## Parser

The parser takes the stream of tokens made in the last step, and turns that into a tree that the code generator will use

## Code generator