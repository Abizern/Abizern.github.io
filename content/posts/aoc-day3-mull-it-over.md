+++
title = "Advent of Code Day3: Mull It Over"
description = "Only day 3 and I'm already feeling inadequate 🙁"
date = 2024-12-03
tags = ["advent-of-code", "swift"]
draft = false
meta = true
math = false
+++

Normally it takes a few more days before I feel my Advent of Code inadequacy, but it struck on day 3{{<sidenote>}}https://adventofcode.com/2024/day/3{{</sidenote>}} instead. Parsing the input into a data structure that I could work with was the hardest part of today's challenge.

I try to use the Swift-Parsing package{{<sidenote>}}https://github.com/pointfreeco/swift-parsing/{{</sidenote>}} because I like the way it works, and also as an excuse to get better at using it. My first attempts at using it for Part 1 failed, so rather than bang my head any longer than I needed to, I resorted to using Swift's new `Regex` functionality. This way I could get to see what part 2 looked like and have an idea of all the parsing requirements for the challenge.

Leaving aside the parsing for now, I'll discuss my solutions{{<sidenote>}}The full solution I came up with is available on https://github.com/Abizern/aoc-swift-2024/blob/main/Sources/Day03.swift{{</sidenote>}}


## Part 1 {#part-1}

The challenge is to check for substrings in a particular form from which 2 numbers can be extracted. These numbers were to be multiplied and summed together.

After extracting the pairs to be multiplied, I just used my old friend `reduce` to multiply the numbers and sum them.

```swift
func part1() async throws -> Int {
  pairs.map { a, b in a * b }.reduce(0, +)
}
```


## Part 2 {#part-2}

As well as checking for the numbers to multiply as in part 1, there is an additional check to see whether the numbers could be multiplied or not, which is done by checking for a switch in the string being parsed.

This may have been possible with Regular Expressions, but I had my heart set on using Swift-Parsing. I defined a type to match the relevant substrings:

```swift
enum Instruction: Equatable {
  case mul(Int, Int)
  case enabled
  case disabled

  var value: Int {
    switch self {
    case .mul(let a, let b): a * b
    case .disabled: 0
    case .enabled: 0
    }
  }
}
```

I used value to return the multiplication when there are two numbers, and 0 for the other cases, because they do not affect the sum.

After parsing out the useful information into a list, I reduce the list keeping track of whether the switch has been enabled or disabled to include calculations:

```swift
func part2() async throws -> Int {
  instructions.reduce(into: (0, Instruction.enabled)) { accumulator, instruction in
    let sum = accumulator.0
    let state = accumulator.1

    switch instruction {
    case .enabled:
      accumulator = (sum, .enabled)
    case .disabled:
      accumulator = (sum, .disabled)
    case .mul:
      if state == .enabled {
        accumulator = (sum + instruction.value, .enabled)
      }
    }
  }.0
}
```

A little long winded, but it's clear in its intent. At least to me it is.


## Parsing {#parsing}

so the initial parsing done with Regular expressions:

```swift
func parseInput() -> [(Int, Int)] {
  let pattern = #/mul\((\d+),(\d+)\)/#

  return data
    .matches(of: pattern)
    .map { match -> (Int, Int)? in
      if let a = Int(match.output.1), let b = Int(match.output.2) {
        return (a, b)
      }
      return nil
    }.compactMap { $0 }
}
```

Now that I look at it, it doesn't look that bad.

Using Swift-Parsing is more verbose. First I had to define the Parsers:

```swift
struct MulParser: Parser {
  var body: some Parser<Substring, Instruction> {
    Parse(Instruction.init) {
      "mul("
      Int.parser()
      ","
      Int.parser()
      ")"
    }
  }
}

struct InstructionParser: Parser {
  var body: some Parser<Substring, Instruction> {
    OneOf {
      MulParser()
      "don't()".map { _ in Instruction.disabled }
      "do()".map { _ in Instruction.enabled }
    }
  }
}
```

Then a parsing function:

```swift
  func parseInput() -> [Instruction] {
  var result = [Instruction]()
  var data = data[...]
  while !data.isEmpty {
    if let pair = try? InstructionParser().parse(&data) {
      result.append(pair)
    } else {
      data = data.dropFirst()
    }
  }
  return result
}
```

Which is stepping through the entire string, dropping a character at a time and checking to see if the required pattern can be parsed off the front of the string.

I find this deeply unsatisfying: There should be a way to do this without having to be so explicit. But for now I'll leave it as one of my challenges for the New Year.

Only 3 days in and I'm struck by my lack of understanding of something. That's not necessarily a bad thing --- Finding out what I don't know is one of the reasons I do Advent of Code.
