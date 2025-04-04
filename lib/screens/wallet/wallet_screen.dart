import 'dart:ui';

import 'package:finance_app/core/app_routes.dart';
import 'package:finance_app/core/app_theme.dart';
import 'package:finance_app/utils/common_widget.dart';
import 'package:finance_app/utils/formatter.dart';
import 'package:finance_app/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  // Separate lists for each tab
  final List<Map<String, dynamic>> wallets = [
    {
      'name': 'Tiền mặt',
      'balance': 2510000,
      'icon': Icons.account_balance_wallet_outlined,
    },
    {'name': 'ATM', 'balance': 397631, 'icon': Icons.credit_card_outlined},
  ];

  // List of available icons with their names for display
  final List<Map<String, dynamic>> availableIcons = [
    {'name': 'Ví tiền', 'icon': Icons.account_balance_wallet_outlined},
    {'name': 'Thẻ tín dụng', 'icon': Icons.credit_card_outlined},
    {'name': 'Tiết kiệm', 'icon': Icons.savings_outlined},
    {'name': 'Đầu tư', 'icon': Icons.trending_up_outlined},
    {'name': 'Bitcoin', 'icon': Icons.currency_bitcoin_outlined},
  ];

  final List<Map<String, dynamic>> savingsWallets = [];
  final List<Map<String, dynamic>> investmentWallets = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Add listener to search controller to update UI on text change
    _searchController.addListener(() {
      setState(() {}); // Rebuild the widget when the search query changes
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterWallets(
    String query,
    List<Map<String, dynamic>> walletList,
  ) {
    final trimmedQuery = query.trim().toLowerCase();
    if (trimmedQuery.isEmpty) {
      return List.from(walletList);
    }
    return walletList.where((wallet) {
      return wallet['name'].toString().toLowerCase().contains(trimmedQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Filter wallets based on the current tab
    final filteredWallets = _filterWallets(_searchController.text, wallets);
    final filteredSavingsWallets = _filterWallets(
      _searchController.text,
      savingsWallets,
    );
    final filteredInvestmentWallets = _filterWallets(
      _searchController.text,
      investmentWallets,
    );

    return Scaffold(
      body: Material(
        color: AppTheme.lightTheme.colorScheme.surface,
        child: Column(
          children: [
            CommonWidgets.buildAppBar(
              context: context,
              isSearching: _isSearching,
              searchController: _searchController,
              onBackPressed: () {
                if (_isSearching) {
                  setState(() {
                    _isSearching = false;
                    _searchController.clear();
                  });
                } else {
                  AppRoutes.navigateToDashboard(context);
                }
              },
              onSearchPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchController.clear();
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            _buildTotalBalance(),
            const SizedBox(height: 16),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Tài khoản
                  filteredWallets.isEmpty && _isSearching
                      ? Center(
                        child: Text(
                          'Không tìm thấy ví nào',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: AppTheme.lightTheme.colorScheme.onSurface,
                          ),
                        ),
                      )
                      : ReorderableListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ).copyWith(bottom: 80),
                        itemCount: filteredWallets.length,
                        itemBuilder: (context, index) {
                          return _buildWalletCard(
                            filteredWallets[index],
                            wallets,
                            key: ValueKey(filteredWallets[index]['name']),
                          );
                        },
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) {
                              newIndex -= 1;
                            }
                            final item = wallets.removeAt(oldIndex);
                            wallets.insert(newIndex, item);
                          });
                        },
                        proxyDecorator: (
                          Widget child,
                          int index,
                          Animation<double> animation,
                        ) {
                          return AnimatedBuilder(
                            animation: animation,
                            builder: (context, child) {
                              final double animValue = Curves.easeInOut
                                  .transform(animation.value);
                              final double elevation =
                                  lerpDouble(0, 8, animValue)!;
                              return Material(
                                elevation: elevation,
                                color: Colors.transparent,
                                child: child,
                              );
                            },
                            child: child,
                          );
                        },
                      ),
                  // Tab 2: Số ví tiết kiệm
                  filteredSavingsWallets.isEmpty
                      ? Center(
                        child: Text(
                          'Số ví tiết kiệm - Chưa có dữ liệu',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: AppTheme.lightTheme.colorScheme.onSurface,
                          ),
                        ),
                      )
                      : ReorderableListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ).copyWith(bottom: 80),
                        itemCount: filteredSavingsWallets.length,
                        itemBuilder: (context, index) {
                          return _buildWalletCard(
                            filteredSavingsWallets[index],
                            savingsWallets,
                            key: ValueKey(
                              filteredSavingsWallets[index]['name'],
                            ),
                          );
                        },
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) {
                              newIndex -= 1;
                            }
                            final item = savingsWallets.removeAt(oldIndex);
                            savingsWallets.insert(newIndex, item);
                          });
                        },
                        proxyDecorator: (
                          Widget child,
                          int index,
                          Animation<double> animation,
                        ) {
                          return AnimatedBuilder(
                            animation: animation,
                            builder: (context, child) {
                              final double animValue = Curves.easeInOut
                                  .transform(animation.value);
                              final double elevation =
                                  lerpDouble(0, 8, animValue)!;
                              return Material(
                                elevation: elevation,
                                color: Colors.transparent,
                                child: child,
                              );
                            },
                            child: child,
                          );
                        },
                      ),
                  // Tab 3: Đầu tư
                  filteredInvestmentWallets.isEmpty
                      ? Center(
                        child: Text(
                          'Đầu tư - Chưa có dữ liệu',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: AppTheme.lightTheme.colorScheme.onSurface,
                          ),
                        ),
                      )
                      : ReorderableListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ).copyWith(bottom: 80),
                        itemCount: filteredInvestmentWallets.length,
                        itemBuilder: (context, index) {
                          return _buildWalletCard(
                            filteredInvestmentWallets[index],
                            investmentWallets,
                            key: ValueKey(
                              filteredInvestmentWallets[index]['name'],
                            ),
                          );
                        },
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) {
                              newIndex -= 1;
                            }
                            final item = investmentWallets.removeAt(oldIndex);
                            investmentWallets.insert(newIndex, item);
                          });
                        },
                        proxyDecorator: (
                          Widget child,
                          int index,
                          Animation<double> animation,
                        ) {
                          return AnimatedBuilder(
                            animation: animation,
                            builder: (context, child) {
                              final double animValue = Curves.easeInOut
                                  .transform(animation.value);
                              final double elevation =
                                  lerpDouble(0, 8, animValue)!;
                              return Material(
                                elevation: elevation,
                                color: Colors.transparent,
                                child: child,
                              );
                            },
                            child: child,
                          );
                        },
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddWalletDialog(context);
        },
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        child: Icon(Icons.add, color: AppTheme.lightTheme.colorScheme.surface),
      ),
    );
  }

  Widget _buildTotalBalance() {
    // Calculate total balance from all lists
    final totalBalance =
        wallets.fold<int>(
          0,
          (sum, wallet) => sum + (wallet['balance'] as int),
        ) +
        savingsWallets.fold<int>(
          0,
          (sum, wallet) => sum + (wallet['balance'] as int),
        ) +
        investmentWallets.fold<int>(
          0,
          (sum, wallet) => sum + (wallet['balance'] as int),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        NumberFormat.currency(
          locale: 'vi_VN',
          symbol: '₫',
        ).format(totalBalance),
        style: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppTheme.incomeColor,
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelStyle: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      labelColor: AppTheme.lightTheme.colorScheme.primary,
      unselectedLabelColor: AppTheme.lightTheme.colorScheme.onSurface
          .withValues(alpha: 0.6),
      indicatorColor: AppTheme.lightTheme.colorScheme.primary,
      tabs: const [
        Tab(text: 'Tài khoản'),
        Tab(text: 'Số ví tiết kiệm'),
        Tab(text: 'Đầu tư'),
      ],
    );
  }

  Widget _buildWalletCard(
    Map<String, dynamic> wallet,
    List<Map<String, dynamic>> walletList, {
    Key? key,
  }) {
    return Container(
      key: key, // Required for ReorderableListView
      margin: const EdgeInsets.only(top: 16),
      decoration: _boxDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Optional: Add a drag handle icon to indicate reordering
            const Icon(Icons.drag_handle, color: Colors.grey, size: 20),
            Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                wallet['icon'],
                size: 24,
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wallet['name'],
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    NumberFormat.currency(
                      locale: 'vi_VN',
                      symbol: '₫',
                    ).format(wallet['balance']),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.incomeColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                  alpha: 0.6,
                ),
              ),
              offset: const Offset(0, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: AppTheme.lightTheme.colorScheme.surface,
              elevation: 8,
              onSelected: (String result) {
                if (result == 'edit') {
                  _showEditDialog(context, wallet);
                } else if (result == 'delete') {
                  _showDeleteDialog(context, wallet, walletList);
                }
              },
              itemBuilder:
                  (BuildContext context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit,
                            size: 20,
                            color: AppTheme.lightTheme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sửa',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.lightTheme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete,
                            size: 20,
                            color: AppTheme.lightTheme.colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Xóa',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.lightTheme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
            ),
          ],
        ),
      ),
    );
  }

  Future<IconData?> _showIconSelectionPopup(
    BuildContext context,
    IconData currentIcon,
  ) async {
    return await showDialog<IconData>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: AppTheme.lightTheme.colorScheme.surface,
            title: Text(
              'Chọn biểu tượng',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 200, // Adjust height to fit 2 rows (based on your design)
              child: SingleChildScrollView(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  // Disable GridView's own scrolling
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1, // Square items
                  ),
                  itemCount: availableIcons.length,
                  itemBuilder: (context, index) {
                    final iconData = availableIcons[index];
                    final isSelected = iconData['icon'] == currentIcon;
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context, iconData['icon']);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? AppTheme.lightTheme.colorScheme.primary
                                      .withValues(alpha: 0.1)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                isSelected
                                    ? AppTheme.lightTheme.colorScheme.primary
                                    : AppTheme.lightTheme.colorScheme.onSurface
                                        .withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              iconData['icon'],
                              color: AppTheme.lightTheme.colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              iconData['name'],
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color:
                                    AppTheme.lightTheme.colorScheme.onSurface,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Hủy',
                  style: GoogleFonts.poppins(
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _showEditDialog(BuildContext context, Map<String, dynamic> wallet) {
    final formKey = GlobalKey<FormState>(); // Form key for validation
    TextEditingController nameController = TextEditingController(
      text: wallet['name'],
    );
    TextEditingController balanceController = TextEditingController(
      text:
          Formatter.currencyInputFormatter
              .formatEditUpdate(
                TextEditingValue.empty,
                TextEditingValue(text: wallet['balance'].toString()),
              )
              .text,
    );
    IconData selectedIcon = wallet['icon'];

    CommonWidgets.showFormDialog(
      context: context,
      formKey: formKey,
      formFields: [
        TextFormField(
          controller: nameController,
          decoration: InputDecoration(
            label: RichText(
              text: TextSpan(
                text: 'Tên ví ',
                style: GoogleFonts.poppins(
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                  fontSize: 16,
                ),
                children: const [
                  TextSpan(
                    text: '*',
                    style: TextStyle(color: AppTheme.expenseColor),
                  ),
                ],
              ),
            ),
            hintText: 'Nhập tên ví',
            hintStyle: GoogleFonts.poppins(
              color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                alpha: 0.6,
              ),
            ),
            border: const OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
            errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppTheme.expenseColor),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppTheme.expenseColor),
            ),
            errorStyle: const TextStyle(color: AppTheme.expenseColor),
          ),
          cursorColor: AppTheme.lightTheme.colorScheme.primary,
          style: GoogleFonts.poppins(
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
          validator: Validators.validateWalletName,
        ),
        const SizedBox(height: 16),
        CommonWidgets.buildBalanceInputField(balanceController),
        const SizedBox(height: 16),
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return ListTile(
              title: Text(
                'Biểu tượng',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
              trailing: Icon(
                selectedIcon,
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
              onTap: () async {
                final newIcon = await _showIconSelectionPopup(
                  context,
                  selectedIcon,
                );
                if (newIcon != null) {
                  setState(() {
                    selectedIcon = newIcon;
                  });
                }
              },
            );
          },
        ),
      ],
      title: 'Sửa ví',
      actionButtonText: 'Lưu',
      onActionButtonPressed: () {
        setState(() {
          wallet['name'] = nameController.text.trim();
          wallet['balance'] = Formatter.getRawCurrencyValue(
            balanceController.text,
          );
          wallet['icon'] = selectedIcon;
        });
      },
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    Map<String, dynamic> wallet,
    List<Map<String, dynamic>> walletList,
  ) {
    CommonWidgets.showDeleteDialog(
      context: context,
      title: 'Xác nhận xóa',
      content: 'Bạn có chắc muốn xóa ví "${wallet['name']}" không?',
      onDeletePressed: () {
        setState(() {
          walletList.remove(wallet);
        });
      },
    );
  }

  void _showAddWalletDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    TextEditingController nameController = TextEditingController();
    TextEditingController balanceController = TextEditingController();
    IconData selectedIcon = availableIcons[0]['icon']; // Default icon

    CommonWidgets.showFormDialog(
      context: context,
      formKey: formKey,
      formFields: [
        TextFormField(
          controller: nameController,
          decoration: InputDecoration(
            label: RichText(
              text: TextSpan(
                text: 'Tên ví ',
                style: GoogleFonts.poppins(
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                  fontSize: 16,
                ),
                children: const [
                  TextSpan(
                    text: '*',
                    style: TextStyle(color: AppTheme.expenseColor),
                  ),
                ],
              ),
            ),
            hintText: 'Nhập tên ví',
            hintStyle: GoogleFonts.poppins(
              color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                alpha: 0.6,
              ),
            ),
            border: const OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
            errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppTheme.expenseColor),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppTheme.expenseColor),
            ),
            errorStyle: const TextStyle(color: AppTheme.expenseColor),
          ),
          cursorColor: AppTheme.lightTheme.colorScheme.primary,
          style: GoogleFonts.poppins(
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
          validator: Validators.validateWalletName,
        ),
        const SizedBox(height: 16),
        CommonWidgets.buildBalanceInputField(balanceController),
        const SizedBox(height: 16),
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return ListTile(
              title: Text(
                'Biểu tượng',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
              trailing: Icon(
                selectedIcon,
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
              onTap: () async {
                final newIcon = await _showIconSelectionPopup(
                  context,
                  selectedIcon,
                );
                if (newIcon != null) {
                  setState(() {
                    selectedIcon = newIcon;
                  });
                }
              },
            );
          },
        ),
      ],
      title: 'Thêm ví mới',
      actionButtonText: 'Thêm',
      onActionButtonPressed: () {
        setState(() {
          final newWallet = {
            'name': nameController.text.trim(),
            'balance': Formatter.getRawCurrencyValue(balanceController.text),
            'icon': selectedIcon,
          };
          switch (_tabController.index) {
            case 0:
              wallets.add(newWallet);
              break;
            case 1:
              savingsWallets.add(newWallet);
              break;
            case 2:
              investmentWallets.add(newWallet);
              break;
          }
        });
      },
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: AppTheme.lightTheme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
            alpha: 0.15,
          ),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
