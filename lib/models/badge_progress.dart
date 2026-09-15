class BadgeProgress {
  final String badgeId;
  final String key;
  final String name;
  final String description;
  final int colorHex; // ARGB int, parsed at load time
  final int goal;
  final int progress;
  final DateTime? unlockedAt;

  const BadgeProgress({
    required this.badgeId,
    required this.key,
    required this.name,
    required this.description,
    required this.colorHex,
    required this.goal,
    required this.progress,
    this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;
  bool get isInProgress => !isUnlocked && progress > 0;

  String get stateLabel {
    if (isUnlocked) return '달성';
    if (isInProgress) return '진행';
    return '미달성';
  }

  double get opacity => isUnlocked || isInProgress ? 1 : 0.5;
}

class HeatDay {
  final DateTime day;
  final int minutes;
  const HeatDay({required this.day, required this.minutes});

  /// Bucketed intensity 0..3, matches the prototype's hashed heat-cell demo.
  int get intensity {
    if (minutes <= 0) return 0;
    if (minutes < 15) return 1;
    if (minutes < 45) return 2;
    return 3;
  }
}
