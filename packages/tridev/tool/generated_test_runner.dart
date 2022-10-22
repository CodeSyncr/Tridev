import 'dart:async';
import 'dart:io';

import 'package:tridev_runtime/runtime.dart';

Future main(List<String> args) async {
  final tridevDir = Directory.current.uri;
  final blacklist = [
    (String s) => s.contains('test/command/'),
    (String s) => s.contains('/compilation_errors/'),
    (String s) => s.contains('test/openapi/'),
    (String s) => s.contains('postgresql/migration/'),
    (String s) => s.contains('db/migration/'),
    (String s) => s.endsWith('entity_mirrors_test.dart'),
    (String s) => s.endsWith('moc_openapi_test.dart'),
    (String s) => s.endsWith('auth_documentation_test.dart'),
    (String s) => s.endsWith('entity_mirrors_test.dart'),
    (String s) => s.endsWith('cli/command_test.dart'),
  ];

  List<File> testFiles;

  if (args.length == 1) {
    testFiles = [File(args.first)];
  } else {
    final testDir = args.isNotEmpty
        ? tridevDir.resolveUri(Uri.parse(args[0]))
        : tridevDir.resolve('test/');

    testFiles = Directory.fromUri(testDir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('_test.dart'))
        .where((f) => blacklist.every(
            (blacklistFunction) => blacklistFunction(f.uri.path) == false))
        .toList();
  }
  var remainingCounter = testFiles.length;
  final passingFiles = <File>[];
  final failingFiles = <File>[];
  for (var f in testFiles) {
    final currentTime = DateTime.now();
    final makePrompt = () =>
        '(Pass: ${passingFiles.length} Fail: ${failingFiles.length} Remain: $remainingCounter)';

    print('Running tests derived from ${f.path}...');
    final ctx = BuildContext(
        tridevDir.resolve('lib/').resolve('tridev.dart'),
        Directory.current.uri.resolve('../').resolve('_build/'),
        Directory.current.uri.resolve('../').resolve('run'),
        File(tridevDir.resolve(f.path).path).readAsStringSync(),
        forTests: true);
    final bm = BuildManager(ctx);
    await bm.build();

    final result = await Process.start('dart', ['test/main_test.dart'],
        workingDirectory:
            ctx.buildDirectoryUri.toFilePath(windows: Platform.isWindows),
        environment: {
          'TRIDEV_CI_DIR_LOCATION': Directory.current.uri
              .resolve('../../')
              .resolve('ci/')
              .toFilePath(windows: Platform.isWindows)
        });
    // ignore: unawaited_futures
    stdout.addStream(result.stdout);
    // ignore: unawaited_futures
    stderr.addStream(result.stderr);

    if (await result.exitCode != 0) {
      exitCode = -1;
      failingFiles.add(f);
      print('Tests FAILED in ${f.path}.');
    } else {
      passingFiles.add(f);
    }

    final elapsed = DateTime.now().difference(currentTime);
    remainingCounter--;
    print(
        '${makePrompt()} (${elapsed.inSeconds}s) Completed tests derived from ${f.path}.');
    await bm.clean();
  }

  print('==============');
  print('Result Summary');
  print('==============');

  final testRoot =
      Directory.current.uri.resolve('../').resolve('tridev/').resolve('test/');
  String stripParentDir(Uri uri) {
    final testPathList = uri.pathSegments;
    final parentDirPathList = testRoot.pathSegments;
    final components = testPathList.skip(parentDirPathList.length - 1);

    return components.join('/');
  }

  passingFiles.forEach((f) {
    print('  ${stripParentDir(f.uri)}: success');
  });
  failingFiles.forEach((f) {
    print('  ${stripParentDir(f.uri)}: FAILURE');
  });
}
