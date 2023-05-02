import 'package:pilisp/pilisp.dart';
import 'package:pilisp_cli/pilisp_cli.dart';
import 'package:pilisp_cli/src/cli_repl/repl_adapter/vm.dart';
import 'package:pilisp_cli/src/pilisp_cli_impl.dart';
import 'package:test/test.dart';

void main() {
  group('/ pilisp_cli', () {
    group('/ cliMain', () {
      group('/ load command', () {
        test('/ *command-line-args* includes all arguments', () {
          expect(
              () => cliMain(piLispEnv,
                  ['load', '--file', 'test/pilisp_cli_load_test.pil']),
              prints('3\n'));
        });
        test('/ --no-print does not print final value', () {
          expect(
              () => cliMain(piLispEnv, [
                    'load',
                    '--no-print',
                    '--file',
                    'test/pilisp_cli_load_test.pil'
                  ]),
              prints(''));
        });
      });
      group('/ eval command', () {
        test('/ evaluates and prints final expression', () {
          expect(
              () => cliMain(piLispEnv,
                  ['eval', '(def test-wow 42)', '(reduce + (range 10))']),
              prints('45\n'));
          expect(PiLisp.loadString('test-wow'), 42);
        });
        test('/ --no-print does not print final value', () {
          expect(
              () => cliMain(
                  piLispEnv, ['eval', '--no-print', '(reduce + (range 10))']),
              prints(''));
        });
      });
    });
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
        expect(await loadFile(piLispEnv, 'test/pilisp_cli_test.pil'), 42);
        expect(PiLisp.loadString('test-answer'), 42);
      });
      test('future/await is awaited', () async {
        expect(await loadFile(piLispEnv, 'test/pilisp_cli_await_test.pil'), 21);
      });
    });
    group('/ eval', () {
      test('does not print by default', () {
        expect(() => handleEval(piLispEnv, ['(+ 1 2 3 4 5)']), prints(''));
      });
      test('prints if specified and not nil', () {
        expect(
            () => handleEval(piLispEnv, ['(+ 1 2 3 4 5)'], shouldPrint: true),
            prints('15\n'));
        expect(() => handleEval(piLispEnv, ['nil'], shouldPrint: true),
            prints(''));
      });
    });
  });
}
