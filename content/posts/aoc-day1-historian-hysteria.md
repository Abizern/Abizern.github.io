+++
title = "AoC Day 1: Historian Hysteria"
description = "Notes on Advent of Code 2024 Day 1"
date = 2024-12-01
tags = ["advent-of-code", "swift"]
draft = false
meta = true
math = false
+++

Advent of Code{{<sidenote>}}https://adventofcode.com{{</sidenote>}} is an advent calendar of programming problems created by Eric Wastl{{<sidenote>}}http://was.tl{{</sidenote>}}.

I've normally done these in languages that I don't use for work --- Common-lisp and Haskell. This year I am going to concentrate on using my primary language of Swift.

I created a template package{{<sidenote>}}https://github.com/Abizern/swift-aoc-starter-template{{</sidenote>}}, based on one provided by Apple, for Swift solutions.

As expected the first day's problem is fairly easy and a way to make sure that one's environment is set up correctly and works.

This is the 10th anniversary event, and since it involves a missing historian, I think there may be throwbacks to problems from previous years.


## Parsing {#parsing}

Parsing the data was nothing special: The input consisted of two numbers on a line, separated by three spaces. Each number represented an entry on the two lists so created a local variable that just returned the two lists. This follow my philosophy of not doing too much to the input for part1 because you don't know what you'll need for part2


## Part 1 {#part-1}

The problem is to find the difference between terms in the sorted list and sum them. The example showed that the differences were the absolute differences.

To get the solution quickly I did the natural thing of sorting the two lists, mapping the differences and summing them:

```swift
func part1() async throws -> Int {
  // lists is an ([Int], [Int]) of the input
  zip(lists.0.sorted(), lists.1.sorted()).map { left, right in
    abs(left - right)
  }
  .reduce(0, +)
}
```

After I managed to solve both parts I came back to this and tried something different: rather than sorting the lists, I used the Heap structure from the Swift-Collections package{{<sidenote>}}https://github.com/apple/swift-collections{{</sidenote>}}. I initialised two heaps and used the `removeMin()` method on each to successively get the smallest value from each list:

```swift
func part1() async throws -> Int {
  let (left, right) = lists
  var leftHeap = Heap(left)
  var rightHeap = Heap(right)

  var result: Int = 0
  while !leftHeap.isEmpty && !rightHeap.isEmpty {
    result += abs(leftHeap.removeMin() - rightHeap.removeMin())
  }

  return result
}
```

This may have been slightly faster.


## Part 2 {#part-2}

This part required counting the number of occurrences of each number in the second list. Since I had to use this as a lookup table I created a dictionary by using the handy initialiser on `Dictionary` that takes a grouping. For example, given the example list of `[4, 3, 5, 3, 9, 3]` we can get a dictionary of the groupings with:

```swift
Dictionary(grouping: input, by: { $0 })
// -> [3: [3, 3, 3], 9: [9], 5: [5], 4: [4]]
```

and by mapping the values to counts we can get a lookup table for the frequencies:

```swift
Dictionary(grouping: input, by: { $0 }).mapValues(\.count)
// -> [4: 1, 9: 1, 5: 1, 3: 3]
```

After that it's just a case of calculating the values and summing them, which I did in a single reduce:

```swift
func part2() async throws -> Int {
  let (left, right) = lists
  let counts = Dictionary(grouping: right, by: { $0 }).mapValues(\.count)

  let simililarities = left.reduce(into: 0) { partialResult, l in
    let n = counts[l, default: 0]
    partialResult += l * n
  }

  return simililarities
}
```

The full solution is available on Github{{<sidenote>}}https://github.com/Abizern/aoc-swift-2024/blob/main/Sources/Day01.swift{{</sidenote>}}.

A simple puzzle that let me test my Swift environment, and this blog.
