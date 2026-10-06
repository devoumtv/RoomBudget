import 'package:flutter/material.dart';

import '../models.dart';
import '../money.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/editors.dart';

class RoomsPage extends StatelessWidget {
  const RoomsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = BudgetScope.of(context);
    final rooms = store.rooms;
    return Column(
      children: [
        const PageHeader(
          emoji: '🏠',
          title: 'Rooms',
          subtitle: 'Name the spaces you want to furnish',
        ),
        Expanded(
          child: rooms.isEmpty
              ? EmptyView(
                  emoji: '🛋️',
                  title: 'No rooms yet',
                  message: 'Add a room to start estimating furniture. Your list begins empty.',
                  actionLabel: '➕ Add room',
                  actionKey: const Key('add-room'),
                  onAction: () => _createRoom(context),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    final count = store.itemsFor(room.id).length;
                    final countLabel = count == 1 ? '1 item' : '$count items';
                    return Entrance(
                      index: index,
                      child: SoftCard(
                        child: Row(
                          children: [
                            _EmojiBadge(emoji: room.emoji),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    room.name,
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
                                    '$countLabel · ${formatMoney(store.totalFor(room.id))}',
                                    style: const TextStyle(color: AppColors.muted),
                                  ),
                                ],
                              ),
                            ),
                            EmojiAction(
                              emoji: '✏️',
                              tooltip: 'Edit room',
                              semanticsLabel: 'Edit ${room.name}',
                              onPressed: () => _editRoom(context, room),
                            ),
                            const SizedBox(width: 8),
                            EmojiAction(
                              emoji: '🗑️',
                              tooltip: 'Delete room',
                              semanticsLabel: 'Delete ${room.name}',
                              onPressed: () => _deleteRoom(context, room),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (rooms.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: GradientButton(
              key: const Key('add-room'),
              label: '➕ Add room',
              onPressed: () => _createRoom(context),
            ),
          ),
      ],
    );
  }
}

class _EmojiBadge extends StatelessWidget {
  const _EmojiBadge({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.ice,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 26)),
    );
  }
}

Future<void> _createRoom(BuildContext context) async {
  final store = BudgetScope.of(context);
  final draft = await showRoomEditor(context);
  if (draft == null) {
    return;
  }
  await store.addRoom(name: draft.name, emoji: draft.emoji);
}

Future<void> _editRoom(BuildContext context, Room room) async {
  final store = BudgetScope.of(context);
  final draft = await showRoomEditor(context, existing: room);
  if (draft == null) {
    return;
  }
  await store.updateRoom(id: room.id, name: draft.name, emoji: draft.emoji);
}

Future<void> _deleteRoom(BuildContext context, Room room) async {
  final store = BudgetScope.of(context);
  final count = store.itemsFor(room.id).length;
  final extra = count == 0
      ? 'This room will be removed from your estimate.'
      : 'This also removes $count furniture ${count == 1 ? 'item' : 'items'} in this room.';
  final ok = await confirmDelete(
    context,
    title: 'Delete this room?',
    message: extra,
  );
  if (!ok) {
    return;
  }
  await store.deleteRoom(room.id);
}
