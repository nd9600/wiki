
[Gulp](https://gulpjs.com/) is a build system - it's a system that helps you automate tasks that you need to do to build your app.

# Installation
```
npm install --global gulp-cli # installs the CLI tool
npm install --save-dev gulp # installs Gulp itself
``` 

# gulpfile.js
Gulp, like [Webpack](/webpack.html), uses a config file; Gulp's is always called `gulpfile.js`.

It's made up of a series of __tasks__: each [task](#task) does something different to build a bit of your app' this is the simplest possible task:
```
function defaultTask(cb) {
  // place code for your default task here
  cb();
}

exports.default = defaultTask
```

The `gulpfile` is ran with `gulp [task1] [task2]`, `gulp` will run the default task.

You can split up the tasks into different files, by making a `gulpfile.js` directory, moving your previous JS file into that & renaming it `index.js`, and importing your different tasks.

# Tasks
Each task in a [Gulpfile](#gulpfilejs) uses some of the Gulp [APIs](https://gulpjs.com/docs/en/api/concepts) like [src()](https://gulpjs.com/docs/en/api/src) or [dest()](https://gulpjs.com/docs/en/api/dest) to do something, like bundle many CSS files together, use [Webpack](/webpack.html) to bundle and transpile some JS, or version different files. 

`gulp --tasks` will list all of your tasks.

Each task is _asynchronous_ - they **don't** run synchronously, this is quite important: if you think they run synchronously, you'd expect `gulp taskA taskB taskC` to run `taskA`, then `taskB`, then `taskC`, but that doesn't happen. Make sure that if you need your tasks to run in a particular order, for example by merging their outputs into a manifest file, that you [make them run synchronously](#running_tasks_synchronously).

Each task is an asynchronous function - the first parameter is an error-first callback, a [common Node pattern](https://nodejs.org/api/errors.html#errors_error_first_callbacks) where the callback is called with the error as the first parameter, if any, or `null` if there isn't an error.
In the simple Gulpfile example above, `cb` is the callback function:
```
function defaultTask(cb) {
  // place code for your default task here
  cb();
}
```

## Signaling task completion

The task can return nothing, a [Node stream](https://nodejs.org/api/stream.html#stream_stream), [promise](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Using_promises), [event emitter](https://nodejs.org/api/events.html#events_events), [child process](https://nodejs.org/api/child_process.html#child_process_child_process), or an [observable](https://github.com/tc39/proposal-observable/blob/master/README.md).
 
All of the above options are different ways Node libraries handle asynchronous functions; Gulp tasks can use any of them.

When a task finishes, [Gulp needs to know if it should stop or continue](https://gulpjs.com/docs/en/getting-started/async-completion) - if your task returns something and an error is thrown, Gulp will stop straight away and show the error; otherwise it'll continue.

If your task _doesn't_ return something, you need to specifically tell Gulp the task's finished, by calling the callback function, with a `new Error()`, or nothing (if it was successful).

If you get a warning like
> "Did you forget to signal async completion?"

you need to do one of the above things - returning a stream, calling the callback, etc.

## Running tasks synchronously

Use [series()](#composition)

## Privacy
Tasks can either be public or private
* public tasks are `exported`, and can be ran by `Gulp` (the old method was calling `gulp.task`)
* private tasks aren't exported, and can only be used by other tasks, normally as part of a `series()` or `parallel()` [composition](#composition)

## Composition

If you want to compose tasks together, you can use `series()` to run them one-after-another, or `parallel()` to run them concurrently:

```
const { series } = require('gulp');
function transpile(cb) {
  // body omitted
  cb();
}

function bundle(cb) {
  // body omitted
  cb();
}

exports.buildJS = series(transpile, bundle);
```

 

```
const { parallel } = require('gulp');
function javascript(cb) {
  // body omitted
  cb();
}

function css(cb) {
  // body omitted
  cb();
}

exports.buildAll = parallel(javascript, css);
```

You can nest them as much as you want:
```
exports.build = series(
    clean,
    parallel(
        cssTranspile,
        series(jsTranspile, jsBundle)
    ),
    parallel(cssMinify, jsMinify),
    publish
);
```

The Gulp [docs](https://gulpjs.com/docs/en/getting-started/creating-tasks#compose-tasks) says this:
> When a composed operation is run, each task will be executed every time it was referenced. For example, a clean task referenced before two different tasks would be run twice and lead to undesired results. Instead, refactor the clean task to be specified in the final composition.

and to change this
```
const css = series(clean, ...);
const javascript = series(clean, ...);
exports.build = parallel(css, javascript);
```
to this
```
const css = series(...);
const javascript = series(...);
exports.build = series(clean, parallel(css, javascript));
```

# Using files

Gulp's main [API](https://gulpjs.com/docs/en/api/concepts) are the [src()](https://gulpjs.com/docs/en/api/src), [dest()](https://gulpjs.com/docs/en/api/dest) and `pipe()`, called like `gulp.src()` or `src()`, depending on how you import it.

```
const { src, dest } = require('gulp');
const babel = require('gulp-babel');

exports.default = function() {
  return src('src/*.js')
    .pipe(babel())
    .pipe(dest('output/'));
}

```

You can [call src() or dest()](https://gulpjs.com/docs/en/getting-started/working-with-files#adding-files-to-the-stream) in the middle of a pipeline to add files halfway through (e.g. to transpile some [typescript](/typescript.html), then uglifying it and normal JS), or to write intermediate states to the filesystem (e.g. to create unminified and minified files with the same pipeline).

## src()
```
src(globs, [options])
```

`src()` is given a [glob](#globs) to read from the file system, and makes a [Node stream](https://nodejs.org/api/stream.html#stream_stream) that produces [Vinyl](#vinyl) objects. It finds all the files that match the glob, and reads them into memory to pass through the stream, one file at a time.

> A stream is an abstract interface for working with streaming data in Node.js

The stream that `src()` makes should be returned, to [signal task completion](#signaling_task_completion).

It has [3 modes](https://gulpjs.com/docs/en/getting-started/working-with-files#modes-streaming-buffered-and-empty):
* buffered, the default, where files are read into memory (many plugins only support it)
* streaming, where files are streamed from the filesystem in small chunks
* empty, where files have no contents - it's only useful when working with file metadata

Each file is represented by a [Vinyl](#vinyl) instance.

It has useful [options](https://gulpjs.com/docs/en/api/src#options), like `base`, which explicitly sets the [glob base](#glob_base) on the [Vinyl](#vinyl) objects that are created.


## pipe()

`pipe()` is generally where plugins will transform the files in the stream - each call to `pipe()` is given one file in the stream.

It's used to chain different Transform or Writable streams together:
* a [Transform](https://nodejs.org/api/stream.html#stream_class_stream_transform) stream is one where the output is related to the input somehow - they implement both [Readable](https://nodejs.org/api/stream.html#stream_readable_streams) and Writable - like the [crypto streams](https://nodejs.org/api/crypto.html#crypto_class_cipher)
* a [Writable](https://nodejs.org/api/stream.html#stream_writable_streams) stream is an abstraction for a destination to which data is written, such as `fs` write streams or TCP sockets

## dest()
```
dest(folder, [options])
```

You give `dest()` an output directory string, and it makes a [Node stream](https://nodejs.org/api/stream.html#stream_stream) that consumes [Vinyl](#vinyl) objects. It's normally used to signal task completion.
When it gets a file through the stream (as a Vinyl, passed through `pipe()s`), it writes the file out to the filesystem at that directory.

You could also use [symlink()](https://gulpjs.com/docs/en/api/symlink), which makes links rather than files.

# Globs
[src()](#src\(\)) takes in either 1 string glob, or an array of globs to find files for your pipeline to work on - if it's given an array, it goes through them from the start to the end; this is useful for [negative globs](#exclamation_marks).

A glob is a string of characters used to match filepaths, that can include wildcards, like in Unix paths.

The _path separator_ is always `/`, even on Windows.

A _segment_ is everything between path separators.

Don't use Node's path methods, like path.join, to create globs - on Windows, it makes an invalid glob because Node uses `\\` as the path separator.
Avoid `__dirname`, `__filename`, or `process.cwd()` for the same reason.

## Single asterisks
`*` matches any series of characters _within a single segment_, so inside 1 directory.

## Double asterisks
`**` matches any series of characters _within multiple segments_, so inside nested directories, not just 1 directory:
`./resources/assets/js/**/*.js` matches any JS files inside the `js` folder, no matter how deeply nested they are.

## Exclamation marks
`!` removes any files that otherwise would've been included in the stream (so it must come after a non-negative glob).
Here, any files in the `designSystem` directory aren't included in the stream:
```
gulp.src([
    "./resources/assets/css/**/*.css",
    "!./resources/assets/css/designSystem/**/*",
], {base: "./resources/assets"})
```

## Glob base
The glob base is the bit of the glob before any special characters: in `/src/js/**.js`, it's `/src/js/`.
Each [Vinyl](#vinyl) instance that [src()](#src\(\)) makes has the glob base set as their base property. 

The base must be the same for all globs used by `src()` - if they're different, you need to set it explicitly.

When the Vinyl is written to the file system with [dest()](#dest\(\)), the base gets removed from the output path to preserve directory structures.

If you want to change what the glob base is, use the `base` [option](https://gulpjs.com/docs/en/api/src#options) in `src()`:

```
gulp.src([
    "./resources/assets/css/**/*.css",
    "!./resources/assets/css/designSystem/**/*",
], {base: "./resources/assets"})
```

I needed to set the base here explicitly, because the two globs have different bases otherwise.

You also might want to change the base to put the output files in a different directory:
```
gulp.src(
    "./resources/assets/images/**/*", 
    {base: "./resources/assets"}
)
```
Here, this avoids putting the images directly into wherever `gulp.dest()` specifies (which will use the same, single, path, in a versioning task), instead putting them inside the `images` folder inside where `gulp.dest()` specifies.

# Vinyl
A Vinyl is a metadata object that describes a file - the main properties are `path` and `contents` - core aspects of a file on your file system. 

Vinyl objects can describe local or remote files.

# Plugins
Gulp plugins are [Node Transform Streams](https://github.com/rvagg/through2) that transform files in a pipeline.
 They can change the filename, metadata, or contents of every file that passes through the stream.