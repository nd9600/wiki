tags: [technology/computer/programming]

# What people mean by "testing"

Generally, there are 2 reasons for testing:
1. Checking that you're doing the right thing
2. Checking that you're doing the thing right

Only the people who've made the requirements (normally the "Product Owner") can know if you've met the first reason.
Depending on who the Product Owner is and how interested they are, this can happen at different points in development - before any code's been written, with wireframes/white-boarding, when the code is on testing, when it's gone live but is hidden, when it's live for everyone..

Basically, people set the requirements, so only people can know if you've met them; we can't write tests on our computers for that. Users must check that you're doing the right thing, manually.

At work, we had a project to let people message their customers, and queue messages up to be sent automatically (inventively called "Messaging").

People can know if you've met the first reason too (both the Product Owners, and other people, if they've been given enough detail on what they need to do, and the background and context, e.g. someone can check if a particular queued message is sent when it should be, if they know about the messaging project, what a queued message is, ...), and, depending on what you're doing, a computer can check if you've met the second reason, subject to time & effort constraints - these are automated tests:
For example,  I wrote a test that made sure we'd be making a booking and a customer, as long as we gave the main system (TMS) the right data. This was only possible, though, because the code I was testing didn't really interact with anything - it didn't try to talk to another system, or get something from a database, or anything like that.

On TMS at work, we can't currently write automated tests for code that gets stuff from our database (we can on the system we made for Messaging), or for code that talks to different systems (this is true for all of our systems). To get round this, we can "mock" hitting a database or talking to a different system, but this causes a few problems.
Mocking things is a slow and repetitive process, and not many people want to do it; it's a lot of "when I call this, I want that to happen", over and over again - depending on how the code you're testing is written, you  can write more code to mock things than code to actually test something. It can seem like you're wasting a lot of effort, running to stand still. Testing with mocks is a lot more effort than testing without them, and if you make something harder to do, people will do it less. I think this is a big part of the reason why there aren't as many tests on TMS; they're too hard to write.

---

Also, when you mock something, you're not truly testing the real code that you'll actually be running, by design. This is particularly a problem when the feature you want to test relies on something like a database query or an API call, making the _correct_ query or call is important:
For example, with the Messaging project, we've had lots of issues with the page that shows the queued messages that are going to be sent out in the near future; this is because we need two different systems in interact in a particular way for the page to work properly, and we can't write tests for that. The correctness of a particular function can depend on if the right database query or API call is made, in the right way, and we can't always test that.

![a flow through an API request](static/images/testing_apiFlow.png)

We wanted to test that if we called `api/property/{propertyId}/queued-messages` at the top there, we'd get the right `queued_messages[]` at the bottom. Every line from one thing to another is an interaction between different systems. We could make the API call at the top fine, because that was to the Messaging system. It could query the database on the right, but then, it would need to call TMS, and TMS would need to query its own database. Neither of those things could happen - when our Messaging tests are running, TMS doesn't exist (we could create it, but that would take a fair bit of effort and slow down the tests a lot), and even if it did, it wouldn't be able to query its database; no database exists when TMS runs in tests.

That mismatch between what code runs in tests and in reality means our tests can't actually always "check that you're doing the thing right" - that must be done manually, by users.

You can't treat "Checking that you're doing the right thing" and "Checking that you're doing the thing right" independently, either - both can interact with eachother - changing what you do to fix doing something right can mean you're now doing the wrong thing, and vice-versa.

So, automated tests aren't enough, we need user tests.
Traditionally, with game development at least, they have 2 different phases of manual user testing: alpha and beta testing.
With alpha testing, this is where they make all the functionality - "Checking that you're doing the right thing" - then, once they have the functions nailed down, they go into a code freeze - they don't add any new code - then start beta testing - they only fix bugs present in the system, they don't add new features - "Checking that you're doing the thing right".

We do both of these at the same time, with different people doing different bits at the same time, with things being changed or fixed in one place possibly affecting things in a different place.