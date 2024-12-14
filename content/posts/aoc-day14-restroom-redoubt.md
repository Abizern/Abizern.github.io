+++
title = "Advent of Code Day14: Restroom Redoubt"
description = "Easter Eggs in a Christmas themed puzzle?"
date = 2024-12-14T14:30:00Z
tags = ["advent-of-code", "swift"]
draft = false
meta = true
math = false
+++

I think this{{<sidenote>}}https://adventofcode.com/2024/day/14{{</sidenote>}} was a short one because part2 wasn't the easiest to come up with a definitive answer.


## Part 1 {#part-1}

I think I'm getting better with parsing inputs, I got this into my system quickly and the rest of it was just writing a simulation for 100 iterations, counting locations and figuring out the safety score.

It probably isn't worth putting the code itself here, but it's available{{<sidenote>}}https://github.com/Abizern/aoc-swift-2024/blob/main/Sources/Day14.swift{{</sidenote>}} on Github.


## Part 2 {#part-2}

No way to write a test for this, and I wasn't going to cycle through all the possibilities to look for a tree. And there wasn't a description of the tree. Thinking it could have something to do with the solution to part 1, I looked at varies points, if any quadrants we empty, or symmetric, but it turned out that finding the **minimum of the safety score**, is the answer. You can see the output of my tree{{<sidenote>}}[aoc-tree.txt](/img/2024/12/aoc-tree.txt){{</sidenote>}} as a text file.
