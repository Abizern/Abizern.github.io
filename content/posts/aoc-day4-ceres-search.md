+++
title = "Advent of Code Day4: Ceres Search"
description = "I love the smell of Graph Theory in the morning. It smells like — coffee."
date = 2024-12-04
tags = ["advent-of-code", "swift"]
draft = false
meta = true
math = false
+++

Today{{<sidenote>}}https://adventofcode.com/2024/day/4{{</sidenote>}} wasn't so much about graph theory once you read the questions, but I took a similar approach to solving the problem. Parsing was trivial; just read a nested array of Characters.

My solution can be found on Github{{<sidenote>}}https://github.com/Abizern/aoc-swift-2024/blob/main/Sources/Day04.swift{{</sidenote>}}


## Part 1 {#part-1}

The word search game is about finding the word "XMAS" in any direction.

I used a simple search to get the positions of the Character "X" as a tuple, as my start positions.

With an enum to specify directions as compass points: North, North East, West etc

```swift
enum Direction: Equatable, CaseIterable {
  case n, ne, e, se, s, sw, w, nw // Compass points
}
```

Then I created a type to represent candidates:

```swift
struct Candidate {
  let partial: String
  let direction: Direction
  let position: (Int, Int)
  var isValid: Bool {
    partial == "XMAS"
  }
}
```

To start with, given a position for an "X" I created all possible candidates and put them in an array. This is what I meant when I said I took a graph theoretical approach, don't check the point, just add it to a list to check later. I did this with a method:

```swift
struct Candidate {
  // ...
  static func initial(row: Int, col: Int) -> [Candidate] {
    var accumulator = [Candidate]()
    for direction in Direction.allCases {
      accumulator.append(Candidate(partial: "X", direction: direction, position: (row, col)))
    }
    return accumulator
  }
}
```

Now I can use this to create an array of all the starting points with their directions to search.

```swift
func countOccurrencesAround(_ position: (Int, Int), rows: [[Character]]) -> Int {
  var count = 0
  let dimensions = (width: rows[0].count, height: rows.count)
  var candidates = Candidate.initial(row: position.0, col: position.1)[...]

  while let candidate = candidates.first {
    var newCandidates = candidates.dropFirst()
    if candidate.isValid {
      count += 1
      candidates = candidates.dropFirst()
    } else {
      if let next = candidate.next(rows: rows, dimensions: dimensions) {
        newCandidates.append(next)
      }
    }
    candidates = newCandidates
  }

  return count
}
```

For each candidate in this list, if it is valid, I increment the count of found words. If it is not valid, I try to create a new candidate, by adding a value in the search direction to the list. This creation method is long winded, but it's easy to write by following a process:

```swift
struct Candidate {
  // ...

  func next(rows: [[Character]], dimensions: (width: Int, height: Int)) -> Candidate? {
    guard "XMAS".hasPrefix(partial) else { return nil }

    var newRow = position.0
    var newCol = position.1
    switch direction {
    case .n:
      guard position.0 > 0
      else { return nil }
      newRow = position.0 - 1
    case .ne:
      guard position.0 > 0,
            position.1 < dimensions.height - 1
      else { return nil }
      newRow = position.0 - 1
      newCol = position.1 + 1
    case .e:
      guard position.1 < dimensions.width - 1
      else { return nil }
      newCol = position.1 + 1
    case .se:
      guard position.0 < dimensions.width - 1,
            position.1 < dimensions.height - 1
      else { return nil }
      newRow = position.0 + 1
      newCol = position.1 + 1
    case .s:
      guard position.0 < dimensions.height - 1
      else { return nil }
      newRow = position.0 + 1
    case .sw:
      guard position.0 < dimensions.width - 1,
            position.1 > 0
      else { return nil }
      newRow = position.0 + 1
      newCol = position.1 - 1
    case .w:
      guard position.1 > 0
      else { return nil }
      newCol = position.1 - 1
    case .nw:
      guard position.0 > 0,
            position.1 > 0
      else { return nil }
      newRow = position.0 - 1
      newCol = position.1 - 1
    }

    let value = rows[newRow][newCol]
    let newPartial = partial + String(value)
    return Candidate(partial: newPartial, direction: direction, position: (newRow, newCol))
  }
}
```

If the current partial string is not part of "XMAS" I return nil

If it is, then after some wordy checks to make sure the next search position is within the bounds of the grid I create a new candidate and add that to the end of the list.

By the time the list is empty, I've searched all valid candidates around the start position and I can return the count.

To get the answer, I map this function to each start point and sum the results:

```swift
func countOccurences(_ rows: [[Character]]) -> Int {
    let starts = findStarts("X", rows: rows)
    let count = starts.map {
      countOccurrencesAround($0, rows: rows)
    }.reduce(0, +)

    return count
  }
```

And that's it for the first part.


## Part 2 {#part-2}

This is simpler than part 1. I followed a similar method to part 1 by first finding all the possible start positions --- an "A" character.

```swift
func hasCross(_ position: (Int, Int), rows: [[Character]], dimensions: (width: Int, height: Int)) -> Bool {
  let row = position.0
  let col = position.1
  var result = false

  guard (1 ..< dimensions.width - 1).contains(row),
        (1 ..< dimensions.height - 1).contains(col)
  else { return false }

  let ne = rows[row + 1][col + 1]
  let se = rows[row + 1][col - 1]
  let sw = rows[row - 1][col - 1]
  let nw = rows[row - 1][col + 1]

  switch (nw, se) {
  case ("M", "S"):
    if (sw == "M" && ne == "S") || (sw == "S" && ne == "M") { result = true }
  case ("S", "M"):
    if (sw == "M" && ne == "S") || (sw == "S" && ne == "M") { result = true }
  default: result = false
  }
  return result
}
```

First, I make sure that the start position is at least one row and column in from the edge, and then I check the diagonally opposite corners. If one contains M the other must contain an S and vice-versa, I do this for both sets of corners, and if both checks pass then the position has a valid "X-MAS"

To get the solution I map this function onto the list of start points, filter them for validity and return the count.

```swift
func countCrosses(_ rows: [[Character]]) -> Int {
  let dimensions = (width: rows[0].count, height: rows.count)
  let starts = findStarts("A", rows: rows)
  let count = starts.map {
    hasCross($0, rows: rows, dimensions: dimensions)
  }.filter { $0 }.count

  return count
}
```


## Final Thoughts {#final-thoughts}

-   A recursive solution for each start point would have been an option, but I saw a grid and thought "graph theory" so I went with this method.
-   For previous Advents, I've used different languages, and created a small library of utility functions. Perhaps now is the time to do it for my Swift solutions. I want to write some common parsers, and maybe a `Grid` type would have been useful for wrapping bounds-checks and getting neighbouring positions would have made this a little shorter.
