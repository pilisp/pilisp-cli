import 'package:pilisp/pilisp.dart';
import 'package:pilisp_cli/pilisp_cli.dart';
import 'package:pilisp_cli/src/cli_repl/repl_adapter/vm.dart';
import 'package:pilisp_cli/src/pilisp_cli_impl.dart';
import 'package:test/test.dart';

void main() {
  group('/ pilisp_cli', () {
    group('/ completions', () {
      test('shared prefixes are filled in', () {
        expect(
            calculateSharedPrefix('mat', [
              'math/e',
              'math/ln10',
              'math/ln2',
              'math/log10e',
              'math/log2e',
              'math/pi',
              'math/sqrt1-2',
              'math/sqrt2',
            ]),
            'h/');
      });
    });
    group('/ loadFile', () {
      test('environment is mutated', () async {
        expect(await loadFile(piLispEnv, 'test/pilisp_cli_test.pil', []), 42);
        expect(PiLisp.loadString('test-answer'), 42);
      });
      test('future/await is awaited', () async {
        expect(await loadFile(piLispEnv, 'test/pilisp_cli_await_test.pil', []),
            21);
      });
    });
    group('/ eval', () {
      test('prints if not nil', () {
        expect(() => handleEval(piLispEnv, ['(+ 1 2 3 4 5)']), prints('15\n'));
        expect(() => handleEval(piLispEnv, ['nil']), prints(''));
      });
    });
  });
}
