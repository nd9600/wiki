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
    const element = document.getElementById('<?php echo $date . \"-\" . $id; ?>');
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
Instead of adding a JS `<script>` to the HTML body inside an echoed string in PHP, just pull out the JS into a function, and call it from the jQuery AJAX's `onSuccess` function.
Far better.

# If you're repeating yourself a lot, de-duplicate
Writing the same code twice might be fine, three times probably isn't.

# Try not write functions with side-effects
If you can make a function's output depend only on its input, do. Don't change anything about the world either, if you can help it - don't print anything, insert something into a database, make an API call.

This makes the function _far_ easier to test - if its output just depends on its input, you don't need to set anything complicated up to call it, mock anything, stub anything...
and if something's easier to test, you're more likely to write tests for it!

# Testing
Generally, there are 2 reasons for testing:
1. Checking that you're doing the right thing
2. Checking that you're doing the thing right

Only people can do the first one - see [here](testing.html) for more.

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

### Code that runs in tests should be the same as code that's running in production 
Mocks can provide a false sense of security


# Be consistent
Keep variable names, function arguments' positions, and "general coding styles" (early returns vs. returning from both `if` branches, etc) consistent - it'll give you less you need to think about.

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