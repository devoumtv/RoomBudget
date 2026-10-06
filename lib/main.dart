import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pages/items_page.dart';
import 'pages/rooms_page.dart';
import 'pages/total_page.dart';
import 'store.dart';
import 'theme.dart';
import 'widgets/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  final store = BudgetStore();
  await store.load();
  runApp(RoomBudgetApp(store: store));
}

class RoomBudgetApp extends StatelessWidget {
  const RoomBudgetApp({super.key, required this.store});

  final BudgetStore store;

  @override
  Widget build(BuildContext context) {
    return BudgetScope(
      store: store,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Room Budget',
        theme: buildAppTheme(),
        themeMode: ThemeMode.light,
        home: const HomeShell(),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _goTo(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    const pages = [
      RoomsPage(key: ValueKey('rooms')),
      ItemsPage(key: ValueKey('items')),
      TotalPage(key: ValueKey('total')),
    ];
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.background),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: AppTabs(
                index: _index,
                goTo: _goTo,
                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          for (var i = 0; i < pages.length; i++)
                            ExcludeSemantics(
                              excluding: i != _index,
                              child: AnimatedOpacity(
                                opacity: i == _index ? 1 : 0,
                                duration: const Duration(milliseconds: 280),
                                curve: Curves.easeOutCubic,
                                child: AnimatedSlide(
                                  offset: i == _index
                                      ? Offset.zero
                                      : const Offset(0.04, 0),
                                  duration: const Duration(milliseconds: 280),
                                  curve: Curves.easeOutCubic,
                                  child: IgnorePointer(
                                    ignoring: i != _index,
                                    child: TickerMode(
                                      enabled: i == _index,
                                      child: pages[i],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    _NavBar(index: _index, onChanged: _goTo),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const _tabs = [
    (emoji: '🏠', label: 'Rooms', key: Key('nav-rooms')),
    (emoji: '🪑', label: 'Items', key: Key('nav-items')),
    (emoji: '💶', label: 'Total', key: Key('nav-total')),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(
              color: Color(0x330D47A1),
              blurRadius: 22,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              for (var i = 0; i < _tabs.length; i++)
                Expanded(
                  child: _NavItem(
                    buttonKey: _tabs[i].key,
                    emoji: _tabs[i].emoji,
                    label: _tabs[i].label,
                    selected: i == index,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onChanged(i);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.buttonKey,
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Key buttonKey;
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        key: buttonKey,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.button : null,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: selected ? 1.08 : 1,
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                child: ExcludeSemantics(
                  child: Text(emoji, style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
