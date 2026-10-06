import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _BottomTabBar(
        selectedIndex: navigationShell.currentIndex,
        onSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

class _BottomTabBar extends StatelessWidget {
  const _BottomTabBar({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = <_TabItem>[
    _TabItem(Icons.home_outlined, Icons.home_rounded, 'Trang chủ'),
    _TabItem(Icons.search_rounded, Icons.search_rounded, 'Tìm trọ'),
    _TabItem(Icons.map_outlined, Icons.map_rounded, 'Bản đồ'),
    _TabItem(Icons.groups_outlined, Icons.groups_rounded, 'Ở ghép'),
    _TabItem(Icons.person_outline_rounded, Icons.person_rounded, 'Cá nhân'),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .12),
            blurRadius: 24,
            offset: const Offset(0, -7),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 70,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NavigationItem(item: _items[0], index: 0, selected: selectedIndex == 0, onTap: onSelected),
              _NavigationItem(item: _items[1], index: 1, selected: selectedIndex == 1, onTap: onSelected),
              _MapNavigationItem(selected: selectedIndex == 2, onTap: () => onSelected(2)),
              _NavigationItem(item: _items[3], index: 3, selected: selectedIndex == 3, onTap: onSelected),
              _NavigationItem(item: _items[4], index: 4, selected: selectedIndex == 4, onTap: onSelected),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({required this.item, required this.index, required this.selected, required this.onTap});

  final _TabItem item;
  final int index;
  final bool selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF008E79);
    const inactiveColor = Color(0xFF708784);
    final color = selected ? activeColor : inactiveColor;
    return Expanded(
      child: Semantics(
        selected: selected,
        label: item.label,
        button: true,
        child: InkWell(
          key: ValueKey('bottom-tab-$index'),
          borderRadius: BorderRadius.circular(18),
          onTap: () => onTap(index),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(3, 8, 3, 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: selected ? 5 : 0,
                  height: 5,
                  decoration: const BoxDecoration(color: activeColor, shape: BoxShape.circle),
                ),
                const SizedBox(height: 3),
                Icon(selected ? item.selectedIcon : item.icon, size: 23, color: color),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    style: TextStyle(
                      color: color,
                      fontSize: 10.5,
                      height: 1,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapNavigationItem extends StatelessWidget {
  const _MapNavigationItem({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        selected: selected,
        label: 'Bản đồ',
        button: true,
        child: Center(
          child: Transform.translate(
            offset: const Offset(0, -18),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: const ValueKey('bottom-tab-2'),
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF007E6C)
                        : const Color(0xFF00AE91),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF008E79).withValues(alpha: .38),
                        blurRadius: 16,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
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
