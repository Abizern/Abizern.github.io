+++
title = "Advent of Code Day9: Disk Fragmenter"
description = "I should have read the question properly ☹️"
date = 2024-12-09
tags = ["advent-of-code", "swift"]
draft = false
meta = true
math = false
+++

I had a bit of difficulty today{{<sidenote>}}https://adventofcode.come/2024/day/9{{</sidenote>}} for two reasons. Firstly, Swift doesn't seem to be that good with deep recursions. I wanted to use a recursive solution, but my stack size grow too large. Secondly, I didn't read the requirements for part 2 properly, and it took me a while to figure out how to bubble files up into the empty slots.

I eventually got it done with an imperative loop{{<sidenote>}}https://github.com/Abizern/aoc-swift-2024/blob/main/Sources/Day09.swift{{</sidenote>}}


## Part 1 {#part-1}

Given a representation for a file system with file blocks and empty spaces, we are supposed to move files from the back into the empty spaces in the front and calculate a checksum.

I created a type to represent either a file block or a space, and this turned out to be helpful for part 2:

```swift
enum Descriptor: Equatable, CustomStringConvertible {
  case file(id: Int, length: Int)
  case empty(length: Int)

  var expanded: [Int] {
    switch self {
    case .file(let id, let length):
      Array(repeating: id, count: length)
    case .empty(let length):
      Array(repeating: Int.min, count: length)
    }
  }

  var fileId: Int {
    switch self {
    case .file(id: let id, length: _):
      id
    case .empty(length: _):
      Int.min
    }
  }

  var length: Int {
    switch self {
    case .file(_, let length):
      length
    case .empty(let length):
      length
    }
  }
}
```

This meant that the input was an array of these `Descriptors`

I expanded my list into a list of numbers that matches the examples by using the `expanded` var on my type. Then I read from both ends of this list, if there was a space in the front, I appended the last value that was not a space in it's place. I didn't keep track of the spaces at the end, because they did not contribute to the checksum.

```swift
func rearrange(_ input: Deque<Int>) -> [Int] {
  var input = input
  var accumulator: [Int] = []
  while let f = input.popFirst() {
    if f > Int.min {
      accumulator.append(f)
    } else if !input.isEmpty {
      accumulator.append(input.popLast()!)
      // Clear out spaces from the back
      while !input.isEmpty, input.last! == Int.min {
        input.removeLast()
      }
    } else {
      continue
    }
  }

  return accumulator
}
```

I then had a simple function to calculate the checksum

```swift
func checksum(_ input: [Int]) -> Int {
    input.enumerated().map(*).reduce(0, +)
  }
```

and the entire solution was just putting these together:

```swift
func part1() async throws -> Int {
  let files = Deque(diskMap.flatMap(\.expanded))
  let rearranged = rearrange(files)

  return checksum(rearranged)
}
```


## Part 2 {#part-2}

This is where I got stuck for a while. Rather than trying to move each fileID once, after every movement of a file block I tried to move the files at the back into any possible new spaces that were made available by the files being moved.

After I went through the example again, I kept track of the current fileID I was trying to move, but all my recursive code seemed to overrun the stack. I'm not sure if I was writing badly recurring code, or whether Swift not being optimised for recursion is an issue. I eventually managed to get my solution to work and my choice of data structure helped.

I run through the fileIDs in reverse, I find the length of the block to move, and then look for free space at the front. If it exists, I replace the old position with empty space and insert the the fileIDs in the space. If there is more space left over, I fill that with an empty block. Then I try the next lowest FileID.

When the fileID becomes `1` I return the list since the `0` files are at the front by definition.

```swift
unc defrag(_ input: [Descriptor]) -> [Descriptor] {
  var input = input[...]
  var highestIndex = input.last!.fileId

  while highestIndex > 0 {
    guard let candidateIndex = input.firstIndex(where: { $0.fileId == highestIndex }) else { fatalError("We should have fileID \(highestIndex)") }
    let candidateLength = input[candidateIndex].length

    guard let targetIndex = input.firstIndex(
      where: { descriptor in
        if case .empty(let length) = descriptor, length >= candidateLength {
          true
        } else {
          false
        }
      }
    ),
      targetIndex < candidateIndex
    else {
      highestIndex -= 1
      continue
    }

    input.replaceSubrange(candidateIndex ... candidateIndex, with: [.empty(length: candidateLength)])
    let targetLength = input[targetIndex].length
    let newTarget = Descriptor.file(id: highestIndex, length: candidateLength)
    if targetLength == candidateLength {
      input.replaceSubrange(targetIndex ... targetIndex, with: [newTarget])
    } else {
      input.replaceSubrange(targetIndex ... targetIndex, with: [newTarget, .empty(length: targetLength - candidateLength)])
    }

    highestIndex -= 1
  }

  return Array(input)
}
```

Once that is working, it's just a procedure to get the final result:

```swift
func part2() async throws -> Int {
  defrag(diskMap)
    .flatMap(\.expanded)
    .map { $0 > Int.min ? $0 : 0 }
    .enumerated()
    .map { $0 * $1 }
    .reduce(0, +)
}
```

And this still ran fairly quickly: in about 0.2s which is good enough.


## Final thoughts {#final-thoughts}

Recursion didn't work and it bothers me. When I get some time I'll try it in a different language to see if it works better there.

Reading the question is important. I'm usually diligent about it, but for some reason I was so concerned about my recursive code not working that I didn't think that maybe I was solving the wrong problem.
