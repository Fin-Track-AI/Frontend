import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fintrack_mobile/screens/legal/terms_privacy_screen.dart';
import 'package:fintrack_mobile/screens/onboarding/app_landing_screen.dart';

void main() {
  testWidgets('AppLandingScreen displays enlarged Terms text and Read Terms button',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppLandingScreen(),
      ),
    );

    // Verify the prominent Terms statement exists
    expect(
      find.text('By continuing, you agree to FinTrack’s Terms of Service & Privacy Policy'),
      findsOneWidget,
    );

    // Verify the Read Terms button exists
    expect(
      find.text('Read Terms of Service and Privacy Policy'),
      findsOneWidget,
    );
  });

  testWidgets('TermsPrivacyScreen renders both tabs and switches properly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TermsPrivacyScreen(),
      ),
    );

    // Check header & compliance badge
    expect(find.text('Legal & Compliance'), findsOneWidget);
    expect(
      find.text('DPDP Act 2023 & RBI Compliant • Updated September 2026'),
      findsOneWidget,
    );

    // Check Terms of Service tab is visible
    expect(find.text('Acceptance of Terms'), findsOneWidget);
    expect(find.text('Informational & Intelligence Nature'), findsOneWidget);

    // Switch to Privacy Policy tab
    await tester.tap(find.text('Privacy Policy'));
    await tester.pumpAndSettle();

    // Check Privacy Policy content is visible
    expect(
      find.text('Digital Personal Data Protection (DPDP) Act 2023'),
      findsOneWidget,
    );
    expect(find.text('What Information We Collect'), findsOneWidget);


    // Check Accept button
    expect(find.text('I Understand and Accept'), findsOneWidget);
  });
}
