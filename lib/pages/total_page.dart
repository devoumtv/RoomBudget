import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../money.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';

class TotalPage extends StatelessWidget {
  const TotalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = BudgetScope.of(context);
    final rooms = store.rooms;
    return Column(
      children: [
        const PageHeader(
          emoji: '💶',
          title: 'Total',
          subtitle: 'Your furniture estimate, room by room',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            children: [
              Entrance(
                index: 0,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    children: [
                      const Text('💰', style: TextStyle(fontSize: 28)),
                      const SizedBox(height: 6),
                      const Text(
                        'Grand total',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedMoney(
                        key: const Key('grand-total'),
                        value: store.grandTotal,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${store.roomCount == 1 ? '1 room' : '${store.roomCount} rooms'} · ${store.itemCount == 1 ? '1 item' : '${store.itemCount} items'}',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (rooms.isEmpty)
                const Entrance(
                  index: 1,
                  child: SoftCard(
                    child: Text(
                      'Nothing to total yet ✨\nAdd rooms and furniture, and the estimate will grow here.',
                      style: TextStyle(color: AppColors.ink, height: 1.4),
                    ),
                  ),
                )
              else
                for (var i = 0; i < rooms.length; i++)
                  Entrance(
                    index: i + 1,
                    child: _RoomTotalCard(roomId: rooms[i].id),
                  ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: CopyEstimateButton(),
        ),
      ],
    );
  }
}

class _RoomTotalCard extends StatelessWidget {
  const _RoomTotalCard({required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context) {
    final store = BudgetScope.of(context);
    final room = store.rooms.firstWhere((entry) => entry.id == roomId);
    final items = store.itemsFor(room.id);
    final total = store.totalFor(room.id);
    final share = store.grandTotal == 0 ? 0.0 : total / store.grandTotal;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(room.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  room.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                formatMoney(total),
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: share.clamp(0, 1),
              minHeight: 8,
              backgroundColor: AppColors.ice,
              color: AppColors.blue,
            ),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const Text(
              'No items yet',
              style: TextStyle(color: AppColors.muted),
            )
          else
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${item.emoji} ${item.name} × ${item.quantity} · ${formatMoney(item.lineTotal)}',
                  style: const TextStyle(color: AppColors.ink),
                ),
              ),
        ],
      ),
    );
  }
}

class AnimatedMoney extends StatefulWidget {
  const AnimatedMoney({
    super.key,
    required this.value,
    required this.style,
  });

  final double value;
  final TextStyle style;

  @override
  State<AnimatedMoney> createState() => _AnimatedMoneyState();
}

class _AnimatedMoneyState extends State<AnimatedMoney>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _animation = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedMoney oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(begin: _animation.value, end: widget.value).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Text(formatMoney(_animation.value), style: widget.style);
      },
    );
  }
}

class CopyEstimateButton extends StatefulWidget {
  const CopyEstimateButton({super.key});

  @override
  State<CopyEstimateButton> createState() => _CopyEstimateButtonState();
}

class _CopyEstimateButtonState extends State<CopyEstimateButton> {
  bool _copied = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    final store = BudgetScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: store.buildSummary()));
    if (!mounted) {
      return;
    }
    setState(() => _copied = true);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard 📋'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(16, 0, 16, 108),
        ),
      );
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GradientButton(
          key: const Key('copy-total'),
          label: _copied ? '✅ Copied' : '📋 Copy estimate',
          onPressed: _copy,
        ),
        const SizedBox(height: 6),
        const Text(
          'Copies every room, item, and total',
          style: TextStyle(color: Color(0xE6FFFFFF), fontSize: 12),
        ),
      ],
    );
  }
}
