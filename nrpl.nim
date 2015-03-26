##
## nrpl.nim
##
##
import os
import re
import strutils

var prefixLines = newSeq[string]()
var inBlock = false
var blockStartKeywords =
  ["var", "let",
   "proc", "method", "iterator", "macro", "template", "converter",
   "type", "const",
   "block", "if", "when", "while", "case", "for",
    "try:"]

var blockImmediateKeywords =
  ["block", "if", "when", "while", "case", "for", "try:"]

proc printHelp(): void =
  stdout.writeln(":? - print this help")
  stdout.writeln(":help - print this help")
  stdout.writeln(":history - show history")
  stdout.writeln(":clear - clear history")
  stdout.writeln(":run - run what's currently in history")
  stdout.writeln(":quit - exit REPL")

proc isStartBlock(line: string): bool =
  var ln = line.strip()
  var tokens = ln.split(re"\s")
  if tokens[0] in blockStartKeywords:
    return true
  else:
    return false

proc isBlockImmediate(line: string): bool =
  var ln = line.strip()
  var tokens = ln.split(re"\s")
  if tokens[0] in blockImmediateKeywords:
    return true
  else:
    return false

while(true):
  if inBlock:
    stdout.write("- ")
  else:
    stdout.write("> ")
  stdout.flushFile()
  var line = stdin.readLine()

  if line.strip().len() == 0:
    if inBlock:
      inBlock = false
    if prefixLines.len() ==  0 or isBlockImmediate(prefixLines[0]) == false:
      continue

  if inBlock and line.strip().startsWith(":") == false:
    prefixLines.add(line)
    continue

  if isStartBlock(line):
    inBlock = true
    prefixLines.add(line)
    continue

  if line.strip().startsWith("#"):
    continue

  if line.strip().startsWith("quit()") or line == ":quit":
    break

  if line == ":?" or line == ":help":
    printHelp()
    continue

  if line == ":history":
    for prefixLine in items(prefixLines):
      stdout.writeln(prefixLine)
    continue

  if line == ":clear":
    prefixLines = newSeq[string]()
    inBlock = false
    continue

  if line == ":run":
    if prefixLines.len() == 0:
      continue
    else:
      line = ""

  if line.startsWith("import "):
    prefixLines.add(line)
    continue

  if line =~ re"\s*(\w+)\s*\=\s*.*":
    prefixLines.add(line)
    continue


  prefixLines.add(line)
  var lines = join(prefixLines, "\n")
  writeFile("nrpltmp.nim", lines)
  try:
    discard execShellCmd("nim --cc:tcc --verbosity:0 -d:release -r c nrpltmp.nim")
    discard prefixLines.pop()
  except:
    break

removeFile("nrpltmp.nim")
removeFile("nrpltmp")
removeFile("nrpltmp.exe")
removeDir("nimcache")
quit()
