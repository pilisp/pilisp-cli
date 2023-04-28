import 'package:pilisp/pilisp.dart';
import 'package:pilisp_cli/pilisp_cli.dart' as pcli;

void main() {
  // NB. The pilisp package ships with piLispEnv as the default.
  pcli.cliMain(piLispEnv, [
    'eval',
    '(+ 1 2 3 4)',
    '(* 5 6 7 8)',
    '(map even? (range 10))',
  ]);
}
