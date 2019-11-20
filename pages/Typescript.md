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
Like the code exampls above show, Typescript is like JS, but with added type annotations; arguments to functions, and what the functions return can be _typed_: they are given [types](#types), primitive ones like `string` or `number` (JS doesn't have integer/float/double types, only numbers), composite/abstract ones like an array of numbers, `number[]`, [generics](#generics), [classes](#classes), [interfaces](#interfaces), [enums](#enums) etc.

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

## Any
Typescript has an escape hatch: the `any` type; any type can be assigned to it, and it can be assigned to any type; all of these work fine:
```
let notSure: any = 4;
notSure = "maybe a string instead";
notSure = false;
notSure.ifItExists();

function f(x: string[]) {...}
f(notSure)
```
This seems to defeat the point of the [type checking](#type_checking), and it does - the type checker will ignore anything with an any, even if it would normally throw an error. The point of `any` is when you don't know what type something is (if you're using a third-party library without [declarations](#declarations), for example), or you've started migrating an existing codebase over to TS, and you haven't figured out the proper type for something yet.

## Primitives

TS has the standard, simple, types:
```
let isDone: boolean = false;

let n: number = 4;
let n2: number = 4.123;

let s: string = "abcdef";

let list: number[] = [1, 2, 3];
let list: Array<number> = [1, 2, 3];
```

Array elements _must_ have all be the same type: you can't have an array with any type under the sun, unless you use the `any` above.
<sub>note:</sub> you _can_ declare an array like
```
let list: (string | number)[] = ["abc", 1, 2];
```

If you know you'll always want a specific number of elements together, you can use a tuple, which _can_ have different types in it:
```
let x: [string, number] = ["abc", 1];
```
though, it _must_ always have 2 elements, no more, no less.
Order matters here, you can't do `x = [1, "abc"]`, nor `x[3]`.

`function f(): void` means `f` doesn't return anything

## Never
`never` represents values that never occur: it's the return type for a function that always throws an exception, or one that never returns.

It's useful after a `switch` statement:
```
function assertUnreachable(x: never): never {
    throw new Error("Didn't expect to get here");
}

enum Direction {
    Up = "Up",
    Down = "Down",
    Left = "Left",
    Right = "Right"
}

let direction: Direction = Direction.Up;
switch (direction) {
    case Direction.Up: {
    } case Direction.Down: {
    } case Direction.Left: {
    }
}
```
here, Typescript will exhaustively check that I've covered all the [enums](#enums) cases. and it'll complain I've missed `Direction.Right`.

## Classes
Like [ES6](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Classes), Typescript has classes:
```
class Board {
    public static idCounter: number = 0;

    public readonly numberOfRows: number;

    constructor(
        public readonly id: number,
        public readonly status: Status = Status.NotStarted
    ) {
        this.numberOfRows = this.boardData.length;
        ...
    }

    public boardAsString(rowSeparator: string = "\n"): string {
        ...
    }
}
```
except here, there are 
* static properties accessed like `Board.idCounter++`
* public, private, and protected modifiers, like in Java
* `readonly` attributes, so properties can only be set in the constructor
* parameter properties, so you can declare and assign a property in the constructor, in one go: put a visibility modifier or `readonly` before the argument

## Functions
You can make a specific type for a function like this:
```
type EventCallback = (dispatchedEvent: DispatchedEvent) => void;

let list: EventCallback[] = [
    (dispatchedEvent: DispatchedEvent) => {// do something with dispatchedEvent},
    (dispatchedEvent: DispatchedEvent) => {// do something with dispatchedEvent}
];
```

Functions can have default parameters:
```
function buildName(firstName: string, lastName = "Smith") {
    return firstName + " " + lastName;
}
buildName("John");
```


## Interfaces
Interfaces are a way of saying an object has specific properties that have specific values, a bit like a class, but far more lightweight and easier to define:
```
interface BoardPosition {
    x: number;
    y: number;
}

let bp: BoardPosition = {
    x: 0, 
    y: 0
};

interface BoardOptions {
    status: Status;
    boardData?: BoardType;
    startPoint?: BoardPosition;
    endPoint?: BoardPosition;
}
```
`boardData` etc. in `BoardOptions` are all optional properties.
You can also have `readonly` properties, like in [classes](#classes).

They're useful when you want to specify exactly what sort of object your function takes in, rather than just a plain `object` - this way, you _know_ what properties it'll have.

<sup>note:</sup> TS's uses [structural subtyping](https://en.wikipedia.org/wiki/Structural_type_system), rather than nominative subtyping - types are equivalent if they have the same structure, not the same name, so this is perfectly ok:
```
interface BoardPosition {
    x: number;
    y: number;
}
interface Point {
    x: number;
    y: number;
}

function f(bp: BoardPosition): void

let p: Point = {
    x: 0, 
    y: 0
};
f(p) // not a BoardPosition
```
because `BoardPosition` and `Point` have the same structure.

## Enums
Enums are specific sets of named constants, with either string or number-based keys:
```
enum Place {
    Character = "c",
    Wall = "x",
    Empty = " ",
    End = "e"
}
let p: Place = Place.Character;
```

## Generics
Like in the queue example above, Typescript has generics:
```
class Queue<T> {
    private queue: T[];

    ...

    public enqueue(item: T): void {
        this.queue.push(item);
    }
}
```
the queue has a list of some thing in it; we don't know what it is, just that's all the same type, and we can only push that type of thing on to the queue.
We declare the specific type of thing that's in the queue when we instantiate one:
```
let startPoint = {x: 0, y: 1};
let queue = new Queue<BoardPosition>();
queue.enqueue(startPoint);
```

## Type aliases
[Type aliases](https://www.typescriptlang.org/docs/handbook/advanced-types.html#type-aliases) let you give a different name to a type (you can alias primitives, unions, tuples, etc.).
They're normally used for documentation purposes, or to give you a shorter name to use rather than having to type out the whole thing:
```
enum Place {
    Character = "c",
    Wall = "x",
    Empty = " ",
    End = "e"
}
type BoardType = Place[][];
```

## Unions
If you need a parameter to be one specific type from a multiple options, you use unions:
```
function f(x: string | number) {
    if (typeof x === "string") {
        // do something with x as a string
    }
    if (typeof x === "number") {
        // do something with x as a string
    }
}
```
since Typescript knows `x` could be either a string or a number, you need to use a [type guard](https://www.typescriptlang.org/docs/handbook/advanced-types.html#type-guards-and-differentiating-types) so it knows what type the actually passed-in argument is.

There are also things called discriminated unions, also known as tagged unions or algebraic data types (ADTs), which have 3 parts to them

1. Types that have a common, singleton type property — the discriminant.
2. A type alias that takes the union of those types — the union.
3. Type guards on the common property.


```
interface Square {
    kind: "square"; // discriminant
    size: number;
}
interface Rectangle {
    kind: "rectangle";
    width: number;
    height: number;
}
interface Circle {
    kind: "circle";
    radius: number;
}

type Shape = Square | Rectangle | Circle; // type alias

function area(s: Shape) {
    switch (s.kind) { // type guard
        case "square": return s.size * s.size;
        case "rectangle": return s.height * s.width;
        case "circle": return Math.PI * s.radius ** 2;
    }
}
```

## Optional types
A variable/property can be typed to be optional:
```
let x: number? = 4;
x = undefined;
```
here, `x` is actually `number | undefined`.

This is useful when getting an element from the DOM:
```
let element: ?HTMLElement = document.getElementByID("elementId");
```

If you're sure the variable is actually defined, put a `!` on the end, and Typescript will treat it like the concrete one:
```
let firstPosition: Position = queue.dequeue()!; // dequeue: ?T
```

It can be used in functions and interfaces too, but the `?` is beside the argument/property name here, not the type:
```
function f(x: number, y?: number) {
    return x + (y || 0);
}
interface C {
    a: number,
    b?: number,
}
```

## Index signatures
If you want to type the keys of an object, you do it with index signatures, which describe how to index into the object:
```
let listeners: { 
    [key: string]: number
} = {
    default: 1
};
```
<sub>[source](https://www.typescriptlang.org/docs/handbook/advanced-types.html#index-types-and-index-signatures)</sub>

## Exporting
You can export typings from a file:
```
enum Direction {
    Up = "Up",
    Down = "Down",
    Left = "Left",
    Right = "Right"
}
export { Direction };
```

# Type inference
See [type inference](/type_inference.html) for more.

# Declarations
You can type JS files with `.d.ts` files, so you can add types to a JS library you've pulled off NPM that isn't typed yet:
```
// arithmetics.d.ts for a file arithmetics.js
declare namespace arithmetics {
    add(left: number, right: number): number;
    subtract(left: number, right: number): number;
    multiply(left: number, right: number): number;
    divide(left: number, right: number): number;
}
```
They're a bit like C `.h` headers.