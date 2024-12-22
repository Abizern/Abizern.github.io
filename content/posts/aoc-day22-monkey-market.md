+++
title = "Advent of Code Day22: Monkey Market"
description = "Nothing fancy for this one, just a process to follow"
date = 2024-12-22
tags = ["advent-of-code", "swift"]
draft = false
meta = true
math = false
+++

After spending far too long yesterday unsuccessfully trying to get my head around nested recursions, today{{<sidenote>}}https://adventofcode.com/2024/day/22{{</sidenote>}} was something a little easier.


## Part 1 {#part-1}

We are given a list of numbers and a transformation to apply to them.

It's a simple enough process and careful reading let's it be written directly.

```swift
func mix(_ number: Int, _ secretNumber: Int) -> Int {
  number ^ secretNumber
}

func prune(_ secretNumber: Int) -> Int {
  secretNumber % 16777216
}

func next(from: Int) -> Int {
  let a = prune(mix(from * 64, from))
  let b = prune(mix(Int(floor(Double(a) / 32.0)), a))
  let c = prune(mix(b * 2048, b))

  return c
}
```

I wrote functions for the `mix` and `prune` transformation, and a `next` function to generate a new number from the old one.

Then I wrote a function that returns a function that takes a number and transforms it the given number of times. I find it easier to write function returning functions when they are used with `map` operations.

```swift
func evolvutionFunction(n: Int) -> (Int) -> Int {
  { secretNumber in
    var num = secretNumber
    for _ in 0 ..< n {
      num = next(from: num)
    }

    return num
  }
}
```

And then put it all together.

```swift
func part1() async throws -> Int {
  rows.map(evolvutionFunction(n: 2000)).reduce(0, +)
}
```

As I said, nothing fancy, just write code to match the requirements.


## Part 2 {#part-2}

There are further transformations to make and then a calculation to make.

```swift
func evolutionReduction(n: Int) -> (Int) -> [Int] {
  { secretNumber in
    (0 ..< n).reductions(secretNumber) { num, _ in
      next(from: num)
    }
  }
}
```

Rather than return a single number, this returns a list of all the secret numbers generated. I used the reductions{{<sidenote>}}https://swiftpackageindex.com/apple/swift-algorithms/1.2.0/documentation/algorithms/reductions{{</sidenote>}} method from the Swift-Algorithms package.

The main processing is done in the differences method

```swift
func differences(_ numbers: [Int]) -> [String: Int] {
   let ones = numbers.map { $0 % 10 }
   var dict: [String: Int] = [:]

   for slice in ones.windows(ofCount: 5) {
     var k: [String] = []
     let v = slice.last!
     for (n, l) in zip(slice.dropFirst(), slice) {
       k.append(String(n - l))
     }
     let key = k.joined(separator: ",")
     guard dict[key] == nil else { continue }
     dict[key] = v
   }
   return dict
 }
```

I used the modulo method to get the `ones` digit. And then I used the `windows(ofCount:)` to get overlapping slices of length 5 (I need five number to get 4 differences) and I make a string out of the list of differences (Swift tuples are not hashable so I can't use them as dictionary keys). I only add a sequence the first time it is found, that is one of the requirements of the puzzle.

I now have a dictionary of the a sequence of 4 changes, and the number of bananas that will be gained if that sequence is chosen.

```swift
func part2() async throws -> Int {
  rows
    .map(evolutionReduction(n: 2000))
    .map(differences)
    .reduce(into: [String: Int]()) { partialResult, dict in
      for key in dict.keys {
        partialResult[key, default: 0] += dict[key] ?? 0
      }
    }
    .values.max() ?? 0
}
```

I take the dictionary for each of the numbers and then join them together with a reduction. Adding up the values of the bananas if the sequence already exists in the partial result (the accumulator).

The result is just the largest value in the dictionary.


## Final Thoughts {#final-thoughts}

The full code is on Github{{<sidenote>}}https://github.com/Abizern/aoc-swift-2024/blob/main/Sources/Day22.swift{{</sidenote>}}.

Unfortunately, I wasted a lot of time trying to debug my code before I realised that the example input for part 2 is not the same as the input for Part 1.

Both parts run in under 2s and I can't see any obvious way of making this run any faster. Also, unlike the beginning of the month, I don't feel the urge to make my code as elegant as possible. It works, I get results in a reasonable amount of time, and I've written notes about my work on here.

Just a few more days to go. Maybe just one more for me before I finish the others off between Christmas and the New Year.
