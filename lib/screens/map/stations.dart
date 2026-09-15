enum StationKind { npc, shelf, table }

/// A point of interest along the library's side-view world — matches
/// `STATIONS` in the prototype. `category` links shelf stations to the
/// `books.category` value they browse.
class Station {
  final String id;
  final double x;
  final String name;
  final String action;
  final StationKind kind;
  final String? category;

  const Station({
    required this.id,
    required this.x,
    required this.name,
    required this.action,
    required this.kind,
    this.category,
  });
}

const double kWorldWidth = 830;

const List<Station> kStations = [
  Station(id: 'desk', x: 44, name: '사서 데스크', action: '말 걸기', kind: StationKind.npc),
  Station(id: 'new', x: 168, name: '신간 코너', action: '살펴보기', kind: StationKind.shelf, category: 'new'),
  Station(id: 'novel', x: 292, name: '소설 서가', action: '살펴보기', kind: StationKind.shelf, category: 'novel'),
  Station(id: 'essay', x: 416, name: '에세이 서가', action: '살펴보기', kind: StationKind.shelf, category: 'essay'),
  Station(id: 'sf', x: 540, name: 'SF·판타지 서가', action: '살펴보기', kind: StationKind.shelf, category: 'sf'),
  Station(id: 'poem', x: 664, name: '시 서가', action: '살펴보기', kind: StationKind.shelf, category: 'poem'),
  Station(id: 'table', x: 784, name: '내 책상', action: '감상문 쓰기', kind: StationKind.table),
];
