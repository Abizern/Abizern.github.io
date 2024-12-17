+++
title = "Advent of Code Day15: Warehouse Woes"
description = "Sometimes this feels like work"
date = 2024-12-17
tags = ["advent-of-code", "swift"]
draft = false
meta = true
math = false
+++

I actually got this{{<sidenote>}}https://adventofcode.com/2024/day/15{{</sidenote>}} done on the day, but haven't written it up because I'm not too happy with the way I got to my solution{{<sidenote>}}https://github.com/Abizern/aoc-swift-2024/blob/main/Sources/Day15.swift{{</sidenote>}}.

I'm not a fan of problems like this. You have a map and a process; it's just a case of writing out the process. Very much like the day job of a programmer - here's the current system, here are the new requirements: get on with it. At least with AoC I don't have to have my code pass anyone's review.

For some reason my parsing code wasn't working and I spent too long trying to debug that rather than just getting on with it. I ended up with a hybrid solution of splitting the input into two parts and then running parsers over each part.

We are supposed to take a map of the warehouse and a list of moves and then just process these moves over the grid.

A couple of things to note: Firstly, because the map is surrounded by walls, checking that points are within bounds are a lot easier. Any point you are at will get you 4 neighbours. Some of them may be wall tiles, but they will be valid entries on the grid. Secondly, things only move by one space, which makes checking valid moves easier.


## Part 1 {#part-1}

There really isn't much to this. I ended up with a recursive function:

```swift
func move(
  _ state: ((Int, Int), [[Character]]),
  dir: Character,
  tip: (Int, Int)? = nil,
  boxes: [(Int, Int)] = []
) -> ((Int, Int), [[Character]]) {
  var ((r, c), rows) = state

  let dr: Int
  let dc: Int

  switch dir {
  case "^": (dr, dc) = (-1, 0)
  case ">": (dr, dc) = (0, 1)
  case "v": (dr, dc) = (1, 0)
  case "<": (dr, dc) = (0, -1)
  default: fatalError("Unknown direction \(dir)")
  }

  let (nr, nc) = tip ?? (r + dr, c + dc)
  let candidate = rows[nr][nc]

  if candidate == "#" {
    return state
  } else if candidate == "." {
    for box in boxes {
      rows[box.0 + dr][box.1 + dc] = "O"
    }
    rows[r][c] = "."
    (r, c) = (r + dr, c + dc)
    rows[r][c] = "@"
    return ((r, c), rows)
  } else { // candidate = "O"
    let newTip = (nr + dr, nc + dc)
    let newBoxes = boxes + [(nr, nc)]
    return move(state, dir: dir, tip: newTip, boxes: newBoxes)
  }
}
```

I keep track of the tip of my search path, in whatever direction I am going and there are three conditions:

The tile is a wall: Nothing moves and I just return the original state of the map.

The tile is a space: I set the robot tile to ".", set the next tile in the given direction to "@" as the robot has moved, and then I take the pile of boxes that I've collected{{<sidenote>}}See the next condition{{</sidenote>}} and move them one position up in the given direction.

If the tile contains a box, this is the recursive case, I add it's position to the running `boxes` variable. This is what tracks all the boxes that have to be moved. and then move the tip (which is the next search tile) in the given direction. And I start again.

Since the whole, single width, stack is moving, I don't need to worry about resetting any empty tiles, because everything moves.


## Part 2 {#part-2}

With a bigger map, and a different way of handling boxes.

Horizontal moves are handled almost exactly the same way as with part 1, except now I keep track of the character than I am moving as well as its position.

```swift
func moveHorizontally(_ state: (Cell, [[Character]]), hOffset: Int, nextPos: Cell, boxes: [Cell: Character]) -> (Cell, [[Character]]) {
  var (robot, rows) = state
  var boxes = boxes
  let candidate = rows[nextPos.row][nextPos.col]

  guard candidate != "#" else {
    return state
  }

  if candidate == "." {
    for (key, value) in boxes {
      rows[key.row][key.col + hOffset] = value
    }
    rows[robot.row][robot.col] = "."

    rows[robot.row][robot.col + hOffset] = "@"
    return (Cell(robot.row, robot.col + hOffset), rows)
  }

  if candidate == "[" || candidate == "]" {
    boxes[nextPos] = candidate
    let newNextPos = Cell((nextPos.row, nextPos.col + hOffset))

    return moveHorizontally(state, hOffset: hOffset, nextPos: newNextPos, boxes: boxes)
  }

  fatalError("We should have handled something by now.")
}
```

