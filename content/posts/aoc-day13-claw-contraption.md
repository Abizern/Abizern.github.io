+++
title = "Advent of Code Day13: Claw Contraption"
description = "The claw has chosen..."
date = 2024-12-14T13:30:00Z
tags = ["advent-of-code", "swift"]
draft = false
meta = true
math = true
+++

I went on a bit of a math rabbit hole, but came up with a solution that runs quickly enough.

This one is just about maths. We have a machine with buttons to move a claw{{<sidenote>}}https://adventofcode.com/2024/day/13{{</sidenote>}} and want to know a) can it be positioned in a particular place, and b) if it can be positioned, how much will it cost.


## Part 1 {#part-1}

We are told that the machine should take no more than 100 button presses to move the claw. As I like to get the first part done quickly so that I can get to the second part, I wrote a brute for solution that just ran through 100 button presses until I found an answer.

```swift
var minimumCost: Int? {
  var minimumCost: Int?
  for a in 0 ..< 100 {
    for b in 0 ..< 100 {
      let currentX = a * buttonA.dx + b * buttonB.dx
      let currentY = a * buttonA.dy + b * buttonB.dy

      if currentX == prize.x, currentY == prize.y {
        let cost = 3 * a + b
        if minimumCost == nil || cost < minimumCost! {
          minimumCost = cost
        }
      }
    }
  }
  return minimumCost
}
```

Even for all of the inputs, this hardly took any time. I'm not sure I even needed to worry about the minimum cost, these are straight line equations and will only have one solution.

Running the solution was a one liner.

```swift
func part1() async throws -> Int {
  machines.compactMap(\.costToWin).reduce(0, +)
}
```


## Part 2 {#part-2}

With the target positions set to large numbers, this brute force method was not going to be feasible.

We have two equations linear equations

\\[
a\_x m + b\_x n = c\_x \quad (1) \\\\
a\_y m + b\_y n = c\_y \quad (2)
\\]

where:

-   \\(a\_x\\) and \\(b\_x\\) are the distances moved in the \\(x\\) direction by the \\(a\\) and \\(b\\) buttons.
-   \\(a\_y\\) and \\(b\_y\\) are the distances moved in the \\(y\\) direction by the \\(a\\) and \\(b\\) buttons.
-   \\(c\_x\\) and \\(c\_y\\) are the distances in the \\(x\\) and \\(y\\) direction to the target.

These are simultaneous equations that could be solved mathematically many ways, direct substitution, matrix methods, etc. But we know that these are Linear Diophantine{{<sidenote>}}https://en.wikipedia.org/wiki/Diophantine_equation#:~:text=In%20mathematics%2C%20a%20Diophantine%20equation{{</sidenote>}} equations, that have whole number solutions, and I didn't want to use numerical methods that deal with Real numbers.

I thought about using the Chinese Remainder Theorem{{<sidenote>}}https://en.wikipedia.org/wiki/Chinese_remainder_theorem{{</sidenote>}}, but for only two equations I didn't want to go turning them into modular forms.

But there is the Extended Euclidean Algorithm{{<sidenote>}}https://en.wikipedia.org/wiki/Extended_Euclidean_algorithm{{</sidenote>}} which deals with equations of the form we are given, so I tried to use that.

But since there are two equations, I didn't need to go that far, there are only a couple of checks that need to be done. Essentially the code to solve this returns a tuple of the number of presses required for A and B, or nil if there is no solution.

```swift
  public func diophantineEEA(ax: Int, bx: Int, ay: Int, by: Int, cx: Int, cy: Int) -> (m: Int, n: Int)? {
  let aPrime = ay * bx - by * ax
  let cPrime = cy * bx - by * cx

  if aPrime == 0 || cPrime % aPrime != 0 {
    return nil
  }

  let m = cPrime / aPrime

  let numerator = cx - ax * m
  if numerator % bx != 0 {
    return nil
  }

  let n = numerator / bx

  return (m, n)
}
```

We can rearrange \\((1)\\) so that there is only one variable on the left:

\\[
n = \frac{c\_x - a\_xm}{b\_x} \quad (3)
\\]

Substitute this value of n into \\((2)\\):

\\[ a\_y m + b\_y \left( \displaystyle \frac{c\_x - a\_x m}{b\_x} \right) = c\_y \quad (4) \\]

With a little re-arrangement and distribution{{<marginnote>}}Left as an exercise for the reader.{{</marginnote>}} this can be re-written as:

\\[ (a\_y b\_x - b\_y a\_x) m = c\_y b\_x - b\_y c\_x \quad (5) \\]

We can simplify this as:

\\[ a' = a\_y b\_x - b\_y a\_x , c' = c\_y b\_x - b\_y c\_x  \quad (6) \\]

And we are left with:

\\[ a'm = c' \quad (7) \\]

This is where the conditions for Diophantine equations apply. obviously \\[a'\\] can't be zero, and \\[c' / a' \\] has to be a whole number. Since presses can only be whole numbers, \\[m\\] and \\[n\\] have to be whole numbers.

The rest is just substitution.

```swift
var costToWin: Int? {
  guard let (a, b) = diophantineEEA(
          ax: buttonA.dx,
          bx: buttonB.dx,
          ay: buttonA.dy,
          by: buttonB.dy,
          cx: prize.x,
          cy: prize.y
        )
  else {
    return nil
  }
  return 3 * a + b
}

func part2() async throws -> Int {
  machines.map(\.corrected).compactMap((\.costToWin)).reduce(0, +)
}
```

This runs really quickly. Not sure I needed to spend the time learning how to make sure the answers are whole numbers, but that's one of the reasons I do AoC -- to learn new things.

As usual, the full code{{<sidenote>}}https://github.com/Abizern/aoc-swift-2024/blob/main/Sources/Day13.swift{{</sidenote>}} is on Github.
