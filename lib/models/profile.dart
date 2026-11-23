class Profile {
  final String id;
  final String displayName;
  final int level;
  final int xp;
  final int xpToNext;
  final int floorAccess;
  final String avatarSeed;

  const Profile({
    required this.id,
    required this.displayName,
    required this.level,
    required this.xp,
    required this.xpToNext,
    required this.floorAccess,
    required this.avatarSeed,
  });

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
        id: m['id'] as String,
        displayName: m['display_name'] as String? ?? '이름 없는 독자',
        level: (m['level'] as num?)?.toInt() ?? 1,
        xp: (m['xp'] as num?)?.toInt() ?? 0,
        xpToNext: (m['xp_to_next'] as num?)?.toInt() ?? 200,
        floorAccess: (m['floor_access'] as num?)?.toInt() ?? 1,
        avatarSeed: m['avatar_seed'] as String? ?? 'player',
      );

  Profile copyWith({int? level, int? xp, int? xpToNext}) => Profile(
        id: id,
        displayName: displayName,
        level: level ?? this.level,
        xp: xp ?? this.xp,
        xpToNext: xpToNext ?? this.xpToNext,
        floorAccess: floorAccess,
        avatarSeed: avatarSeed,
      );

  String get xpLabel => '$xp / $xpToNext XP';
  double get xpProgress => xpToNext == 0 ? 0 : (xp / xpToNext).clamp(0, 1).toDouble();
}
