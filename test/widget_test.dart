import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixitnew/main.dart';

void main() {
  testWidgets('App builds and shows WelcomeScreen when no user is logged in',
      (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const MyApp());

    // Verify that MaterialApp is created
    expect(find.byType(MaterialApp), findsOneWidget);

    // Since no user is logged in, AuthWrapper should show WelcomeScreen
    // Adjust the text check to something unique in your WelcomeScreen
    expect(find.text('Welcome'), findsOneWidget);
  });

  testWidgets('Verify email screen shows resend and logout buttons',
      (WidgetTester tester) async {
    // Build the VerifyEmailScreen directly
    await tester.pumpWidget(const MaterialApp(home: VerifyEmailScreen()));

    // Check for the title
    expect(find.text('Verify Email'), findsOneWidget);

    // Check for the resend button
    expect(find.text('Resend Verification'), findsOneWidget);

    // Check for the logout button
    expect(find.text('Logout'), findsOneWidget);
  });
}
