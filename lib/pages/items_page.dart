import 'package:flutter/material.dart';

import '../models.dart';
import '../money.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/editors.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key});

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  String? _roomFilter;

  @override
  Widget build(BuildContext context) {
    final store = BudgetScope.of(context);
    final rooms = store.rooms;
    final filter = rooms.any((room) => room.id == _roomFilter) ? _roomFilter : null;
    final visibleRooms = filter == null
        ? rooms
        : rooms.where((room) => room.id == filter).toList(growable: false);

    return Column(
      children: [
        const PageHeader(
          emoji: '🪑',
          title: 'Items',
          subtitle: 'Add furniture, prices, and quantities',
        ),
        if (rooms.isEmpty)
          Expanded(
            child: EmptyView(
              emoji: '🏠',
              title: 'Add a room first',
              message: 'Furniture belongs to a room. Create one on the Rooms tab.',
              actionLabel: '🏠 Go to Rooms',
              actionKey: const Key('go-rooms'),
              onAction: () => AppTabs.of(context).goTo(0),
            ),
          )
        else ...[
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: rooms.length + 1,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final selected = index == 0 ? filter == null : rooms[index - 1].id == filter;
                final label = index == 0 ? '✨ All' : '${rooms[index - 1].emoji} ${rooms[index - 1].name}';
                return _FilterChip(
                  label: label,
                  selected: selected,
                  onTap: () {
                    setState(() {
                      _roomFilter = index == 0 ? null : rooms[index - 1].id;
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              children: [
                for (final room in visibleRooms) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 4),
                    child: Text(
                      '${room.emoji}  ${room.name}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (store.itemsFor(room.id).isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'No items in this room yet',
                        style: TextStyle(color: Color(0xE6FFFFFF)),
                      ),
                    )
                  else
                    for (var i = 0; i < store.itemsFor(room.id).length; i++)
                      Entrance(
                        index: i,
                        child: _ItemCard(item: store.itemsFor(room.id)[i]),
                      ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: GradientButton(
              key: const Key('add-item'),
              label: '➕ Add item',
              onPressed: () => _createItem(context, filter),
            ),
          ),
        ],
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected ? AppColors.button : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x220A3E86),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item});

  final FurnitureItem item;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.ice,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(item.emoji, style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatMoney(item.price)} each · × ${item.quantity}',
                  style: const TextStyle(color: AppColors.muted),
                ),
                Text(
                  formatMoney(item.lineTotal),
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          EmojiAction(
            emoji: '✏️',
            tooltip: 'Edit item',
            semanticsLabel: 'Edit ${item.name}',
            onPressed: () => _editItem(context, item),
          ),
          const SizedBox(width: 8),
          EmojiAction(
            emoji: '🗑️',
            tooltip: 'Delete item',
            semanticsLabel: 'Delete ${item.name}',
            onPressed: () => _deleteItem(context, item),
          ),
        ],
      ),
    );
  }
}

Future<void> _createItem(BuildContext context, String? roomId) async {
  final store = BudgetScope.of(context);
  if (store.rooms.isEmpty) {
    return;
  }
  final draft = await showItemEditor(
    context,
    rooms: store.rooms,
    initialRoomId: roomId,
  );
  if (draft == null) {
    return;
  }
  await store.addItem(
    roomId: draft.roomId,
    name: draft.name,
    emoji: draft.emoji,
    price: draft.price,
    quantity: draft.quantity,
  );
}

Future<void> _editItem(BuildContext context, FurnitureItem item) async {
  final store = BudgetScope.of(context);
  final draft = await showItemEditor(
    context,
    rooms: store.rooms,
    existing: item,
  );
  if (draft == null) {
    return;
  }
  await store.updateItem(
    id: item.id,
    roomId: draft.roomId,
    name: draft.name,
    emoji: draft.emoji,
    price: draft.price,
    quantity: draft.quantity,
  );
}

Future<void> _deleteItem(BuildContext context, FurnitureItem item) async {
  final store = BudgetScope.of(context);
  final ok = await confirmDelete(
    context,
    title: 'Delete this item?',
    message: '${item.emoji} ${item.name} will leave the estimate.',
  );
  if (!ok) {
    return;
  }
  await store.deleteItem(item.id);
}
