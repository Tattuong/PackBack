import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:packback/core/constants/iap_constants.dart';
import 'package:packback/core/pack/pack_logic.dart';
import 'package:packback/core/services/hive_service.dart';
import 'package:packback/core/services/storage_service.dart';
import 'package:packback/providers/pack_provider.dart';
import 'package:packback/providers/shop_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('pb_pack');
    await HiveService.init(path: dir.path, suffix: '_pack');
    await StorageService.instance.init();
  });

  setUp(() async {
    await HiveService.kv.clear();
  });
  test('bring back ignores items that were never packed', () {
    final items = [
      PackItem(
          id: '1',
          tripId: 't',
          name: 'Passport',
          group: ItemGroup.essentials,
          place: ItemPlace.bag,
          icon: 'passport',
          packed: true,
          back: ReturnMark.confirmed),
      PackItem(
          id: '2',
          tripId: 't',
          name: 'Charger',
          group: ItemGroup.tech,
          place: ItemPlace.room,
          icon: 'charger'),
    ];
    expect(PackMath.toBringBack(items).map((item) => item.name), ['Passport']);
    expect(PackMath.canFinish(items), isFalse);
    items.last.back = ReturnMark.confirmed;
    expect(PackMath.canFinish(items), isTrue);
    expect(PackMath.stillOut(items), 0);
  });

  test('a city break spans the sample dates', () {
    final start = DateTime(2026, 10, 16);
    final end = DateTime(2026, 10, 19);
    expect(rangeLabel(start, end), 'Oct 16–19');
    expect(spanDays(start, end), 4);
    expect(daysLabel(1), '1 day');
    expect(PackTemplates.city, hasLength(12));
    expect(PackTemplates.work, hasLength(4));
  });

  test('demo trips are removed, and a ninth trip is refused', () async {
    final day = DateTime(2026, 10, 16);
    PackTrip trip(String id, String name) => PackTrip(
          id: id,
          name: name,
          start: day,
          end: day,
          kind: TripKind.city,
          bag: BagKind.cabin,
          created: day,
        );
    await StorageService.instance.saveData('pb_pack', {
      'trips': [
        trip('lisbon', 'Lisbon').toJson(),
        trip('office', 'Studio desk').toJson(),
        trip('mine', 'Home').toJson(),
      ],
      'items': [
        PackItem(
          id: 'lisbon-0',
          tripId: 'lisbon',
          name: 'Passport',
          group: ItemGroup.essentials,
          place: ItemPlace.bag,
          icon: 'passport',
        ).toJson(),
        PackItem(
          id: 'mine-0',
          tripId: 'mine',
          name: 'Keys',
          group: ItemGroup.essentials,
          place: ItemPlace.bag,
          icon: 'box',
        ).toJson(),
      ],
    });
    final shop = ShopProvider();
    await shop.init(remote: false);
    final board = PackProvider(shop);
    await board.init();
    expect(board.trips.map((row) => row.id), ['mine']);
    expect(board.itemsOf('mine').map((row) => row.name), ['Keys']);
    final again = PackProvider(shop);
    await again.init();
    expect(again.trips.map((row) => row.id), ['mine']);
    for (var i = 0; i < IapConstants.freeArchiveLimit - 1; i++) {
      expect(
        await again.create(
            name: 'Trip $i',
            start: DateTime(2026, 11, 1),
            end: DateTime(2026, 11, 3),
            kind: TripKind.work,
            bag: BagKind.backpack),
        isNotNull,
      );
    }
    expect(
      await again.create(
          name: 'One more',
          start: DateTime(2026, 11, 1),
          end: DateTime(2026, 11, 3),
          kind: TripKind.city,
          bag: BagKind.cabin),
      isNull,
    );
  });
}
