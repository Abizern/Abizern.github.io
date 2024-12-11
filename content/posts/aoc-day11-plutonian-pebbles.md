+++
title = "Advent of Code Day11: Plutonian Pebbles"
description = "I've seen this type of problem before"
date = 2024-12-11
tags = ["advent-of-code", "swift"]
draft = false
meta = true
math = false
+++

Today{{<sidenote>}}https://adventofcode.com/2024/day/11{{</sidenote>}} we had a list of stones that changed over time and we had to count how many there would be at the end of the count. I thought this sort of problem would come up, I've seen it before{{<sidenote>}}The Lanternfish from 2021 https://adventofcode.com/2021/day/6{{</sidenote>}}, and it is one of my favourite ones because it was the first time I saw the process for solving these puzzles.

The problem is that with the splitting of the stones (or the spawning in the case of lanternfish) the number of stones starts going up very quickly, though their identifying numbers lie mostly within a smaller range. In the case of lanternfish it was the number of days in the cycle, for the stones it today's puzzle, it is the identifier.

For odd length numbers, this index goes up to larger numbers, which will probably need to split into two stones in the following cycle. Eventually, these identifiers will start to appear multiple times, which is the clue to the process for solving these puzzles: We can deal with blocks of stones (excuse the pun) sharing an ID in one step.


## Part 1 {#part-1}

I turned the input into a dictionary of identifiers and their counts from the input. There are no duplicates to start with.

```swift
var stoneDictionary: [Int: Int] {
  do {
    let numbers = try NumberLine(separator: " ").parse(data)
    return Dictionary(grouping: numbers, by: { $0 }).mapValues(\.count)
  } catch {
    fatalError("Could not parse input \(error)")
  }
}
```

The main engine of the solution is the function with processes the list of stones: in my case a dcitionary

```swift
func step(_ dict: [Int: Int]) -> [Int: Int] {
  var keys = dict.keys.filter { $0 != 0 }.map { ($0, String($0)) }
  let partitionIndex = keys.partition { $0.1.count % 2 == 1 }
  var accum = [Int: Int]()

  if let zeroes = dict[0] {
    accum[1] = zeroes
  }

  // even length keys
  for pair in keys[0 ..< partitionIndex] {
    let (key, strKey) = pair
    let count = dict[key]!
    let midpoint = strKey.count / 2

    accum[Int(strKey.prefix(midpoint))!, default: 0] += count
    accum[Int(strKey.suffix(midpoint))!, default: 0] += count
  }

  for pair in keys[partitionIndex ..< keys.count] {
    let key = pair.0
    let newKey = key * 2024
    let value = dict[key]!

    accum[newKey, default: 0] += value
  }

  return accum
}
```

Which looks long but is quite simple

Start by splitting the keys into a pair of the key and the string representation of the key. Then use the `partion(by:)` method on arrays, which rearranges an array such that elements which pass the predicate appear after elements that fail the predicate. The value returned is the index of the partion

```swift
var keys = dict.keys.filter { $0 != 0 }.map { ($0, String($0)) }
let partitionIndex = keys.partition { $0.1.count % 2 == 1 }
```

I create a dictionary to hold the new state of the stones, and deal with those that have an identifier of 0 to have identifier's of 1

```swift
var accum = [Int: Int]()

if let zeroes = dict[0] {
  accum[1] = zeroes
}
```

For keys that have even length keys, I loop through them, performing the split to get the news keys and then adding the counts of those stones to the new dictionary.

```swift
for pair in keys[0 ..< partitionIndex] {
  let (key, strKey) = pair
  let count = dict[key]!
  let midpoint = strKey.count / 2

  accum[Int(strKey.prefix(midpoint))!, default: 0] += count
  accum[Int(strKey.suffix(midpoint))!, default: 0] += count
}
```

For the odd length key, I multiply the key by `2024` ad assign the value to this keys in the new dictionary, and return the new state of the stones.

```swift
for pair in keys[partitionIndex ..< keys.count] {
  let key = pair.0
  let newKey = key * 2024
  let value = dict[key]!

  accum[newKey, default: 0] += value
}

return accum
```

To run this for a given number of blinks I created a helper function that iteratively runs the step function for a given number of times.

```swift
func stepper(_ dict: [Int: Int], blinks: Int) -> Int {
  var dict = dict
  for _ in 0 ..< blinks {
    dict = step(dict)
  }

  return dict.values.reduce(0, +)
}
```

Running it for 25 times is easy enough now.

```swift
func part1() async throws -> Int {
  stepper(stoneDictionary, blinks: 25)
}
```


## Part 2 {#part-2}

It may be possible to run the first part by applying the rules to one stone at a time for part 1, I remember from my attempts at Lanternfish that this takes a long time for step 2. Except it doesn't really.

Change the number of steps to 75 instead of 25, and it still runs in millisecond time.

```swift
func part2() async throws -> Int {
  stepper(stoneDictionary, blinks: 75)
}
```

The full source, which is not much longer, is available on Github{{<sidenote>}}https://github.com/Abizern/aoc-swift-2024/blob/main/Sources/Day11.swift{{</sidenote>}}.
