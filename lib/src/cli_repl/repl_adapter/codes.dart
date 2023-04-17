library constants;

const startOfLine = 1;
const backward = 2;
const eof = 4;
const endOfLine = 5;
const forward = 6;
const tab = 9;
const clear = 12;
const carriageReturn = 13;
const newLine = 10;
const killToEnd = 11;
const killToStart = 21;
const ctrlW = 23;
const yank = 25;
const escape = 27;
const space = 32;
const arrowUp = 65;
const arrowDown = 66;
const arrowRight = 67;
const arrowLeft = 68;
const end = 70;
const home = 72;
const backspace = 127;

final String ansiEscape = String.fromCharCode(escape);

/// Returns the code of the first code unit.
int c(String s) => s.codeUnitAt(0);
