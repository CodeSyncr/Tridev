import 'dart:convert';
import 'dart:io';
import 'dart:mirrors';

import 'package:tridev/src/application/channel.dart';
import 'package:tridev/src/db/managed/object.dart';
import 'package:tridev/src/http/controller.dart';
import 'package:tridev/src/http/serializable.dart';
import 'package:tridev/src/runtime/impl.dart';
import 'package:tridev/src/runtime/orm/data_model_compiler.dart';
import 'package:tridev_runtime/runtime.dart';
import 'package:yaml/yaml.dart';

class TridevCompiler extends Compiler {
  @override
  Map<String, dynamic> compile(MirrorContext context) {
    final m = <String, dynamic>{};

    m.addEntries(context
        .getSubclassesOf(ApplicationChannel)
        .map((t) => MapEntry(_getClassName(t), ChannelRuntimeImpl(t))));
    m.addEntries(context
        .getSubclassesOf(Serializable)
        .map((t) => MapEntry(_getClassName(t), SerializableRuntimeImpl(t))));
    m.addEntries(context
        .getSubclassesOf(Controller)
        .map((t) => MapEntry(_getClassName(t), ControllerRuntimeImpl(t))));

    m.addAll(DataModelCompiler().compile(context));

    return m;
  }

  String _getClassName(ClassMirror mirror) {
    return MirrorSystem.getName(mirror.simpleName);
  }

  @override
  List<Uri> getUrisToResolve(BuildContext context) {
    return context.context
        .getSubclassesOf(ManagedObject)
        .map((c) => c.location!.sourceUri)
        .toList();
  }

  @override
  void deflectPackage(Directory destinationDirectory) {
    final libFile = File.fromUri(
        destinationDirectory.uri.resolve("lib/").resolve("tridev.dart"));
    final contents = libFile.readAsStringSync();
    libFile.writeAsStringSync(contents.replaceFirst(
        "export 'package:tridev/src/runtime/compiler.dart';", ""));
  }

  @override
  void didFinishPackageGeneration(BuildContext context) {
    if (context.forTests) {
      final devPackages = [
        {'name': 'tridev_test', 'path': 'test_harness'},
        {'name': 'tridev_common_test', 'path': 'common_test'},
        {'name': 'fs_test_agent', 'path': 'fs_test_agent'},
      ];
      final targetPubspecFile =
          File.fromUri(context.buildDirectoryUri.resolve("pubspec.yaml"));
      final pubspecContents = json.decode(targetPubspecFile.readAsStringSync());
      for (final package in devPackages) {
        pubspecContents["dev_dependencies"]
            [package['name']!] = {"path": "packages/${package['path']!}"};

        copyDirectory(
            src: context.sourceApplicationDirectory.uri
                .resolve("../")
                .resolve(package['path']!),
            dst: context.buildPackagesDirectory.uri.resolve(package['path']!));
      }

      pubspecContents["dependency_overrides"]["tridev"] =
          pubspecContents["dependencies"]["tridev"];
      targetPubspecFile.writeAsStringSync(json.encode(pubspecContents));

      final tridevPackages = [
        {'name': 'tridev_codable', 'path': 'codable'},
        {'name': 'tridev_common', 'path': 'common'},
        {'name': 'tridev_config', 'path': 'config'},
        {'name': 'tridev_isolate_exec', 'path': 'isolate_exec'},
        {'name': 'tridev_open_api', 'path': 'open_api'},
        {'name': 'tridev_password_hash', 'path': 'password_hash'},
      ];
      _overwritePackageDependency(context, 'tridev', tridevPackages);

      final runtimePackages = [
        {'name': 'tridev_isolate_exec', 'path': 'isolate_exec'},
      ];
      _overwritePackageDependency(context, 'tridev_runtime', runtimePackages);

      final commonTestPackages = [
        {'name': 'tridev_common', 'path': 'common'},
      ];
      _overwritePackageDependency(context, 'common_test', commonTestPackages);

      final commonPackages = [
        {'name': 'tridev_open_api', 'path': 'open_api'},
      ];
      _overwritePackageDependency(context, 'common', commonPackages);

      final oapiPackages = [
        {'name': 'tridev_codable', 'path': 'codable'},
      ];
      _overwritePackageDependency(context, 'open_api', oapiPackages);
    }
  }

  void _overwritePackageDependency(BuildContext context, String packageName,
      List<Map<String, String>> packages) {
    final pubspecFile = File.fromUri(context.buildDirectoryUri
        .resolve('packages/')
        .resolve('${packageName}/')
        .resolve("pubspec.yaml"));
    final pubspecContents = loadYaml(pubspecFile.readAsStringSync());
    final jsonContents = json.decode(json.encode(pubspecContents));
    for (final package in packages) {
      jsonContents["dependencies"]
          [package['name']!] = {"path": "../${package['path']!}"};
      copyDirectory(
          src: context.sourceApplicationDirectory.uri
              .resolve("../")
              .resolve(package['path']!),
          dst: context.buildPackagesDirectory.uri.resolve(package['path']!));
    }
    pubspecFile.writeAsStringSync(json.encode(jsonContents));
  }
}