For vertical moves I have to handle things a little differently: Rather than a single point being the "tip" of the search, it can be a row, which is everything connected to the robot.

```swift
func moveVertically(_ state: (Cell, [[Character]]), vOffset: Int, nextPos: [Cell], boxes: [Cell: Character]) -> (Cell, [[Character]]) {
  var (robot, rows) = state
  var boxes = boxes
  let candidates = nextPos.map { rows[$0.row][$0.col] }

  if candidates.contains("#") {
    return state
  }

  if candidates.allSatisfy({ $0 == "." }) {
    for (key, _) in boxes {
      rows[key.row][key.col] = "."
    }
    for (key, value) in boxes {
      rows[key.row + vOffset][key.col] = value
    }
    rows[robot.row][robot.col] = "."
    rows[robot.row + vOffset][robot.col] = "@"
    return (Cell(robot.row + vOffset, robot.col), rows)
  }

  if candidates.contains("[") || candidates.contains("]") {
    var candidateBoxes = nextPos.map { ($0, rows[$0.row][$0.col]) }.sorted { $0.0.col < $1.0.col }

    if let lst = candidateBoxes.last, lst.1 == "[" {
      let (rightRow, rightCol) = (lst.0.row, lst.0.col + 1)
      candidateBoxes.append((Cell((rightRow, rightCol)), rows[rightRow][rightCol]))
    }

    if let fst = candidateBoxes.first, fst.1 == "]" {
      let (leftRow, leftCol) = (fst.0.row, fst.0.col - 1)
      candidateBoxes.append((Cell((leftRow, leftCol)), rows[leftRow][leftCol]))
    }

    var newNextPos: [Cell] = []
    for (cell, value) in candidateBoxes {
      if value == "[" || value == "]" {
        boxes[cell] = value
        newNextPos.append(Cell((cell.row + vOffset, cell.col)))
      }
    }

    return moveVertically(state, vOffset: vOffset, nextPos: newNextPos, boxes: boxes)
  }

  fatalError("We should have matched something by now")
}
```

I have to handle the ends of this row a little differently since boxes are in two parts. That's what the sorting and checking code is. I sort my list of moving candidates, if the leftmost point is "]" I know there is a "[" to it's left, and if there is a "[" at the right, then there is a "]" one cell over.

The same recursive process applies.

I then run these two recursive functions from a single non-recursive function:

```swift
func wideMove(_ state: (Cell, [[Character]]), dir: Character) -> (Cell, [[Character]]) {
  let (r, c) = (state.0.row, state.0.col)

  switch dir {
  case "^":
    let vOffset = -1
    return moveVertically(state, vOffset: vOffset, nextPos: [Cell((r + vOffset, c))], boxes: [:])
  case "v":
    let vOffset = 1
    return moveVertically(state, vOffset: vOffset, nextPos: [Cell((r + vOffset, c))], boxes: [:])
  case ">":
    let hOffset = 1
    return moveHorizontally(state, hOffset: hOffset, nextPos: Cell((r, c + hOffset)), boxes: [:])
  case "<":
    let hOffset = -1
    return moveHorizontally(state, hOffset: hOffset, nextPos: Cell((r, c + hOffset)), boxes: [:])
  default:
    fatalError("Unknown direction \(dir)")
  }
}
```

And that was it.

One of the only things that I managed to take from this was that I really thought about the recursive solution to part 2 and my code ran and gave me the correct answer at the first attempt. Unfortunately, I was a little sick of it by the time I'd finished that I can't bring myself to go back and tidy it up. Maybe I'll go back and tidy it up at some later date.
