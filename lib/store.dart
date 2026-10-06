import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'money.dart';

class BudgetStore extends ChangeNotifier {
  static const storageKey = 'room_budget_v1';

  final List<Room> _rooms = [];
  final List<FurnitureItem> _items = [];

  List<Room> get rooms => List.unmodifiable(_rooms);

  List<FurnitureItem> get items => List.unmodifiable(_items);

  int get roomCount => _rooms.length;

  int get itemCount => _items.length;

  List<FurnitureItem> itemsFor(String roomId) {
    return _items.where((item) => item.roomId == roomId).toList(growable: false);
  }

  double totalFor(String roomId) {
    final cents = itemsFor(roomId).fold<int>(0, (sum, item) => sum + item.lineCents);
    return cents / 100;
  }

  double get grandTotal {
    final cents = _items.fold<int>(0, (sum, item) => sum + item.lineCents);
    return cents / 100;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    _rooms.clear();
    _items.clear();
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          final map = Map<String, dynamic>.from(decoded);
          final rooms = map['rooms'];
          final items = map['items'];
          if (rooms is List) {
            for (final entry in rooms) {
              if (entry is Map) {
                final room = Room.tryParse(Map<String, dynamic>.from(entry));
                if (room != null) {
                  _rooms.add(room);
                }
              }
            }
          }
          if (items is List) {
            for (final entry in items) {
              if (entry is Map) {
                final item = FurnitureItem.tryParse(Map<String, dynamic>.from(entry));
                if (item != null && _rooms.any((room) => room.id == item.roomId)) {
                  _items.add(item);
                }
              }
            }
          }
        }
      } on FormatException {
        _rooms.clear();
        _items.clear();
      }
    }
    notifyListeners();
  }

  Future<void> addRoom({required String name, required String emoji}) async {
    _rooms.add(Room(id: _newId(), name: name.trim(), emoji: emoji));
    notifyListeners();
    await _persist();
  }

  Future<void> updateRoom({
    required String id,
    required String name,
    required String emoji,
  }) async {
    final index = _rooms.indexWhere((room) => room.id == id);
    if (index == -1) {
      return;
    }
    _rooms[index] = Room(id: id, name: name.trim(), emoji: emoji);
    notifyListeners();
    await _persist();
  }

  Future<void> deleteRoom(String id) async {
    _rooms.removeWhere((room) => room.id == id);
    _items.removeWhere((item) => item.roomId == id);
    notifyListeners();
    await _persist();
  }

  Future<void> addItem({
    required String roomId,
    required String name,
    required String emoji,
    required double price,
    required int quantity,
  }) async {
    if (!_rooms.any((room) => room.id == roomId)) {
      return;
    }
    _items.add(
      FurnitureItem(
        id: _newId(),
        roomId: roomId,
        name: name.trim(),
        emoji: emoji,
        price: roundMoney(price),
        quantity: quantity,
      ),
    );
    notifyListeners();
    await _persist();
  }

  Future<void> updateItem({
    required String id,
    required String roomId,
    required String name,
    required String emoji,
    required double price,
    required int quantity,
  }) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1 || !_rooms.any((room) => room.id == roomId)) {
      return;
    }
    _items[index] = FurnitureItem(
      id: id,
      roomId: roomId,
      name: name.trim(),
      emoji: emoji,
      price: roundMoney(price),
      quantity: quantity,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> deleteItem(String id) async {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
    await _persist();
  }

  String buildSummary() {
    final buffer = StringBuffer()
      ..writeln('Room Budget 💶')
      ..writeln('Furniture estimate');
    if (_rooms.isEmpty) {
      buffer
        ..writeln()
        ..writeln('No rooms yet 🏠')
        ..writeln('💶 Grand total: ${formatMoney(0)}');
      return buffer.toString().trimRight();
    }
    for (final room in _rooms) {
      buffer
        ..writeln()
        ..writeln('${room.emoji} ${room.name}');
      final roomItems = itemsFor(room.id);
      if (roomItems.isEmpty) {
        buffer.writeln('  No items yet');
      } else {
        for (final item in roomItems) {
          buffer.writeln(
            '  ${item.emoji} ${item.name} × ${item.quantity} — ${formatMoney(item.lineTotal)}',
          );
        }
      }
      buffer.writeln('  Room total: ${formatMoney(totalFor(room.id))}');
    }
    buffer
      ..writeln()
      ..writeln('💶 Grand total: ${formatMoney(grandTotal)}');
    return buffer.toString().trimRight();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode({
      'rooms': _rooms.map((room) => room.toJson()).toList(),
      'items': _items.map((item) => item.toJson()).toList(),
    });
    await prefs.setString(storageKey, payload);
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();
}

class BudgetScope extends InheritedNotifier<BudgetStore> {
  const BudgetScope({
    super.key,
    required BudgetStore store,
    required super.child,
  }) : super(notifier: store);

  static BudgetStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<BudgetScope>();
    assert(scope != null, 'BudgetScope was not found');
    return scope!.notifier!;
  }
}
