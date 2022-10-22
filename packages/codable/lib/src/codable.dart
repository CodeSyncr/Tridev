import 'package:tridev_codeunit/src/resolver.dart';

abstract class Referable {
  void resolveOrThrow(ReferenceResolver resolver);
}
