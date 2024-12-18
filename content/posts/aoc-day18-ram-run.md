+++
title = "Advent of Code Day18: RAM Run"
description = "Did it fast, and then did it well."
date = 2024-12-18
tags = ["advent-of-code", "swift"]
draft = false
meta = true
math = false
+++

I enjoyed today's puzzle{{<sidenote>}}https://adventofcode.com/2024/day/18{{</sidenote>}}.Not because it was reasonably easy, but because I managed to grind out a reasonable efficient solution after thinking about the problem for a little bit. This gave me as much satisfaction as when I figured out the Lanternfish{{<sidenote>}}The Lanternfish from 2021 https://adventofcode.com/2021/day/6{{</sidenote>}} problem.

I also got to play with GameplayKit{{<sidenote>}}https://developer.apple.com/documentation/gameplaykit{{</sidenote>}} and Swift-algorithms{{<sidenote>}}https://github.com/apple/swift-algorithms{{</sidenote>}}.


## Part 1 {#part-1}

given a list of positions in a grid, we are supposed to find the shortest number of steps to go from one corner to another.

Unlike Reindeer Maze{{<sidenote>}}https://adventofcode.com/2024/day/16{{</sidenote>}}, this is a pure path finding problem. I don't need to implement the search myself{{<sidenote>}}Not wanting to do this myself is one of the reasons I haven't even started solving Day 16 yet{{</sidenote>}}, I can just use the built in methods from GameplayKit.

```swift
func part1() async throws -> String {
  let graph = createGraph(width: 71, height: 71)
  let points = points.prefix(1024)
  remove(points: points, from: graph)

  let start = graph.node(atGridPosition: vector_int2(0, 0))!
  let end = graph.node(atGridPosition: vector_int2(70, 70))!

  let path = graph.findPath(from: start, to: end)

  return "\(path.count - 1)" // steps, is one less than length of path
}
```

The full code{{<sidenote>}}https://github.com/Abizern/aoc-swift-2024/blob/main/Sources/Day18.swift{{</sidenote>}} has more context around the helper functions, but this is quite simple:

I create a `GKGridGraph` of the specified size, take the first 1024 points off my input list and remove those nodes from the graph. The `GKGridGraph` class takes care of creating a graph for all the remaining nodes, connecting them to their nearest neighbours. Removing nodes leaves me with graph of what cells are connected.

The `FindPath(from:to:)` method returns a list of the nodes traversed in the shortest path from start to end, and I subtract 1 from that as steps are the transitions between paths.

That was that. As usual I tried to get Part 1 as quickly as possible so I can get on to part 2.


## Part 2 {#part-2}

Now we have to use the full input list of points and find which one completely closes off the end point from the start point.


### Step 1: Brute Force {#step-1-brute-force}

I wasn't sure if it would work in a reasonable amount of time, but it was quick to write so I gave it a try:

```swift
func bruteForce() -> String {
  let graph = createGraph(width: 71, height: 71)
  let start = graph.node(atGridPosition: vector_int2(0, 0))!
  let end = graph.node(atGridPosition: vector_int2(70, 70))!

  remove(points: points.prefix(1024), from: graph)

  for point in points.dropFirst(1024) {
    let node = graph.node(atGridPosition: vector_int2(Int32(point.1), Int32(point.0)))!
    graph.remove([node])

    if graph.findPath(from: start, to: end).isEmpty {
      return "\(point.0),\(point.1)"
    }
  }

  return "Anser not found"
}
```

I create a graph, and the start and end points and then remove the first 1024 points from the graph. I know this doesn't disconnect the start and end because I've already worked out how many steps it takes.

Then, I remove one node at a time and see if a path exists, still using the `findPath(from:to:)` method.

This ran in 23s on my machine. Which is okay, but not really what I am looking for.


### Stejp 2: Binary Search {#stejp-2-binary-search}

Searching for the path is what takes time, so it is a good idea to reduce the number of times we have run that bit of code.

Since the list is ordered, the nodes are removed one at a time in a sequence, A binary search can be used instead.

