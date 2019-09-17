https://en.wikipedia.org/wiki/Hindley-Milner_type_system#Introduction
https://eli.thegreenplace.net/2018/type-inference/

# Types in general

Types in Computer Science are a formalised way to enforcing categories of things, for example:
* integers
* numbers
* strings
* arrays
* arrays of strings
* algebraic data types (ADTs)
* functions
* functions that take in integers and return strings
* arrays of functions that ... etc

A _type system_ is a set of rules that assigns different types to different things, then (generally) the types are checked to see that they've been connected in a consistent way: e.g. that a function that expects to receive an integer and return an array doesn't instead get a string and return another function.
This _type checking_ can be done at compile time, which is called _static type checking_, and/or at runtime, called _dynamic type checking_.

_Typing_ is assigning a variable/parameter a type.

Types are normally checked to reduce/remove bugs (like the function receiving/returning the wrong types, above), but they can also be used to let the compiler optimize things, for documentation, etc.

Different languages have more or less expressive type systems:
* Javascript doesn't let you explicitly assign types to variables/parameters at all
* Red/Rebol lets you type function parameters and return types (though return types are ignored right now), but not variables
* [Haskell](haskell.html) requires that everything is typed, and will _infer_ types - if a variable is instantiated as the result of calling a function that returns an int, it knows the variable's an int - so you don't need to type every single thing yourself

<dl class="definitionList">
    <dt>Type system</dt>
    <dd>A set of rules that assigns different types to different things</dd>
    
    <dt>Type checking</dt>
    <dd>Checking that types have been connected consistently</dd>

    <dt>Static type checking</dt>
    <dd>Type checking at compile time</dd>
    <dt>Dynamic type checking</dt>
    <dd>Type checking at runtime</dd>

    <dt>Hindley-Milner type system</dt>
    <dd>A type system with parametric polymorphism (generic functions & types) that can infer the most general type of a program, in almost linear time</dd>
</dl>
# Inference
This is some [Haskell](haskell.html) code:
```
f baseAmt str = replicate rptAmt newStr
  where
    rptAmt = if baseAmt > 5 
      then baseAmt 
      else baseAmt + 2
    newStr = “Hello “ ++ str
```

Haskell can _infer_ that `f` returns a list of strings, even though there aren't any types in the definition:
1. `baseAmt > 5` and `>` only compares [two variables of the same type](http://hackage.haskell.org/package/base-4.12.0.0/docs/Data-Ord.html#v:-62-), means `baseAmt` is an int, like 5
2. Every expression must always return the same type, and `baseAmt` and `baseAmt + 2` are both ints, so `rptAmt` is an int
3. `++` concats 2 lists together, and `"Hello "` is a string, so `newStr` must be a string too
4. `replicate rptAmt newStr` is taking in an int and a string ,and replicate's [type signature](https://hackage.haskell.org/package/base-4.12.0.0/docs/Prelude.html#v:replicate) is `Int -> a -> [a]`, so it returns a list of strings

No types needed.