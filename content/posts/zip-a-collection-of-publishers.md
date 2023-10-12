+++
title = "Zip a Collection of Publishers"
description = "I wrote a publisher that takes an array of publishers and produces a single publisher of the array of their outputs."
date = 2019-09-29
tags = ["combine", "swift"]
draft = false
meta = true
math = false
+++

I have an array of publishers: `[Publisher<Data, Error>]` and want a publisher of the array of their outputs: `Publisher<[Data], Error>`. The Combine framework provides the `Zip` family of publishers which only go up to 4 inputs so this won't suit my needs. I'm going to write about the steps I took to create a publisher that does what I want.

This seems like a daunting task. There is a blog post about creating a [Combine Latest publisher](https://danieltull.co.uk/blog/2019/08/04/combine-latest-collection/) which does something similar to what I needed. I could have used that publisher, but I wanted to be more explicit that this was a `Zip` type of publisher not a `CombineLatest` type of publisher.

At a recent [NSCoder Night](https://nscodernightlondon.com){{<sidenote>}}A monthly meetup of iOS and macOS developers{{</sidenote>}}, [Daniel](https://twitter.com/danielctull) helped me write a publisher that fetched all the pages of a paginated URL. From talking to him and referring to his write up I came to realise that creating a publisher is basically like following a recipe. And more importantly it's not the Publisher that does the work: when a publisher receives a subscription, it creates an internal `Subscription` object which it returns to the subscriber. It is this Subscription object which actually does the work.


## Why do I Need my Own Publisher? {#why-do-i-need-my-own-publisher}

For an app that I am developing for a client I fetch 24 images from 24 different URLs. I need all the images, and I need them to be ordered for the resulting object that I create to be considered complete. I want to be able to write a chain a like this at the call site:

```swift
urls                  // [String]
  .map(convertToURL)  // [URL]
  .map(loadURL)       // [Publisher<Data, Error>]
  .zip                // Publisher<[Data], Error>
  .sink {...}         // Consume [Data] or handle the error
```


## Why Zip and not CombineLatest? {#why-zip-and-not-combinelatest}

As the array of publishers that I have are one-shot publishers, I _could_ use the CombineLatest publisher described in the post above. There is a difference between CombineLatest and Zip. A diagram will help to make this clearer.

{{< figure
  src="/img/2019/09/CombineLatest.png"
  title="Marble diagram or CombineLatest"
  label="combine-latest-marble-diagram"
  caption="The _latest_ outputs of the publishers"
  attr=""
  link=""
>}}

{{< figure
  src="/img/2019/09/Zip.png"
  title="Marble diagram or Zip"
  label="zip-marble-diagram"
  caption="Publishes _pairs_ of outputs."
  attr=""
  link=""
>}}

I chose to write the Zip publisher because conceptually, I want to wait for all the matched outputs and using a Zip makes this requirement explicit. And, I wanted an excuse to write a publisher.


## Writing the Publisher {#writing-the-publisher}


### Step 1: {#step-1}

Create a struct which defines its `Output` and `Failure` matched to the _upstream_ `Output` and `Failure`.

Let's start with the Publisher itself. Publishers are =struct=s. In my case it's just a container to hold the array of publishers so I constrain the generic type to be a collection of publishers. I also typealias the Output to be an array of the upstream publisher's Outputs and the Failure to be the upstream publisher's Failure type.

```swift
public struct ZipCollection<Publishers>
    where
    Publishers: Collection,
    Publishers.Element: Publisher
{
    public typealias Output = [Publishers.Element.Output]
    public typealias Failure = Publishers.Element.Failure

    private let publishers: Publishers

    public init(_ publishers: Publishers) {
        self.publishers = publishers
    }
}
```


### Step 2: {#step-2}

Make this struct conform to `Publisher` matching the `Output` and `Failure` to the _downstream_ `Input` and `Failure`.

Add an extension to make `ZiCollection` conform to `Publisher` and implement the required method. This will not compile yet, because the `Subscription` type hasn't been defined. Note that I'm constraining the downstream `Output` and `Failure` to `Zip`'s `Output` and `Failure`. The method simply creates a `Subscription` object and passes it along to the subscriber.

```swift
extension ZipCollection: Publisher {
    public func receive<Subscriber>(subscriber: Subscriber)
        where
        Subscriber: Combine.Subscriber,
        Subscriber.Failure == Failure,
        Subscriber.Input == Output
    {
        let subscription = Subscription(subscriber: subscriber, publishers: publishers)
        subscriber.receive(subscription: subscription)
    }
}
```


### Step 3: {#step-3}

Create a `Subscription` object to return to the downstream subscribers that does the work of transforming the _upstream_ `Output` and `Failure` to the _downstream_ `Input` and `Failure`

```swift
extension ZipCollection {
   fileprivate final class Subscription<Subscriber>: Combine.Subscription
        where
        Subscriber: Combine.Subscriber,
        Subscriber.Failure == Failure,
        Subscriber.Input == Output
    {
        private let subscribers: [AnyCancellable]
        private let queues: [Queue<Publishers.Element.Output>]

        init(subscriber: Subscriber, publishers: Publishers) {
            var count = publishers.count
            var outputs = publishers.map { _ in Queue<Publishers.Element.Output>() }
            queues = outputs
            var completions = 0
            var hasCompleted = false
            let lock = NSLock()

            subscribers = publishers.enumerated().map { index, publisher in
                publisher.sink(receiveCompletion: { completion in
                    lock.lock()
                    defer { lock.unlock() }

                    guard case .finished = completion else {
                        // Any failure causes the entire subscription to fail.
                        subscriber.receive(completion: completion)
                        hasCompleted = true
                        outputs.forEach { queue in
                            queue.removeAll()
                        }
                        return
                    }

                    completions += 1

                    guard completions == count else { return }

                    subscriber.receive(completion: completion)
                    hasCompleted = true
                }, receiveValue: { value in
                    lock.lock()
                    defer { lock.unlock() }

                    guard !hasCompleted else { return }
                    outputs[index].enqueue(value)

                    guard (outputs.compactMap{ $0.peek() }.count) == count else { return }

                    _ = subscriber.receive(outputs.compactMap({ $0.dequeue() }))
                })
            }
        }

        public func cancel() {
            subscribers.forEach { $0.cancel() }
            queues.forEach { $0.removeAll() }
        }

        public func request(_ demand: Subscribers.Demand) {}
    }
}
```

This is a bit more code, because this is where the actual work is being done.

The only property is an array of `AnyCancellable` which is used to handle the output of the upstream array of publishers. The `init` method configures each of these to handle the output of the upstream publishers. I use a \`Queue\` to hold on to the received values, and when at least one value has been received from each of the publishers, I dequeue those results and send them on to the downstream subscriber as an array.

I handle cancellation by sending a `cancel()` message to each of the `Cancellables`.

As I'm not handling back pressure there is an empty implementation of the required `request(_)` method.


## Make it Chainable {#make-it-chainable}

That's it for the publisher. The only thing left to do is to write some conveniences to allow it to be used with chaining syntax. That's quite simple:

```swift
extension Collection where Element: Publisher {
    /// Combine the array of publishers to give a single array of the `Zip ` of their outputs
    public var zip: ZipCollection<Self> {
        ZipCollection(self)
    }
}
```


## Closing Thoughts {#closing-thoughts}

Is this as efficient as Combine's `Zip` functions? I Don't know. At the call site it's a lot easier to use this rather than trying to turn 24 requests into 6 batches of `Zip4` then a `Zip3` and then a `Zip2` to chain all 24 requests together (I know, because that was what I started to write). So it solves the problem I had in a way that I wanted to write the code. Also, the more of these that I write, the more comfortable I get writing them, which is another benefit.


## Edit {#edit}

Thanks to [Iain Smith](https://twitter.com/_iains) who messaged me to point out that cancellation didn't clear out the queues I've made some minor corrections to the code.


## Code Repository {#code-repository}

The code for this is available as part of the [FoundationCombine](https://github.com/CombineHarvesters/FoundationCombine) Swift Package available on GitHub. Alongside the `CombineLatest` publisher which inspired it.
