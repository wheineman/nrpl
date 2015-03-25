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
  if line.strip().len() == 0:
    continue
  if line.strip().startsWith("#"):
    continue
  if line.strip().startsWith("quit()") or line == ":quit":
    break

  if line.startsWith("import "):
    prefixLines.add(line)
    continue

  var lines = join(prefixLines, "\n") & "\n" & line
  writeFile("nrpltmp.nim", lines)
  try:
    discard execShellCmd("nim --cc:tcc --verbosity:0 -d:release -r c nrpltmp.nim")
  except:
    break

removeFile("nrpltmp.nim")
removeFile("nrpltmp")
removeFile("nrpltmp.exe")
removeDir("nimcache")
quit()
