import 'package:flutter_test/flutter_test.dart';
import 'package:room_budget/money.dart';
import 'package:room_budget/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('formats euro amounts', () {
    expect(formatMoney(0), '€0.00');
    expect(formatMoney(241), '€241.00');
    expect(formatMoney(1200.5), '€1,200.50');
    expect(parsePrice('120,50'), 120.5);
    expect(parsePrice(''), isNull);
  });

  test('starts empty, saves, and reloads', () async {
    final store = BudgetStore();
    await store.load();
    expect(store.rooms, isEmpty);
    expect(store.grandTotal, 0);
    expect(
      store.buildSummary(),
      'Room Budget 💶\n'
      'Furniture estimate\n'
      '\n'
      'No rooms yet 🏠\n'
      '💶 Grand total: €0.00',
    );

    await store.addRoom(name: 'Living room', emoji: '🏠');
    final roomId = store.rooms.single.id;
    await store.addItem(
      roomId: roomId,
      name: 'Sofa',
      emoji: '🛋️',
      price: 120.5,
      quantity: 2,
    );

    expect(store.grandTotal, 241);
    expect(store.buildSummary(), contains('🛋️ Sofa × 2 — €241.00'));
    expect(store.buildSummary(), contains('💶 Grand total: €241.00'));

    final reloaded = BudgetStore();
    await reloaded.load();
    expect(reloaded.rooms.single.name, 'Living room');
    expect(reloaded.items.single.name, 'Sofa');
    expect(reloaded.grandTotal, 241);

    await reloaded.deleteRoom(roomId);
    expect(reloaded.rooms, isEmpty);
    expect(reloaded.items, isEmpty);

    final afterDelete = BudgetStore();
    await afterDelete.load();
    expect(afterDelete.rooms, isEmpty);
  });

  test('ignores unreadable storage', () async {
    SharedPreferences.setMockInitialValues({
      BudgetStore.storageKey: '{not json',
    });
    final store = BudgetStore();
    await store.load();
    expect(store.rooms, isEmpty);
    expect(store.items, isEmpty);
  });
}
