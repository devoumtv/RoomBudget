import 'money.dart';

class Room {
  const Room({
    required this.id,
    required this.name,
    required this.emoji,
  });

  final String id;
  final String name;
  final String emoji;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'emoji': emoji,
  };

  static Room? tryParse(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final emoji = json['emoji'];
    if (id is! String || name is! String || emoji is! String) {
      return null;
    }
    if (id.isEmpty || name.trim().isEmpty || emoji.isEmpty) {
      return null;
    }
    return Room(id: id, name: name.trim(), emoji: emoji);
  }
}

class FurnitureItem {
  const FurnitureItem({
    required this.id,
    required this.roomId,
    required this.name,
    required this.emoji,
    required this.price,
    required this.quantity,
  });

  final String id;
  final String roomId;
  final String name;
  final String emoji;
  final double price;
  final int quantity;

  int get lineCents => (price * 100).round() * quantity;

  double get lineTotal => lineCents / 100;

  Map<String, dynamic> toJson() => {
    'id': id,
    'roomId': roomId,
    'name': name,
    'emoji': emoji,
    'price': price,
    'quantity': quantity,
  };

  static FurnitureItem? tryParse(Map<String, dynamic> json) {
    final id = json['id'];
    final roomId = json['roomId'];
    final name = json['name'];
    final emoji = json['emoji'];
    final price = json['price'];
    final quantity = json['quantity'];
    if (id is! String ||
        roomId is! String ||
        name is! String ||
        emoji is! String ||
        price is! num ||
        quantity is! num) {
      return null;
    }
    final qty = quantity.round();
    if (id.isEmpty ||
        roomId.isEmpty ||
        name.trim().isEmpty ||
        emoji.isEmpty ||
        qty < 1 ||
        qty > 999) {
      return null;
    }
    final parsed = roundMoney(price.toDouble());
    if (parsed < 0) {
      return null;
    }
    return FurnitureItem(
      id: id,
      roomId: roomId,
      name: name.trim(),
      emoji: emoji,
      price: parsed,
      quantity: qty,
    );
  }
}

class RoomDraft {
  const RoomDraft({required this.name, required this.emoji});

  final String name;
  final String emoji;
}

class ItemDraft {
  const ItemDraft({
    required this.roomId,
    required this.name,
    required this.emoji,
    required this.price,
    required this.quantity,
  });

  final String roomId;
  final String name;
  final String emoji;
  final double price;
  final int quantity;
}

const roomEmojis = <String>[
  '🏠',
  '🛋️',
  '🛏️',
  '🍳',
  '🚿',
  '🪴',
  '👶',
  '💼',
  '📚',
  '🎮',
  '🍽️',
  '🚗',
];

const itemEmojis = <String>[
  '🛋️',
  '🪑',
  '🛏️',
  '💡',
  '📺',
  '🪞',
  '🖼️',
  '🪴',
  '🗄️',
  '🚪',
  '🧸',
  '📚',
  '🍽️',
  '☕',
  '🖥️',
  '🕰️',
];
