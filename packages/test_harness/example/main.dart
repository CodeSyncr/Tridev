import 'package:test/test.dart';
import 'package:tridev/tridev.dart';
import 'package:tridev_test/tridev_test.dart';

void main() {
  final harness = TestHarness<App>()..install();

  test("GET /example returns simple map", () async {
    final response = await harness.agent!.get("/example");
    expectResponse(response, 200, body: {"key": "value"});
  });
}

class App extends ApplicationChannel {
  @override
  Controller get entryPoint {
    final router = Router();
    router
        .route("/example")
        .linkFunction((req) async => Response.ok({"key": "value"}));
    return router;
  }
}
