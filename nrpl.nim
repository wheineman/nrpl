##
## nrpl.nim
##
##
import os
import strutils

var prefixLines = newSeq[string]()

while(true):
  stdout.write("> ")
  stdout.flushFile()
  var line = stdin.readLine()
  if line == "quit()" or line == ":quit":
    break;

  if line.startsWith("import "):
    prefixLines.add(line)
    continue;

  var lines = join(prefixLines, "\n") & "\n" & line
  writeFile("tmp.nim", lines)
  try:
    discard execShellCmd("nim --cc:tcc --verbosity:0 -d:release -r c tmp.nim")
  except:
    break

quit()
