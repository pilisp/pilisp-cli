import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:async/async.dart';
import 'package:pilisp_cli/src/pilisp_cli_style.dart';

import '../../cli_repl.dart';
import 'codes.dart';

final RegExp promptPattern = RegExp(r'^(pl[^>]*>\s*)+');

class ReplAdapter {
  Repl repl;

  ReplAdapter(this.repl);

  Iterable<String> run() sync* {
    try {
      // Try to set up for interactive session
      stdin.echoMode = false;
      stdin.lineMode = false;
    } on StdinException {
      // If it can't, print both input and prompts (useful for testing)
      yield* linesToStatements(inputLines());
      return;
    }
    while (true) {
      try {
        var result = readStatement();
        if (result == null) {
          print("");
          break;
        }
        yield result;
      } on Exception catch (e) {
        print(e);
      }
    }
    exit();
  }

  Iterable<String> inputLines() sync* {
    while (true) {
      try {
        String? line = stdin.readLineSync();
        if (line == null) break;
        yield line;
      } on StdinException {
        break;
      }
    }
  }

  Stream<String> runAsync() {
    bool interactive = true;
    try {
      stdin.echoMode = false;
      stdin.lineMode = false;
    } on StdinException {
      interactive = false;
    }

    late StreamController<String> controller;
    controller = StreamController(
        onListen: () async {
          try {
            var charQueue =
                this.charQueue = StreamQueue<int>(stdin.expand((data) => data));
            while (true) {
              if (!interactive && !(await charQueue.hasNext)) {
                this.charQueue = null;
                controller.close();
                return;
              }

              var result = await _readStatementAsync(charQueue);
              if (result == null) {
                print("");
                break;
              }
              controller.add(result);
            }
          } catch (error, stackTrace) {
            controller.addError(error, stackTrace);
            await exit();
            controller.close();
          }
        },
        onCancel: exit,
        sync: true);

    return controller.stream;
  }

  FutureOr<void> exit() {
    try {
      stdin.lineMode = true;
      stdin.echoMode = true;
    } on StdinException {
      stderr.writeln('StdinException');
    }

    charQueue?.cancel(immediate: true);
    charQueue = null;
  }

  Iterable<String> linesToStatements(Iterable<String> lines) sync* {
    String previous = "";
    for (var line in lines) {
      write(previous == "" ? repl.prompt : repl.continuation);
      previous += line;
      stdout.writeln(line);
      if (repl.validator(previous)) {
        yield previous;
        previous = "";
      } else {
        previous += '\n';
      }
    }
  }

  StreamQueue<int>? charQueue;

  List<int> buffer = [];
  int cursor = 0;

  setCursor(int c) {
    if (c < 0) {
      c = 0;
    } else if (c > buffer.length) {
      c = buffer.length;
    }
    moveCursor(c - cursor);
    cursor = c;
  }

  write(String text) {
    stdout.write(text);
  }

  writeChar(int char) {
    stdout.writeCharCode(char);
  }

  int historyIndex = -1;
  String currentSaved = "";

  String previousLines = "";
  bool inContinuation = false;

  String? readStatement() {
    startReadStatement();
    while (true) {
      int char = stdin.readByteSync();
      if (char == eof && buffer.isEmpty) return null;
      if (char == escape) {
        var char = stdin.readByteSync();
        if (char == c('[') || char == c('O')) {
          var ansi = stdin.readByteSync();
          if (!handleAnsi(ansi)) {
            write('^[');
            input(char);
            input(ansi);
          }
          continue;
        }
        write('^[');
      }
      var result = processCharacter(char);
      if (result != null) return result;
    }
  }

  Future<String?> _readStatementAsync(StreamQueue<int> charQueue) async {
    startReadStatement();
    while (true) {
      int char = await charQueue.next;
      if (char == eof && buffer.isEmpty) return null;
      if (char == escape) {
        char = await charQueue.next;
        if (char == c('[') || char == c('O')) {
          var ansi = await charQueue.next;
          if (!handleAnsi(ansi)) {
            write('^[');
            input(char);
            input(ansi);
          }
          continue;
        }
        write('^[');
      }
      var result = processCharacter(char);
      if (result != null) return result;
    }
  }

  void startReadStatement() {
    write(repl.prompt);
    buffer.clear();
    cursor = 0;
    historyIndex = -1;
    currentSaved = "";
    inContinuation = false;
    previousLines = "";
  }

  List<int> yanked = [];
  bool areCompletionResultsVisible = false;

