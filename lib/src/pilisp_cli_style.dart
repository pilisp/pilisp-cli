import 'package:chalkdart/chalk.dart';

String styleString(Map<String, String> palette, String paletteKey, String s,
    {List<String>? styles}) {
  String hex;
  if (s.startsWith('#')) {
    hex = s;
  } else {
    hex = palette[paletteKey] ?? palette['__fallback']!;
  }
  return applyStringStyles(styles, chalk.hex(hex)(s));
}

String applyStringStyles(List<String>? styles, String s) {
  if (styles != null) {
    String finalString = s;
    for (final style in styles) {
      switch (style) {
        case 'dim':
          finalString = chalk.dim(finalString);
          break;
        case 'bold':
          finalString = chalk.bold(finalString);
          break;
        case 'underline':
          finalString = chalk.underline(finalString);
          break;
      }
    }
    return finalString;
  } else {
    return s;
  }
}

final styleBoolean = 'boolean';
final styleComment = 'comment';
final styleDateTime = 'date-time';
final styleError = 'error';
final styleInfo = 'info';
final styleNil = 'nil';
final styleNumber = 'number';
final stylePrompt = 'prompt';
final styleSubdued = 'subdued';
final styleTitle = 'title';
final styleUnderline = 'underline';
final styleWarn = 'warn';

final defaultDarkPalette = {
  'boolean': '#d96e7b',
  'comment': '#8c8d8c',
  'date-time': '#97c6e8',
  'error': '#e75569',
  '__fallback': '#8c8d8c',
  'file': '#d96e7b',
  'info': '#71b259',
  'nil': '#8c8d8c',
  'number': '#71b259',
  // 'prompt': '#ad87f3',
  'prompt': '#58b1e4',
  'string': '#e6d566',
  'subdued': '#575858',
  'symbol': '#ad87f3',
  'term': '#ad87f3',
  'title': '#97c6e8',
  // 'title': '#e6d566',
  // 'title': '#ccba45',
  'warn': '#e6d566',
};

// From https://lospec.com/palette-list/colorblind-16
final colorBlindDarkPalette = {
  'boolean': '#b66dff',
  'comment': '#676767',
  'date-time': '#97c6e8',
  'error': '#920000',
  '__fallback': '#676767',
  'file': '#ff6db6',
  'info': '#22cf22',
  'nil': '#676767',
  'number': '#22cf22',
  'prompt': '#006ddb',
  'string': '#ffdf4d',
  'subdued': '#676767',
  'symbol': '#b66dff',
  'term': '#b66dff',
  'title': '#ffffff',
  'unstarted': '#920000',
  'warn': '#ffdf4d',

  // "#000000",
  // "#252525",
  // "#676767",
  // "#ffffff",
  // "#171723",
  // "#004949",
  // "#009999",
  // "#22cf22",
  // "#490092",
  // "#006ddb",
  // "#b66dff",
  // "#ff6db6",
  // "#920000",
  // "#8f4e00",
  // "#db6d00",
  // "#ffdf4d",
};

// final defaultLightPalette = {
//   'comment': '#8c8d8c',
//   'done': '#56993d',
//   'epic workflow state': '#444444',
//   'epic workflow': '#444444',
//   'epic': '#56993d',
//   '__fallback': '#444444',
//   'iteration': '#61a3cf',
//   'label': '#c3a73f',
//   'member': '#658ee7',
//   'milestone': '#df8632',
//   'prompt': '#ad87f3',
//   'started': '#5c1bd2',
//   'story': '#5c1bd2',
//   'subdued': '#575858',
//   'task': '#ad87f3',
//   'team': '#224bb3',
//   'title': '#50ab54',
//   'unstarted': '#931f17',
//   'workflow state': '#444444',
//   'workflow': '#444444',
// };

// final colorblindLightColors = {};
