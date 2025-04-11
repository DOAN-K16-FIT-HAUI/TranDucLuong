import 'package:finance_app/core/app_routes.dart';
import 'package:finance_app/screens/account/account_screen.dart';
import 'package:finance_app/screens/top/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    _PlaceholderScreen(placeholderKey: 'group_notes'),
    _PlaceholderScreen(placeholderKey: 'reports'),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _addTransaction,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        tooltip: l10n.addTransactionTooltip, // Thêm tooltip từ l10n
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
        l10n.dashboardTitle, // Thêm label từ l10n cho tooltip
      ),
      _buildBottomNavItem(
        theme,
        Icons.note_alt_outlined,
        Icons.note_alt,
        1,
        bottomNavIndex,
        l10n.groupNotesPlaceholder,
      ),
      const BottomNavigationBarItem(icon: SizedBox.shrink(), label: ''),
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
      String label, // Thêm label từ l10n
      ) {
    bool isSelected = itemIndex == currentBottomNavIndex;
    return BottomNavigationBarItem(
      icon: Icon(
        isSelected ? activeIcon : inactiveIcon,
        size: 26,
      ),
      label: '', // Giữ trống để ẩn label
      tooltip: label, // Sử dụng label từ l10n làm tooltip
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String placeholderKey;

  const _PlaceholderScreen({required this.placeholderKey});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    String displayText;
    switch (placeholderKey) {
      case 'group_notes':
        displayText = l10n.groupNotesPlaceholder;
        break;
      case 'reports':
        displayText = l10n.reportsPlaceholder;
        break;
      default:
        displayText = placeholderKey;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          displayText,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Text(
          displayText,
          style: GoogleFonts.poppins(
            fontSize: 24,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}