+++
title = "Advent of Code Day8: Resonant Collinearity"
description = "Maybe this explains my spotty WiFi coverage"
date = 2024-12-08
tags = ["advent-of-code", "swift"]
draft = false
meta = true
math = false
+++

We are given a grid of antennas{{<sidenote>}}https://adventofcode.come/2024/day/8{{</sidenote>}} and we're supposed to find which ones line up and find points that extend from them, and count the unique positions where they occur.

There aren't that may points. I wrote, what I thought was a quick and dirty solution, but both parts ran in about 1ms, so I didn't think it was worth doing much cleaning up.

I'm not going to show the code here, if you'd like to see it, the solution is online{{<sidenote>}}https://github.com/Abizern/aoc-swift-2024/blob/main/Sources/Day08.swift{{</sidenote>}}. I'll concentrate on the reasoning.


## Part 1 {#part-1}

To find an antinode between two antennas of the same time, work out the changes to the rows and columns to get to `target` from `source` and add that offset to `target`

I parsed out the antennas, and used the Swift-Algorithms package{{<sidenote>}}https://github.com/apple/swift-algorithms{{</sidenote>}} to generate a product of this list. Which gave me a pair of every antenna with every other antenna.

Each pair is a `(source, target)` pair.

If both antennas are the same, ignore the pair.

If the antennas are of different types ignore the pair.

Work out the offset between the two antennas: the change in row and column to get to `target` from `source`.

add this offset to `target` to get the antinode along the line from `source` to `target`

Check that this antinode is within the boundary otherwise ignore it.

I only check for the antinode in one direcion. Since I am taking a product of every node with every other node, the antinode in the opposite direction when I eventually examine `(target, source)`.

After I get these, I throw them in a set to remove duplicates and then count the set to get the result.


## Part 2 {#part-2}

There are two differences that need to be accounted for:

-   Antinodes are produced all along the line to the boundaries.
-   Antennas on the same line are also antinodes.

To take account of this:

For each pair I add the `source` point to the list of antinodes returned. I only add source, because the `target` antenna will be considered when I eventually examine the transposed pair.

Rather than add the offset once, I keep adding offsets while they remain with the bounds.

After I get these, I create sets from the results and combine them to remove duplicates and count them. This also took less than 1ms


## Notes {#notes}

Both solutions ran in under 1ms. There are days when I come up with a quick solution to part 1 just so that I can get on to part 2. After than I try and refactor the two solutions. Both parts ran fast enough today that I don't feel it's necessary.

I expected a harder problem for the first weekend, but I'm okay being proved wrong, I'm sure those days are coming.
