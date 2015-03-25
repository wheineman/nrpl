# nrpl
Crude Nim REPL

Based on an idea from here, <http://hookrace.net/blog/what-makes-nim-practical/>, this is a crude Read Evaluate Print Loop (REPL) for Nim using TCC to quickly compile each Read. It's quite crude, but supports simple imports and can be used in it's current incarnation to explore modules and APIs. For now, other than import statements, there is no deferred (or multiline) execution. You can however string together multiple statements using semi-colons to separate them.

Requirements:
Nim installed and in your PATH.
TCC installed and in your PATH.

Compile the source:
```
nim -d:release c nrpl.nim
```
Tested on Linux and Windows 8.1

Sample execution:
```
nrpl
> import math
> echo(sqrt(2))
> 1.414213562373095
> # comments can be used
> # crude multiple statement execution
> var a:int; a = 6 * 7; echo(a)
> 42
> # use either quit() or :quit to exit
> quit()
```
