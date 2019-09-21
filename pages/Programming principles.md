tags: [technology/computer/programming]

These are principles, **not** rules - you don't _need_ to follow every single one exactly all the time, you're allowed to break them. Like George Orwell's [6 rules for writing](http://www.openculture.com/2016/05/george-orwells-six-rules-for-writing-clear-and-tight-prose.html)<sup id="fnref:1">[1](#fn:1)</sup>:
> Break any of these rules sooner than say anything outright barbarous.

(all examples are in PHP)

# Remember context and form
If you're developing a solution to a problem, you might get stuck in a rut, making the solution in a particular way, and forget there could be other approaches that you haven't considered, so take a minute, and pre-empt yourself - think "ok I'm doing it _this_ particular way, but what other way could I be doing it?"
[Day 11, 12 and 13 here](/my_wiki.html#day_11) is a perfect example - for quite a while, I thought the only way to make tables of contents for this wiki was to use recursion, since the table is pretty recursive itself (it's a list of lists, and each list can contain another list, which can contain ...), but that was too hard for me to get working. Eventually, after a few different ASCII art drawings, I realised I was too stuck into using recursion, and it was actually a tree, with a pretty simple algorithm:
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

# Don't use global variables, only global constants
It can get confusing to see who changed what where and when; stick to functions passing arguments back and forth so you can trace the dataflow.
`CONSTANTS` are fine because they can't be changed

# Don't use things that have been defined in other files, unless you explicitly import them
Like the above, but even worse - how do you know what file a variable was defined in? Many `variable $x is undefined` problems will pop up if you do this.

To avoid it, do something like this:
```
use App\Order\OrderFactory; // (PHP namespaces)

function f(double $price) {
    $order = OrderFactory::makeOrder($price);
}

// rather than
function f(double $price) {
    $order = makeOrder($price); // where did this come from?
}
```

If you don't have modules or something similar in your language, maybe use a consistent way to "import" files at the top of a script or something like that.

# Don't include/evaluate files
This is pretty much the above one, but at the file level - if you do it, you'll just be tempted to use variables that're defined in the "parent" file inside the child, it's far too easy to make the child depend on the parent.

The problem is because there's pretty much always going to be a dependency between files (unless the included file is a library of somesort), and tracking those dependencies in your head is just annoying and will cause mistakes - you'll forget about them; allowing the computer to do it instead is a better idea.

You shouldn't [include](https://www.php.net/manual/en/function.include.php) files "down" - so, file `a` includes file `b` includes file `c` - but you _can_ extend files "up" with inheritance, like [Twig templates](https://twig.symfony.com/):
```

// template.html - just inserts "Hello {{ name }}" into the "content" block that's in "base.html"
{% extends "base.html" %}
{% block content %}
    Hello {{ name }}
{% endblock %}

// base.html
<html>
<head>
    ...
<head>
<body>
    {% block content %}
        Default content
    {% endblock %}
</body>
</html>
```
Because there's not really much of a dependency here.

# If you're repeating yourself a lot, de-duplicate

Writing the same code twice might be fine, three times probably isn't.


---

1. <span id="fn:1"></span> The other 5, if you're curious <sup>[\[return\]](#fnref:1)</sup>:
> 1. Never use a metaphor, simile, or other figure of speech which you are used to seeing in print.
>
> 2. Never use a long word where a short one will do.
> 
> 3. If it is possible to cut a word out, always cut it out.
> 
> 4. Never use the passive where you can use the active.
> 
> 5. Never use a foreign phrase, a scientific word, or a jargon word if you can think of an everyday English equivalent.