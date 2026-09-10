import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:book_reading/main.dart';
import 'package:book_reading/providers/easy_word_provider.dart';

void main() {
  testWidgets('Test bottom sheet opens without layout crashes', (WidgetTester tester) async {
    final provider = EasyReadProvider();
    provider.isOnboarding = false; // skip onboarding to library

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const EasyReadApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Library is shown
    expect(find.text('The Quiet Power of Reading Slowly'), findsWidgets);

    final planBtn = find.text("Free plan");
    expect(planBtn, findsOneWidget);
    await tester.tap(planBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text("EasyRead Plus"), findsWidgets);
  });
}