  String? processCharacter(int char) {
    if (char != tab) {
      if (areCompletionResultsVisible) {
        clearCompletionResults();
      }
    }
    switch (char) {
      case eof:
        if (cursor != buffer.length) delete(1);
        break;
      case clear:
        clearScreen();
        break;
      case backspace:
        if (cursor > 0) {
          setCursor(cursor - 1);
          delete(1);
        }
        break;
      case ctrlW:
        int searchCursor = cursor - 1;
        while (true) {
          if (searchCursor == -1) {
            break;
          } else {
            final codePoint = buffer[searchCursor];
            if (codePoint == space ||
                codePoint == c('.') ||
                codePoint == c('-') ||
                codePoint == c('_') ||
                codePoint == c('{') ||
                codePoint == c('}') ||
                codePoint == c('(') ||
                codePoint == c(')') ||
                codePoint == c('[') ||
                codePoint == c(']') ||
                codePoint == c('"')) {
              // Handle multiple ctrlW and swallow one space + next whole word
              if (searchCursor != cursor - 1) {
                break;
              }
            }
          }
          searchCursor--;
        }
        if (cursor == 0 && searchCursor == -1) {
          break;
        } else {
          final numToDelete = cursor - searchCursor;
          setCursor(searchCursor + 1);
          delete(numToDelete - 1);
        }
        break;
      case killToEnd:
        yanked = delete(buffer.length - cursor);
        break;
      case killToStart:
        int oldCursor = cursor;
        setCursor(0);
        yanked = delete(oldCursor);
        break;
      case yank:
        yanked.forEach(input);
        break;
      case startOfLine:
        setCursor(0);
        break;
      case endOfLine:
        setCursor(buffer.length);
        break;
      case forward:
        setCursor(cursor + 1);
        break;
      case backward:
        setCursor(cursor - 1);
        break;
      case tab:
        List<int> autoCompleteCodePoints = [];
        int searchCursor = cursor - 1;
        while (true) {
          if (searchCursor == -1) {
            break;
          } else {
            final codePoint = buffer[searchCursor];
            if (codePoint == space ||
                codePoint == c('{') ||
                codePoint == c('}') ||
                codePoint == c('(') ||
                codePoint == c(')') ||
                codePoint == c('[') ||
                codePoint == c(']')) {
              break;
            } else {
              autoCompleteCodePoints.add(codePoint);
            }
          }
          searchCursor--;
        }
        if (autoCompleteCodePoints.isNotEmpty) {
          final completionPrefix =
              String.fromCharCodes(autoCompleteCodePoints.reversed);
          final completions = repl.completionsFor(completionPrefix);
          if (completions.isNotEmpty) {
            if (completions.length == 1) {
              // If one result, write its suffix directly into buffer.
              clearCompletionResults();
              var autoCompletion = completions.first;
              if (completionPrefix.startsWith('.')) {
                autoCompletion =
                    autoCompletion.substring(completionPrefix.length - 1);
              } else {
                autoCompletion =
                    autoCompletion.substring(completionPrefix.length);
              }
              for (final byte in utf8.encode(autoCompletion)) {
                input(byte);
              }
            } else {
              // Show autocomplete results
              String sharedFurtherPrefix =
                  calculateSharedPrefix(completionPrefix, completions);
              if (sharedFurtherPrefix.isNotEmpty) {
                for (final byte in utf8.encode(sharedFurtherPrefix)) {
                  input(byte);
                }
              }

              saveCursorPosition();
              clearCompletionResults();
              // moveCursorDown(1);
              // clearToEnd(); // clear from here to end, to remove previous autocomplete results
              write('\n');
              final prefixLength =
                  completionPrefix.length + sharedFurtherPrefix.length;
              for (final autoCompletion in completions) {
                String s;
                if (completionPrefix.startsWith('.')) {
                  s = autoCompletion.substring(prefixLength - 1);
                } else {
                  s = autoCompletion.substring(prefixLength);
                }
                write(styleString(defaultDarkPalette, styleSubdued,
                    completionPrefix + sharedFurtherPrefix));
                write(s);
                write(' ');
              }
              areCompletionResultsVisible = true;
              restoreCursorPosition();
              // moveCursorUp(1);
            }
          } else {
            areCompletionResultsVisible = false;
          }
        }
        break;
      case carriageReturn:
      case newLine:
        String contents = String.fromCharCodes(buffer);
        setCursor(buffer.length);
        input(char);
        if (repl.history.isEmpty || contents != repl.history.first) {
          // repl.history.insert(0, contents);
          repl.history.insert(0, contents.replaceFirst(promptPattern, ''));
        }
        while (repl.history.length > repl.maxHistory) {
          repl.history.removeLast();
        }
        if (char == carriageReturn) {
          write('\n');
        }
        if (repl.validator(previousLines + contents)) {
          return previousLines + contents;
        }
        previousLines += '$contents\n';
        buffer.clear();
        cursor = 0;
        clearToEnd(); // remove previous auto-complete results
        inContinuation = true;
        write(repl.continuation);
        break;
      default:
        input(char);
        break;
    }
    return null;
  }

