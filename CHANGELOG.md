## v1.0.0-alpha.14

* Adds `compile` command.
* For `load` command, changes `--evalBefore` and `--evalAfter` to `--eval-before` and `--eval-after` respectively.
* Adds `--[no-]print` flag, to control whether `eval` and `load` commands print their final expressions.
* Corrects some async/await call sites.

## v1.0.0-alpha.13

* Ensure that `PLAwait` values are Dart `await`ed in the load and eval command paths.

## v1.0.0-alpha.12

* When no command provided, start the REPL.

## v1.0.0-alpha.11

* Completely revamped CLI arguments, using command-based syntax now. Run `help` for top-level and `help <command>` for command-specific help.
* If `--env-vars` provided to any of the sub-commands, PiLisp bindings are created for every entry in `Platform.environment`, prefixed with `env/` (e.g., `env/HOME`).

## v1.0.0-alpha.10

* Improved auto-complete
   * Moving the cursor or typing characters clears auto-complete results.
   * Entering <kbd>TAB</kbd> in the middle of a line does not clear already-entered text from the display (never did so from the actual buffer).
   * When all completion results share a further prefix than what the user typed, that shared prefix is proactively inserted.
      * Example: `mat` followed by entering <kbd>TAB</kbd> will automatically insert `math/` into the line and show all completion results for it.

## v1.0.0-alpha.9

* Richer cli_repl with more editing commands and TAB completion for in-scope PiLisp bindings
* Repo changes to make pub.dev output more useful.

## v1.0.0-alpha.8

* Initial inclusion of cli_repl for richer REPL experience
* Supports `-e` or `--eval` as CLI parameter for evaluating PiLisp forms directly

## v1.0.0-alpha.7

- Initial version, set to same version as the version of [PiLisp](https://github.com/pilisp/pilisp) it relies on.
