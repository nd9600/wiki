tags: [technology/computer/programming]

These are principles, **not** rules - you don't _need_ to follow every single one exactly all the time, you're allowed to break them. Like George Orwell's [6 rules for writing](http://www.openculture.com/2016/05/george-orwells-six-rules-for-writing-clear-and-tight-prose.html)<sup id="fnref:1">[1](#fn:1)</sup>:
> Break any of these rules sooner than say anything outright barbarous.

<sub>(all examples are in PHP)</sub>

# Remember context and form
If you're developing a solution to a problem, you might get stuck in a rut, making the solution in a particular way, and forget there could be other approaches that you haven't considered, so take a minute, and pre-empt yourself - think "ok I'm doing it _this_ particular way, but what other way could I be doing it?"
[Day 11, 12 and 13 here](my_wiki.html#day_11) is a perfect example - for quite a while, I thought the only way to make tables of contents for this wiki was to use recursion, since the table is pretty recursive itself (it's a list of lists, and each list can contain another list, which can contain ...), but that was too hard for me to get working. Eventually, after a few different ASCII art drawings, I realised I was too stuck into using recursion, and it was actually a tree, with a [pretty simple algorithm](my_wiki.html#day_13).

# Get other people's input
This helps with [this one](#remember_context_and_form)

I've made many bad decisions because I was working by myself and I didn't get anyone else to 
* look at my work
* to brainstorm with
* bounce ideas off of
* plan something with
* tell me how they'd solve something
* listen to what I was doing and see if they had any ideas
* complain to

A good example:
At work, we load a calendar on a webpage with lots of bookings in it. I had to do something after the calendar had finished loading, so, I found the code that added the rows in the calendar to the page. It, in our weird legacy way of making HTML, worked like this (sadly, similar to [this W3Schools page](https://www.w3schools.com/php/php_ajax_php.asp)):
* a JS function would make an AJAX call to an `.ajax.php` file
* that AJAX PHP script directly echoed out the calendar rows as HTML, to the output response
* the JS function took that response, the calendar rows, and directly added it to the page

I decided that the best place for my new code to run was in the AJAX PHP script - after it had finished echoing its own HTML, I did this:
```
echo "
<script>
    setTimeout(function() {
            const element = document.getElementById('<?php echo $date . \"-\" . $id; ?>');
        }, 
        10
    );
    ...
</script>
";
```
If wasn't fun, doing all of that quote-escaping.

Then, in our mandatory code reviews, one of my colleagues suggested I do this instead:
```
function doStuffAfterCalendarLoads() {
    const element = document.getElementById(date + "-" + id);
    ...
}
$.post(url, data, {
    success() {
        ...
        doStuffAfterCalendarLoads();
    }
})
```
Instead of adding JS function inside a timeout inside a `<script>` to the HTML body inside an echoed string in PHP, just pull out the JS into a function, and call it from the jQuery AJAX's `onSuccess` function.
Far better.

# Having a bigger toolbox is better
It's good to know lots of different ways of doing something, even if aren't necessarily going to use a particular method all the time; for example, functional programming's [maps and filters](https://en.wikipedia.org/wiki/Map_\(higher-order_function\)\#Examples\:_mapping_a_list) are incredibly useful to know about: there'll probably be some situation where using them will make your code far easier to understand.
Though, you need to keep in mind the next point..

# That shiny new tool/technique you've just heard probably isn't the perfect thing to use _all the time_
Ok, you've just heard about [monads](http://learnyouahaskell.com/a-fistful-of-monads), and you might think they're amazingly incredible and everyone should always use them, they abstract away _everything_ etc etc.
You're probably wrong. Even if moands are perfect for whatever you're doing (they're probably not), other people will need to read, understand, maintain, ..., your code whenever they want to change it/it breaks. Most likely, they probably won't know how to use your shiny new tool, or have even have heard of it.

# If you're repeating yourself a lot, de-duplicate
People generally call this [don't repeat yourself](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself), although it's not just as simple as "when you write something twice, immediately pull that code out into a function":

## Abstractions are tools, not goals
The purpose of an abstraction is to remove details from the code that you don't need to worry about, they're not something you should blindly aim for because "a more abstract function is always better".
For example, mapping a function across an array can be better than a foreach, because it lets you focus on the important bit, the mapped function, not the array iteration:
```
$list = [1, 2, 3, 4];

$newList = array_map(
    function(int $element) {
        return $element * 2;
    },
    $list
);

// vs

$newList = [];
foreach ($list as $element) {
    $newList[] = $element * 2;
}

/*
unfortunately, PHP doesn't have nice syntax for mapping; but arrow functions are coming soon, and'll look like this:
$list = [1, 2, 3, 4];
$newList = map(fn($element) => $element * 2, $list);
*/
```

## Don't abstract too early
When you're writing some code, resist the urge to abstract away a bit of it until you actually need to.
You might make a mistake and implicitly remove details from the first version that are actually different in different instances of the problem, or leave in unnecessary details. You might not even realise your mistake until you go to use the abstraction in 2nd or 3rd case!
For example, say you're writing code to let people book a hotel room, and you're calculating the total price, which includes taxes. Calculating the tax is annoying, so you pull it out and abstract it away, implicitly assuming that the tax is based on the number of nights the customer has booked the room for, because that's how you calculate taxes in your country, Eurasia.
_Then_, later on, you expand out to Eastasia, but over there they calculate hotel room taxes based on the number of people staying in the room, and you've assumed too much! Now you have to go and fix the messy abstraction from before.
If you'd left the abstracting until there were the 2 different cases, you might not have made the mistake.

# Try not write functions with side-effects
If you can make a function's output depend only on its input, do. Don't change anything about the world either, if you can help it - don't print anything, insert something into a database, make an API call.

This makes the function _far_ easier to test - if its output just depends on its input, you don't need to set anything complicated up to call it, mock anything, stub anything...
and if something's easier to test, you're more likely to write tests for it!

# Testing
Generally, there are 2 reasons for testing:
1. Checking that you're doing the right thing
2. Checking that you're doing the thing right

Only people can do the first one - see [here](/testing.html) for more.

## Do the Right Thing
If you can, before you start doing something, make sure that it's the Right Thing to do - there's no point making an airplane, if your boss actually wanted a tank, or you needed something that could work underwater.
Initially, I was going to say "there's no point wasting effort in doing the Wrong Thing", but occasionally, you'll only figure out what the Right Thing is by exploring & making many different Wrong Things first; sometimes you just have to start making things, and see what works afterwards. The space (?) of things you _could_ do is so massive you might not be able to narrow it down just by thinking about it.

## Do the Thing Right
Write tests

### No need for 100% code coverage
If you find yourself writing tests purely to get to 100% code coverage, you should probably not write those tests; not everything needs a test written for it - this is a pretty pointless thing to test, you can look at and see if it's right:
```
function index(bool $isLoggedIn) {
    if (!$isLoggedIn) {
        return new ErrorResponse("not logged in");
    }
}
```
Especially if you've already written a test for the same code in a different function, you don't really need to test it again.

### Don't write fragile tests
If, in a test, you [decouple](/notes_on_the_synthesis_of_form.html) the code that you're testing so it's a "true unit test", by mocking out all of its dependencies, everything it needs to run successfully, and every function it calls, you're decoupling the  tested code from the _effects_ of the mocked code, but you have **explicitly** coupled it to the fact that it _does_ need that specific dependency with that specific format, or that it calls that specific function, which returns this specific data.
Instead of your code being decoupled from other code, your test is now coupled to it instead.
For example, say we want to get a particular country's [VAT](https://en.wikipedia.org/wiki/Value-added_tax) rate right now. This requires some sort of database query or API call, because it's live data that can change, so you'll need to mock this out if you want to make a "unit" test (this is [Mockery's](http://docs.mockery.io/en/latest/reference/creating_test_doubles.html) syntax):
```
$countryRepository
    ->shouldReceive("getTaxPercentForPropertyNow")
    ->andReturn(0.2);
```
Imagine, later on, that you change the method `getTaxPercentForPropertyNow` to instead be called `getCurrentTaxPercent`, and instead of representing a 20% tax rate as 0.2, you use 20; you'll need to change everywhere `getTaxPercentForPropertyNow` is called. Most likely, your IDE will do the renaming for you automatically, but it probably won't do the refactoring in the test, because it's a string, and since you're used to having your IDE do it for you, you'll probably forget to change it everywhere manually, so you'll forget about the test, which will fail, but you'll only realise the mistake once your tests run, whenever that is.
Your test is now _fragile_; the more often you change your code like this (and not just in these sorts of simple refactorings, if you completely change what the mocked function does or returns, too), the more often you'll have to change your tests, for little real benefit.
At work, we were spending so much time fixing these broken-but-not-really unit tests that we decided to delete all of them.

A test breaking because the behaviour of the code it's testing has changed is good; breaking because that code's dependency's behaviour has isn't.

### Code that runs in tests should be the same as code that's running in production 
Mocks can provide a false sense of security here - when you make a mock, you're kinda embedding some assumptions about the code you're mocking, and those assumptions might not be right.

# Comments
I say "comments", but I think it should be more general than that, and called "descriptions" instead, because you can achieve the same thing without comments.

## If something isn't obvious from the code, describe it
When you've just written some code, every bit of it will seem obvious to you, because you just wrote it! You can wait 6 months to forget about it, then come back, get confused at it, and try to write a comment, _or_ you can [have someone else](l#get_other_peoples_input) to look at it right now - if they ask a question about anything, then it's probably not obvious enough, and needs a comment.

Generally, _why_ a particular bit of code exists is far less obvious to a reader than what it does, so you'll probably need to describe that more often.

## Put the description as close as possible to the thing it's describing
The further away a description is from the thing it's describing, the less likely it is to be read & the more likely it is to be wrong.
This is pretty much X's Law<sup id="fnref:2">[2](#fn:2)</sup>, but for code:
* if the description for some code is on the line above it, people will probably see it & correct it if the code changes and outdates the description
* if the description is at the top, people _might_ see it and might correct it
* if the description's on a wiki somewhere, people probably _won't_ even imagine that it might exist, so they won't read or correct it

The best way to describe something, I think, is to use a variable or a function name - they're very simple abstractions that are directly tied to the thing that they're doing, and if you change the behaviour of a variable or a function so much that the name's invalid, you'll probably fix the name.
So, if you have this (JS) code:
```js
if (
    (
        (
            typeof numberOfAdults === "string"
            && ! RegExp(/^.*\.$/).test(numberOfAdults)
        )
        || typeof numberOfAdults !== "string"
    )
    && !isNaN(parseFloat(numberOfAdults))
    && isFinite(numberOfAdults)
) {
    return;
}
```

it's _far_ better to refactor it to this
```js
function isNumber(n) {
    const isString = typeof n === "string";
    if (isString) {
        const stringEndsInDot = RegExp(/^.*\.$/).test(n);
        if (stringEndsInDot) {
            return false;
        }
    }

    return !isNaN(parseFloat(n)) && isFinite(n);
}

if (!isNumber(numberOfAdults)) {
    return;
}
```
Both the code being in a function with the name `isNumber`, and the regex test being given the name `stringEndsInDot` make this far easier to understand.

# If you people to do something, make it easy for them to do
The easier something is to do, the more likely people are to do it.

# Be consistent
Keep variable names, function arguments' positions, and "general coding styles" (early returns vs. returning from both `if` branches, etc) consistent - it'll give you less unnecessary stuff you need to think about. The less unnecessary stuff you need to think about, the more necessary things you can afford to kep in your brain.

# Type things
If you can give things a type, do.
I don't think there're any exceptions to this one.

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

2. <span id="fn:2"></span> X's Law <sup>[\[return\]](#fnref:2)</sup>:
> 