If you don't know what a binary search{{<marginnote>}}This is a simple explanation of a binary search, I first heard it in a Colombo episode and it has always stayed with me.{{</marginnote>}} is, let me give you an example. You have a large number of small bags of gold and a weighing machine that charges you each time you use it. Each of the bags has 10 gold coins in it of equal weight, except, one bag has 9 gold coins and a lead coin that weights slightly <span class="underline">less</span> than the gold ones. You want to spend as little as possible on weighing scale charges{{<marginnote>}}I don't know why; you have all this gold around you.{{</marginnote>}} so you can't jest weigh each bag. Instead you split them into two piles. You weight the first one and then the second pile. One of these piles will weigh less than the other{{{assuming an even number of bags. If it's an odd number, you split  them into even piles, and if they both weight the same, then the left over one is the bag you are looking for.}}} so you know that one of those bags is the one you are looking for. You split this pile into two and weight both piles, again, looking for the lighter pile. This is the process: just keep splitting in two and working on the pile that is lightest. This is obviously going to be faster than weighing each bag. And cheaper.

The swift-algorithms package has a method on arrays called `partioningIndex` which takes a predicate that you provide to show whether the element belongs in the first half or the second half of each shortened list. And it returns the index of the first item where that predicate returns true.

My solution looks like this:

```swift
func binarySearch() -> String {
  let index = points.partitioningIndex { point in
    let graph = createGraph(width: 71, height: 71)
    let start = graph.node(atGridPosition: vector_int2(0, 0))!
    let end = graph.node(atGridPosition: vector_int2(70, 70))!
    let searchIndex = points.firstIndex { $0 == point }!
    let slice = points.prefix(through: searchIndex)
    remove(points: slice, from: graph)

    return graph.findPath(from: start, to: end).isEmpty
  }

  let point = points[index]

  return "\(point.0),\(point.1)"
}
```

Within the predicate, I create a graph, remove all the nodes up to and including the point being examined, and see if a path can be found to the end point. This does the search for me. I use the returned index to get the value to use as the result.

This runs faster, about 13s. This is okay, but I was sure I could do better.


### Part 3 Obstacle based search. {#part-3-obstacle-based-search-dot}

I want to minimise the number of times I have to look for a path. And I had that moment of clarity that, as programmers, makes us feel as if we are doing what we were meant to do.

```swift
func obstacle() -> String {
  let graph = createGraph(width: 71, height: 71)
  let start = graph.node(atGridPosition: vector_int2(0, 0))!
  let end = graph.node(atGridPosition: vector_int2(70, 70))!

  remove(points: points.prefix(1024), from: graph)
  var path = graph.findPath(from: start, to: end)

  for point in points.dropFirst(1024) {
    let node = graph.node(atGridPosition: vector_int2(Int32(point.1), Int32(point.0)))!
    graph.remove([node])

    guard path.contains(node) else { continue }

    let newPath = graph.findPath(from: start, to: end)

    if newPath.isEmpty {
      return "\(point.0),\(point.1)"
    } else {
      path = newPath
    }
  }

  return "Answer not found"
}
```

I set up the graph, start and end points as usual, and remove the first 1024 nodes from the input. I know that a path exists at this point, so I cache it in the `path` variable.

Now I go through the remaining points one by one, just as with the brute force search, <span class="underline">except</span> if the node to be removed is not one of the nodes on the shortest path, it isn't going to change anything. So I just remove the node and check the next node to remove. If you have a path and the node being taken away is not on that path, there is no need to recalculate the path. I still remove it, because If I do have to search for another path, it's important that it is not included.

If the node is on the path, then I remove the node and search for the path again, cacheing the result in the same variable.

I do this until I find a node to remove that is on the path, and the new recalculated path does not exist.

This runs an just over 1s. I can live with that.


## General Progress. {#general-progress-dot}

I'm behind in my solutions, but I'm up to date with my notes. I still have Day 16 to do and the second part of Day17. But I'll get around to them when I can.

My notes are out of order, but I don't think that matters and I don't want to be held up by wanting to write them in order.

I'm a little concerned about tomorrow. Today was reasonably easy to just get an answer. There might be some terrors yet to come.
