tags: [technology/computer/programming/languages]

Typescript is a superset of [Javascript](https://en.wikipedia.org/wiki/JavaScript) - anything that's valid JS is _also_ valid TS; but Typescript has added to Javascript, so valid TS normally isn't valid JS.

For example, here's a TS implementation of a queue:
```
// http://code.iamkate.com/javascript/queues/
export default class Queue<T> {
    private queue: T[];
    private offset: number;

    public isEmpty(): boolean {
        return (this.queue.length === 0);
    }

    public enqueue(item: T): void {
        this.queue.push(item);
    }

    public dequeue(): T | undefined {
        ...
    }

    ...
}
```

and the corresponding JS
```
export default class Queue {
    queue;
    offset;

    ...

    isEmpty() {
        return (this.queue.length === 0);
    }

    enqueue(item) {
        this.queue.push(item);
    }

    dequeue() {
        ...
    }

    ...
}
```

Typescript is Javascript with added [type annotations](#type_annotations) that are [type checked](#type_checking) when the `.ts` files are compiled into JS.

# Type checking
The main benefit of Typescript is its type checker, `tsc` - it checks _at compile time_ that, when you define a e.g. function `f` that takes 2 arguments `x` and `y` that are strings:
* you're always giving it exactly 2 arguments, not 1, not 3, both strings - `f(1, "a")` or `f("a")` won't compile
* you're not using `x` or `y` like it's a different type - `x["key"] = 7` won't compile

or, you define a boolean `b`
```
let b: boolean = true;
```
you don't try to use it as a number
```
let c = b + 2;
```

One particularly annoying thing TS stops happening is null errors:
```
let element = document.getElementByID("elementId");
```
here, `element` can be undefined, if it's not on the page, and TS won't let you pass a possibly null variable into a function that expects a not-null variable.

Also, JS is very stupid:
```
function f(x, y) {return x + y;}
f(1)
```
You'd expect that to throw an error, but in Javascript, if you don't pass in a required parameter, it silently makes it `undefined`!
Obviously, Typescript doesn't let you do that.

---

A big difference from JS is that these errors are found at _compile_ time, not _run_time like JS, and they stop your program from even being compiled in the first place.

This also helps with refactoring - if you change the type of an argument from a `string` to a `number`, the TS compiler will complain at you until you've fixed, across your entire codebase, _every_ instance where you're still passing in a `string`.

# Type annotations
Like the code exampls above show, Typescript is like JS, but with added type annotations; arguments to functions, and what the functions return can be _typed_: they are given [types](#types), primitive ones like `string` or `number` (JS doesn't have integer/float/double types, only numbers), more complicated ones like an array of numbers, `number[]`, [generics](#generics), [classes](#classes), [interfaces](#interfaces), [enums](#enums) etc.

```
enqueue(item)
```
in JS becomes

```
public enqueue(item: T): void
```
in TS - `enqueue` takes an item of type T only, and  doesn't return anything.

Generally in TS, type annotations are written with the thing you want to type, a `:`, and the type it has:
```
let isDone: boolean = false;
enqueue(item: T): void
type EventCallback = (dispatchedEvent: DispatchedEvent) => void;
```

# Types

## Primitives

## Classes

## Functions

## Interfaces

## Enums

## Generics

## Unions

## Optional types

https://www.typescriptlang.org/docs/handbook/advanced-types.html#nullable-types

# Type inference

See [type inference](type_inference.html) for more.

# Declarations