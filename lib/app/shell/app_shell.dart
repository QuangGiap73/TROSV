import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _BottomTabBar(
        selectedIndex: _tabIndexFromPath(currentPath),
        onSelected: (index) {
          const routes = [
            '/',
            '/search',
            '/roommate',
            '/favorites',
            '/profile',
          ];
          context.go(routes[index]);
        },
      ),
    );
  }

  int _tabIndexFromPath(String path) {
    if (path == '/profile' || path.startsWith('/profile/')) return 4;
    if (path == '/favorites' || path.startsWith('/favorites/')) return 3;
    if (path == '/roommate' || path.startsWith('/roommate/')) return 2;
    if (path == '/search' || path.startsWith('/search/')) return 1;
    return 0;
  }
}

class _BottomTabBar extends StatelessWidget {
  const _BottomTabBar({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = <_TabItem>[
    _TabItem(Icons.home_outlined, Icons.home_rounded, 'Trang chủ'),
    _TabItem(Icons.search_rounded, Icons.search_rounded, 'Tìm trọ'),
    _TabItem(Icons.group_outlined, Icons.group_rounded, 'Ở ghép'),
    _TabItem(Icons.favorite_border_rounded, Icons.favorite_rounded, 'Đã lưu'),
    _TabItem(Icons.person_outline_rounded, Icons.person_rounded, 'Cá nhân'),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE8E2D8))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .07),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final selected = index == selectedIndex;
              final color = selected
                  ? const Color(0xFF008E79)
                  : const Color(0xFF6D9297);

              return Expanded(
                child: InkWell(
                  key: ValueKey('bottom-tab-$index'),
                  onTap: () => onSelected(index),
                  child: Semantics(
                    selected: selected,
                    label: item.label,
                    button: true,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 7, bottom: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: Icon(
                              selected ? item.selectedIcon : item.icon,
                              key: ValueKey(selected),
                              size: 21,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 3),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              item.label,
                              maxLines: 1,
                              style: TextStyle(
                                color: color,
                                fontSize: 10,
                                height: 1,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem(this.icon, this.selectedIcon, this.label);

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
