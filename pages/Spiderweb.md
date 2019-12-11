
[Github](https://github.com/nd9600/spiderweb)

# The problem

Twitter lays out their tweets in a linear thread, but the tweets aren't actually in a linear thread, they're more like a [tree](https://en.wikipedia.org/wiki/Tree_\(data_structure\)) (or a web) - blogs do the same sort of thing, with comments.

On the left here is how tweets are actually structured, on the right how Twitter displays them:
![tree structure vs thread](static/images/spiderweb/twitterNetworkDiagram.png)

# A solution?

Spiderweb displays them in a form that's more like how they're structured:
![Spiderweb's tree-ish structure](static/images/spiderweb/spiderwebNetworkDiagram.png)