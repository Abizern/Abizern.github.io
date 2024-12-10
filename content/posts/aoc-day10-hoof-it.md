+++
title = "Advent of Code Day10: Hoof It"
description = "Easier than expected, don't look a gift reindeer in the mouth."
date = 2024-12-10
tags = ["advent-of-code", "swift"]
draft = false
meta = true
math = false
+++

I was expecting a Graph{{<sidenote>}}https://adventofcode.come/2024/day/9{{</sidenote>}} problem to show up around now, and it as a good time to create a utility `Grid` class to make working with these 2D graphs a little easier.

Unlike yesterday's{{<sidenote>}}https://abizern.dev/posts/aoc-day9-disk-fragmenter/{{</sidenote>}} debacle, I read the question carefully. I took care to only count one start -- end point as a route, which meant that part 2 was quite easy to do. I ended up refactoring both methods into one, but I'll show the original methods here because it might make for a clearer explanation


## Part 1 {#part-1}

My grid type takes care of returning neighbours of a point {{<sidenote>}}Which I represent with a Cell struct to refer to a point in a grid{{</sidenote>}} and only returning valid cells that are within bounds.

Given a staring position (which I find by looking for all the Cells with value 0) I calculate the score using:

```swift
func score(_ grid: Grid<Int>, start: Cell) -> Int {
  var count = 0
  var queue = Deque<Cell>([start])
  var ends = Set<Cell>()

  while !queue.isEmpty {
    let cursor = queue.removeFirst()

    guard let cursorValue = grid.element(cursor),
          cursorValue != 9
    else {
      if !ends.contains(cursor) {
        count += 1
        ends.insert(cursor)
      }
      continue
    }

    let neighbours = grid
      .neighbours(cursor, includeDiagonals: false)
      .filter { grid.element($0)! - cursorValue == 1 }
    queue.append(contentsOf: neighbours)
  }

  return count
}
```

I set up some variables to track the count and the endpoints of each trailhead I also set up a queue to store the candidates to consider{{<sidenote>}}I did something similar for Day 4 https://abizern.dev/posts/aoc-day4-ceres-search/{{</sidenote>}}, and initialise it with the position of the start point.

Then go through the list, taking a value from it as long as there are values to be taken. Most loops will add a value to this list and it is how the routes are calculated.

```swift
let cursor = queue.removeFirst()
```

if the value is not an end point, get all the neighbours that have values that are strictly one more than the value of the current point and add them to the queue. Since the condition is looking for greater values, there is no need to worry about backtracking.

```swift
let neighbours = grid
  .neighbours(cursor, includeDiagonals: false)
  .filter { grid.element($0)! - cursorValue == 1 }
queue.append(contentsOf: neighbours)
```

if the value is 9, we have reached the end of the trail

```swift
guard let cursorValue = grid.element(cursor),
      cursorValue != 9
else {
  if !ends.contains(cursor) {
    count += 1
    ends.insert(cursor)
  }
  continue
}
```

We check whether we have already found the end point. The requirement is that we find the longest path, but the length doesn't matter as we are not doing anything with the length. If there are multiple paths, one of them is bound to be the longest. If I've found the path I just move on to the next cell in the list without incrementing the count.

Running the code to get the answer:

```swift
func part1() async throws -> Int {
  trailHeads(grid).map { score(grid, start: $0) }.reduce(0, +)
}
```


## Part 2 {#part-2}

For the second part, there is no need to check if we have already considered the end point. We have to find all paths, and this is made easier by the requirement that the value is always increasing, so there are no loops.

The code is a simplified version of that used for part 1

```swift
func rating(_ grid: Grid<Int>, start: Cell) -> Int {
  var count = 0
  var queue = Deque<Cell>([start])

  while !queue.isEmpty {
    let cursor = queue.removeFirst()

    guard let cursorValue = grid.element(cursor),
          cursorValue != 9
    else {
      count += 1
      continue
    }

    let neighbours = grid
      .neighbours(cursor, includeDiagonals: false)
      .filter { grid.element($0)! - cursorValue == 1 }
    queue.append(contentsOf: neighbours)
  }

  return count
}
```

```swift
func part2() async throws -> Int {
  trailHeads(grid).map { rating(grid, start: $0) }.reduce(0, +)
}
```


## Tidying Up {#tidying-up}

The code is so similar that I rewrote it to a single function. The full solution is on Github{{<sidenote>}}https://github.com/Abizern/aoc-swift-2024/blob/main/Sources/Day10.swift{{</sidenote>}}.

```swift
func trailCount(_ grid: Grid<Int>, start: Cell, allPaths: Bool = false) -> Int {
  var count = 0
  var queue = Deque<Cell>([start])
  var ends = Set<Cell>()

  while !queue.isEmpty {
    let cursor = queue.removeFirst()
    let cursorValue = grid.element(cursor)!

    if cursorValue == 9 {
      switch (allPaths, ends.contains(cursor)) {
      case (false, false):
        count += 1
        ends.insert(cursor)
      case (false, true):
        continue
      case (true, _):
        count += 1
        continue
      }
    }

    let neighbours = grid
      .neighbours(cursor, includeDiagonals: false)
      .filter { grid.element($0)! - cursorValue == 1 }
    queue.append(contentsOf: neighbours)
  }

  return count
}
```

Which takes a flag that controls whether unique paths are counted or all paths.

And the code to get the answer is similar for both parts.

```swift
func part1() async throws -> Int {
  trailHeads(grid)
    .map { trailCount(grid, start: $0, allPaths: false) }
    .reduce(0, +)
}

func part2() async throws -> Int {
  trailHeads(grid)
    .map { trailCount(grid, start: $0, allPaths: true) }
    .reduce(0, +)
}
```

I'm not sure what the final part of the puzzle is about -- why is the reindeer making flags? Maybe this problem will appear later on in the series?
