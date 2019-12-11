
[Github](https://github.com/nd9600/spiderweb)

# The problem

Twitter lays out their tweets in a linear thread, but the tweets aren't actually in a linear thread, they're more like a [tree](https://en.wikipedia.org/wiki/Tree_\(data_structure\)) (or a web) - blogs do the same sort of thing, with comments.

On the left here is how tweets are actually structured, on the right how Twitter displays them:
![tree structure vs thread](static/images/spiderweb/twitterNetworkDiagram.png)

# A solution?

Spiderweb displays them in a form that's more like how they're structured:
![Spiderweb's tree-ish structure](static/images/spiderweb/spiderwebNetworkDiagram.png)

The problem here is that you can show as many branches off of a single tweet at a time, but how do you show branches off 1 tweet, and then __more__ branches off of tweets underneath it? They'll probably overlap, and laying them out would be a bit of a nightmare.

## The idea

### A tree of posts
I think this was originally sparked by [this tweet by Marcin Ignac](https://twitter.com/marcinignac/status/1184400358405234688) showing this web of tweets (higher-res [here](https://www.figma.com/file/riPXW9Lqpyuxo5K88EtUgG/MAR-19008-Thread-Viz?node-id=0%3A1)):
![Figma tweet web](static/images/spiderweb/figmaTweetWeb.jpg)

Basically, it's:
* a collection of posts, but rather than being laid out in a linear list, in a tree, so you can see the connections between posts more easily
* being able to see all(ish) the branches at once
* and, rather than only be able to link many child posts to 1 parent by replying to the parent, you can link many children to many parents, maybe by clicking "add parent/child" on each one

### Socially
Generally, the theme is "reduce iffy behaviours like pile-ons, while still allowing people to be social" - avoiding the creation of behaviour that seems to happen on the Internet, but not as much IRL, maybe by copying how IRL conversations work/things from physical conversations that we don't always include on the web (see Brian Earp's quote below)?

Riffing off of [vTaiwan](https://www.technologyreview.com/s/611816/the-simple-but-ingenious-system-taiwan-uses-to-crowdsource-its-laws/) - they found that not letting people reply to eachother's posts meant everyone was able to come to a consensus - I also want to let you control who can reply to you, __separate__ from who can see your posts - remembering [Visakan's](https://twitter.com/visakanv) thread about how people with few followers like replies, and people with loads don't.

You're social with some people, but not every single person in the whole world, but also not necessarily completely private, unless you want to be.

Copying in [Brian Earp's thread about Twitter](https://twitter.com/briandavidearp/status/1090350858989195265), too:
> I have a hypothesis about what might contribute to \*moral outrage\* being such a big thing on social media. Imagine I’m sitting in a room of 30 people & I make a dramatic statement about how outraged I am about X. And say 5 people cheer in response (analogous to liking or RT). 
> 
> But suppose the other 25 ppl kind of stare at the table, or give me a weird look or roll their eyes, or in some other way (relatively) passively express that they think I’m kind of over-doing it or maybe not being as nuanced or charitable or whatever as I should be. 
> 
> IRL we get this kind of ‘passive negative’ feedback when we act morally outraged about certain things, at least sometimes. Now, a few people in the room might clear their throat and actively say, “Hey, maybe it’s more complicated than that” and on Twitter there is a mechanism for that: comments
> 
> But it’s pretty costly to leave a comment pushing back against someone’s seemingly excessive or inadequately grounded moral outrage, and so most ppl probably just read the tweet and silently move on w their day. And there is no icon on Twitter that registers passive disapproval.
> 
> So it seems like we’re missing one of the major IRL pieces of social information that perhaps our outrage needs to be in some way tempered, or not everyone is on board, or maybe we should consider a different perspective. 
> 
> If Twitter collected data of people who read or clicked on a tweet, but did NOT like it or retweet it (nor go so far as write a contrary comment), and converted this into an emoji of a neutral (or some kind of mildly disapproving?) face, this might majorly tamp down on viral moral outrage that is fueled by likes and retweet’s from a small subset of the ‘people in the room’

## Features

### Posts
You can make many posts, each with a title, a body with a high character limit (\~10000?), and images (just pasted URLs for now).
Posts can live separately, or be connected to other ones, through different methods:

#### Links/connections

Like tweets or comments, you can reply to a post with another post

---

Explicitly linking a post to another, __after__ both have been made; you don't need to know in advance, when making the post, which ones to link to it.

This would be in 2 different directions, a link from post A to post B, or from B to A: in a link from A to B, A is the parent, B the child

##### User-level link graphs
This explicit linking means users could have their own graphs of links between posts (not sure how useful this would be).

---

Mentioning a post inside another post - this opens up the possibility of [transclusion](https://en.wikipedia.org/wiki/Transclusion) later on

---

Like in Twitter, "quote posting", where you reply to another post, but rather than it appearing underneath the parent in the Y direction, it's "above" it in the Z direction.
(writing it like that makes it seem similar to mentioning a post, above)

### Social

##### View and reply control
To limit pile-ons, dogpiling, flaming, trolling, ratio-ing, you __must__ control who can reply to you, __separate__ from who can see your posts:
* you can allow everyone to see your posts, or a specific set of people
* you can __not__ allow everyone to reply to your posts, only specific people - this can be a specific set of people, people you follow, people who follow you, both, some combination of them, ... (tentative, users might just set it to "people who follow you", and then there'd essentially be no limit)

This will probably have unforeseen consequences, though.

#### Free-for-all times

Though, if no one can reply to you unless you specifically allow them to, it'd be quite hard to break in to a a group, since you can't talk to them.
To avoid that, users could choose to allow anyone to reply to them, for a short period of time (1 - 2 hours?) once a day/week, if they want - the time period might be for a user's specific timezone, so "8pm" in GMT for someone in the UK, or it could be the same time period for __all__ users, so 8pm GMT on a Sunday for UK users, 7pm for GMT+1, etc.

### Offline
It'd be relatively easy to do this all offline, and just store an array of Posts, and an array of Post <-> Post Links in [Local storage](https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage) or [IndexedDB](https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API), without any network calls or user accounts - a [PWA](https://developers.google.com/web/progressive-web-apps) is worth [looking in to](https://developers.google.com/web/fundamentals/instant-and-offline/web-storage/offline-for-pwa).

People could import/export their data to JSON files really easily, and could import them from their online account, or export them __to__ it.

# Technically

This will be written with a [Laravel](https://laravel.com/) backend, since I know it best, and a frontend in [Vue](https://vuejs.org/) where necessary, for the same reason.

## Database
* 1 User can have many Posts
* Many Posts can be Linked to many Posts, through a Link table - each link has a type, and parent and child Post IDs


### Branches
I can imagine linking Posts together with a table of `parent <-> child IDs` would mean that whenever you wanted to see a branch of Posts, loading that would be quite slow, since you'd need to join the parent Post ID on the Link table to get its children, then to get the first child's child (the parent's grandchild), join again, then to get the great-grandchild, join __again__.

To avoid this possible slowness, I think it might be good to also store the Branch ID in a Post -> Branch table.
I think you would make the Branches like this:
```
every new reply to a Post always makes a new Branch, unless user A is replying to a Post also by user A, and there are no other replies
```
Though, I have a feeling this won't work when I try it, so I'll live with the possible slowness for now.
Also, I shouldn't prematurely optimize, especially since everything else apart from the Post <-> Post Links would be normally relational.

A [graph database](https://en.wikipedia.org/wiki/Graph_database) might work for Links, something like [Cayley](https://cayley.io/).

# Milestones

## V1
* Users
* Posts
* Showing all the posts for a user - if you're logged in, your posts at `spiderweb.com`, user X's posts at `spiderweb.com/user/x` 

## V2
* Replies