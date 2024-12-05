+++
title = "Advent of Code Day5: Print Queue"
description = "PC Load Letter?! What 🤬 does that mean?"
date = 2024-12-05
tags = ["advent-of-code", "swift"]
draft = false
meta = true
math = false
+++

I made a couple of mis-steps that slowed me down a little.

This was another day{{<sidenote>}}https://adventofcode/2024/day/5{{</sidenote>}} where part 2 wasn't as much of a jump in difficulty, but needed careful reading; only add the middle values for lists that need sorting. You can see my full solution on Github{{<sidenote>}}https://github.com/Abizern/aoc-swift-2024/blob/main/Sources/Day05.swift{{</sidenote>}}.


## Part 1 {#part-1}

Validate a list of numbers given a set of rules.

I first tried to read the rules into a dictionary of `[Int: [Int]]` for each page, show the pages that are supposed to come after it. That failed my tests because it didn't take into account for the requirement that the rules imply a negative. If `A|B` then `B` must come after `A` and if `B` comes before `A` then the list is not valid. So both cases need to be encoded into the check.

Since `(Int, Int)` is not `Hashable` I created a small struct to encode first and last values and then use that as the key for my dictionary.

```swift
struct Pair: Hashable {
  let first: Int
  let second: Int

  init(_ first: Int, _ second: Int) {
    self.first = first
    self.second = second
  }
}
```

Then I created a function to iterate through the rules, encoding the correct order as `true` and the reverse condition as `false`

```swift
func ordering(_ rules: [(Int, Int)]) -> [Pair: Bool] {
  var dict: [Pair: Bool] = [:]
  dict.reserveCapacity(rules.count * 2)
  for (first, second) in rules {
    dict[Pair(first, second)] = true
    dict[Pair(second, first)] = false
  }

  return dict
}
```

The tricky part is the validation function. Since I knew that I was going to be mapping over the input list using the ordering, I wrote a function that returns the function to be used. Closures are first-class types in Swift, and this frequently makes code clearer at the call site:

```swift
func isValidFuntion(_ ordering: [Pair: Bool]) -> ([Int]) -> Bool {
  { pages in
    let pageCount = pages.count
    for i in 0 ..< pageCount - 1 {
      for j in i + 1 ..< pageCount {
        let pair = Pair(pages[i], pages[j])
        if ordering[pair] ?? true {
          continue
        } else {
          return false
        }
      }
    }
    return true
  }
}
```

This goes through the list by creating every possible pair of orderings, if they are allowed or not encoded, then it is a valid pairing. If it is specifically disallowed, then I return false without checking the rest of the list.

To get the answer I filtered for valid lists, found the midpoint using:

```swift
func middleValue(_ list: [Int]) -> Int {
  list[list.count / 2]
}
```

Note, `Int` division in swift means I don't have to worry about flooring the result.

After finding the midpoint, I just summed them up.

```swift
func part1() async throws -> Int {
  let (rules, pages) = parsedInput
  let ordering = ordering(rules)

  return pages
    .filter(isValidFuntion(ordering))
    .map(middleValue)
    .reduce(0, +)
}
```


## Part 2 {#part-2}

If the list is invalid we should sort it, find the middle value and sum those values.

For lists in Swift, you can pass in a function to use for the comparison of two values, returning `true` if they are correctly ordered. As with the first part, I wrote a function that returned a sorting function:

```swift
func sortingFunction(_ ordering: [Pair: Bool]) -> ((Int, Int) -> Bool) {
  { first, second in
    ordering[Pair(first, second)] ?? true
  }
}
```

Since I already have a dictionary of what should come before what, I just used that dictionary. After that the solution was trivial:

```swift
func part2() async throws -> Int {
   let (rules, pages) = parsedInput
   let ordering = ordering(rules)

   return pages
     .filter(isInvalidFuntion(ordering))
     .map { $0.sorted(by: sortingFunction(ordering)) }
     .map(middleValue)
     .reduce(0, +)
 }
```


## Final Thoughts {#final-thoughts}

-   This wasn't as fiddly as I thought it would be once I correctly encoded the rules.
-   My parsing code is taking up more and more space in my solutions, I really should extract them out to a utility library.
