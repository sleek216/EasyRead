import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:book_reading/main.dart';
import 'package:book_reading/providers/easy_word_provider.dart';

void main() {
  testWidgets('Easy Read App renders welcome onboarding', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => EasyReadProvider(),
        child: const EasyReadApp(),
      ),
    );

    expect(find.text('Get started'), findsOneWidget);
  });
}
