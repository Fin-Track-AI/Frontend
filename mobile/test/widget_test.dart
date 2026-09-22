import 'package:flutter_test/flutter_test.dart';
import 'package:fintrack_mobile/main.dart';

void main() {
  testWidgets('FinTrack smoke test and boot verification', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FinTrackApp());

    // Verify splash screen renders FinTrack branding
    expect(find.text('FinTrack'), findsOneWidget);

    // Allow splash timer to complete
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
