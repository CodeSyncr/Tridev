import 'dart:async';
import 'dart:mirrors';

import 'package:tridev/src/application/channel.dart';
import 'package:tridev_isolate_exec/tridev_isolate_exec.dart';
import 'package:tridev_runtime/runtime.dart';

class GetChannelExecutable extends Executable<String> {
  GetChannelExecutable(Map<String, dynamic> message) : super(message);

  @override
  Future<String> execute() async {
    final channels =
        RuntimeContext.current.runtimes.iterable.whereType<ChannelRuntime>();
    if (channels.length != 1) {
      throw StateError(
          "No ApplicationChannel subclass was found for this project. "
          "Make sure it is imported in your application library file.");
    }
    var runtime = channels.first;

    return MirrorSystem.getName(reflectClass(runtime.channelType).simpleName);
  }

  static List<String> importsForPackage(String? packageName) => [
        "package:tridev/tridev.dart",
        "package:$packageName/$packageName.dart",
        "package:tridev_runtime/runtime.dart"
      ];
}
