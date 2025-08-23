import 'package:flutter_test/flutter_test.dart';

import 'package:agentic_notes/main.dart';

void main() {
  testWidgets('renders onboarding welcome', (tester) async {
    await tester.pumpWidget(const MyApp());

    // The onboarding welcome page should show the app title.
    expect(find.text('Agentic Notes'), findsOneWidget);
  });
}
