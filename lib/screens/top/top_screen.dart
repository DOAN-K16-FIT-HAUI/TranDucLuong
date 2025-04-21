import 'package:finance_app/core/app_routes.dart';
import 'package:finance_app/screens/account/account_screen.dart';
import 'package:finance_app/screens/group_note/group_note_screen.dart';
import 'package:finance_app/screens/report/report_screen.dart';
import 'package:finance_app/screens/top/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TopScreen extends StatefulWidget {
  const TopScreen({super.key});

  @override
  TopScreenState createState() => TopScreenState();
}

class TopScreenState extends State<TopScreen> {
  int _selectedIndex = 0;

  // Danh sách màn hình với const constructor
  static final List<Widget> _screens = [
    DashboardScreen(),
    GroupNoteScreen(),
    ReportScreen(),
    AccountScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      _addTransaction();
      return;
    }
    setState(() {
      _selectedIndex = index > 2 ? index - 1 : index;
    });
  }

  void _addTransaction() {
    if (mounted) {
      AppRoutes.navigateToTransaction(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    int bottomNavIndex = _selectedIndex < 2 ? _selectedIndex : _selectedIndex + 1;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: bottomNavIndex,
        onTap: _onItemTapped,
        items: _buildBottomNavigationBarItems(theme, l10n),
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      ),
    );
  }

  List<BottomNavigationBarItem> _buildBottomNavigationBarItems(ThemeData theme, AppLocalizations l10n) {
    int bottomNavIndex = _selectedIndex < 2 ? _selectedIndex : _selectedIndex + 1;

    return [
      _buildBottomNavItem(
        theme,
        Icons.home_outlined,
        Icons.home,
        0,
        bottomNavIndex,
        l10n.dashboardTitle,
      ),
      _buildBottomNavItem(
        theme,
        Icons.note_alt_outlined,
        Icons.note_alt,
        1,
        bottomNavIndex,
        l10n.groupNotesPlaceholder,
      ),
      BottomNavigationBarItem(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.add,
            color: theme.colorScheme.onPrimary,
            size: 30,
          ),
        ),
        label: '',
        tooltip: l10n.addTransactionTooltip,
      ),
      _buildBottomNavItem(
        theme,
        Icons.bar_chart_outlined,
        Icons.bar_chart,
        3,
        bottomNavIndex,
        l10n.reportsPlaceholder,
      ),
      _buildBottomNavItem(
        theme,
        Icons.person_outlined,
        Icons.person,
        4,
        bottomNavIndex,
        l10n.accountTitle,
      ),
    ];
  }

  BottomNavigationBarItem _buildBottomNavItem(
      ThemeData theme,
      IconData inactiveIcon,
      IconData activeIcon,
      int itemIndex,
      int currentBottomNavIndex,
      String label,
      ) {
    bool isSelected = itemIndex == currentBottomNavIndex;
    return BottomNavigationBarItem(
      icon: Icon(
        isSelected ? activeIcon : inactiveIcon,
        size: 26,
      ),
      label: '',
      tooltip: label,
    );
  }
}