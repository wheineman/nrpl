# nrpl
Crude Nim REPL

Based on an idea from here, <http://hookrace.net/blog/what-makes-nim-practical/>, this is a crude Read Evaluate Print Loop (REPL) for Nim using TCC to quickly compile each Read. It's quite crude, but supports deferred (or multiline) entry and execution. I'm creating this as a way to explore nim outside of the normal edit, compile, and run cycle although that's exactly what's going on behind the scene. In its current incarnation it is not intended as a development environment and it may not work exactly the way you want it to. That said, if you want to explore the features of Nim or explore some of the available modules, or try out a piece of code, it will do.

Requirements:
Nim installed and in your PATH.
TCC installed and in your PATH.

Compile the source:
```
nim -d:release c nrpl.nim
```
Tested on Linux and Windows 8.1 with both the stable and devel versions of Nim

Sample execution:
```
nrpl
> import math
> echo(sqrt(2))
1.414213562373095
> # comments can be used
> # crude multiple statement execution
> var a:int; a = 6 * 7; echo(a)
42
> # use either quit() or :quit to exit
> quit()
```
Multi-line or deferred entry and execution is supported based on the following keywords: "var", "let", "proc", "method", "iterator", "macro", "template", "converter", "type", "const",  "block", "if", "when", "while", "case", "for", "try". When a line starts with one of these keywords, the lines are stored in a history buffer. In multi-line or deferred entry is indicated by the line prompt changing from "> " to "- ". Entering an empty line will revert back to immediate mode. If the keyword at the start of deferred block is "block", "if, "when", "while", "case", "for", or "try" then deferred block will be executed upon exit of deferred entry mode. Otherwise the deferred block will be invoked when the first immediate line is executed. Some examples might help.

This example demonstrates entering a proc and executing it:
```
$ nrpl
> proc test() =
-   echo "Hello"
-
> # note that we entered an empty line to exit the deferred mode
> test()
Hello
> :quit
```

This example demonstrated multiple var entry:
```
$ nrpl
> var
-   a = 6
-   b = 7
-   c = 8
-
> echo(a * b + c)
50
> :quit
```

This example shows an if statement that will be executed on exit of deferred mode:
```
$ nimscript nrpl.nim
> if 6 * 7 == 42:
-   echo("6 * 7 is 42 and all's right in the universe")
- else:
-   echo("Something is terribly wrong")
-
6 * 7 is 42 and all's right in the universe
> :quit
```
And here's an example from Rosetta Code:
```
$ nrpl
> proc Fibonacci(n: int, current: int64, next: int64): int64 =
-   if n == 0:
-     result = current
-   else:
-     result = Fibonacci(n - 1, next, current + next)
- proc Fibonacci(n: int): int64 =
-   result = Fibonacci(n, 0, 1)
-
> echo(Fibonacci(5))
5
> echo(Fibonacci(10))
55
> echo(Fibonacci(20))
6765
> echo(Fibonacci(30))
832040
>
```

There are some immediate commands, that begin with a colon. You can access them by entering ":help" or ":?" at any prompt. The current ones are:
```
> :help
:? - print this help
:help - print this help
:history - show history
:clear - clear history
:run - run what's currently in history
:quit - exit REPL
>
```

Using nrpl in a Windows cmd shell or powershell will provide some history handling, i.e. the ability to use the up arrow and down arrow to recall lines. Under Linux you can use rlwrap to provide the same functionality:

```
rlwrap nrpl
```
