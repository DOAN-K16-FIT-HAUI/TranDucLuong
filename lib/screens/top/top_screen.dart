import 'package:finance_app/core/app_theme.dart';
import 'package:finance_app/screens/top/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TopScreen extends StatefulWidget {
  const TopScreen({super.key});

  @override
  TopScreenState createState() => TopScreenState();
}

class TopScreenState extends State<TopScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    DashboardScreen(),
    _buildCenteredText('Ghi chú nhóm'),
    _buildCenteredText('Báo cáo'),
    _buildCenteredText('Tài khoản'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: _selectedIndex < 2 ? _selectedIndex : _selectedIndex + 1,
        onTap: _onItemTapped,
        items: _buildBottomNavigationBarItems(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTransaction,
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  static Widget _buildCenteredText(String text) {
    return Center(child: Text(text, style: GoogleFonts.poppins(fontSize: 24)));
  }

  List<BottomNavigationBarItem> _buildBottomNavigationBarItems() {
    return [
      _buildBottomNavigationBarItem(Icons.home_outlined, 0),
      _buildBottomNavigationBarItem(Icons.note_outlined, 1),
      const BottomNavigationBarItem(icon: SizedBox.shrink(), label: ''),
      _buildBottomNavigationBarItem(Icons.bar_chart_outlined, 2),
      _buildBottomNavigationBarItem(Icons.person_outlined, 3),
    ];
  }

  BottomNavigationBarItem _buildBottomNavigationBarItem(IconData icon, int index) {
    return BottomNavigationBarItem(
      icon: Icon(icon, color: _selectedIndex == index ? AppTheme.lightTheme.colorScheme.primary : Colors.grey[600]),
      label: '',
    );
  }
}