##
## nrpl.nim
##
##
import os
import osproc
import re
import strutils
import parseopt
import sequtils

const version = "0.1.5" # TODO: get from nrpl.nimble

## C compiler to use for execution
when defined(macosx):
  var nrpl_cc = "clang" ## tcc seems badly supported, see: https://github.com/wheineman/nrpl/issues/16
else:
  var nrpl_cc = "tcc"

var prefixLines = newSeq[string]()
var inBlock = false
var inBlockImmediate = false

let blockStartKeywords =
  ["var", "let",
   "proc", "method", "iterator", "macro", "template", "converter",
   "type", "const",
   "block", "if", "when", "while", "case", "for",
    "try:"]

let blockImmediateKeywords =
  ["block", "if", "when", "while", "case", "for", "try:"]

let errorsNotDisplayed =
  ["is declared but not used [XDeclaredButNotUsed]"]

proc printHelp(): void =
  stdout.writeLine(":? - print this help")
  stdout.writeLine(":help - print this help")
  stdout.writeLine(":history - show history")
  stdout.writeLine(":clear - clear history")
  stdout.writeLine(":delete n[,m] - delete line or range of lines from history")
  stdout.writeLine(":load filename - clears history and loads a file into history")
  stdout.writeLine(":append filename - appends a file into history")
  stdout.writeLine(":save filename - saves history to file")
  stdout.writeLine(":run - run what's currently in history")
  stdout.writeLine(":version - display the current version")
  stdout.writeLine(":quit - exit REPL")

proc isStartBlock(line: string): bool =
  var ln = line.strip()
  var tokens = ln.split(re"\s")
  if (tokens[0] in blockStartKeywords) or (line.len == ln.len and ln.endsWith(":")):
    if (tokens[0] in ["let", "var"]):
      if ln != tokens[0]:
        return false
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
  for line in filename.lines():
    prefixLines.add(line)
  return

proc isErrorNotDisplayed(line: string): bool =
  var returnValue = false
  for errorNotDisplayed in errorsNotDisplayed:
    if line.contains(errorNotDisplayed):
      returnValue = true
      break
  return returnValue

proc runLoop() = 
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

    elif line.startsWith(":delete ") or line.startsWith(":d "):
      var tokens = line.strip().split(re":d(elete)?\s+")
      if tokens[1].contains(","):
        proc myStrip(s: string): string = s.strip()
        var lineNums = tokens[1].split(",").map(myStrip).map(parseInt)
        var lineNum = lineNums[0] - 1
        for x in lineNums[0]..lineNums[1]:
          if lineNum < prefixLines.len():
            prefixLines.delete(lineNum)
          else:
            echo "Error: Line number outside range of lines."
            break
      else:
        var lineNum = parseInt(tokens[1]) - 1
        if lineNum < prefixLines.len():
          prefixLines.delete(lineNum)
        else:
          echo "Error: Line number outside range of lines."
      continue

    elif line.strip().startsWith("quit()") or line == ":quit" or line == ":q":
      break

    elif line == ":?" or line == ":help":
      printHelp()
      continue

    elif line == ":history" or line == ":h":
      var linum = 1
      for prefixLine in items(prefixLines):
        stdout.writeLine(align(intToStr(linum), 3) & ": " & prefixLine)
        linum = linum + 1
      stdout.writeLine("")
      continue

    elif line == ":clear" or line == ":c":
      prefixLines = newSeq[string]()
      inBlock = false
      inBlockImmediate = false
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
      #TODO: we probably want to optimize for compilation speed, so `-d:release` seems wrong
      let result = execCmdEx("nim --cc:" & nrpl_cc & " --verbosity:0 -d:release -r c nrpltmp.nim")
      for rline in splitLines(result.output):
        if not(isErrorNotDisplayed(rline)):
          if rline.strip().len() > 0:
            stdout.writeLine(rline)
      if line.contains("echo"):
        discard prefixLines.pop()
    except:
      break

  # NOTE: not guaranteed to run if error occurs
  removeFile("nrpltmp.nim")
  removeFile("nrpltmp")
  removeFile("nrpltmp.exe")
  removeDir("nimcache")
  quit()

proc help(): auto = 
  # TODO: find a more standard formatting
  return """
  --help(h): get help
  --version(v): get version
  --cc:<compiler> use compiler (eg:[tcc], clang)
"""

proc main() =
  var p = initOptParser()
  for kind, key, val in p.getopt():
    # writelnL kind, key, val
    case kind
    of cmdArgument: doAssert false, help()
    of cmdLongOption, cmdShortOption:
      case key
      of "help", "h": echo help(); return
      of "version", "v": echo version; return
      of "cc": nrpl_cc = val
      else: doAssert false, help()
    of cmdEnd: doAssert false # cannot happen
  runLoop()

main()