  input(int char) {
    buffer.insert(cursor++, char);
    write(String.fromCharCodes(buffer.skip(cursor - 1)));
    moveCursor(-(buffer.length - cursor));
  }

  List<int> delete(int amount) {
    if (amount <= 0) return [];
    int wipeAmount = buffer.length - cursor;
    if (amount > wipeAmount) amount = wipeAmount;
    write(' ' * wipeAmount);
    moveCursor(-wipeAmount);
    var result = buffer.sublist(cursor, cursor + amount);
    for (int i = 0; i < amount; i++) {
      buffer.removeAt(cursor);
    }
    write(String.fromCharCodes(buffer.skip(cursor)));
    moveCursor(-(buffer.length - cursor));
    return result;
  }

  replaceWith(String text) {
    moveCursor(-cursor);
    write(' ' * buffer.length);
    moveCursor(-buffer.length);
    write(text);
    buffer.clear();
    buffer.addAll(text.codeUnits);
    cursor = buffer.length;
  }

  bool handleAnsi(int char) {
    if (areCompletionResultsVisible) {
      clearCompletionResults();
    }
    switch (char) {
      case arrowLeft:
        setCursor(cursor - 1);
        return true;
      case arrowRight:
        setCursor(cursor + 1);
        return true;
      case arrowUp:
        if (historyIndex + 1 < repl.history.length) {
          if (historyIndex == -1) {
            currentSaved = String.fromCharCodes(buffer);
          } else {
            repl.history[historyIndex] = String.fromCharCodes(buffer);
          }
          replaceWith(repl.history[++historyIndex]);
        }
        return true;
      case arrowDown:
        if (historyIndex > 0) {
          repl.history[historyIndex] = String.fromCharCodes(buffer);
          replaceWith(repl.history[--historyIndex]);
        } else if (historyIndex == 0) {
          historyIndex--;
          replaceWith(currentSaved);
        }
        return true;
      case home:
        setCursor(0);
        return true;
      case end:
        setCursor(buffer.length);
        return true;
      default:
        return false;
    }
  }

  moveCursor(int amount) {
    if (amount == 0) return;
    int amt = amount < 0 ? -amount : amount;
    String dir = amount < 0 ? 'D' : 'C';
    write('$ansiEscape[$amt$dir');
  }

  moveCursorUp(int amount) {
    write('$ansiEscape[${amount}A');
  }

  moveCursorDown(int amount) {
    write('$ansiEscape[${amount}B');
  }

  moveCursorToLineStart(int amount) {
    write('\r');
  }

  clearCompletionResults() {
    saveCursorPosition();
    moveCursorDown(1);
    moveCursorToLineStart(1);
    clearToEnd();
    restoreCursorPosition();
    areCompletionResultsVisible = false;
  }

  /// Clears screen from current cursor to end of screen.
  clearToEnd() {
    write('$ansiEscape[J');
  }

  saveCursorPosition() {
    write('${ansiEscape}7');
  }

  restoreCursorPosition() {
    write('${ansiEscape}8');
  }

  clearScreen() {
    write('$ansiEscape[2J'); // clear
    write('$ansiEscape[H'); // return home
    rewriteBuffer();
  }

  rewriteBuffer() {
    write(inContinuation ? repl.continuation : repl.prompt);
    write(String.fromCharCodes(buffer));
    moveCursor(cursor - buffer.length);
  }

  clearBuffer() {
    // NB: This resets all of the stateful things in this class.
    startReadStatement();
  }
}

/// Return shared further prefix for the given strings, so that autocomplete
/// is even more helpful.
String calculateSharedPrefix(
    String completionPrefix, Iterable<String> completions) {
  if (completions.isEmpty) {
    return '';
  } else {
    final prefixLength = completionPrefix.length;
    String sharedFurtherPrefix = completions.first.substring(prefixLength);
    for (final completion in completions.skip(1)) {
      if (sharedFurtherPrefix.isEmpty) {
        return '';
      } else {
        final restOfCompletion = completion.substring(prefixLength);
        final restOfCompletionCodeUnits = restOfCompletion.codeUnits;
        final sharedFurtherPrefixCodeUnits = sharedFurtherPrefix.codeUnits;
        List<int> newSharedFurtherPrefix = [];
        for (int i = 0;
            i <
                min(restOfCompletionCodeUnits.length,
                    sharedFurtherPrefixCodeUnits.length);
            i++) {
          final sharCu = sharedFurtherPrefixCodeUnits[i];
          final restCu = restOfCompletionCodeUnits[i];
          if (sharCu == restCu) {
            newSharedFurtherPrefix.add(restCu);
          }
        }
        sharedFurtherPrefix = String.fromCharCodes(newSharedFurtherPrefix);
      }
    }
    return sharedFurtherPrefix;
  }
}
