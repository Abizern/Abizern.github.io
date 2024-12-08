+++
title = "Advent of Code Day7: Bridge Repair"
description = "It's turtles all the way down."
date = 2024-12-07
tags = ["advent-of-code", "swift"]
draft = false
meta = true
math = true
+++

Recursion can make your head hurt, but it can simplify some classes of problems once you get used to the idea of turtles{{<sidenote>}}https://en.wikipedia.org/wiki/Turtles_all_the_way_down{{</sidenote>}} all the way down.

Today{{<sidenote>}}https://adventofcode.com/2024/day/7{{</sidenote>}} was about trying to validate lists of numbers according to simple rules.

It isn't possible to just insert all combinations of the operators, because for 2 numbers there are 2 possibilities. For 3 numbers there are 4 possibilities. For 4 numbers 8. Essentially: it's \\(\mathcal{O}(2^{n-1})\\) which grows really quickly. A quick look at the input shows that some lines have 10 values. So A recursive solution which fails quickly is a better idea.

If I had read the question properly and understood the meaning of **always evaluated left-to-right** I might have saved myself some trouble.

I don't normally include a lot of tests in my solutions - I test the parsing and the example answers, and the correct result is another test. That's usually enough. My solution{{<sidenote>}}https://github.com/Abizern/aoc-swift-2024/blob/main/Sources/Day04.swift{{</sidenote>}} I had to write tests{{<sidenote>}}https://github.com/Abizern/aoc-swift-2024/blob/main/Tests/Day07Tests.swift#L22-L35{{</sidenote>}} for my validation code, which pointed out that I was taking numbers from the wrong end.


## Part 1 {#part-1}

There are only two operations that can be applied to successive numbers, addition and subtraction.

So I extracted each row into a convenient type with an internal check for validity:

```swift
struct Calibration: Equatable, Sendable {
  let target: Int
  let values: [Int]

  var isValid: Bool {
    // ...
  }
}
```

And the answer is a filter, map and reduce:

```swift
func part1() async throws -> Int {
  calibrations.filter(\.isValid).map(\.target).reduce(0, +)
}
```

The thought process with recursion is to consider:

-   The base case
-   if the base condition is not reached, how do we construct the next check?

Since we are starting with a list of values, the base case is going to be either the empty array, or a single value. We are checking that the single value is equal to the target value. If it is we return `true`

If we haven't reached the base case, we want to see whether multiplication or addition can by inserted before the last value {{<marginnote>}}By habit I was taking values from the front of the list when I should have been taking them from the end. Since operators apply left to right{{</marginnote>}}

To check if multiplication works, we see if the target value is a whole multiple of the last value.

To check if addition works, we see if the target value is bigger than the last value.

So there are two possibilities to check if we aren't at the base case. Recursion means calling the same function again with new parameters that will get closer to the base case. So we check them both, and if either of them is true, the entire check is true: The test operation is encoded in the new target, we either divide by or subtract the last value in the list:

```swift
var isValidWithConcoatenation: Bool {
   canConcatenate(target, values: values[...])
 }

 private func canMakeTarget(_ target: Int, values: Array<Int>.SubSequence) -> Bool {
   var values = values
   guard let nextValue = values.popLast() else { fatalError("Out of bounds") }
   guard values.count > 0 else { return target == nextValue }

   let branch1 = target % nextValue == 0 && canMakeTarget(target / nextValue, values: values)
   let branch2 = target > nextValue && canMakeTarget(target - nextValue, values: values)

   return branch1 || branch2
 }
```

Since this is an OR check, if branch1 passes there is no need to check branch2. Inlining the two checks was marginally faster, but I prefer the readability of having the two branches.


## Part 2 {#part-2}

With the new operation of concatenation it's a little bit trickier. But the same technique applies as wit the first part.

The base case for concatenation is that the string representation of the target ends with the string representation of the last value. And the inverse to apply to the new target is to remove the number from the suffix. The new validation functions are:

```swift
var isValidWithConcoatenation: Bool {
  canConcatenate(target, values: values[...])
}

private func canConcatenate(_ target: Int, values: Array<Int>.SubSequence) -> Bool {
  var values = values
  guard let nextValue = values.popLast() else { fatalError("Out of bounds") }
  guard values.count > 0 else { return target == nextValue }

  let strTarget = String(target)
  let strNextValue = String(nextValue)

  let branch1 = target % nextValue == 0 && canConcatenate(target / nextValue, values: values)
  let branch2 = target > nextValue && canConcatenate(target - nextValue, values: values)
  let branch3 = strTarget.count > strNextValue.count
    && strTarget.hasSuffix(strNextValue)
    && canConcatenate(strTarget.remove(strNextValue), values: values)

  return branch1 || branch2 || branch3
}

// Convenience extension
extension String {
  func remove(_ suffix: String) -> Int {
    let suffixLCount = suffix.count
    let newStr = self[..<index(endIndex, offsetBy: -suffixLCount)]
    return Int(newStr)!
  }
}
```

The trick here is to realise that it only applies when there are two values left to check: for example:

`1319: 13 19`

Using the using `branch3` this would recurse with:

```swift
canConcatenate(13, values: [19])
```

And we don't need to do any specific checks because we've reached the base case of a single value that matches the target. That's why the check for branch3 is that the target has more digits that the value at the end of the list.
