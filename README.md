Shared code for running a rudimentary command-line interface to the PiLisp programming language.

Designed originally for use with the [pilisp] and [pilisp-native] projects.

## Features

* Convenient `cliMain` function that expects a `PLEnv` instance and your program's `main` arguments and provides:
   * PiLisp REPL if no arguments passed
   * `-h` / `--help` to print usage
   * `-l` / `--load` to load and interpret a file of PiLisp code
      * Binds the symbol `*command-line-args*` to the subsequent command-line arguments passed in.
   * `-r` / `--repl` to run a PiLisp REPL
* Public `repl` and `loadFile` functions for starting a PiLisp REPL and loading a PiLisp file, respectively.

## Getting started

```shell
$ dart pub add pilisp_cli
```

Then for your Dart program's entry-point, let's say `bin/cli.dart`:

```dart
import 'package:pilisp/pilisp.dart';
import 'package:pilisp_cli/pilisp_cli.dart' as pcli;

void main(List<String> args) {
  // piLispEnv is the default provided by the pilisp package
  pcli.cliMain(piLispEnv, args);
}
```

Now try running a REPL:

```shell
$ dart run bin/cli.dart
pl>
```

## Usage

### Dart Usage

As show in Getting Started, this is the simplest integration of the pilisp_cli package that
proxies your main handling to the `cliMain` function:

```dart
import 'package:pilisp/pilisp.dart';
import 'package:pilisp_cli/pilisp_cli.dart' as pcli;

void main(List<String> args) {
  // piLispEnv is the default provided by the pilisp package
  pcli.cliMain(piLispEnv, args);
}
```

If you do not want to use `cliMain` for parsing arguments, etc., you can use this package's
other functions directly.

To start a PiLisp REPL:

```dart
import 'package:pilisp/pilisp.dart';
import 'package:pilisp_cli/pilisp_cli.dart' as pcli;

void main(List<String> args) {
  // Start a REPL
  pcli.repl(piLispEnv);
}
```

To load a PiLisp file:

```dart
import 'package:pilisp/pilisp.dart';
import 'package:pilisp_cli/pilisp_cli.dart' as pcli;

void main(List<String> args) {
  // Load a file, pass args that become *command-line-args* in PiLisp
  pcli.loadFile(piLispEnv, '/path/to/a/file', args);
}
```

You can also change the `piLispEnv` or create your own `PLEnv` instance and pass that to these functions. The primary reason for doing so would be to change or add default language bindings. See [this file in pilisp-native][pilisp-native-env] for a non-trivial example of extending the default `PLEnv`.

### CLI Usage

We can use the [main example] found in this project to demonstrate how the CLI behaves:

```shell
$ dart run example/pilisp_cli_main_example.dart
pl>
```

```shell
$ dart run example/pilisp_cli_main_example.dart -l example/example.pil a b c
You passed in 3 command-line arguments: a, b, c
nil
```

## Additional information

Read up on PiLisp in these repositories:

* [pilisp]
* [pilisp-native]

## License

Copyright © Daniel Gregoire 2023

[Eclipse Public License - v 2.0](https://www.eclipse.org/org/documents/epl-2.0/EPL-2.0.txt)

    THE ACCOMPANYING PROGRAM IS PROVIDED UNDER THE TERMS OF THIS ECLIPSE
    PUBLIC LICENSE ("AGREEMENT"). ANY USE, REPRODUCTION OR DISTRIBUTION
    OF THE PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THIS AGREEMENT.

### Exceptions

**Project:** cli\_repl

The cli\_repl code in this project has been copied and adapted from the [cli_repl](https://github.com/jathak/cli_repl) library by Jennifer Thakar, which is licensed under BSD 3-Clause "New" or "Revised" License.

<!-- Links -->
[main example]: https://github.com/pilisp/pilisp-cli/blob/main/example/pilisp_cli_main_example.dart
[pilisp]: https://github.com/pilisp/pilisp
[pilisp-native]: https://github.com/pilisp/pilisp-native
[pilisp-native-env]: https://github.com/pilisp/pilisp-native/blob/main/lib/src/pilisp_native_public.dart