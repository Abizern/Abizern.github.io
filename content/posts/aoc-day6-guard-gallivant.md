+++
title = "Advent of Code Day6: Guard Gallivant"
description = "💂‍♀️ Please don't touch the reins: The elves may bite!"
date = 2024-12-06
tags = ["advent-of-code", "swift"]
draft = false
meta = true
math = false
+++

Another{{<sidenote>}}https://adventofcode.com/2024/day/6{{</sidenote>}} grid traversal and the longest solution{{<sidenote>}}https://github.com/Abizern/aoc-swift-2024/blob/main/Sources/Day06.swift{{</sidenote>}} I've had to write so far.

Not just the longest solution; my first attempt at part 2 took around 6s to run, I managed to get this to around 0.5s. Maybe I could be more efficient, maybe I'm missing the trick to make this faster.

There isn't much to say about the solutions, so I'll keep those sections short: there is a link to my solution if you want to see the details. The interesting part is making it run faster, since I couldn't make it more efficient, I went for running it concurrently.

Frankly, I don't really like the code for my solution. There's some repetition, and I'm traversing the graph with a loop rather than being recursive and it just seems clunky.  But that's okay. This isn't code for work and there are bound to be days when I'm not really feeling it. I can always go back to it later{{<marginnote>}}Unlikely that I will{{</marginnote>}}

Not helped by my constantly writing `guard` as a variable name which I shouldn't do in swift because it's a reserved word. I know I can escape such variables with backticks, but I didn't think my variable name was crucial enough to have to do that.


## Part 1 {#part-1}

Find all the positions that the guard visits.

This is really just a case of following the rules of movement, keeping a set of positions visited and then returning the count.


## Part 2 {#part-2}

I couldn't think of a clever algorithm for this. Just to get an answer done went through every location that the guard visited and put an obstacle there, then ran the path to see if it looped, or if the guard could leave the grid. To check for a loop, I checked the position of the guard and the direction. If that was already in the set of visited positions, I took it to be a loop, because the same path would continue to be followed.

Since only one obstacle could be added, it would have to be in one of the places that the guard visited, so that reduced the size of the search set.

This was good enough to get me an answer.


## Making things faster {#making-things-faster}

My first attempt ran okay and gave me the correct answer an about 6 seconds. That's not too bad, but it's a little annoying. Sometimes I run all my solutions at once, and a big stall in the middle of the output would annoy me.

I tried to make things faster by checking if there was an obstacle in the new path {{<sidenote>}}If there isn't an obstacle{{</sidenote>}}. That was a little faster, running in around 4-5 seconds. Better, but not by much.

Normally, I wouldn't try and solve these problems in parallel. There are many operations, but they are short, there are just lots of them. But I don't have to run them all individually, I can run chunks of them individually. Playing around with various sizes for the chunks give me these estimates for Part 2

| Chunk Size | Part 2 time (s) |
|------------|-----------------|
| 1          | 42              |
| 10         | 3.3             |
| 30         | 0.6             |
| 50         | 0.5             |
| 100        | 0.5             |
| 200        | 0.5             |
| ...        | ...             |

And it plateaued at around 0.5s. Not as fast as the other solutions so far this year, but 10 times faster than not using concurrency.


## Final Thoughts {#final-thoughts}

-   We're starting to see the outline of the image on the main page - it looks like it could be the number 10, containing various other images from the previous years puzzles.
-   I wasn't too enthused by today's challenge. I got a solution with some quick and dirty code and came back to it on and off during the day to see if I could do it better.
-   Writing these daily summaries is working out to keep me working on the puzzles in a reasonable time. I wanted to get a better solution before writing this. I may have postponed it otherwise.
-   The next two days are weekends, and from past experience, that's when things start getting harder.
