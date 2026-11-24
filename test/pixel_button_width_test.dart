// Regression test for a real bug: PixelButton used as a plain (no
// explicit width) sibling next to an Expanded label inside a Row — e.g.
// the reader's "감상문" button next to the "문장을 누르면 ..." hint —
// collapsed that label to near-zero width, wrapping Korean text one
// character per line. Root cause: PixelButton unconditionally stretched
// its child to `width: double.infinity`, which is only valid when the
// button's own box gets a *bounded* width (a grid cell, a full-width list
// item) — in a Row, a plain sibling gets *unbounded* width, so forcing
// infinity there broke layout instead.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_book_journal/widgets/pixel_button.dart';

void main() {
  testWidgets('a label next to a plain (unsized) PixelButton in a Row keeps most of the row width', (tester) async {
    const screenWidth = 390.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: screenWidth,
            child: Row(
              children: [
                const Expanded(
                  child: Text('문장을 누르면 밑줄 · 말풍선 · 포스트잇을 붙일 수 있어요'),
                ),
                PixelButton(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  onTap: () {},
                  child: const Text('감상문'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);

    final textSize = tester.getSize(find.text('문장을 누르면 밑줄 · 말풍선 · 포스트잇을 붙일 수 있어요'));
    // Before the fix this collapsed to ~14px (one character's width) and
    // wrapped vertically; it should instead take up most of the row,
    // leaving just enough for the button on the right.
    expect(textSize.width, greaterThan(screenWidth * 0.5));
  });

  testWidgets('a PixelButton still stretches to fill a bounded parent (e.g. a grid cell)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 150,
            child: PixelButton(
              onTap: () {},
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('title'),
                  Text('author'),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final columnSize = tester.getSize(find.byType(Column));
    expect(columnSize.width, greaterThan(150));
  });
}
