tags: [technology/computer/programming/languages/design]

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

No types needed, though if you wanted to, it would be
```
f :: Int -> String -> [String]
f baseAmt str = replicate rptAmt newStr
  where
    rptAmt = if baseAmt > 5 
      then baseAmt 
      else baseAmt + 2
    newStr = “Hello “ ++ str
```

Given an expression `E` and a type `T`, there are 3 questions you can ask:
1. Is `E` a `T`? -  `E : T`? - this is type checking
2. What type is `E`? -  `E : _`? - can we derive a type for E? - this is type inference
3. Given `T`, is there an expression for it - `_ : T`? An example of a `T`?

# Hindley-Milner type system
The Hindley-Milner (HM) type system is a type system with parametric polymorphism (generic functions & types) that can infer the most general type of a program, in almost linear time. It was described by Roger Hindley first, rediscovered by Robin Milner, and proved by Luis Damas.

HM does type inference, but can also be used for type checking - if you say `E` is a `T1`, it infers a type `T` for `E`, and then checks if `T1 == T`.

Examples:
```
mymap f [] = []
mymap f (first:rest) = f first : mymap f rest

types: 
mymap :: (t1 -> t2) -> [t1] -> [t2]

2nd argument
first expression is [], a list
second expression is (first:rest), : is cons, so first cons'ed on last, so it's a list too ("rest" can be an empty list)
but we don't the types of first/rest (nothing constrains them), so the element have a "generic" type t1

1st argument
f is applied to an element in the list (type t1), so f takes in a t1, but nothing constrains the return type, so it's t2
f :: (t1 -> t2)

result
: prepends a head on a tail of a list, and the head element must have the same type as the elements in the list, so
: :: (t3 -> [t3] -> [t3])

in this case, t3 :: f first :: t2
so here : :: t2 -> [t2]

so mymap :: (t1 -> t2) -> [t1] -> [t2]
```

Another example:
```
foo f g x = if f(x == 1) then g(x) else 20

"if cond" must return a boolean, and the types of the branches must be the same and are what the if returns,
f(x == 1) :: bool
g(x) :: 20 :: int

== :: t -> t
so x == 1 means x :: 1 :: int

so g :: (int -> int)
and f :: (bool -> bool)

foo's return type is whatever the if returns, and it returns an int 

foo :: (bool -> bool) -> (int -> int) -> int -> int
foo f g x
```

## Algorithm

There are 3 stages to HM type inference:
1. Assign unique symbolic type names (like t1, t2, ...) to all subexpressions.
2. Using the language's typing rules, write a list of type equations (or constraints) in terms of these type names.
3. Solve the list of type equations using [unification](https://eli.thegreenplace.net/2018/unification/).

### Stage 1
Taking the above example, stage 1, assigning symbolic type names to subexpressions:
```
foo f g x = if f(x == 1) then g(x) else 20

foo                             t0
f                               t1
g                               t2
x                               t3
if f(x == 1) then g(x) else 20  t4
f(x == 1)                       t5
x == 1                          t6
1                               int
g(x)                            t7
x                               t3
20                              int
```

_Every_ subexpression gets a type, and we du-duplicate them (`x` is there twice, and has type `t3` both times), and 20 is always a constant int, so we don't need a symbolic name for it.

### Stage 2
Writing type equations/constraints:
```
t1 = (t6 -> t5)                 since t1 is the type of f, t6 is the type of x == 1, and t5 the type of f(x == 1)
t3 = int                        because of the types of ==, and the 2nd argument in x == 1
t6 = bool                       ""
t2 = (t3 -> t7)                 since t2 is the type of g, t3 is the type of x, and t7 is the type of g(x)
t6 = bool                       again, since it's the condition of the if
t4 = int                        since the then and else branches must match, and 20 = int
```

### Stage 3
Now we have a list of type constraints, we need to find the most general solution - the _most general unifier_.

#### Unification
Unification is a process of automatically solving equations between symbolic terms, like we want to do here.

We need to define different _terms_ from constants, variables and function applications:
* A lowercase letter represents a constant (could be any kind of constant, like an integer or a string)
* An uppercase letter represents a variable
* `f(...)` is an application of function f to some parameters, which are terms themselves

Examples: 
* `V`: a single variable term
* `foo(V, k)`: function foo applied to variable V and constant k
* `foo(bar(k), baz(V))`: a nested function application

Unification's sort of a generalisation of pattern matching:
We have a constant term, and a pattern term, which has variables. Pattern matching is finding an assignment of variables that makes the two terms match:
Constant term: `f(a, b, bar(t))`
Pattern term:  `f(a, V, X)`

Obviously `V = b` and `X = bar(t)` - this can also be called a _substitution_, mapping variables to their assigned values.

In a slightly harder case, variables can appear multiple times:
Constant term: `f(top(a), a, g(top(a)), t)
Pattern term: ` f(V,      a, g(V),      t)`

Here, `V = top(a)`/

Sometimes, though, there isn't a valid substitution:
Constant term: `f(top(a), a, g(top(b)), t)
Pattern term: ` f(V,      a, g(V),      t)`
`V` can't match both `top(a)` and `top(b)` at the same time.

---

Unification's similar to that pattern matching, except both terms can have variables, so there isn't a constant term and a pattern term:
First term: `f(a, V, bar(D))`
Second term `f(D, k, bar(a))`
Finding a substitution that makes them equivalent is unification - it's `{V = k, D = a}` here.

Sometimes there can be an infinite number of possible unifiers:
First term: ` f(X, Y)`
Second term: `f(Z, g(X))`
`{X = Z, Y = g(X)}`, `{X=K, Z=K, Y=g(K)}`, `{X=j(K), Z=j(K), Y=g(j(K))}` etc. are all valid substitutions here, and the first one is the **most general unifier** - it can be turned into any of the others, by applying `{Z = j(K)}`, but the reverse isn't true.

Essentially, `X` must equal `Z`, and it can do that directly `X = Z`, or they can both be a different variable `K`, or a function of it `j(K)`, or a function of it, `h(j(K))`, forever.

#### Unification algorithm
Solving unification problems seems simple, but there are a few corner cases to know about - Peter Norvig's noted a common error <sup id="fnref:1">[1](#fn:1)</sup>



<sub>big thanks to [Eli Bendersky](https://eli.thegreenplace.net/2018/type-inference/) & [Wikipedia](https://en.wikipedia.org/wiki/Hindley-Milner_type_system#Introduction)</sub>


---

1. <span id="fn:1"></span> [Correcting a Widespread Error in Unification Algorithms](https://www.semanticscholar.org/paper/Correcting-a-Widespread-Error-in-Unification-Norvig/95af3dc93c2e69b2c739a9098c3428a49e54e1b6) <sup>[\[return\]](#fnref:1)</sup>