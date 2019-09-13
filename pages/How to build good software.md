tags: [technology/computer/programming]
> Software has characteristics that make it hard to build with traditional management techniques; effective development requires a different, more exploratory and iterative approach.

You can't just throw money at software to make it better; giant airlnes have flight search apps that are worse than ones students make, taxi companies have terrible booking apps, big corporate IT systems normally have gigantic budgets and take years to build.

The root cause of bad software is more project management than a lack of funding:
* The project owners start out wanting to build a specific solution and never explicitly identify the problem they are trying to solve. 
* Then they gather a long list of requirements from a large group of stakeholders. 
* This list is then handed off to a correspondingly large external development team, who get to work building this highly customised piece of software from scratch. 
* Once all the requirements are met, everyone celebrates as the system is launched and the project is declared complete.

Though, even it technically meets the requirements, users find big issues: it's slow, hard to use, and frustrating, with subtle bugs. The external dev team have left by now. and can't fix it. By the time a new team starts, all the implicit knowledge gained building it has gone with the developers, and the cycle starts again.

Different projects have different languages, architectures and interface design - they aren't too important. What's more important is
* Reusing good software - it lets you build good things quickly
* Software is limited by how complicated it gets before it breaks down (see [a codebase is an organism](https://meltingasphalt.com/a-codebase-is-an-organism/))
* The main value in software is the knowledge gained by the people who make it (not just developers) - not the code they make

This leads to some core principles:
1. Start as simple as possible
2. Seek out problems and iterate
3. Hire the best engineers you can

# Software is limited by complexity
IT systems often have loads of features, but users hate them for being confusing. In contrast, well-liked mobile apps are praised for their simplicity and intuitiveness. Learning to use software is hard.
Beyond a point, new features make things worse for users because the complexity becomes overwhelming - iTunes was split into apps for music, podcasts and TV shows, because it was too complicated for one app - the limit isn't how many features can be implemented, but what can fit into a simple interface.

Even ignoring usability, engineering slows to a halt when a project becomes too complex. Each new line of code added to an application has a chance of interacting with every other line. The bigger an application’s codebase, the more bugs are introduced whenever a new feature is built. Eventually, the rate of work created from new bugs cancels out the rate of work done from feature development. This is the reason why many large IT systems have issues that go unfixed for years. Adding more engineers to the project just adds to the chaos: they start running faster in place as the codebase keels over from its own weight.

Then, the only way forward is to rationalise and simplify the codebase. The architecture can be redesigned to limit unexpected interactions. Non-critical features can be removed, even if they have already been built. Automated tools can be deployed to check for bugs and badly written code. Human minds can only handle a finite amount of complexity, so how sophisticated a software system can get depends on how efficiently this complexity budget is used.

> Measuring programming progress by lines of code is like measuring aircraft building progress by weight

Building good software involves alternating cycles of expanding and reducing complexity. As new features are developed, disorder naturally accumulates in the system. When this messiness starts to cause problems, progress is suspended to spend time cleaning up. This two-step process is necessary because there is no such thing as platonically good engineering: it depends on your needs and the practical problems you encounter. Even a simple user interface such as Google’s search bar contains a massive amount of complexity under the surface that cannot be perfected in a single iteration. The challenge is managing this cycle, letting it get messy enough to make meaningful progress, but not letting it get so complicated that it becomes overwhelming.

# Software is more about developing knowledge than writing code
Most ideas are bad; thats no-one’s fault. It's just that the number of possible ideas is so large that any particular idea is probably not going to work, even if it was chosen very carefully and intelligently. To make progress, you need to start with a bunch of bad ideas, discard the worst, and evolve the most promising ones. Apple goes through dozens of prototypes before landing on a final product. The final product may be deceptively simple; it is the intricate knowledge of why this particular solution was chosen over its alternatives that allows it to be good.

This knowledge continues to be important even after the product is built. If a new team takes over the code for an unfamiliar piece of software, the software will soon start to degrade. Operating systems update, business requirements change, and security problems are discovered that need to be fixed. Handling these subtle errors is often harder than building the software in the first place, since it requires intimate knowledge of the system’s architecture and design principles - you don't want to knock over [Chesterton's fence](https://en.wikipedia.org/wiki/Wikipedia:Chesterton%27s_fence).

In the short term, an unfamiliar development team can address these problems with stopgap fixes. Over time though, new bugs accumulate due to the makeshift nature of the additional code. User interfaces become confusing due to mismatched design paradigms, and system complexity increases as a whole. Software should be treated not as a static product, but as a living manifestation of the development team’s collective understanding.

Even if a system is very well documented, some knowledge is lost every time a new team takes over. Over the years, the system becomes a patchwork of code from many different authors. It becomes harder and harder to keep running; eventually, there is no one left who truly understands how it works.

# Reusing software lets you build good things quickly
Modern software is almost never developed from scratch. Even the most innovative applications are built using existing software that has been combined and modified to achieve a new result - you don't need to write everything yourself (that's "Not Invented Here" syndrome) - but [this isn't always true](https://www.joelonsoftware.com/2001/10/14/in-defense-of-not-invented-here-syndrome/), it's not a hard rule.
Using open source code doesnt just make your development faster, it lets you use technology that is far more sophisticated than anything you could've made yourself. It lets you stop wasting time on solved problems and instead focus on delivering actual value with business-specific code.

You cannot make technological progress if all your time is spent on rebuilding existing technology. Software engineering is about building automated systems, and one of the first things that gets automated away is routine software engineering work. The point is to understand what the right systems to reuse are, how to customise them to fit your unique requirements, and fixing novel problems discovered along the way.

# 3 principles

## Start as simple as possible
What better way to ensure your app solves people’s problems than by having it address as many as possible? After all, this works for physical stores such as supermarkets. The difference is that while it is relatively easy to add a new item for sale once a physical store is set up, an app with twice as many features is more than twice as hard to build and much harder to use.

Building good software requires focus: starting with the simplest solution that could solve the problem. A well-made but simplistic app never has problems adding necessary features. But a big IT system that does a lot of things poorly is usually impossible to simplify and fix. Software projects rarely fail because they are too small; they fail because they get too big.

Unfortunately, keeping a project focused is very hard in practice - one way to manage this bloat is by using a priority list. Requirements are all still gathered, but each are tagged according to whether they are absolutely critical features, high-value additions, or nice-to-haves (like the [MOSCOW method](https://en.wikipedia.org/wiki/MoSCoW_method)). This approach also makes explicit the trade-offs of having more features - stakeholders who want to increase the priority for a feature have to also consider what features they are willing to deprioritise. Teams can start on the most critical objectives, working their way down the list as time and resources allow.

## Seek out problems and iterate
In truth, modern software is so complicated and changes so rapidly that no amount of planning will eliminate all shortcomings. Like writing a good paper, awkward early drafts are necessary to get a feel of what the final paper should be. To build good software, you need to first build bad software, then actively seek out problems to improve on your solution.

This starts with something as simple as talking to the actual people you are trying to help. The goal is to understand the root problem you want to solve and avoid jumping to a solution based just on preconceived ideas of what you need to do.

Having a clear problem statement lets you experimentally test the viability of different solutions that are too hard to determine theoretically. Talking to a chatbot may not be any easier than navigating a website, and users may not want to install yet another app on their phones no matter how secure it is. With software, apparently obvious solutions often have fatal flaws that don't show up until they're used. 
The aim isn't yet to build the final product, but to first identify these problems as quickly and as cheaply as possible:
* Non-functional mock-ups to test interface designs
* Semi-functional mock-ups to try different features
* Prototype code, written hastily, could help garner feedback more quickly. 
Anything created at this stage should be treated as disposable. The desired output of this process isn't the code written, but a clearer understanding of what the right thing to build is.

With a good understanding of the right solution, you can start work on building the actual product. You stop exploring new ideas and narrow down to identifying problems with your particular implementation. Begin with a small number of testers who will quickly spot the obvious bugs that need to be fixed. As problems are addressed, you can increasingly open up to a larger pool who will find more esoteric issues.

Most people only give feedback once. If you start by launching to a large audience, everyone will give you the same obvious feedback and you’ll have nowhere to go from there. Even the best product ideas built by the best engineers will start out with significant issues. The aim is to repeatedly refine the output, sanding down rough edges until a good product emerges.

Overall, the approach is to use these different feedback loops to efficiently identify problems. Small feedback loops allow for quick and easy correction but miss out on broader issues. Large feedback loops catch broader issues but are slow and expensive. You want to use both, resolving as much as possible with tight loops while still having wide loops to catch unexpected errors. Building software is not about avoiding failure; it is about strategically failing as fast as possible to get the information you need to build something good.


## Hire the best engineers you can
A good engineer has a better grasp of existing software they can reuse, thus minimising the parts of the system they have to build from scratch. They have a better grasp of engineering tools, automating away most of the routine aspects of their own job. Automation also means freeing up humans to work on solving unexpected errors, which the best engineers are disproportionately better at. Good engineers themselves design systems that are more robust and easier to understand by others. This has a multiplier effect, letting their colleagues build upon their work much more quickly and reliably. Overall, good engineers are so much more effective not because they produce a lot more code, but because the decisions they make save you from work you did not know could be avoided.

Smaller teams of good engineers will also create fewer bugs and security problems than larger teams of average engineers. Similar to writing an essay, the more authors there are, the more coding styles, assumptions, and quirks there are to reconcile in the final composite product, exposing a greater surface area for potential issues to arise. In contrast, a system built by a smaller team of good engineers will be more concise, coherent, and better understood by its creators. You cannot have security without simplicity, and simplicity is rarely the result of large-scale collaborations.

# Conclusion
* Good software development starts with building a clear understanding of the problem you want to solve. This lets you test many possible solutions and converge on a good approach. 
* Development is accelerated by reusing the right open source code and cloud services, granting immediate access to established software systems and sophisticated new technology. 
* The development cycle alternates between exploration and consolidation, quickly and messily progressing on new ideas, then focusing and simplifying to keep the complexity manageable.
* As the project moves forward, it gets tested with successively larger groups of people to eliminate increasingly uncommon problems. Launching is when the real work ramps up for a good development team: layers of automated systems should be built to handle issues quickly and prevent harm to actual users. 

Ultimately, while there are infinite intricacies to software development, understanding this process provides a basis to tackle the complexities of how to build good software.

[source](https://www.csc.gov.sg/articles/how-to-build-good-software)
