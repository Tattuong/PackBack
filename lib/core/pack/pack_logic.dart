enum TripKind { city, beach, outdoors, work }

enum BagKind { cabin, backpack, checked }

enum ItemGroup { essentials, tech, clothes, toiletries }

enum ItemPlace { room, bathroom, bag }

enum ItemHold { personal, borrowed }

enum ReturnMark { pending, confirmed, usedUp, left, moved }

class PackTrip {
  PackTrip({
    required this.id,
    required this.name,
    required this.start,
    required this.end,
    required this.kind,
    required this.bag,
    required this.created,
    this.broughtBack = false,
  });

  final String id;
  String name;
  DateTime start;
  DateTime end;
  TripKind kind;
  BagKind bag;
  bool broughtBack;
  final DateTime created;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'start': ymd(start),
        'end': ymd(end),
        'kind': kind.name,
        'bag': bag.name,
        'broughtBack': broughtBack,
        'created': created.toIso8601String(),
      };

  factory PackTrip.fromJson(Map<String, dynamic> json) {
    return PackTrip(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      start: parseDay(json['start'] as String? ?? ''),
      end: parseDay(json['end'] as String? ?? ''),
      kind:
          _enumByName(TripKind.values, json['kind'] as String?, TripKind.city),
      bag: _enumByName(BagKind.values, json['bag'] as String?, BagKind.cabin),
      broughtBack: json['broughtBack'] as bool? ?? false,
      created:
          DateTime.tryParse(json['created'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class PackItem {
  PackItem({
    required this.id,
    required this.tripId,
    required this.name,
    required this.group,
    required this.place,
    required this.icon,
    this.hold = ItemHold.personal,
    this.packed = false,
    this.back = ReturnMark.pending,
    this.hint = '',
    this.order = 0,
  });

  final String id;
  String tripId;
  String name;
  ItemGroup group;
  ItemPlace place;
  ItemHold hold;
  bool packed;
  ReturnMark back;
  String hint;
  String icon;
  int order;

  Map<String, dynamic> toJson() => {
        'id': id,
        'tripId': tripId,
        'name': name,
        'group': group.name,
        'place': place.name,
        'hold': hold.name,
        'packed': packed,
        'back': back.name,
        'hint': hint,
        'icon': icon,
        'order': order,
      };

  factory PackItem.fromJson(Map<String, dynamic> json) {
    return PackItem(
      id: json['id'] as String? ?? '',
      tripId: json['tripId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      group: _enumByName(
          ItemGroup.values, json['group'] as String?, ItemGroup.essentials),
      place: _enumByName(
          ItemPlace.values, json['place'] as String?, ItemPlace.bag),
      hold: _enumByName(
          ItemHold.values, json['hold'] as String?, ItemHold.personal),
      packed: json['packed'] as bool? ?? false,
      back: _enumByName(
          ReturnMark.values, json['back'] as String?, ReturnMark.pending),
      hint: json['hint'] as String? ?? '',
      icon: json['icon'] as String? ?? 'box',
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }
}

class StarterItem {
  const StarterItem({
    required this.name,
    required this.group,
    required this.place,
    required this.icon,
    this.hint = '',
    this.hold = ItemHold.personal,
  });

  final String name;
  final ItemGroup group;
  final ItemPlace place;
  final String icon;
  final String hint;
  final ItemHold hold;
}

class PackTemplates {
  PackTemplates._();

  static const city = <StarterItem>[
    StarterItem(
        name: 'Passport',
        group: ItemGroup.essentials,
        place: ItemPlace.bag,
        icon: 'passport'),
    StarterItem(
        name: 'Wallet',
        group: ItemGroup.essentials,
        place: ItemPlace.bag,
        icon: 'wallet'),
    StarterItem(
        name: 'Phone',
        group: ItemGroup.essentials,
        place: ItemPlace.bag,
        icon: 'phone'),
    StarterItem(
        name: 'Sunglasses',
        group: ItemGroup.essentials,
        place: ItemPlace.room,
        icon: 'sun',
        hint: 'Check drawers and your day bag'),
    StarterItem(
        name: 'Phone charger',
        group: ItemGroup.tech,
        place: ItemPlace.room,
        icon: 'charger',
        hint: 'Check outlets and bedside'),
    StarterItem(
        name: 'Power bank',
        group: ItemGroup.tech,
        place: ItemPlace.bag,
        icon: 'battery'),
    StarterItem(
        name: 'Shirt',
        group: ItemGroup.clothes,
        place: ItemPlace.bag,
        icon: 'shirt'),
    StarterItem(
        name: 'Trousers',
        group: ItemGroup.clothes,
        place: ItemPlace.bag,
        icon: 'shirt'),
    StarterItem(
        name: 'Light jacket',
        group: ItemGroup.clothes,
        place: ItemPlace.bag,
        icon: 'shirt'),
    StarterItem(
        name: 'Spare tee',
        group: ItemGroup.clothes,
        place: ItemPlace.bag,
        icon: 'shirt'),
    StarterItem(
        name: 'Toothbrush',
        group: ItemGroup.toiletries,
        place: ItemPlace.bathroom,
        icon: 'soap'),
    StarterItem(
        name: 'Sunscreen',
        group: ItemGroup.toiletries,
        place: ItemPlace.bathroom,
        icon: 'soap'),
  ];

  static const beach = <StarterItem>[
    StarterItem(
        name: 'Swimsuit',
        group: ItemGroup.clothes,
        place: ItemPlace.bathroom,
        icon: 'shirt'),
    StarterItem(
        name: 'Sunscreen',
        group: ItemGroup.toiletries,
        place: ItemPlace.bathroom,
        icon: 'soap'),
    StarterItem(
        name: 'Sunglasses',
        group: ItemGroup.essentials,
        place: ItemPlace.bag,
        icon: 'sun'),
    StarterItem(
        name: 'Sandals',
        group: ItemGroup.clothes,
        place: ItemPlace.room,
        icon: 'shirt'),
    StarterItem(
        name: 'Phone',
        group: ItemGroup.essentials,
        place: ItemPlace.bag,
        icon: 'phone'),
    StarterItem(
        name: 'Power bank',
        group: ItemGroup.tech,
        place: ItemPlace.bag,
        icon: 'battery'),
    StarterItem(
        name: 'Hat',
        group: ItemGroup.clothes,
        place: ItemPlace.room,
        icon: 'shirt'),
    StarterItem(
        name: 'Dry bag',
        group: ItemGroup.essentials,
        place: ItemPlace.room,
        icon: 'box'),
  ];

  static const outdoors = <StarterItem>[
    StarterItem(
        name: 'Water bottle',
        group: ItemGroup.essentials,
        place: ItemPlace.bag,
        icon: 'box'),
    StarterItem(
        name: 'Map',
        group: ItemGroup.essentials,
        place: ItemPlace.bag,
        icon: 'note'),
    StarterItem(
        name: 'Rain jacket',
        group: ItemGroup.clothes,
        place: ItemPlace.room,
        icon: 'shirt'),
    StarterItem(
        name: 'Headlamp',
        group: ItemGroup.tech,
        place: ItemPlace.bag,
        icon: 'charger'),
    StarterItem(
        name: 'Power bank',
        group: ItemGroup.tech,
        place: ItemPlace.bag,
        icon: 'battery'),
    StarterItem(
        name: 'First aid',
        group: ItemGroup.toiletries,
        place: ItemPlace.bag,
        icon: 'soap'),
    StarterItem(
        name: 'Socks',
        group: ItemGroup.clothes,
        place: ItemPlace.bag,
        icon: 'shirt'),
    StarterItem(
        name: 'Phone',
        group: ItemGroup.essentials,
        place: ItemPlace.bag,
        icon: 'phone'),
  ];

  static const work = <StarterItem>[
    StarterItem(
        name: 'Laptop',
        group: ItemGroup.tech,
        place: ItemPlace.room,
        icon: 'laptop',
        hint: 'Check the desk before you leave'),
    StarterItem(
        name: 'Badge',
        group: ItemGroup.essentials,
        place: ItemPlace.room,
        icon: 'badge'),
    StarterItem(
        name: 'Charger',
        group: ItemGroup.tech,
        place: ItemPlace.room,
        icon: 'charger',
        hint: 'Check the outlet by the desk'),
    StarterItem(
        name: 'Notebook',
        group: ItemGroup.essentials,
        place: ItemPlace.room,
        icon: 'note',
        hold: ItemHold.borrowed,
        hint: 'This belongs to the studio'),
  ];

  static List<StarterItem> of(TripKind kind) => switch (kind) {
        TripKind.city => city,
        TripKind.beach => beach,
        TripKind.outdoors => outdoors,
        TripKind.work => work,
      };
}

class PackMath {
  PackMath._();

  static List<PackItem> inTrip(List<PackItem> items, String tripId) {
    final rows = items.where((item) => item.tripId == tripId).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return rows;
  }

  static int packedCount(List<PackItem> items) =>
      items.where((item) => item.packed).length;

  static List<PackItem> toBringBack(List<PackItem> items) =>
      items.where((item) => item.packed).toList();

  static bool accounted(PackItem item) => item.back != ReturnMark.pending;

  static int accountedCount(List<PackItem> items) =>
      items.where(accounted).length;

  static int stillOut(List<PackItem> items) =>
      items.where((item) => item.back == ReturnMark.pending).length;

  static bool canFinish(List<PackItem> items) =>
      items.isNotEmpty && stillOut(items) == 0;

  static int percent(int part, int total) {
    if (total <= 0) return 0;
    return ((part / total) * 100).round();
  }

  static (int, int) groupCount(List<PackItem> items, ItemGroup group) {
    final rows = items.where((item) => item.group == group).toList();
    return (rows.where((item) => item.packed).length, rows.length);
  }
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec'
];

String ymd(DateTime value) {
  final day = DateTime(value.year, value.month, value.day);
  final month = day.month.toString().padLeft(2, '0');
  final date = day.day.toString().padLeft(2, '0');
  return '${day.year}-$month-$date';
}

DateTime parseDay(String raw) {
  final head = raw.split('T').first;
  final parts = head.split('-');
  if (parts.length < 3) return DateTime.now();
  final year = int.tryParse(parts[0]) ?? DateTime.now().year;
  final month = int.tryParse(parts[1]) ?? 1;
  final day = int.tryParse(parts[2]) ?? 1;
  return DateTime(year, month, day);
}

int spanDays(DateTime start, DateTime end) {
  final days = DateTime(end.year, end.month, end.day)
          .difference(DateTime(start.year, start.month, start.day))
          .inDays +
      1;
  return days < 1 ? 1 : days;
}

String rangeLabel(DateTime start, DateTime end) {
  final a = DateTime(start.year, start.month, start.day);
  final b = DateTime(end.year, end.month, end.day);
  if (a == b) return '${_months[a.month - 1]} ${a.day}';
  if (a.month == b.month && a.year == b.year) {
    return '${_months[a.month - 1]} ${a.day}–${b.day}';
  }
  return '${_months[a.month - 1]} ${a.day} – ${_months[b.month - 1]} ${b.day}';
}

String daysLabel(int days) => days == 1 ? '1 day' : '$days days';

String kindLabel(TripKind kind) => switch (kind) {
      TripKind.city => 'City break',
      TripKind.beach => 'Beach',
      TripKind.outdoors => 'Outdoors',
      TripKind.work => 'Work',
    };

String bagLabel(BagKind bag) => switch (bag) {
      BagKind.cabin => 'Cabin bag',
      BagKind.backpack => 'Backpack',
      BagKind.checked => 'Checked bag',
    };

String groupLabel(ItemGroup group) => switch (group) {
      ItemGroup.essentials => 'Essentials',
      ItemGroup.tech => 'Tech',
      ItemGroup.clothes => 'Clothes',
      ItemGroup.toiletries => 'Toiletries',
    };

String placeLabel(ItemPlace place) => switch (place) {
      ItemPlace.room => 'Room',
      ItemPlace.bathroom => 'Bathroom',
      ItemPlace.bag => 'Bag',
    };

String returnLabel(ReturnMark mark) => switch (mark) {
      ReturnMark.pending => 'Still to check',
      ReturnMark.confirmed => 'Brought back',
      ReturnMark.usedUp => 'Used up',
      ReturnMark.left => 'Left behind',
      ReturnMark.moved => 'Moved',
    };

T _enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}
