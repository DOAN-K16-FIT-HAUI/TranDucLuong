import 'package:finance_app/blocs/wallet/wallet_bloc.dart';
import 'package:finance_app/blocs/wallet/wallet_event.dart';
import 'package:finance_app/blocs/wallet/wallet_state.dart';
import 'package:finance_app/core/app_routes.dart';
import 'package:finance_app/core/app_theme.dart';
import 'package:finance_app/data/models/wallet.dart';
import 'package:finance_app/utils/common_widget.dart';
import 'package:finance_app/utils/constants.dart';
import 'package:finance_app/utils/dimens.dart';
import 'package:finance_app/utils/formatter.dart';
import 'package:finance_app/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => WalletBloc()..add(LoadWallets()),
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: AppTheme.lightTheme.colorScheme.surface,
          body: BlocBuilder<WalletBloc, WalletState>(
            builder: (context, state) {
              return Column(
                children: [
                  CommonWidgets.buildAppBar(
                    context: context,
                    title: 'Ví của tôi',
                    backIcon: Icons.close,
                    onBackPressed: () {
                      if (state.isSearching) {
                        context.read<WalletBloc>().add(ToggleSearch(false));
                      } else {
                        AppRoutes.navigateToDashboard(context);
                      }
                    },
                    actions: [
                      IconButton(
                        icon: Icon(
                          state.isSearching ? Icons.close : Icons.search,
                          color: AppTheme.lightTheme.colorScheme.surface,
                        ),
                        tooltip: state.isSearching ? 'Đóng tìm kiếm' : 'Tìm kiếm',
                        onPressed: () {
                          context.read<WalletBloc>().add(ToggleSearch(!state.isSearching));
                        },
                      ),
                    ],
                  ),
                  if (state.isSearching)
                    Padding(
                        padding: const EdgeInsets.all(16),
                        child: CommonWidgets.buildSearchField(
                          context: context,
                          hintText: 'Tìm kiếm ví...',
                          onChanged: (value) {
                            context.read<WalletBloc>().add(SearchWallets(value));
                          },
                        ),
                    ),
                  if(!state.isSearching)
                    const SizedBox(height: 16),
                  _buildTotalBalance(state),
                  const SizedBox(height: 16),
                  CommonWidgets.buildTabBar(
                    context: context,
                    tabTitles: const ['Tài khoản', 'Tiết kiệm', 'Đầu tư'],
                    onTabChanged: (index) => context.read<WalletBloc>().add(TabChanged(index)),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildTabContent(context, state, state.wallets, 0),
                        _buildTabContent(context, state, state.savingsWallets, 1),
                        _buildTabContent(context, state, state.investmentWallets, 2),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          floatingActionButton: Builder(
            builder: (fabContext) => FloatingActionButton(
              onPressed: () => _showAddWalletDialog(fabContext),
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
              child: Icon(Icons.add, color: AppTheme.lightTheme.colorScheme.surface),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddWalletDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    IconData selectedIcon = Constants.availableIcons[0]['icon'];
    final currentSelectedTab = context.read<WalletBloc>().state.selectedTab;
    int selectedType = currentSelectedTab;

    CommonWidgets.showFormDialog(
      context: context,
      formKey: formKey,
      formFields: [
        _buildTextField(nameController, 'Tên ví', 'Nhập tên ví', Validators.validateWalletName),
        const SizedBox(height: 16),
        CommonWidgets.buildBalanceInputField(balanceController),
        const SizedBox(height: 16),
        _buildIconSelection(context, selectedIcon, (newIcon) => selectedIcon = newIcon),
      ],
      title: 'Thêm ví mới',
      actionButtonText: 'Thêm',
      onActionButtonPressed: () {
        if (formKey.currentState!.validate()) {
          context.read<WalletBloc>().add(AddWallet(Wallet(
            id: '',
            name: nameController.text.trim(),
            balance: Formatter.getRawCurrencyValue(balanceController.text),
            icon: selectedIcon,
            type: selectedType,
          )));
        }
      },
    );
  }

  Widget _buildTotalBalance(WalletState state) {
    int tabTotalBalance = 0;
    switch (state.selectedTab) {
      case 0:
        tabTotalBalance = state.wallets.fold(0, (sum, wallet) => sum + wallet.balance);
        break;
      case 1:
        tabTotalBalance = state.savingsWallets.fold(0, (sum, wallet) => sum + wallet.balance);
        break;
      case 2:
        tabTotalBalance = state.investmentWallets.fold(0, (sum, wallet) => sum + wallet.balance);
        break;
      default:
        debugPrint("Lỗi: selectedTab không hợp lệ: ${state.selectedTab}");
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(tabTotalBalance),
        style: GoogleFonts.poppins(fontSize: 30, fontWeight: FontWeight.bold, color: tabTotalBalance >= 0 ? AppTheme.incomeColor : AppTheme.expenseColor),
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context, Wallet wallet, int type, int index) {
    return CommonWidgets.buildItemCard(
      context: context,
      item: wallet,
      itemKey: ValueKey(wallet.id),
      title: wallet.name,
      value: wallet.balance.toDouble(),
      icon: wallet.icon,
      menuItems: CommonWidgets.buildEditDeleteMenuItems(),
      onMenuSelected: (result) {
        CommonWidgets.handleEditDeleteActions(
          context: context,
          action: result,
          item: wallet,
          itemName: wallet.name,
          onEdit: (context, wallet) => _showEditDialog(context, wallet),
          onDelete: (context, wallet) => context.read<WalletBloc>().add(DeleteWallet(wallet.id, wallet.type)),
        );
      },
    );
  }

  Future<IconData?> _showIconSelectionPopup(BuildContext context, IconData currentIcon) async {
    return CommonWidgets.showIconSelectionDialog(
      context: context,
      currentIcon: currentIcon,
      availableIcons: Constants.availableIcons,
    );
  }

  void _showEditDialog(BuildContext context, Wallet wallet) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: wallet.name);
    final balanceController = TextEditingController(
      text: Formatter.currencyInputFormatter.formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: wallet.balance.toString())).text,
    );
    IconData selectedIcon = wallet.icon;

    CommonWidgets.showFormDialog(
      context: context,
      formKey: formKey,
      formFields: [
        _buildTextField(nameController, 'Tên ví', 'Nhập tên ví', Validators.validateWalletName),
        const SizedBox(height: 16),
        CommonWidgets.buildBalanceInputField(balanceController),
        const SizedBox(height: 16),
        _buildIconSelection(context, selectedIcon, (newIcon) => selectedIcon = newIcon),
      ],
      title: 'Sửa thông tin ví',
      actionButtonText: 'Lưu',
      onActionButtonPressed: () {
        if (formKey.currentState!.validate()) {
          context.read<WalletBloc>().add(EditWallet(Wallet(
            id: wallet.id,
            name: nameController.text.trim(),
            balance: Formatter.getRawCurrencyValue(balanceController.text),
            icon: selectedIcon,
            type: wallet.type,
          )));
        }
      },
    );
  }

  Widget _buildTabContent(BuildContext context, WalletState state, List<Wallet> items, int type) {
    return CommonWidgets.buildTabContent<Wallet>(
      context: context,
      items: items,
      emptyMessage: 'Không tìm thấy ví nào',
      searchQuery: state.searchQuery,
      filterItems: context.read<WalletBloc>().filterWallets,
      isSearching: state.isSearching,
      type: type,
      itemBuilder: (context, wallet, type, index) => _buildWalletCard(context, wallet, type, index),
      onReorder: (type, oldIndex, newIndex) => context.read<WalletBloc>().add(ReorderWallets(type, oldIndex, newIndex)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, String? Function(String?) validator) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        label: RichText(
          text: TextSpan(
            text: '$label ',
            style: GoogleFonts.poppins(color: AppTheme.lightTheme.colorScheme.onSurface, fontSize: Dimens.textSizeMedium),
            children: const [TextSpan(text: '*', style: TextStyle(color: AppTheme.expenseColor))],
          ),
        ),
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6)),
        border: const OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.lightTheme.colorScheme.primary)),
        errorBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppTheme.expenseColor)),
        focusedErrorBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppTheme.expenseColor)),
        errorStyle: const TextStyle(color: AppTheme.expenseColor),
      ),
      cursorColor: AppTheme.lightTheme.colorScheme.primary,
      style: GoogleFonts.poppins(color: AppTheme.lightTheme.colorScheme.onSurface),
      validator: validator,
    );
  }

  Widget _buildIconSelection(BuildContext context, IconData selectedIcon, Function(IconData) onIconSelected) {
    return StatefulBuilder(
      builder: (dialogContext, setState) => ListTile(
        title: Text('Biểu tượng', style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.lightTheme.colorScheme.onSurface)),
        trailing: Icon(selectedIcon, color: AppTheme.lightTheme.colorScheme.primary),
        onTap: () async {
          final newIcon = await _showIconSelectionPopup(context, selectedIcon);
          if (newIcon != null) {
            setState(() => onIconSelected(newIcon));
          }
        },
      ),
    );
  }
}