Webpack is a module bundler for JS apps - it bundles together all the different modules your JS files need, into 1 bundle

It does this by 
1. looking at an [entry point](#entry_points) JS file 
2. figuring out what other files and modules that file requires - both directly and indirectly - with a [dependency graph](https://webpack.js.org/concepts/dependency-graph/)
3. it runs those other files through different [loaders](#loaders) to process them - on it's own Webpack, can only understand JS and JSON files, so people have made different loaders for CSS files, HTML, [Typescript](/typescript.html), Vue, etc.
4. optionally, [plugins](#plugins) also process those files, e.g. by optimising a bundle, asset management, or adding environment variables
5. after building a dependency graph from an entry point, loading any files it needs, and running them through plugins, Webpack will [output](#output) a bundle it creates for each entry point to somewhere on your filesystem

# Configuration

Webpack, by default, is configured with a normal JS file called `webpack.config.js`; a simple version looks like this:

```
const path = require('path');

module.exports = {
    entry: './src/index.js',
    module: {
        rules: [
            ... // loaders
        ]
    },
    plugins: [
        ...
    ],
    output: {
        filename: 'main.js',
        path: path.resolve(__dirname, 'dist'),
  },
};
```

# Bundles
A bundle is the final version of a soruce file, and will normally contain many other files bundled with an [entry point](#entry_points).
Bundles are made up of (normally 1) [chunks](#chunks) - they're chunks that have been emitted to the filesystem. 

## Chunks
What [bundles](#bundles) are made out of - they're a group of modules inside the webpack bundling process.

# Mode
[mode](https://webpack.js.org/configuration/mode/) tells Webpack which built-in [optimizations](#optimization) to run
```
mode: 'none' | 'development' | 'production'
```

# Entry points
For each entry point JS, [Typescript](/typescript.html), Elm, etc file specified in the `entry` key in the [config file](#configuration), Webpack will walk over it, and find every file it needs, building a dependency graph.
`entry` can be a string, pointing to 1 specific file, an array of strings, an object, mapping a [chunk](#chunk) name to the entry point location.

```
entry: "./src/index.js",

// or

entry: {
    home: './home.js',
    about: './about.js',
    contact: './contact.js'
}
```

# Loaders
Webpack can only understand JS and JSON files; loaders allow it to process CSS files, HTML, [Typescript](/typescript.html), Vue, etc.
They can also transform the input files in some way, like transpile [Typescript](/typescript.html), or import CSS from JS files.

They're defined inside `module.rules`, and are objects with 2 (main) properties - there are others, like `options` and `include` or `exclude`:
1. `test`, to say which files should be transformed, as a regex
2. `use` says which loader should be used

Importantly, **the last loader is ran first, end to start, like function composition;** below, `ts-loader` runs _before_ `css-loader`:
```
module: {
    rules: [
        { test: /\.css$/, use: 'css-loader' },
        { test: /\.ts$/, use: 'ts-loader' }
    ]
  }
```

See [options](https://webpack.js.org/configuration/module/#useentry) and [include/exclude](https://webpack.js.org/configuration/module/#condition).

# Plugins
Plugins do anything [loaders](#loaders) can't, like adding environment variables.

They're specified in the `plugins` array of the [config file](#configuration) - they can take arguments, so you need to make a `new` instance of each plugin.
```
plugins: [
    new webpack.ProgressPlugin(),
    new HtmlWebpackPlugin({template: './src/index.html'})
]
```

# Output
`output` tells Webpack where to output the bundles. 
You only ever specify 1 output property, even if you have multiple [entry points](#entry_points).

* `output.filename` is the filename, it can either be static, or dynamic, and use the entry point name, chunk ID, or hash: `[name].[id].[hash].js`
* `output.path` is the _absolute_ output path: `path.resolve(__dirname, 'dist/assets')`
* `output.publicPath` is the public URL of the output folder, when used in a browser. It's used when loading stuff on-demand, or external resources like files or images. It's prefixed to every URL created by the runtime or loaders, so **it should end in** `/`. Simply, it's the URL of `output.path` from the HTML.

```
output: {
    path: path.resolve(__dirname, "resources/"),
    publicPath: "/",
    filename: "[name].js"
},
```

## Other config options

### Resolve
[resolve](https://webpack.js.org/configuration/resolve/) configures how modules are resolved. 
It's useful if you want to register an `alias` like `@` to be `resources/assets/`, so you don't need to always use relative imports.

`extensions` specifies what order file extensions will be resolved in.

```
resolve: {
    alias: {
        "vue$": "vue/dist/vue.esm.js",
        "@": path.resolve(__dirname, "resources/assets"),
    },
    extensions: ["*", ".js", ".vue", ".json"]
},
```

### Optimization
[optimization](https://webpack.js.org/configuration/optimization/) tells Webpack what optimizations to run, overriding those Webpack chooses for your [mode](#mode).

`splitChunks` lets you split out the chunks from specific places on your filesystem, into their own bundles; this is useful to move everything from `node_modules` into its own [output](#output) bundle, so that you can update your dependencies without forcing your users to redownload every bundle in your application:

```
optimization: {
    splitChunks: {
        cacheGroups: {
            vendor: {
                test: /[\\/]node_modules[\\/]/,
                name: "js/vendors",
                chunks: "all",
                minChunks: 1
            }
        }
    }
},
```

### Devtool
[devtool](https://webpack.js.org/configuration/devtool/) controls what sourcemaps are generated. See the options behind that link