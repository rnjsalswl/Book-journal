// One-off visual verification, not a regression suite: renders a few
// screens that don't require a live Supabase project (their build methods
// never touch ref.watch on data providers) to golden PNGs so the pixel
// styling can be eyeballed. Run with `flutter test --update-goldens
// test/visual_check_test.dart` then open the PNGs under test/goldens/.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pixel_book_journal/models/book.dart';
import 'package:pixel_book_journal/screens/auth_screen.dart';
import 'package:pixel_book_journal/screens/map/map_game_state.dart';
import 'package:pixel_book_journal/screens/map/map_painter.dart';
import 'package:pixel_book_journal/screens/review_screen.dart';
import 'package:pixel_book_journal/theme/pixel_colors.dart';
import 'package:pixel_book_journal/widgets/pixel_toast.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: ThemeData(fontFamily: 'Galmuri11'),
      debugShowCheckedModeBanner: false,
      home: PixelToastHost(child: child),
    ),
  );
}

void main() {
  setUpAll(() async {
    final loader = FontLoader('Galmuri11')
      ..addFont(File('assets/fonts/Galmuri11.ttf').readAsBytes().then(ByteData.sublistView));
    await loader.load();
  });

  testWidgets('auth screen golden', (tester) async {
    tester.view.physicalSize = const Size(430, 920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(_wrap(const AuthScreen()));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/auth_screen.png'));
  });

  testWidgets('review screen golden', (tester) async {
    tester.view.physicalSize = const Size(430, 920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    const book = Book(
      id: 'sand',
      title: '모래의 도시',
      author: '김윤',
      category: 'novel',
      color: PixelColors.wood,
      totalPages: 312,
    );
    await tester.pumpWidget(_wrap(const ReviewScreen(book: book, quote: '"나는 그 기다림을 좋아했다." — 84쪽, 내 밑줄')));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/review_screen.png'));
  });

  testWidgets('map canvas golden', (tester) async {
    final game = MapGameState()..px = 292;
    addTearDown(game.dispose);
    tester.view.physicalSize = const Size(480, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      _wrap(
        ColoredBox(
          color: PixelColors.inkBorder,
          child: Center(
            child: SizedBox(
              width: 480,
              height: 600,
              child: CustomPaint(painter: MapPainter(game)),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/map_canvas.png'));
  });
}
