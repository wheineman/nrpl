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
var inBlock = false
var inBlockImmediate = false
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
  if inBlock:
    stdout.write("- ")
  else:
    stdout.write("> ")
  stdout.flushFile()
  var line = stdin.readLine()

  if line.strip().len() == 0:
    if inBlock:
      inBlock = false
    if prefixLines.len() ==  0 or inBlockImmediate == false:
      continue
    inBlockImmediate = false

  if inBlock and line.strip().startsWith(":") == false:
    prefixLines.add(line)
    continue

  if isStartBlock(line):
    inBlock = true
    if isBlockImmediate(line):
      inBlockImmediate = true
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
    inBlock = false
    inBlockImmediate = false
    continue

  elif line.startsWith(":delete ") or line.startsWith(":d "):
    proc myStrip(s: string): string = s.strip()

    try:
      var numbers =
        line.strip()
            .replace(re":d(elete)?\s+", "")
            .split(re"[,\s]+")
            .map(myStrip)
            .map(parseInt)

      if numbers.len == 2:
        var lineNum = numbers[0] - 1
        for x in numbers[0]..numbers[1]:
          prefixLines.delete(lineNum)
      elif numbers.len == 1:
        var lineNum = numbers[0] - 1
        prefixLines.delete(lineNum)
      else:
        echo "syntax: :delete from[,to]"
    except RangeError:
      echo "Invalid line numbers"
    except ValueError:
      echo "syntax: :delete from[,to]"
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
