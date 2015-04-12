##
## nrpl.nim
##
##
import os
import re
import strutils

const version = "0.1.2"
var cc = "tcc"  # C compiler to use for execution
var prefixLines = newSeq[string]()
var inBlockImmediate = false
var indentLevel = 0
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
  stdout.writeln(":indent - push current indent forward")
  stdout.writeln(":delete n[,m] - delete line or range of lines from history")
  stdout.writeln(":load filename - clears history and loads a file into history")
  stdout.writeln(":append filename - appends a file into history")
  stdout.writeln(":save filename - saves history to file")
  stdout.writeln(":run - run what's currently in history")
  stdout.writeln(":version - display the current version")
  stdout.writeln(":quit - exit REPL")

proc isStartBlock(line: string): bool =
  var ln = line.strip()
  var tokens = ln.split(re"\s")
  if (tokens[0] in blockStartKeywords) or (line.len == ln.len and ln.endsWith(":")):
    return true
  else:
    return false

proc isBlockImmediate(line: string): bool =
  var ln = line.strip()
  var tokens = ln.split(re"\s")
  if (tokens[0] in blockImmediateKeywords) or (line.len == ln.len and ln.endsWith(":")):
    return true
  else:
    return false

proc saveToFile(filename: string) =
  var outstr = ""
  for line in prefixLines:
    outstr.add(line & "\n")
  writeFile(filename, outstr)
  return

proc readFromFile(filename: string) =
  for line in filename.lines:
    prefixLines.add(line)
  return

while(true):
  let indent = ' '.repeat(indentLevel * 2)
  if indentLevel > 0:
    stdout.write("..")
    stdout.write(indent)
  else:
    stdout.write("> ")
  stdout.flushFile()
  var line = indent & stdin.readLine()

  if line.strip().len() == 0:
    if indentLevel > 0:
      indentLevel -= 1
    if prefixLines.len() ==  0 or inBlockImmediate == false:
      continue
    inBlockImmediate = false

  if isStartBlock(line):
    indentLevel += 1
    if isBlockImmediate(line):
      inBlockImmediate = true
    prefixLines.add(line)
    continue

  if indentLevel > 0 and line.strip().startsWith(":") == false:
    prefixLines.add(line)
    continue

  if line.strip().startsWith("#"):
    prefixLines.add(line)
    continue

  elif line.strip().startsWith("quit()") or line == ":quit" or line == ":q":
    break

  elif line == ":?" or line == ":help":
    printHelp()
    continue

  elif line == ":history" or line == ":h":
    var linum = 1
    for prefixLine in items(prefixLines):
      stdout.writeln(align(intToStr(linum), 3) & ": " & prefixLine)
      linum = linum + 1
    continue

  elif line == ":clear" or line == ":c":
    prefixLines = newSeq[string]()
    indentLevel = 0
    inBlockImmediate = false
    continue

  elif line == ":indent" or line == ":i":
    indentLevel += 1
    continue

  elif line.startsWith(":delete ") or line.startsWith(":d "):
    var tokens = line.strip().split(re":d(elete)?\s+")
    if tokens[0].contains(","):
      proc myStrip(s: string): string = s.strip()
      var lineNums = tokens[0].split(",").map(myStrip).map(parseInt)
      var lineNum = lineNums[0] - 1
      for x in 0..lineNums.len:
        prefixLines.delete(lineNum)
    else:
      var lineNum = parseInt(tokens[0]) - 1
      prefixLines.delete(lineNum)
    continue

  elif line == ":run" or line == ":r":
    if prefixLines.len() == 0:
      continue
    else:
      line = ""

  elif line.startsWith(":load ") or line.startsWith(":l "):
    var tokens = line.strip().split(re"\s")
    prefixLines = newSeq[string]()
    readFromFile(tokens[1])
    continue

  elif line.startsWith(":append ") or line.startsWith(":a "):
    var tokens = line.strip().split(re"\s")
    readFromFile(tokens[1])
    continue

  elif line.startsWith(":save ") or line.startsWith(":s "):
    var tokens = line.strip().split(re"\s")
    saveToFile(tokens[1])
    continue

  elif line == ":version" or line == ":v":
    echo(version)
    continue

  elif line.startsWith("import "):
    prefixLines.add(line)
    continue

  elif line =~ re"\s*(\w+)\s*\=\s*.*":
    prefixLines.add(line)
    continue


  prefixLines.add(line)
  var lines = join(prefixLines, "\n")
  writeFile("nrpltmp.nim", lines)
  try:
    let res = execShellCmd("nim --cc:" & cc & " --verbosity:0 -d:release -r c nrpltmp.nim")
    if res != 0 or line.contains("echo"):
      discard prefixLines.pop()
  except:
    break

removeFile("nrpltmp.nim")
removeFile("nrpltmp")
removeFile("nrpltmp.exe")
removeDir("nimcache")
quit()
