import 'dart:async';
import 'dart:io';

import 'package:git/git.dart';
import 'package:glob/glob.dart';
import 'package:io/ansi.dart' as ansi;
import 'package:path/path.dart' as p;

import 'enums.dart';

export 'enums.dart';
export 'options.dart';

void printError(Object object) => print(ansi.red.wrap(object.toString()));

Future<Null> run(String targetDir, String targetBranch, String commitMessage,
    BuildTool buildTool,
    {PubBuildMode pubBuildMode, String buildRunnerConfig}) async {
  var current = p.current;

  if (FileSystemEntity.typeSync(p.join(current, targetDir)) ==
      FileSystemEntityType.NOT_FOUND) {
    stderr.writeln(ansi.yellow.wrap(
        'The `$targetDir` directory does not exist. '
        'This may cause the build to fail. Try setting the `directory` flag.'));
  }

  var isGitDir = await GitDir.isGitDir(current);

  if (!isGitDir) {
    throw 'Not a git directory: $current';
  }

  GitDir gitDir = await GitDir.fromExisting(current, allowSubdirectory: true);

  // current branch cannot be targetBranch

  var currentBranch = await gitDir.getCurrentBranch();

  if (currentBranch.branchName == targetBranch) {
    throw 'Cannot update the current branch $targetBranch';
  }

  var secondsSinceEpoch = new DateTime.now().toUtc().millisecondsSinceEpoch;

  // create a temp dir to dump 'pub build' output to
  var tempDir =
      await Directory.systemTemp.createTemp('peanut.$secondsSinceEpoch.');

  try {
    String command;
    switch (buildTool) {
      case BuildTool.pub:
        assert(buildRunnerConfig == null);
        command = await _runPubBuild(tempDir, targetDir, pubBuildMode);
        break;
      case BuildTool.build:
        assert(pubBuildMode == null);
        command = await _runBuild(tempDir.path, targetDir, buildRunnerConfig);
        break;
    }
    assert(command != null);

    Commit commit = await gitDir.updateBranchWithDirectoryContents(
        targetBranch, p.join(tempDir.path, targetDir), commitMessage);

    if (commit == null) {
      print('There was no change in branch. No commit created.');
    } else {
      print('Branch "$targetBranch" was updated '
          'with `$command` output from `$targetDir`.');
    }
  } finally {
    await tempDir.delete(recursive: true);
  }
}

Future<String> _runBuild(
    String tempDir, String targetDir, String config) async {
  if (Platform.isWindows) {
    printError('Currently uses Unix shell commands `cp` and `mkdir`.'
        ' Will likely fail on Windows.'
        ' See https://github.com/kevmoo/peanut.dart/issues/11');
  }

  var args = ['run', 'build_runner', 'build', '--output', tempDir];

  if (config == null) {
    args.addAll([
      // Force build with dart2js instead of dartdevc.
      '--define',
      'build_web_compilers|entrypoint=compiler=dart2js',
      // Match `pub build` defaults for dart2js.
      '--define',
      'build_web_compilers|entrypoint=dart2js_args=[\"--minify\",\"--no-source-maps\"]',
    ]);
  } else {
    args.addAll(['--config', config]);
  }

  await _runProcess(_pubPath, args, workingDirectory: p.current);

  // Verify `$tempDir/$targetDir` exists
  var contentPath = p.join(tempDir, targetDir);
  if (!FileSystemEntity.isDirectorySync(contentPath)) {
    throw new StateError('Expected directory `$contentPath` was not created.');
  }

  var packagesSymlinkPath = p.join(contentPath, 'packages');
  switch (FileSystemEntity.typeSync(packagesSymlinkPath, followLinks: false)) {
    case FileSystemEntityType.NOT_FOUND:
      // no-op –nothing to do
      break;
    case FileSystemEntityType.LINK:
      var packagesLink = new Link(packagesSymlinkPath);
      assert(packagesLink.existsSync());
      var packagesDirPath = packagesLink.targetSync();
      assert(p.isRelative(packagesDirPath));
      packagesDirPath = p.normalize(p.join(contentPath, packagesDirPath));
      assert(FileSystemEntity.isDirectorySync(packagesDirPath));
      assert(p.isWithin(tempDir, packagesDirPath));

      packagesLink.deleteSync();

      var firstExtraFile = true;
      var initialFiles = new Directory(contentPath)
          .listSync(recursive: true, followLinks: false);
      // TODO: use whereType when github.com/dart-lang/sdk/issues/32463 is fixed
      for (var file in initialFiles.where((i) => i is File)) {
        var relativePath = p.relative(file.path, from: contentPath);

        if (_badFileGlob.matches(relativePath)) {
          if (firstExtraFile) {
            print('Deleting extra files from output directory:');
            firstExtraFile = false;
          }
          file.deleteSync();
          print('  $relativePath');
        }
      }

      var packagesDir = new Directory(packagesDirPath);

      print('Populating contents...');

      var excludeCount = 0;
      await for (var item in packagesDir.list(recursive: true)) {
        if (item is File) {
          var relativePath = p.relative(item.path, from: tempDir);

          if (_badFileGlob.matches(relativePath)) {
            excludeCount++;
            continue;
          }

          if (p.isWithin('packages/\$sdk', relativePath)) {
            // TODO: required for DDC build – need to detect!
            continue;
          }

          var destinationPath = p.join(contentPath, relativePath);

          if (FileSystemEntity.typeSync(p.dirname(destinationPath),
                  followLinks: false) ==
              FileSystemEntityType.NOT_FOUND) {
            await _runProcess('mkdir', ['-p', p.dirname(destinationPath)]);
          }

          stdout.write('.');
          await _runProcess('cp', ['-n', item.path, destinationPath]);
        }
      }
      print('');
      if (excludeCount > 0) {
        print(
            'Excluded $excludeCount item(s) matching `${_globItems.join(', ')}`.');
      }

      break;
    default:
      throw new StateError('Not sure what to do here...');
  }

  return args.join(' ');
}

final _globItems = const [
  '.packages',
  '**.dart',
  '**.module',
  '**.dart.js.deps',
  '**.dart.js.tar.gz',
  '**.ng_placeholder' // Generated by pkg:angular
];

final _badFileGlob = new Glob('{${_globItems.join(',')}}');

Future _runProcess(String proc, List<String> args,
    {String workingDirectory}) async {
  var process = await Process.start(proc, args,
      runInShell: true,
      workingDirectory: workingDirectory,
      mode: ProcessStartMode.INHERIT_STDIO);

  var procExitCode = await process.exitCode;

  if (procExitCode != 0) {
    throw 'Error running `$proc ${args.join(' ')}`.';
  }
}

Future<String> _runPubBuild(
    Directory tempDir, String targetDir, PubBuildMode mode) async {
  var args = [
    'build',
    '--output',
    tempDir.path,
    targetDir,
    '--mode',
    mode.toString().split('.')[1]
  ];

  await _runProcess(_pubPath, args);

  return 'pub build';
}

/// The path to the root directory of the SDK.
final String _sdkDir = (() {
  // The Dart executable is in "/path/to/sdk/bin/dart", so two levels up is
  // "/path/to/sdk".
  var aboveExecutable = p.dirname(p.dirname(Platform.resolvedExecutable));
  assert(FileSystemEntity.isFileSync(p.join(aboveExecutable, 'version')));
  return aboveExecutable;
})();

final String _pubPath =
    p.join(_sdkDir, 'bin', Platform.isWindows ? 'pub.bat' : 'pub');
