// Without --dart-define=SUPABASE_URL/SUPABASE_ANON_KEY, Env.isConfigured is
// false and the app renders the "set up Supabase" screen instead of trying
// (and failing) to reach a backend — this just checks that path renders.

import 'package:flutter_test/flutter_test.dart';

import 'package:pixel_book_journal/app.dart';

void main() {
  testWidgets('shows the Supabase setup screen when unconfigured', (WidgetTester tester) async {
    await tester.pumpWidget(const PixelBookJournalApp());
    await tester.pump();

    expect(find.textContaining('Supabase 설정이 필요해요'), findsOneWidget);
  });
}
