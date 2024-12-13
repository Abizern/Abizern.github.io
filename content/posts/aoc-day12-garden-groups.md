+++
title = "Advent of Code Day12: Garden Groups"
description = "I see flood fills everywhere."
date = 2024-12-13T04:50:00Z
tags = ["advent-of-code", "swift"]
draft = false
meta = true
math = false
+++

Today's challenge{{<sidenote>}}https://adventofcode.com/2024/day/12{{</sidenote>}} felt very strange to me. I read the question. I knew what I had to do for Part 1, but I didn't feel very motivated to actually finish my implementation. I pushed through and eventually got it done, then spent too long thinking about how to do Part 2 before I realised that it was more or less the same approach as for part 1, just with different parameters.


## Part 1 {#part-1}

Given a grid of a farm and its crops we are supposed to work out some number based on the area and the perimeter.

The approach I used was that of flood filling. I take a point from the graph and do a search for all its neighbours that have the same crop type, and I keep doing that until I have found all connected plots of the same type. I keep track of the plots that I have seen so I don't double count them, and do this for all the plots.

Counting the number of plots in each region gives me the area.

Since I was using GameplayKit to help me with my graph, I went through and removed all edges that weren't connected to a plot of the same type. For each plot I then work out the number of sides by subtracting the number of graph edges it has to other plots from 4. Then multiply and sum to get the first answer.

```swift
extension Day12 {
  typealias GridGraph = GKGridGraph<GKGridGraphNode>
  typealias Node = GKGridGraphNode

  func farm(from rows: [[Character]]) -> GridGraph {
    let width = Int32(rows[0].count)
    let height = Int32(rows.count)
    let origin = vector_int2(0, 0)
    let graph = GKGridGraph(
      fromGridStartingAt: origin,
      width: width,
      height: height,
      diagonalsAllowed: false,
      nodeClass: Node.self
    )

    for node in graph.nodes! {
      let node = node as! Node
      let position = node.gridPosition
      let (row, column) = (Int(position.y), Int(position.x))

      for neighbor in node.connectedNodes {
        let neighbor = neighbor as! Node
        let nPosition = neighbor.gridPosition
        let (nRow, nColumn) = (Int(nPosition.y), Int(nPosition.x))

        if rows[nRow][nColumn] != rows[row][column] {
          node.removeConnections(to: [neighbor], bidirectional: true)
        }
      }
    }

    return graph
  }

  func regions(from graph: GridGraph, rows _: [[Character]]) -> [Set<Node>] {
    var regions: [Set<Node>] = []
    var seen: Set<Node> = []

    for node in graph.nodes! {
      let node = node as! Node
      guard !seen.contains(node) else { continue }

      var stack = [node]
      var currentRegion = Set<Node>()

      while !stack.isEmpty {
        let currentNode = stack.removeLast()
        guard !seen.contains(currentNode) else { continue }
        seen.insert(currentNode)
        currentRegion.insert(currentNode)

        // Add unvisited neighbors of the same region to the stack
        for neighbor in currentNode.connectedNodes {
          let neighbor = neighbor as! Node
          if !seen.contains(neighbor) {
            stack.append(neighbor)
          }
        }
      }

      if !currentRegion.isEmpty {
        regions.append(currentRegion)
      }
    }

    return regions
  }

  func price(_ region: Set<Node>) -> Int {
    let area = region.count
    let perimeter = region.reduce(0) { partialResult, node in
      partialResult + 4 - node.connectedNodes.count
    }

    return area * perimeter
  }
}
```


## Part 2 {#part-2}

This took a lot more thought before I bit the bullet and wrote the code.

I defined a struct to represent and edge for a plot:

```swift
struct Edge: Hashable {
   enum Direction: Hashable {
     case top, right, bottom, left
   }

   let position: vector_int2
   let direction: Direction

   var neighbours: [Edge] {
     let x = position.x
     let y = position.y
     switch direction {
     case .top, .bottom:
       return [
         Edge(position: vector_int2(x: x + 1, y: y), direction: direction),
         Edge(position: vector_int2(x: x - 1, y: y), direction: direction),
       ]
     case .right, .left:
       return [
         Edge(position: vector_int2(x: x, y: y + 1), direction: direction),
         Edge(position: vector_int2(x: x, y: y - 1), direction: direction),
       ]
     }
   }
 }
```

This also gives me the neighbours I expect to have in horizontal and vertical directions.

I already have a function for working out a connected region, and I use that to generate all the plot edges:

```swift
func edges(for region: Set<Node>) -> Set<Edge> {
  var edges: Set<Edge> = []

  for node in region {
    let position = node.gridPosition
    let above = position.above
    let below = position.below
    let left = position.left
    let right = position.right

    let neighbours = node.connectedNodes.map { $0 as! Node }.map(\.gridPosition)
    if !neighbours.contains(above) {
      edges.insert(Edge(position: position, direction: .top))
    }

    if !neighbours.contains(below) {
      edges.insert(Edge(position: position, direction: .bottom))
    }

    if !neighbours.contains(left) {
      edges.insert(Edge(position: position, direction: .left))
    }

    if !neighbours.contains(right) {
      edges.insert(Edge(position: position, direction: .right))
    }
  }
  return edges
}
```

Now I use the same flood filling to find all the connected edges. I take an edge off the list, and generate it's expected neighbours and count them up.

```swift
func sides(for region: Set<Node>) -> Int {
  let edges = edges(for: region)
  var totalSides = 0
  var seen = Set<Edge>()

  for edge in edges {
    guard !seen.contains(edge) else { continue }
    var stack = Deque<Edge>([edge])

    while !stack.isEmpty {
      let current = stack.removeFirst()
      guard !seen.contains(current) else { continue }
      seen.insert(current)

      for neighbour in current.neighbours {
        guard !seen.contains(neighbour) else { continue }
        if edges.contains(neighbour) {
          stack.append(neighbour)
        }
      }
    }

    totalSides += 1
  }
  return totalSides
}
```

And that gave me the correct answer.

As usual, the full code for this is on Github{{<sidenote>}}https://github.com/Abizern/aoc-swift-2024/blob/main/Sources/Day12.swift{{</sidenote>}}. It felt like a slog, I don't mind telling you.
