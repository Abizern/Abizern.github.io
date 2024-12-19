+++
title = "Advent of Code Day19: Linen Layout"
description = "Another simple day. Did it fast, then left it alone"
date = 2024-12-19
tags = ["advent-of-code", "swift"]
draft = false
meta = true
math = false
+++

My worries for today's{{<sidenote>}}https://adventofcode.com/2024/day/19{{</sidenote>}} puzzle being very difficult were unfounded. Which makes me more concerned for the weekend.

We are supposed to find the number of towel patterns that are possible given a set of small towels, and then we are supposed to count the number that can be created.

This is an application of the Change-making problem{{<sidenote>}}https://en.wikipedia.org/wiki/Change-making_problem{{</sidenote>}}.


## Part 1 {#part-1}

I made a recursive function which worked, but slowly, so I added a cache to it.

```swift
func isValid(_ target: String, from sources: [String], cache: inout [String: Bool]) -> Bool {
  if target.isEmpty { return true }
  if let cached = cache[target] { return cached }

  let candidates = sources.filter { target.hasPrefix($0) }.map(\.count)
  guard !candidates.isEmpty else {
    return false
  }
  for length in Set(candidates) {
    let newTarget = String(target.dropFirst(length))
    if isValid(newTarget, from: sources, cache: &cache) {
      cache[newTarget] = true
      return true
    } else {
      cache[newTarget] = false
    }
  }
  return false
```

The cache tracks whether towel (and sub-towel) combinations are valid or invalid. Along with the case for the target string remaining empty, this is the base case for the recursive function. If the target string is empty, we have been able to consume it's pattern with what is available, so it is valid.

If none of the available sources are a prefix of the towel, then it's not valid

If there are matches, then I remove the number of characters of the source pattern from the target pattern and continue the search. There is some cacheing along the way.

```swift
func part1() async throws -> Int {
  var cache: [String: Bool] = [:]
  let (sources, targets) = input
  return targets.map { isValid($0, from: sources, cache: &cache) }.filter { $0 }.count
}
```


## Part 2 {#part-2}

Almost exactly the same as the first part, except we are counting what can be made:

```swift
func countMatches(_ target: String, from sources: [String], cache: inout [String: Int]) -> Int {
  if target.isEmpty { return 1 }
  if let cached = cache[target] { return cached }

  let candidates = sources.filter { target.hasPrefix($0) }
  guard !candidates.isEmpty else {
    return 0
  }

  var counts = 0
  for candidate in candidates {
    let newTarget = String(target.dropFirst(candidate.count))
    let count = countMatches(newTarget, from: sources, cache: &cache)
    if count > 0 {
      cache[newTarget] = count
      counts += count
    } else {
      cache[newTarget] = 0
    }
  }

  return counts
}
```

Whenever the base case is reached, I return 1.

While searching, I recurse on the shortened target. In Part 1 I used a set of source lengths, to not duplicate any searches, but in this case it was easier to kick off one call for each match to make consolidating the results faster. And let the cache deal with the multiple calls.

```swift
func part2() async throws -> Int {
  var cache: [String: Int] = [:]
  let (sources, targets) = input
  return targets.map { countMatches($0, from: sources, cache: &cache) }.reduce(0, +)
}
```


## Final Thoughts {#final-thoughts}

It took less than 0.1s for each part and I think that's good enough.

As usual, the full source is available on Github{{<sidenote>}}https://github.com/Abizern/aoc-swift-2024/blob/main/Sources/Day19.swift{{</sidenote>}}.

I still have some left-over challenges to finish and I should work on them rather than tidy this up to be better code. Yes, there is repetition, but that doesn't bother me as much as it seems to for other people. For more, see my Ted talk on why DRY is a scam{{<sidenote>}}There is no talk, but I do think excessive application of DRY may lead to unwanted coupling{{</sidenote>}}.

I'm giving myself permission to slack off on this one.
