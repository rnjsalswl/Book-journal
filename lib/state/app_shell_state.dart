import 'package:flutter_riverpod/legacy.dart';

/// Index into the bottom nav: 0=서관(map) 1=내 서재(shelf) 2=교환일기(feed) 3=나(profile).
/// A `StateProvider` (not a Notifier) because it's exactly one mutable int
/// that several unrelated screens need to both read and jump to (e.g. the
/// "교환일기 초대" action on a book sheet switches to the feed tab).
final currentTabProvider = StateProvider<int>((ref) => 0);
