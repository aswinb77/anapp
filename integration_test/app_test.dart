import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moviecc_flutter/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App starts without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    app.main();
    
    await tester.pumpAndSettle();

    // Verify that some basic widget from the app is present.
    // For example, finding the MaterialApp or a specific known widget.
    expect(find.byType(app.MyApp), findsOneWidget);
  });
}
