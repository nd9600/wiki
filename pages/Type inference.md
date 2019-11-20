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
* [Haskell](/haskell.html) requires that everything is typed, and will _infer_ types - if a variable is instantiated as the result of calling a function that returns an int, it knows the variable's an int - so you don't need to type every single thing yourself

## Polymorphism
A _polymorphic_ function is one that doesn't require its argument(s) to have specific type(s) - they're **generic** functions & types.
The simplest polymorphic function is `id`:
```
f :: a -> a
f = \x -> x
```
This function has a polymorphic type, and polymorphic types are expressed through universal (∀) quantification (something is applicable to every type or holds for everything):
the type of `id` can be written as `forall A. A -> A` - for all types `A`, the type of the function is `A -> A`. These sorts of types (they're called forall/universal quantifiers, because they quantify over all types), can be "instantiated" when they're used with an actual, concrete type, like `integers` or `booleans`.
There are other kinds of quantification, too, like bounded quantification and existential quantification. Bounded quantification is useful when we need to apply other constraints on the generic type variables. It's commonly seen in interface types.

```
map :: (a -> b) -> [a] -> [b]
is the same as writing
map :: forall a. forall b. (a -> b) -> [a] -> [b]
or
map :: forall a b. (a -> b) -> [a] -> [b]
```

Quantifiers can be allowed in different places in a type system: monomorphic types don't allow quantifiers at all (rank 0), rank 1 allows quantifiers at the top level, so this is invalid:
```
forall A. A -> (forall B. B -> B)
```
though the inner quantifier can be moved up here, to
```
forall A, B. A -> B
```
but this isn't always possible, like in
```
forall B. (forall A. A) -> B     -- a forall appearing within the left-hand side of (->) cannot be moved up
```
so this can't be represented in a rank 1 type system

The Hindley-Milner type system only allowed rank 1 types, because type inference is undecidable in an arbitrary-rank system: it's impossible to infer the types of some well-typed expressions without some type annotations, and it's harder to implement arbitrary-rank type inference, too.

Polytypes (or _type schemes_) are types containing variables bound by one or more for-all quantifiers, e.g. `∀ α . α → α` 

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
This is some [Haskell](/haskell.html) code:
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
Constant term: `f(top(a), a, g(top(a)), t)`
Pattern term: ` f(V,      a, g(V),      t)`

Here, `V = top(a)`

Sometimes, though, there isn't a valid substitution:
Constant term: `f(top(a), a, g(top(b)), t)`
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
Solving unification problems seems simple, but there are a few corner cases to know about - Peter Norvig's noted a common error <sup id="fnref:1">[1](#fn:1)</sup>.

The correct algorithm is based on J.A. Robinson's 1965 paper "A machine-oriented logic based on the resolution principle". More efficient algorithms have been developed since, but this focuses on correctness and simplicity, not performance.

We start by defining the data structure for terms:
```
Term

App(Term):  // an application of `fname` to `args`
    fname
    args

Var(Term):
    name

Const(Term):
    value
```

Then a function to unify variables with terms:
```
unify: function [
    {Unifies term 'x and 'y with initial 'subst.

Returns a substitution (a map of name -> term) that unifies 'x and 'y, or none if they can't be unified. Pass 'subst = {} if no substitution is initially known. Note that {} means a valid (but empty) substitution
    }
    x       [object!] "term"
    y       [object!] "term"
    subst   [map! none!]
    return: [map! none!]
] [
    case [
        subst is none [
            none
        ]
        x == y [
            subst
        ]
        x is Var [
            unifyVariable x y subst
        ]
        y is Var [
            unifyVariable y x subst
        ]
        all [
            x is App
            y is App
        ] [
            either any [
                x.fname != y.fname
                (length? x/args) != (length? y/args)
            ] [
                none
            ] [
                repeat i (length? x/args) [
                    subst = unify x/args/i y/args/i subst
                ]
                subst
            ]
        ]
        true [
            none
        ]
    ]
]

unifyVariable: function [
    "Unifies variable 'v with term 'x, using 'subst. Returns updated 'subst or none on failure"
    v     [object!] "variable"
    x     [object!] "term"
    subst [map!]
    return: [map! none!]
] [
    assert v is Var
    case [
        v/name in subst [
            unify subst(v/name) x subst
        ]
        all [         ; this fixes the "common error" Peter Norvig describes in "Correcting a Widespread Error in Unification Algorithms"
            x is Var
            x/name in subst
        ] [
            unify v subst/(x/name) subst
        ]
        occursCheck v x subst [
            none
        ]
        true [
            ; v is not yet in subst and can't simplify x, returns a new map like 'subst but with the key v.name = x
            put subst v/name x
            subst
        ]
    ]
]
```

The key bit is the recursive unification: if `v` is bound in the substitution, its definition is unified with `x` to guarantee consistency throughout the process (vice-verase if x is a variable).
`occursCheck` guarantees that there aren't any variable bindings that refer to themselves, like `X = f(X)`, which might cause infinite loops:

```
occursCheck: function [
    {Does the variable 'v occur anywhere inside 'term?

Needed to guarantee that there aren't any variable bindings that refer to themselves, like X = f(X), which might cause infinite loops

Variables in 'term are looked up in subst and the check is applied recursively}
    v     [object!] "variable"
    term  [object!] "term"
    subst [map!]
    return: [logic!]
] [
    assert v is Var
    case [
        v == term [
            true
        ]
        all [         
            term is Var
            term/name in subst
        ] [
            occursCheck v subst/(term/name) subst
        ]
        term is App [
            foreach arg term/args [
                if occursCheck v arg subst [
                    return true
                ]
                return false
            ]
        ]
        true [
            false
        ]
    ]
]
```

Now, tracing through an execution:
```
unify 
    f(X,         h(X), Y, g(Y))
    f(g(Z),      W,    Z, X)

unify called
root of both arguments are Apps of function f, with the same # of arguments, so it loops over the arguments, unifying them individually
    unify(X, g(Z)): calls unifyVariable(X, g(Z)) because X is a variable
        unifyVariable(X, g(Z)): none of the conditions are matched, so {X = g(Z)} is added to the substitution
    unify(h(X), W): calls unifyVariable(W, h(X), {X = g(Z)}) because W is variable
        unifyVariable(W, h(X), {X = g(Z)}): none of the conditions are matched, so {W = h(X)} is added to the substitution
    unify(Y, Z, {X = g(Z), W = h(X)}): calls unifyVariable(Y, Z, {X = g(Z), W = h(X)}) because Y is a variable
        unifyVariable(Y, Z, {X = g(Z), W = h(X)}): none of the conditions are matched, so {Y = Z} is added to the substitution ({Z = Y} would also be fine)
    unify(g(Y), X, {X = g(Z), W = h(X), Y = Z}): calls unifyVariable(X, g(Y), {X = g(Z), W = h(X), Y = Z})
        unifyVariable(X, g(Y), {X = g(Z), W = h(X), Y = Z}): X is in the substitution, so it calls unify(subst[X], g(Y), subst) = unify(g(Z), g(Y), subst)
            unify(g(Z), g(Y), {X = g(Z), W = h(X), Y = Z}): again, both Apps of g, so loops over the arguments, Z and Y
                unify(Z, Y, {X = g(Z), W = h(X), Y = Z}): Z is a variable, so calls unifyVariable(Z, Y)
                    unifyVariable(Z, Y, {X = g(Z), W = h(X), Y = Z}): Y is a Var and in the substitution, so calls unify(Z, subst[Y], {X = g(Z), W = h(X), Y = Z}) = unify(Z, Z, {X = g(Z), W = h(X), Y = Z})
                        unify(Z, Z, {X = g(Z), W = h(X), Y = Z}):  Z == Z, so it just returns the (final) substitution
    so, mgu = {X = g(Z), W = h(X), Y = Z}

```

The algorithm here isn't too efficient- with large unification problems, check more advanced options. 
It copies around `subst` too much, and we don't try to cache terms that have already been unified, so it repeats too much work.

For a good overview of the efficiency of unification algorithms, check out two papers:
1. "An Efficient Unificaiton algorithm" by Martelli and Montanari
2. "Unification: A Multidisciplinary survey" by Kevin Knight

---

## Formally

The HM type system is normally shown like this in textbooks:
![Var, App, Abs, Let, Inst, Gen](static/images/type_inference_hindleyMilner.png)
but it's a lot less scary that it looks:
* each _typing rule_ means "the top implies the bottom"
* multiple expresses are anded together
* `x : σ` means `x has type σ`
* `∈` means `is in`, `∉` means `isn't in`
* `Γ` is normally called an environment or context (sometimes a "partition"), but here it's our **substitution** - `x : σ ∈ Γ` means `the substitution Γ includes the fact that x has type σ`
* `⊢` means `proves` or `determines`, so `Γ ⊢ x : σ` means that `the substitution Γ determines that x has type σ`
* `,` is a way of including more assumptions into `Γ`, so, `Γ, x : τ ⊢ e : τ'` means that `Γ, with the additional, overriding assumption that x has type τ, proves that e has type τ'`

### Var
The first typing rule `Var` is just our `Variable` from above:
```
if Γ includes that x has type σ, 
then Γ determines that x has type σ
```

### App
This is our `Application` - note, this isn't necessarily _function_ application, it's applying one type to another type:
```
if Γ determines that e0 is a function from τ to τ' AND Γ determines that e1 has the type τ
then Γ determines that e1 applied to e0 has type τ' 
```

### Abs
 `Abstraction` is function abstraction:
```
if Γ, with the extra assumption that x has type τ, determines that e has type τ'
then Γ determines that a function that takes an x and return an e, has type τ to τ'
```

### Let
This rule is for _let polymorphism_<sup id="fnref:2">[2](#fn:2)</sup>:
```
if Γ determines that e has type σ, and Γ, with the extra assumption that x has type σ, determines that e1 has type τ
then Γ determines that a let expression that locally binds x to e0, a value of type σ, makes e1 have type τ

"if we have an expression e0 that is a 𝜎 (being a variable or a function), and some name, x, also a 𝜎, and an expression e1 of type 𝜏, then we can substitute e0 for 𝑥 wherever it appears inside of e1"

"really, this just tells you that a let statement essentially lets you expand the context with a new binding - which is exactly what let does"
```

### Inst
This is about instantiation, sub-typing (**not** like object-oriented sub-typing):
```
σ's relate to type-schemes like ∀ α . α -> α, not types

if we have 
id = ∀x. λx     (σ)
and 
id2 = ∀xy. λx -> x      (σ', y isn't used)
id2 ⊑ id

if Γ determines that e has type-scheme σ' and σ' is a sub-type of σ                   (⊑ means a partial-ordering relation)
then Γ determines that e also has type-scheme σ
```

### Gen
This is about generalizing types, generalization:
```
a free variable is a variable that isn't introduced by a let-statement or lambda inside some expression (not a bound variable); this expression now depends on the value of the free variable from its context

if Γ determines that e has type σ AND α isn't a free variable in Γ
then Γ determines that e has type σ, forall α

"if there is some variable α which is not "free" in anything in your context, then it is safe to say that any expression whose type you know e : σ will have that type for any value of α"
```

---

<sub>big thanks to [Eli Bendersky](https://eli.thegreenplace.net/2018/type-inference/) & [Wikipedia](https://en.wikipedia.org/wiki/Hindley-Milner_type_system#Introduction)</sub>

1. <span id="fn:1"></span> [Correcting a Widespread Error in Unification Algorithms](https://www.semanticscholar.org/paper/Correcting-a-Widespread-Error-in-Unification-Norvig/95af3dc93c2e69b2c739a9098c3428a49e54e1b6) <sup>[\[return\]](#fnref:1)</sup>
2. <span id="fn:2"></span> From [here](https://papl.cs.brown.edu/2018/Type_Inference.html#%28part._let-poly%29) <sup>[\[return\]](#fnref:2)</sup>
> Consider the following program:
```
(let ([id (fun (x) x)])
  (if (id true)
      (id 5)
      (id 6)))
```
> If we write it with explicit type annotations, it type-checks:
```
(if (id<Boolean> true)
    (id<Number> 5)
    (id<Number> 6))
```
> However, if we use type inference, it does not! That is because the A’s in the type of id unify either with Boolean or with Number, depending on the order in which the constraints are processed. At that point id effectively becomes either a (Boolean -> Boolean) or (Number -> Number) function. At the use of id of the other type, then, we get a type error!
> 
> The reason for this is because the types we have inferred through unification are not actually polymorphic. This is important to remember: just because you type variables, you don’t necessarily have polymorphism! The type variables could be unified at the next use, at which point you end up with a mere monomorphic function. Rather, true polymorphism only obtains when you can instantiate type variables.
>
>In languages with true polymorphism, then, constraint generation and unification are not enough. Instead, languages like ML and Haskell implement something colloquially called let-polymorphism. In this strategy, when a term with type variables is bound in a lexical context, the type is automatically promoted to be a quantified one. At each use, the term is effectively automatically instantiated.

Because identifiers not bound using a `let` or `where` clause (or at the top level of a module) are limited with respect to their polymorphism. Specifically, a lambda-bound function (i.e., one passed as argument to another function) cannot be instantiated in two different ways. For example, this program is illegal:
```
let f g  =  (g [], g 'a')       -- ill-typed expression
in f (\x -> x)
```
because `g`, bound to a lambda abstraction whose principal type is `a -> a`, is used within `f` in two different ways: once with type `[a] -> [a]`, and once with type `Char -> Char`.
