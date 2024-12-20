+++
title = "Advent of Code Day20: Race Condition"
description = "In which I give up on my beloved GameplayKit"
date = 2024-12-20
tags = ["advent-of-code", "swift"]
draft = false
meta = true
math = false
+++

Took a while to get this done today. I started late and my solutions for both parts took around 20 seconds each. Good enough to get my answers, then I refactored it to get a better solution that ran both parts in less than 1s

We have another maze{{<sidenote>}}https://adventofcode.com/2024/day/20{{</sidenote>}} problem, with the ability of cutting through walls to give shorter paths.


## Part 1 {#part-1}

Using GameplayKit which I seem to have taken to as my grid walking method of choice{{<marginnote>}}Unfortunately, this was not to last past today.{{</marginnote>}} I created a grid. First I went through the nodes and found those that were walls. And also those that could be candidates for tunnelling through. I picked those as the ones that have three neighbours that are path points.

I then remove the nodes that are walls, which leaves me with a graph created by GameplayKit. And I use it's methods to generate the path{{<sidenote>}}We are helpfully told that there is only one path.{{</sidenote>}} from start to end.

```swift
func bruteForce(from rows: [[Character]], target: Int) -> Int {
  let graph = GKGridGraph(
    fromGridStartingAt: vector_int2(0, 0),
    width: Int32(rows[0].count),
    height: Int32(rows.count),
    diagonalsAllowed: false,
    nodeClass: Node.self
  )

  var walls: [Node] = []
  var candidates: [[Node]] = []
  var start: Node = graph.nodes!.first! as! Node
  var end: Node = graph.nodes!.first! as! Node
  for node in graph.nodes! {
    let node = node as! Node
    let position = node.gridPosition
    let value = rows[Int(position.y)][Int(position.x)]
    switch value {
    case "#":
      walls.append(node)
    case "S":
      start = node
      continue
    case "E":
      end = node
      continue
    default:
      continue
    }
    let neighbours = (node.connectedNodes as! [Node]).filter { n in
      rows[Int(n.gridPosition.y)][Int(n.gridPosition.x)] != "#"
    }
    if neighbours.count > 1 {
      candidates.append(neighbours)
    }
  }

  graph.remove(walls)
  let path = graph.findPath(from: start, to: end) as! [Node]

  let shortened = candidates.filter { candidates in
    guard let s = candidates.first,
          let e = candidates.last,
          let sIndex = path.firstIndex(of: s),
          let eIndex = path.firstIndex(of: e)
    else { return false }
    return abs(eIndex - sIndex) >= target + 2
  }

  return shortened.count
}
```

I then go through the list of nodes that are separated by walls and see if the first and last ones are the requisite distance apart. Yes, I can see that there is a bug in that, I put up to three Nodes in each element, but I only check two I am fortunate that I got the right answer.

This ran, but it took around 20s for part 1. Not too bothered, because I like to get the first answer quickly and tidy it up during the second part.


## Part 2 {#part-2}

Now having more time to think about it, I came up with a better way of defining the solution. The parts I am showing use my own Grid class from my utilities package{{<sidenote>}}https://github.com/Abizern/AoCCommon{{</sidenote>}} which is just a wrapper around rows of Characters. I first used the same algorithm with GameplayKit, but it took over 20s for **each** part which I didn't think was acceptable, and writing out my path search directly gave me much better performance.

First I created a found the path from the start to the end point and represented that in a dictionary. The keys of this dictionary are each Cell along the path, and the value is the distance from the start along the path.

```swift
func track(_ rows: [[Character]]) -> [Cell: Int] {
  let grid = Grid(rows: rows)

  let start = grid.firstCell(for: "S")!
  let end = grid.firstCell(for: "E")!

  var path: [Cell] = []
  var queue: Deque<[Cell]> = [[start]]
  var seen: Set<Cell> = []

  while !queue.isEmpty && path.isEmpty {
    let currentPath = queue.removeFirst()
    let head = currentPath.last!
    if head == end {
      path = currentPath
      continue
    }
    if seen.contains(head) {
      continue
    }
    else {
      seen.insert(head)
    }
    let neighbours = grid.neighbours(head, includeDiagonals: false)
    for neighbour in neighbours {
      guard grid.element(neighbour) != "#",
            !seen.contains(neighbour)
      else {
        continue
      }
      queue.append(currentPath + [neighbour])
    }
  }

  var dict = [Cell: Int]()
  for (distance, position) in path.enumerated() {
    dict[position] = distance
  }

  return dict
}
```

Then I created a method to return all Cells that are a given distance from a Cell, along with the number of steps it takes to get there. For Part 1 this will be 2, for Part 2 this will be 20.

```swift
func targets(from: Cell, distance: Int) -> [(Cell, Int)] {
  var cells: [(Cell, Int)] = []
  for r in -distance ... distance {
    for c in -distance ... distance {
      guard abs(r) + abs(c) <= distance
      else {
        continue
      }
      cells.append((Cell(from.row + r, from.col + c), abs(r) + abs(c)))
    }
  }
  return cells
}
```

Now the actual solution method:

```swift
func countCheats(_ track: [Cell: Int], radius: Int, minReduction reduction: Int) -> Int {
  let path = track.sorted { $0.value < $1.value }
  return path.map { cell, distance in
    var candidates: Set<Cell> = []
    let targets = targets(from: cell, distance: radius)
    for (c, d) in targets {
      guard let dd = track[c],
            !candidates.contains(c),
            dd >= distance + d + reduction
      else {
        continue
      }
      candidates.insert(c)
    }
    return candidates.count

  }.reduce(0, +)
}
```

I sort the keys by the path length, so I'm going forwards along the points that make up the path.

```swift
let path = track.sorted { $0.value < $1.value }
```

I map this array of cells and distances. So that I am examining each point along the route

I create a set to hold possible cheat points. I use a set because cheats are identified by their start and end point, not the route they took.

I then generate the candidates, all the cells within the radius that I can tunnel through to.

```swift
guard let dd = track[c],
      !candidates.contains(c),
      dd >= distance + d + reduction
else {
  continue
}
```

I get the distance of the current point from the start and compare it to the distance from the start of any point than I can tunnel through to. If the difference in length is greater than the target of 100, accounting for the time it takes to tunnel through to that point, then I add it as a possible cheat point.

I then count the number of cheat point for each point, and sum them to get the answer. The same function works for both parts.

```swift
func part1() async throws -> Int {
  countCheats(track, radius: 2, minReduction: 100)
}

func part2() async throws -> Int {
  countCheats(track, radius: 20, minReduction: 100)
}
```


## Final Thoughts {#final-thoughts}

For context, the full code is on Github{{<sidenote>}}https://github.com/Abizern/aoc-swift-2024/blob/main/Sources/Day20.swift{{</sidenote>}}.

I'm a little sad I couldn't get the best out of GameplayKit. I assume that it's able to do far more things than these simple puzzles require it to do, so the overhead swamps any performance I can squeeze out by writing very specific code.

I'm also surprised that I've managed to get to day 20 only missing 3 stars.
