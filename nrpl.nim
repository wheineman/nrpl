##
## nrpl.nim
##
##
import os
import nre
import options
import strutils
import sequtils
import rdstdin

const version = "0.2.0"

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
  echo(":? - print this help")
  echo(":help - print this help")
  echo(":history - show history")
  echo(":clear - clear history")
  echo(":indent - push current indent forward")
  echo(":delete n[,m] - delete line or range of lines from history")
  echo(":load filename - clears history and loads a file into history")
  echo(":append filename - appends a file into history")
  echo(":save filename - saves history to file")
  echo(":run - run what's currently in history")
  echo(":version - display the current version")
  echo(":quit - exit REPL")

proc isStartBlock(line: string): bool =
  var ln = line.strip()
  var tokens = ln.split(re"\s")
  var keyword = tokens[0]
  if (keyword in blockStartKeywords) or (line.len == ln.len and ln.endsWith(":")):
    if keyword == "var" or keyword == "let":
      return not (ln.len > keyword.len)
    else:
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
  var prompt = "> "
  if indentLevel > 0:
    prompt = "  ".repeat(indentLevel + 1)
    stdout.write(indent)
  else:
    stdout.flushFile()
  var line: string
  try:
    line = readLineFromSTDIN(prompt)
  except IOError:
    break

  line = indent & line

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
      echo(align(intToStr(linum), 3) & ": " & prefixLine)
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

  elif line.match(re"\s*(\w+)\s*\=\s*.*").isSome:
    prefixLines.add(line)
    continue


  prefixLines.add(line)
  var lines = join(prefixLines, "\n")
  writeFile("nrpltmp.nim", lines)
  try:
    let res = execShellCmd("nim --cc:" & cc & " --verbosity:0 -d:release --parallelBuild:1 -r c nrpltmp.nim")
    if res != 0 or line.strip().startsWith("echo"):
      discard prefixLines.pop()
  except:
    break

removeFile("nrpltmp.nim")
removeFile("nrpltmp")
removeFile("nrpltmp.exe")
removeDir("nimcache")
quit()
