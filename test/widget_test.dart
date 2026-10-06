import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room_budget/main.dart';
import 'package:room_budget/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('user can add, edit, delete, and copy an empty budget', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );

    final store = BudgetStore();
    await store.load();
    await tester.pumpWidget(RoomBudgetApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('No rooms yet'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-room')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('room-name-field')), 'Living room');
    await tester.tap(find.byKey(const Key('save-entry')));
    await tester.pumpAndSettle();
    expect(find.text('Living room'), findsWidgets);

    await tester.tap(find.byKey(const Key('nav-items')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-item')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('item-name-field')), 'Sofa');
    await tester.enterText(find.byKey(const Key('item-price-field')), '120.50');
    await tester.tap(find.byKey(const Key('qty-plus')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('save-entry')));
    await tester.pumpAndSettle();
    expect(find.text('Sofa'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-total')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('grand-total')),
        matching: find.text('€241.00'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('copy-total')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('✅ Copied'), findsOneWidget);
    expect(find.text('Copied to clipboard 📋'), findsOneWidget);
    expect(copied, contains('🛋️ Sofa × 2 — €241.00'));
    expect(copied, contains('💶 Grand total: €241.00'));

    await tester.tap(find.byKey(const Key('nav-rooms')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit room'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('room-name-field')), 'Bedroom');
    await tester.tap(find.byKey(const Key('save-entry')));
    await tester.pumpAndSettle();
    expect(find.text('Bedroom'), findsWidgets);
    expect(find.text('Living room'), findsNothing);

    await tester.tap(find.byTooltip('Delete room'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Bedroom'), findsWidgets);

    await tester.tap(find.byTooltip('Delete room'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('No rooms yet'), findsOneWidget);
    expect(store.items, isEmpty);
    expect(store.grandTotal, 0);
  });
}
