## 3.3.0

- Parse command line arguments when a `peaunut.yaml` configuration file exists
  and merge the values, with a preference for the command line arguments.
  (Before, the configuration file values were ignored.)
- Added `verbose` option. For now, it prints out all of the files deleted in the
  output directory.

## 3.2.1

- Added examples to README.

## 3.2.0

- If `post-build-dart-script` is provided, pass a second command line argument
  after the build directory. A JSON map between the source directory relative
  to the working directory and the corresponding build directory.

## 3.1.1

- Print a more helpful error when configuration is invalid.

## 3.1.0

- Support configuring builder options.
- Require Dart SDK `>=2.3.0-dev.0.1 <3.0.0`.

## 3.0.3

- Improve printed output while running.
- Updated dependencies.

## 3.0.2

- Improve printed output while running.

## 3.0.1

- Fix height of generated `index.html` page.
- Include `package:peanut` version info in commit message.
- Avoid creating commit messages with a first line longer than 72 characters.

## 3.0.0

- **BREAKING** renamed `diretory` option to `directories`.
- Added `--[no-]source-branch-info` flag.
- Added `--post-build-dart-script` option.
- Add support for `peanut.yaml` configuration.
- Exclude `*.md` and `*.yaml` from output directory.
- Require Dart SDK `>=2.2.0`.

## 2.0.8

- Support the latest `package:build_web_compilers` and friends.

## 2.0.7

- Support the latest `package:build_runner` and friends.

## 2.0.6

* Improve `--help` output.

## 2.0.5

* Support the latest `package:build_runner`.

## 2.0.4

* Support Dart 2 stable. 

## 2.0.3

* Updates to support latest `package:build_runner`.

## 2.0.2

* Require Dart `>=2.0.0-dev.56`.

* Other updates to support running on Dart 2.

## 2.0.1

* Support the latest version of `package:build_web_compilers`.

## 2.0.0

* **BREAKING** Now *only* works with the latest `package:build_runner` and
  friends. 

* Removed manual file management that likely caused problems on Windows.

* The public library has been removed. This package is meant to be an executable
  only.

## 1.1.6

* Moved non-executable file out of `/bin` so it's not activated during
  `pub global activate`.

## 1.1.5

* Run `pub` from the SDK invoking `peanut`. Also fixes the case where `pub` is
  not in the user's PATH.

* Send all output to `stdout`.

* Improve exit codes and error messages on failure.

## 1.1.4

* Added `**.dart.js.deps`, `**.dart.js.tar.gz`, `**.ng_placeholder` to the set 
  of files to exclude.

## 1.1.3

* Only warn if the `directory` does not exist. Build could still work.

* Update dependency on `pkg:git`. Allows running `peanut` in a subdirectory of
  a Git repository.

## 1.1.2

* Support the latest `pkg:git`.

## 1.1.1

* Improve sub-process management.

* Print error/warnings in red – where supported.

## 1.1.0

* Initial support for `build_runner` via `--build_tool` option.

* Updated Dart SDK lower-bound to `2.0.0-dev.22`.
  Using `Iterable.whereType<T>` – introduced in this release. 

## 1.0.0

* Set exit code correctly on errors.

## 0.1.0

* Tweak some things.
* Update readme.

## 0.0.2

* Add mode options, to allow `pub build` to run in debug mode.

## 0.0.1+2

* Run `pub` with `runInShell` to make things work on Windows.

## 0.0.1+1

* Added instructions to `README.md`.

## 0.0.1

* Initial version, created by [Stagehand](http://stagehand.pub/)
