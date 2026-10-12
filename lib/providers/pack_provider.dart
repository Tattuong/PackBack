import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/pack/pack_logic.dart';
import '../core/services/storage_service.dart';
import 'shop_provider.dart';

class PackProvider extends ChangeNotifier {
  PackProvider(this.shop);

  static const _key = 'pb_pack';
  static const _lookKey = 'pb_demo_look';
  static const _demoIds = {'lisbon', 'office'};

  final ShopProvider shop;
  final _uuid = const Uuid();
  final List<PackTrip> _trips = [];
  final List<PackItem> _items = [];

  List<PackTrip> get trips {
    final rows = [..._trips]..sort((a, b) => a.start.compareTo(b.start));
    return rows;
  }

  bool get canAdd => _trips.length < shop.maxArchive;

  PackTrip? findTrip(String id) {
    for (final trip in _trips) {
      if (trip.id == id) return trip;
    }
    return null;
  }

  PackItem? findItem(String id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  List<PackItem> itemsOf(String tripId) => PackMath.inTrip(_items, tripId);

  Future<void> init() async {
    final raw = await StorageService.instance.getData(_key);
    _trips
      ..clear()
      ..addAll(_maps(raw?['trips'])
          .map(PackTrip.fromJson)
          .where((trip) => trip.name.trim().isNotEmpty && trip.id.isNotEmpty));
    _items
      ..clear()
      ..addAll(_maps(raw?['items']).map(PackItem.fromJson).where(
          (item) => item.name.trim().isNotEmpty && item.tripId.isNotEmpty));
    final look = await StorageService.instance.getInt(_lookKey) ?? 0;
    if (look < 3) {
      final before = _trips.length + _items.length;
      _trips.removeWhere((trip) => _demoIds.contains(trip.id));
      _items.removeWhere((item) => _demoIds.contains(item.tripId));
      if (_trips.length + _items.length != before) {
        await _save();
      }
      await StorageService.instance.saveInt(_lookKey, 3);
    }
    notifyListeners();
  }

  Future<PackTrip?> create({
    required String name,
    required DateTime start,
    required DateTime end,
    required TripKind kind,
    required BagKind bag,
  }) async {
    final title = name.trim();
    if (title.isEmpty || !canAdd) return null;
    final trip = PackTrip(
      id: _uuid.v4(),
      name: title,
      start: DateTime(start.year, start.month, start.day),
      end: DateTime(end.year, end.month, end.day),
      kind: kind,
      bag: bag,
      created: DateTime.now(),
    );
    if (trip.end.isBefore(trip.start)) trip.end = trip.start;
    _trips.add(trip);
    final starter = PackTemplates.of(kind);
    for (var i = 0; i < starter.length; i++) {
      final row = starter[i];
      _items.add(
        PackItem(
          id: _uuid.v4(),
          tripId: trip.id,
          name: row.name,
          group: row.group,
          place: row.place,
          icon: row.icon,
          hold: row.hold,
          hint: row.hint,
          order: i,
        ),
      );
    }
    await shop.rewardForTrip();
    await _save();
    notifyListeners();
    return trip;
  }

  Future<void> updateTrip(
    PackTrip trip, {
    required String name,
    required DateTime start,
    required DateTime end,
    required TripKind kind,
    required BagKind bag,
  }) async {
    final title = name.trim();
    if (title.isEmpty) return;
    trip.name = title;
    trip.start = DateTime(start.year, start.month, start.day);
    trip.end = DateTime(end.year, end.month, end.day);
    if (trip.end.isBefore(trip.start)) trip.end = trip.start;
    trip.kind = kind;
    trip.bag = bag;
    await _save();
    notifyListeners();
  }

  Future<PackItem?> addItem(
    String tripId, {
    required String name,
    required ItemGroup group,
    required ItemPlace place,
    required ItemHold hold,
  }) async {
    if (findTrip(tripId) == null) return null;
    final title = name.trim();
    if (title.isEmpty) return null;
    final order = itemsOf(tripId)
            .fold(0, (max, item) => item.order > max ? item.order : max) +
        1;
    final item = PackItem(
      id: _uuid.v4(),
      tripId: tripId,
      name: title,
      group: group,
      place: place,
      hold: hold,
      icon: 'box',
      order: order,
    );
    _items.add(item);
    _touch(tripId);
    await _save();
    notifyListeners();
    return item;
  }

  Future<void> setPacked(String id, bool packed) async {
    final item = findItem(id);
    if (item == null || item.packed == packed) return;
    item.packed = packed;
    if (!packed) item.back = ReturnMark.pending;
    _touch(item.tripId);
    await _save();
    notifyListeners();
  }

  Future<void> setReturn(String id, ReturnMark mark) async {
    final item = findItem(id);
    if (item == null) return;
    item.back = mark;
    if (mark != ReturnMark.pending) item.packed = true;
    _touch(item.tripId);
    await _save();
    notifyListeners();
  }

  Future<void> setHold(String id, ItemHold hold) async {
    final item = findItem(id);
    if (item == null || item.hold == hold) return;
    item.hold = hold;
    await _save();
    notifyListeners();
  }

  Future<bool> moveItem(String id, String toTripId) async {
    final item = findItem(id);
    final target = findTrip(toTripId);
    if (item == null || target == null || item.tripId == toTripId) return false;
    final from = item.tripId;
    item.tripId = toTripId;
    item.packed = false;
    item.back = ReturnMark.pending;
    item.order = itemsOf(toTripId)
            .fold(0, (max, row) => row.order > max ? row.order : max) +
        1;
    _touch(from);
    _touch(toTripId);
    await _save();
    notifyListeners();
    return true;
  }

  Future<void> deleteItem(String id) async {
    final item = findItem(id);
    if (item == null) return;
    final tripId = item.tripId;
    _items.removeWhere((row) => row.id == id);
    _touch(tripId);
    await _save();
    notifyListeners();
  }

  Future<void> deleteTrip(String id) async {
    _trips.removeWhere((trip) => trip.id == id);
    _items.removeWhere((item) => item.tripId == id);
    await _save();
    notifyListeners();
  }

  Future<void> finishReturn(String tripId) async {
    final trip = findTrip(tripId);
    if (trip == null || !PackMath.canFinish(itemsOf(tripId))) return;
    trip.broughtBack = true;
    await _save();
    notifyListeners();
  }

  void _touch(String tripId) {
    final trip = findTrip(tripId);
    if (trip != null) trip.broughtBack = false;
  }

  List<Map<String, dynamic>> _maps(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<void> _save() async {
    await StorageService.instance.saveData(_key, {
      'trips': _trips.map((trip) => trip.toJson()).toList(),
      'items': _items.map((item) => item.toJson()).toList(),
    });
  }
}
