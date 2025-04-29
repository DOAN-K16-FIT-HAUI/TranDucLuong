import 'package:finance_app/blocs/group_note/group_note_bloc.dart';
import 'package:finance_app/core/app_routes.dart';
import 'package:finance_app/screens/account/account_screen.dart';
import 'package:finance_app/screens/group_note/group_note_screen.dart';
import 'package:finance_app/screens/report/report_screen.dart';
import 'package:finance_app/screens/top/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';

class TopScreen extends StatefulWidget {
  const TopScreen({super.key});

  @override
  TopScreenState createState() => TopScreenState();
}

class TopScreenState extends State<TopScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = [
    DashboardScreen(),
    BlocProvider.value(
      value: GetIt.instance<GroupNoteBloc>(),
      child: const GroupNoteScreen(),
    ),
    const ReportScreen(),
    const AccountScreen(),
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
    AppRoutes.navigateToTransaction(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );

    int bottomNavIndex =
        _selectedIndex < 2 ? _selectedIndex : _selectedIndex + 1;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: theme.bottomNavigationBarTheme.backgroundColor,
        elevation: theme.bottomNavigationBarTheme.elevation ?? 8,
        type:
            theme.bottomNavigationBarTheme.type ??
            BottomNavigationBarType.fixed,
        showSelectedLabels:
            theme.bottomNavigationBarTheme.showSelectedLabels ?? false,
        showUnselectedLabels:
            theme.bottomNavigationBarTheme.showUnselectedLabels ?? false,
        currentIndex: bottomNavIndex,
        onTap: _onItemTapped,
        items: _buildBottomNavigationBarItems(theme, l10n, bottomNavIndex),
        selectedItemColor: theme.bottomNavigationBarTheme.selectedItemColor,
        unselectedItemColor: theme.bottomNavigationBarTheme.unselectedItemColor,
        selectedLabelStyle: theme.bottomNavigationBarTheme.selectedLabelStyle,
        unselectedLabelStyle:
            theme.bottomNavigationBarTheme.unselectedLabelStyle,
      ),
    );
  }

  List<BottomNavigationBarItem> _buildBottomNavigationBarItems(
    ThemeData theme,
    AppLocalizations l10n,
    int currentBottomNavIndex,
  ) {
    const double standardIconSize = 26.0;
    const double fabIconSize = 30.0;
    const double fabContainerHeight = 48.0;
    const double fabContainerWidth = 48.0;

    return [
      _buildBottomNavItem(
        theme,
        Icons.dashboard_outlined,
        Icons.dashboard,
        0,
        currentBottomNavIndex,
        l10n.dashboardTitle,
        standardIconSize,
      ),
      _buildBottomNavItem(
        theme,
        Icons.group_outlined,
        Icons.group,
        1,
        currentBottomNavIndex,
        l10n.groupNotesTitle,
        standardIconSize,
      ),
      BottomNavigationBarItem(
        icon: Container(
          width: fabContainerWidth,
          height: fabContainerHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.add,
            color: theme.colorScheme.onPrimary,
            size: fabIconSize,
          ),
        ),
        label: '',
        tooltip: l10n.addTransactionTooltip,
      ),
      _buildBottomNavItem(
        theme,
        Icons.analytics_outlined,
        Icons.analytics,
        3,
        currentBottomNavIndex,
        l10n.reportsTitle,
        standardIconSize,
      ),
      _buildBottomNavItem(
        theme,
        Icons.person_outline,
        Icons.person,
        4,
        currentBottomNavIndex,
        l10n.accountTitle,
        standardIconSize,
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
    double iconSize,
  ) {
    bool isSelected = itemIndex == currentBottomNavIndex;
    return BottomNavigationBarItem(
      icon: Icon(isSelected ? activeIcon : inactiveIcon, size: iconSize),
      label: '',
      tooltip: label,
    );
  }
}