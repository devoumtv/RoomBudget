import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../money.dart';
import '../theme.dart';
import 'common.dart';

Future<RoomDraft?> showRoomEditor(BuildContext context, {Room? existing}) {
  return showAppSheet<RoomDraft>(
    context,
    (context) => RoomEditor(existing: existing),
  );
}

Future<ItemDraft?> showItemEditor(
  BuildContext context, {
  required List<Room> rooms,
  FurnitureItem? existing,
  String? initialRoomId,
}) {
  return showAppSheet<ItemDraft>(
    context,
    (context) => ItemEditor(
      rooms: rooms,
      existing: existing,
      initialRoomId: initialRoomId,
    ),
  );
}

class RoomEditor extends StatefulWidget {
  const RoomEditor({super.key, this.existing});

  final Room? existing;

  @override
  State<RoomEditor> createState() => _RoomEditorState();
}

class _RoomEditorState extends State<RoomEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late String _emoji;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _emoji = widget.existing?.emoji ?? roomEmojis.first;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  List<String> get _emojis {
    final current = widget.existing?.emoji;
    if (current != null && !roomEmojis.contains(current)) {
      return [current, ...roomEmojis];
    }
    return roomEmojis;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.pop(
      context,
      RoomDraft(name: _name.text.trim(), emoji: _emoji),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Grabber(),
            Text(
              editing ? 'Edit room ✏️' : 'New room 🏠',
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pick an emoji and name the space.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            const Text(
              'Emoji',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            EmojiPicker(
              emojis: _emojis,
              selected: _emoji,
              onSelected: (emoji) => setState(() => _emoji = emoji),
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('room-name-field'),
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              maxLength: 40,
              buildCounter: _hideCounter,
              decoration: const InputDecoration(
                labelText: 'Room name',
                hintText: 'Living room',
              ),
              validator: validateName,
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),
            GradientButton(
              key: const Key('save-entry'),
              label: '💾 Save',
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class ItemEditor extends StatefulWidget {
  const ItemEditor({
    super.key,
    required this.rooms,
    this.existing,
    this.initialRoomId,
  });

  final List<Room> rooms;
  final FurnitureItem? existing;
  final String? initialRoomId;

  @override
  State<ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends State<ItemEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late String _emoji;
  late String _roomId;
  late int _quantity;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _price = TextEditingController(
      text: existing == null ? '' : existing.price.toStringAsFixed(2),
    );
    _emoji = existing?.emoji ?? itemEmojis.first;
    _quantity = existing?.quantity ?? 1;
    final requested = existing?.roomId ?? widget.initialRoomId;
    _roomId = widget.rooms.any((room) => room.id == requested)
        ? requested!
        : widget.rooms.first.id;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  List<String> get _emojis {
    final current = widget.existing?.emoji;
    if (current != null && !itemEmojis.contains(current)) {
      return [current, ...itemEmojis];
    }
    return itemEmojis;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final price = parsePrice(_price.text);
    if (price == null) {
      return;
    }
    Navigator.pop(
      context,
      ItemDraft(
        roomId: _roomId,
        name: _name.text.trim(),
        emoji: _emoji,
        price: price,
        quantity: _quantity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Grabber(),
            Text(
              editing ? 'Edit item ✏️' : 'New item 🪑',
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Prices are in euros €. This is your estimate.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            const Text(
              'Room',
              style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final room in widget.rooms)
                  ChoiceChip(
                    label: Text('${room.emoji} ${room.name}'),
                    selected: _roomId == room.id,
                    onSelected: (_) => setState(() => _roomId = room.id),
                    selectedColor: AppColors.blue,
                    backgroundColor: AppColors.ice,
                    labelStyle: TextStyle(
                      color: _roomId == room.id ? Colors.white : AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                    side: BorderSide.none,
                    showCheckmark: false,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Emoji',
              style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            EmojiPicker(
              emojis: _emojis,
              selected: _emoji,
              onSelected: (emoji) => setState(() => _emoji = emoji),
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('item-name-field'),
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              maxLength: 40,
              buildCounter: _hideCounter,
              decoration: const InputDecoration(
                labelText: 'Furniture name',
                hintText: 'Sofa',
              ),
              validator: validateName,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('item-price-field'),
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Price each',
                hintText: '0.00',
                prefixText: '€ ',
              ),
              validator: (value) {
                if (parsePrice(value ?? '') == null) {
                  return 'Enter a price in euros';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Quantity',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _QtyButton(
                  key: const Key('qty-minus'),
                  label: '−',
                  onPressed: _quantity > 1
                      ? () => setState(() => _quantity -= 1)
                      : null,
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    '$_quantity',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _QtyButton(
                  key: const Key('qty-plus'),
                  label: '+',
                  onPressed: _quantity < 999
                      ? () => setState(() => _quantity += 1)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            GradientButton(
              key: const Key('save-entry'),
              label: '💾 Save',
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class EmojiPicker extends StatelessWidget {
  const EmojiPicker({
    super.key,
    required this.emojis,
    required this.selected,
    required this.onSelected,
  });

  final List<String> emojis;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final emoji in emojis)
          GestureDetector(
            onTap: () => onSelected(emoji),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: emoji == selected ? AppColors.button : null,
                color: emoji == selected ? null : AppColors.ice,
                borderRadius: BorderRadius.circular(14),
                boxShadow: emoji == selected
                    ? const [
                        BoxShadow(
                          color: Color(0x330D6EDE),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
      ],
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 5,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFD3E4F5),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onPressed == null ? const Color(0xFFE8EEF4) : AppColors.ice,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: onPressed == null ? AppColors.muted : AppColors.navy,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget? _hideCounter(
  BuildContext context, {
  required int currentLength,
  required bool isFocused,
  required int? maxLength,
}) {
  return null;
}
