[Gulp](https://gulpjs.com/) is a build system - it's a system that helps you automate tasks that you need to do to build your system.

# Installation
```
npm install --global gulp-cli # installs the CLI tool
npm install --save-dev gulp # installs Gulp itself
``` 

# How to use it

## gulpfile.js
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

## Tasks
Each task in a [Gulpfile](#gulpfilejs) uses some of the Gulp [APIs](https://gulpjs.com/docs/en/api/concepts) like [src()](https://gulpjs.com/docs/en/api/src) or [dest()](https://gulpjs.com/docs/en/api/dest) to do something, like bundle many CSS files together, use [Webpack](/webpack.html) to bundle and transpile some JS, or version different files. 

Each task is __asynchronous__ - they **don't** run synchronously, this is quite important: if you think they run synchronously, you'd expect `gulp taskA taskB taskC` to run `taskA`, then `taskB`, then `taskC`, but that doesn't happen. Make sure that if you need your tasks to run in a particular order, for example by merging their outputs into a manifest file, that you [make them run synchronously](#running_tasks_synchronously).

Each task is an asynchronous function - the first parameter is an error-first callback, a [common Node pattern](https://nodejs.org/api/errors.html#errors_error_first_callbacks) where the callback is called with the error as the first parameter, if any, or `null` if there isn't an error.
In the simple Gulpfile example above, `cb` is the callback function:
```
function defaultTask(cb) {
  // place code for your default task here
  cb();
}
```

### Signaling task completion

The task can return nothing, a [Node stream](https://nodejs.org/api/stream.html#stream_stream), [promise](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Using_promises), [event emitter](https://nodejs.org/api/events.html#events_events), [child process](https://nodejs.org/api/child_process.html#child_process_child_process), or an [observable](https://github.com/tc39/proposal-observable/blob/master/README.md).
 
All of the above options are different ways Node libraries handle asynchronous functions; Gulp tasks can use any of them.

When a task finishes, [Gulp needs to know if it should stop or continue](https://gulpjs.com/docs/en/getting-started/async-completion) - if your task returns something and an error is thrown, Gulp will stop straight away and show the error; otherwise it'll continue.

If your task __doesn't__ return something, you need to specifically tell Gulp the task's finished, by calling the callback function, with a `new Error()`, or nothing (if it was successful).

If you get a warning like
> "Did you forget to signal async completion?"

you need to do one of the above things - returning a stream, calling the callback, etc.

## Running tasks synchronously