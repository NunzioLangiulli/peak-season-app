import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../providers/app_navigation.dart';
import '../providers/home_controller.dart';
import '../providers/library_controller.dart';
import '../widgets/pill_nav_bar.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'shopping_list_screen.dart';
import '../data/food_repository.dart';
import '../widgets/help_button.dart';
import 'detail_sections_screen.dart';
import 'family_screen.dart';
import 'food_detail_screen.dart';
import 'storage_tips_screen.dart';
import '../theme/app_backdrop.dart';

/// Container of the 3 tabs with the floating pill bar.
/// IndexedStack keeps the state (scroll, filters) when switching tabs.
/// The active tab lives in [AppNavigation], so a notification can change it too.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  late final AppNavigation _nav = context.read<AppNavigation>();

  @override
  void initState() {
    super.initState();
    _nav.addListener(_consumePending);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _consumePending();
      if (kIsWeb) _openPreviewTarget();
    });
  }

  /// Web preview only: `?tab=1`, `?route=storage`, `?food=<id>`
  /// open a page directly (used by scripts/preview_screens.py).
  void _openPreviewTarget() {
    final q = Uri.base.queryParameters;
    final tab = int.tryParse(q['tab'] ?? '');
    if (tab != null) _nav.selectTab(tab);
    if (q['route'] == 'storage') {
      _nav.open(route: AppNavigation.routeStorageTips);
    }
    if (q['route'] == 'sections') {
      Navigator.of(context).push(AppPageRoute(builder: (_) => const DetailSectionsScreen()));
    }
    final month = int.tryParse(q['month'] ?? '');
    if (month != null) context.read<HomeController>().setMonth(month - 1);
    final help = q['help'];
    if (help != null) {
      HelpSheet.show(context, context.read<FoodDatabase>().entries([help]));
    }
    final family = q['family'];
    if (family != null) {
      Navigator.of(context).push(AppPageRoute(builder: (_) => FamilyScreen(family: family)));
    }
    final food = q['food'];
    if (food != null) {
      Navigator.of(context).push(AppPageRoute(builder: (_) => FoodDetailScreen(itemId: food)));
    }
  }

  @override
  void dispose() {
    _nav.removeListener(_consumePending);
    super.dispose();
  }

  void _consumePending() {
    if (_nav.pendingMonth != null) {
      context.read<HomeController>().setMonth(_nav.pendingMonth!);
      _nav.pendingMonth = null;
    }
    if (_nav.pendingRoute == AppNavigation.routeStorageTips) {
      _nav.pendingRoute = null;
      Navigator.of(context).push(
        AppPageRoute(builder: (_) => const StorageTipsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final tab = context.watch<AppNavigation>().tab;
    final listCount = context.select<LibraryController, int>((l) => l.shoppingListIds.length);
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: tab,
        children: const [HomeScreen(), ShoppingListScreen(), SettingsScreen()],
      ),
      bottomNavigationBar: PillNavBar(
        selectedIndex: tab,
        onSelected: _nav.selectTab,
        items: [
          PillNavItem(
            icon: 'nav.home',
            selectedIcon: 'nav.home',
            label: s.tabPeakSeason,
          ),
          PillNavItem(
            icon: 'nav.shopping',
            selectedIcon: 'nav.shopping',
            label: s.tabShopping,
            badgeCount: listCount,
          ),
          PillNavItem(
            icon: 'nav.settings',
            selectedIcon: 'nav.settings',
            label: s.tabSettings,
          ),
        ],
      ),
    );
  }
}
