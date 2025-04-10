import 'package:finance_app/core/app_routes.dart';
import 'package:finance_app/screens/account/account_screen.dart';
import 'package:finance_app/screens/top/dashboard_screen.dart'; // Đảm bảo import đúng
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import l10n

class TopScreen extends StatefulWidget {
  const TopScreen({super.key});

  @override
  TopScreenState createState() => TopScreenState();
}

class TopScreenState extends State<TopScreen> {
  int _selectedIndex = 0;

  // Khởi tạo danh sách màn hình một lần và giữ chúng trong state
  // Sử dụng const nếu màn hình không cần tham số
  final List<Widget> _screens = [
    DashboardScreen(), // Màn hình Dashboard
    const _PlaceholderScreen(placeholderKey: 'group_notes'), // Placeholder Ghi chú nhóm
    const _PlaceholderScreen(placeholderKey: 'reports'),   // Placeholder Báo cáo
    const AccountScreen(),   // Màn hình Account
  ];

  void _onItemTapped(int index) {
    // Index 2 là vị trí của FAB (không có item)
    if (index == 2) {
      _addTransaction();
      return;
    }
    setState(() {
      // Ánh xạ index của BottomNavigationBar (0, 1, 3, 4)
      // sang index của _screens (0, 1, 2, 3)
      _selectedIndex = index > 2 ? index - 1 : index;
    });
  }

  void _addTransaction() {
    // Kiểm tra context còn tồn tại trước khi điều hướng
    if (mounted) {
      AppRoutes.navigateToTransaction(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Lấy theme hiện tại
    // final l10n = AppLocalizations.of(context)!; // Lấy l10n

    // Tính toán currentIndex cho BottomNavigationBar dựa trên _selectedIndex
    // Ánh xạ ngược index của _screens (0, 1, 2, 3)
    // sang index của BottomNavigationBar (0, 1, 3, 4)
    int bottomNavIndex = _selectedIndex < 2 ? _selectedIndex : _selectedIndex + 1;

    return Scaffold(
      // Sử dụng IndexedStack để giữ state của các màn hình con
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: theme.colorScheme.surface, // Sử dụng màu từ theme
        elevation: 8,
        type: BottomNavigationBarType.fixed, // Quan trọng khi có > 3 item
        showSelectedLabels: false, // Ẩn label
        showUnselectedLabels: false, // Ẩn label
        currentIndex: bottomNavIndex, // Index hiển thị trên thanh điều hướng
        onTap: _onItemTapped,
        items: _buildBottomNavigationBarItems(theme), // Truyền theme vào helper
        selectedItemColor: theme.colorScheme.primary, // Màu item được chọn
        unselectedItemColor: theme.colorScheme.onSurface.withValues(alpha: 0.6), // Màu item không được chọn
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTransaction,
        backgroundColor: theme.colorScheme.primary, // Sử dụng màu từ theme
        foregroundColor: theme.colorScheme.onPrimary, // Màu icon trên FAB
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked, // Neo FAB vào giữa
    );
  }

  // Helper xây dựng các item cho BottomNavigationBar
  List<BottomNavigationBarItem> _buildBottomNavigationBarItems(ThemeData theme) {
    // Tính toán lại bottomNavIndex để biết item nào đang được chọn
    int bottomNavIndex = _selectedIndex < 2 ? _selectedIndex : _selectedIndex + 1;

    return [
      _buildBottomNavItem(theme, Icons.home_outlined, Icons.home, 0, bottomNavIndex), // Index 0
      _buildBottomNavItem(theme, Icons.note_alt_outlined, Icons.note_alt, 1, bottomNavIndex), // Index 1
      // Khoảng trống cho FAB
      const BottomNavigationBarItem(icon: SizedBox.shrink(), label: ''), // Index 2
      _buildBottomNavItem(theme, Icons.bar_chart_outlined, Icons.bar_chart, 3, bottomNavIndex), // Index 3
      _buildBottomNavItem(theme, Icons.person_outlined, Icons.person, 4, bottomNavIndex), // Index 4
    ];
  }

  // Helper xây dựng một BottomNavigationBarItem với icon active/inactive
  BottomNavigationBarItem _buildBottomNavItem(ThemeData theme, IconData inactiveIcon, IconData activeIcon, int itemIndex, int currentBottomNavIndex) {
    bool isSelected = itemIndex == currentBottomNavIndex;
    return BottomNavigationBarItem(
      icon: Icon(
        isSelected ? activeIcon : inactiveIcon,
        // Màu sắc sẽ được quản lý bởi selectedItemColor/unselectedItemColor của BottomNavigationBar
        size: 26, // Kích thước icon
      ),
      label: '', // Label bị ẩn
    );
  }
}

// Widget Placeholder đơn giản (có thể tạo file riêng nếu cần)
class _PlaceholderScreen extends StatelessWidget {
  final String placeholderKey; // Key để lấy text từ l10n

  const _PlaceholderScreen({required this.placeholderKey}); // Bỏ key khỏi constructor

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String displayText;

    // Lấy text dựa trên key
    switch (placeholderKey) {
      case 'group_notes':
        displayText = l10n.groupNotesPlaceholder; // Key cần định nghĩa trong .arb
        break;
      case 'reports':
        displayText = l10n.reportsPlaceholder; // Key cần định nghĩa trong .arb
        break;
      default:
        displayText = placeholderKey; // Hiển thị key nếu không khớp
    }

    // Thêm Scaffold để có AppBar và nền chuẩn
    return Scaffold(
      appBar: AppBar(
        title: Text(displayText, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        automaticallyImplyLeading: false, // Không hiển thị nút back tự động
      ),
      body: Center(
        child: Text(
          displayText,
          style: GoogleFonts.poppins(fontSize: 24, color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
    );
  }
}