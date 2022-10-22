import 'dart:io';
import 'dart:mirrors';

import 'package:tridev_config/src/configuration.dart';
import 'package:tridev_config/src/runtime.dart';
import 'package:tridev_runtime/runtime.dart';

class ConfigurationCompiler extends Compiler {
  @override
  Map<String, dynamic> compile(MirrorContext context) {
    return Map.fromEntries(
      context.getSubclassesOf(Configuration).map((c) {
        return MapEntry(
          MirrorSystem.getName(c.simpleName),
          ConfigurationRuntimeImpl(c),
        );
      }),
    );
  }

  @override
  void deflectPackage(Directory destinationDirectory) {
    final libFile = File.fromUri(
      destinationDirectory.uri.resolve("lib/").resolve("tridev_config.dart"),
    );
    final contents = libFile.readAsStringSync();
    libFile.writeAsStringSync(
      contents.replaceFirst("export 'src/compiler.dart';", ""),
    );
  }
}
