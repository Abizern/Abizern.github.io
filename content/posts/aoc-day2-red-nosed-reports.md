+++
title = "Advent of Code Day2: Red-Nosed Reports"
description = "Use the (brute) force, Luke."
date = 2024-12-02
tags = ["advent-of-code", "swift"]
draft = false
meta = true
math = true
+++

Today's{{<sidenote>}}https://adventofcode.com/2024/day/2{{</sidenote>}} challenge was only slightly more complicated than yesterday's, and one where brute(ish) force was enough. My solution is on Github{{<sidenote>}}https://github.com/Abizern/aoc-swift-2024/blob/main/Sources/Day02.swift{{</sidenote>}}.


## Part 1 {#part-1}

To check if a report (a list of numbers) is safe; see if they are all increasing or all decreasing and the difference is inclusively between 1 and 3.

I used the `adjacentPairs()` method from the Swift-Algorithms package{{<sidenote>}}https://github.com/apple/swift-algorithms{{</sidenote>}} rather than `zip` to get a sequence of pairs of numbers.

After checking whether the differences should be increasing or decreasing, I made sure that all the pairs satisfied the condition by using the `allSatisfy()` method.

```swift
func isSafe(_ report: [Int]) -> Bool {
  guard let start = report.first,
        let end = report.last,
        start != end
  else { return false }
  let shouldIncrease = start < end ? true : false

  return report.adjacentPairs().allSatisfy { a, b in
    (shouldIncrease ? a < b : a > b) && (1 ... 3).contains(abs(a - b))
  }
}
```

I used this to filter and count the input to get my answer.


## Part 2 {#part-2}

To check if a report is correctable, see if removing a single number from the list makes it safe. After a few minutes thought about complexity, I used a brute(ish) force solution.

If a report is not safe, I removed one of the numbers and checked again:

```nil
func isSafeOrCorrectable(_ report: [Int]) -> Bool {
  guard !isSafe(report) else { return true }
  let length = report.count
  var i = 0
  var correctable = false

  while i < length, !correctable {
    var arr = report
    arr.remove(at: i)
    correctable = isSafe(arr)
    i += 1
  }

  return correctable
}
```

And, again, a filter and count gives me the answer.


## Complexity {#complexity}

My completely unscientific assessment of the complexity of removing an element and checking the array again:

The `adjacentPairs()` method has \\(\mathcal{O}(1)\\) complexity, and I'm going through the elements in a single pass which is \\(\mathcal{O}(n)\\)

Removing and checking the list again means another  \\(\mathcal{O}(n)\\) operation, taking it up to  \\(\mathcal{O}(n^2)\\), which is not good, but at least it's not exponential.

Looking at the full problem input there are 1000 lines, each with around 10-ish numbers. Each line will require about 100 to 1000 operations. So the full input is around 1 million operations; not a lot.

So, no need to do anything clever, and my solutions are still output in milliseconds.
