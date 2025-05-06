import 'package:finance_app/blocs/localization/localization_bloc.dart';
import 'package:finance_app/blocs/localization/localization_state.dart';
import 'package:finance_app/blocs/wallet/wallet_bloc.dart';
import 'package:finance_app/blocs/wallet/wallet_event.dart';
import 'package:finance_app/blocs/wallet/wallet_state.dart';
import 'package:finance_app/core/app_routes.dart';
import 'package:finance_app/core/app_theme.dart';
import 'package:finance_app/data/models/wallet.dart';
import 'package:finance_app/utils/common_widget/app_bar_tab_bar.dart';
import 'package:finance_app/utils/common_widget/dialogs.dart';
import 'package:finance_app/utils/common_widget/input_fields.dart';
import 'package:finance_app/utils/common_widget/lists_cards.dart';
import 'package:finance_app/utils/common_widget/menu_actions.dart';
import 'package:finance_app/utils/common_widget/utility_widgets.dart';
import 'package:finance_app/utils/constants.dart';
import 'package:finance_app/utils/formatter.dart';
import 'package:finance_app/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  List<Wallet> _getFilteredListForTab(WalletState state, int tabIndex) {
    List<Wallet> listToFilter;
    switch (tabIndex) {
      case 0:
        listToFilter = state.wallets;
        break;
      case 1:
        listToFilter = state.savingsWallets;
        break;
      case 2:
        listToFilter = state.investmentWallets;
        break;
      default:
        listToFilter = [];
    }

    if (state.searchQuery.isEmpty) {
      return listToFilter;
    }

    final lowerCaseQuery = state.searchQuery.toLowerCase();
    return listToFilter
        .where((wallet) => wallet.name.toLowerCase().contains(lowerCaseQuery))
        .toList();
  }

  String _getCurrencySymbol(Locale locale) {
    switch (locale.languageCode) {
      case 'vi':
        return '₫';
      case 'ja':
        return '¥';
      case 'en':
      default:
        return '\$';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return BlocBuilder<LocalizationBloc, LocalizationState>(
      builder: (context, localizationState) {
        final locale = localizationState.locale;

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: theme.colorScheme.surface,
            body: BlocBuilder<WalletBloc, WalletState>(
              builder: (context, state) {
                final tabController = DefaultTabController.of(context);

                // Listen to tab controller changes from swipe
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted(context)) {
                    try {
                      if (tabController.index != state.selectedTab) {
                        if (tabController.animation?.isCompleted ?? false) {
                          // Update state when tab is changed by swiping
                          context.read<WalletBloc>().add(
                            TabChanged(tabController.index),
                          );
                        } else {
                          // Only animate programmatically if the tab change
                          // was initiated through button press, not swipe
                          tabController.animateTo(state.selectedTab);
                        }
                      }
                    } catch (e) {
                      debugPrint("Error handling TabController: $e");
                    }
                  }
                });

                final filteredWalletsTab0 = _getFilteredListForTab(state, 0);
                final filteredWalletsTab1 = _getFilteredListForTab(state, 1);
                final filteredWalletsTab2 = _getFilteredListForTab(state, 2);

                return Column(
                  children: [
                    AppBarTabBar.buildAppBar(
                      context: context,
                      title: l10n.myWalletsTitle,
                      showBackButton: true,
                      backIcon: Icons.arrow_back,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      onBackPressed: () {
                        if (state.isSearching) {
                          context.read<WalletBloc>().add(ToggleSearch(false));
                          context.read<WalletBloc>().add(SearchWallets(''));
                        } else {
                          AppRoutes.navigateToDashboard(context);
                        }
                      },
                      actions: [
                        IconButton(
                          icon: Icon(
                            state.isSearching ? Icons.close : Icons.search,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                          tooltip:
                              state.isSearching
                                  ? l10n.closeSearchTooltip
                                  : l10n.searchTooltip,
                          onPressed: () {
                            final bloc = context.read<WalletBloc>();
                            bloc.add(ToggleSearch(!state.isSearching));
                            if (state.isSearching) {
                              bloc.add(SearchWallets(''));
                            }
                          },
                        ),
                      ],
                    ),
                    if (state.isLoading)
                      Expanded(
                        child: Center(
                          child: UtilityWidgets.buildLoadingIndicator(
                            context: context,
                          ),
                        ),
                      ),
                    if (!state.isLoading) ...[
                      if (state.isSearching)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: UtilityWidgets.buildSearchField(
                            context: context,
                            hintText: l10n.searchWalletsHint,
                            onChanged: (value) {
                              context.read<WalletBloc>().add(
                                SearchWallets(value),
                              );
                            },
                          ),
                        ),
                      if (!state.isSearching) const SizedBox(height: 16),
                      _buildTotalBalance(
                        context,
                        state,
                        filteredWalletsTab0,
                        filteredWalletsTab1,
                        filteredWalletsTab2,
                        locale,
                      ),
                      const SizedBox(height: 16),
                      AppBarTabBar.buildTabBar(
                        context: context,
                        tabTitles: [
                          l10n.tabAccounts,
                          l10n.tabSavings,
                          l10n.tabInvestments,
                        ],
                        controller: tabController,
                        onTabChanged:
                            (index) => context.read<WalletBloc>().add(
                              TabChanged(index),
                            ),
                      ),
                      Expanded(
                        child:
                            state.error != null
                                ? UtilityWidgets.buildErrorState(
                                  context: context,
                                  message: (context) => state.error!(context),
                                  onRetry:
                                      () => context.read<WalletBloc>().add(
                                        LoadWallets(),
                                      ),
                                )
                                : TabBarView(
                                  controller: tabController,
                                  children: [
                                    _buildTabContent(
                                      context,
                                      state,
                                      filteredWalletsTab0,
                                      0,
                                      locale,
                                    ),
                                    _buildTabContent(
                                      context,
                                      state,
                                      filteredWalletsTab1,
                                      1,
                                      locale,
                                    ),
                                    _buildTabContent(
                                      context,
                                      state,
                                      filteredWalletsTab2,
                                      2,
                                      locale,
                                    ),
                                  ],
                                ),
                      ),
                    ],
                  ],
                );
              },
            ),
            floatingActionButton: Builder(
              builder:
                  (fabContext) => FloatingActionButton(
                    onPressed: () => _showAddWalletDialog(fabContext),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    tooltip: l10n.addWalletTooltip,
                    child: const Icon(Icons.add),
                  ),
            ),
          ),
        );
      },
    );
  }

  bool mounted(BuildContext context) {
    try {
      context.widget;
      return true;
    } catch (e) {
      return false;
    }
  }

  void _showAddWalletDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => _AddWalletDialog(
            walletType: context.read<WalletBloc>().state.selectedTab,
          ),
    );
  }

  void _showEditDialog(BuildContext context, Wallet wallet) {
    showDialog(
      context: context,
      builder: (dialogContext) => _EditWalletDialog(wallet: wallet),
    );
  }

  Widget _buildTotalBalance(
    BuildContext context,
    WalletState state,
    List<Wallet> filteredTab0,
    List<Wallet> filteredTab1,
    List<Wallet> filteredTab2,
    Locale locale,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    List<Wallet> currentTabWallets;
    switch (state.selectedTab) {
      case 0:
        currentTabWallets = filteredTab0;
        break;
      case 1:
        currentTabWallets = filteredTab1;
        break;
      case 2:
        currentTabWallets = filteredTab2;
        break;
      default:
        currentTabWallets = [];
    }

    int tabTotalBalance = currentTabWallets.fold(
      0,
      (sum, wallet) => sum + wallet.balance,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            l10n.totalBalance,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            NumberFormat.currency(
              locale: locale.toString(),
              symbol: _getCurrencySymbol(locale),
              decimalDigits: 0,
            ).format(tabTotalBalance),
            style: GoogleFonts.notoSans(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color:
                  tabTotalBalance >= 0
                      ? AppTheme.incomeColor
                      : AppTheme.expenseColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(
    BuildContext context,
    Wallet wallet,
    int type,
    int index,
    Locale locale,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return ListsCards.buildItemCard(
      context: context,
      item: wallet,
      itemKey: ValueKey(wallet.id),
      title: wallet.name,
      value: wallet.balance.toDouble(),
      icon: wallet.icon,
      valueLocale: locale.toString(),
      valuePrefix: '',
      menuItems: MenuActions.buildEditDeleteMenuItems(context: context),
      onMenuSelected: (result) {
        if (result == 'edit') {
          _showEditDialog(context, wallet);
        } else if (result == 'delete') {
          Dialogs.showDeleteDialog(
            context: context,
            title: l10n.confirmDeleteTitle,
            content: l10n.confirmDeleteWalletContent(wallet.name),
            onDeletePressed:
                () => context.read<WalletBloc>().add(
                  DeleteWallet(wallet.id, wallet.type),
                ),
          );
        }
      },
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    WalletState state,
    List<Wallet> items,
    int type,
    Locale locale,
  ) {
    final l10n = AppLocalizations.of(context)!;

    if (items.isEmpty) {
      return UtilityWidgets.buildEmptyState(
        context: context,
        message:
            state.isSearching
                ? l10n.noWalletsFoundSearch
                : l10n.noWalletsInThisCategory,
        suggestion: state.isSearching ? null : l10n.addWalletSuggestion,
        icon: Icons.account_balance_wallet_outlined,
        onActionPressed:
            state.isSearching ? null : () => _showAddWalletDialog(context),
      );
    } else {
      return RefreshIndicator(
        onRefresh: () async {
          context.read<WalletBloc>().add(LoadWallets());
          return;
        },
        child: ListsCards.buildTabContent<Wallet>(
          context: context,
          items: items,
          itemBuilder:
              (ctx, wallet, index) =>
                  _buildWalletCard(ctx, wallet, type, index, locale),
        ),
      );
    }
  }
}

class _AddWalletDialog extends StatefulWidget {
  final int walletType;

  const _AddWalletDialog({required this.walletType});

  @override
  State<_AddWalletDialog> createState() => _AddWalletDialogState();
}

class _AddWalletDialogState extends State<_AddWalletDialog> {
  late TextEditingController nameController;
  late final TextEditingController balanceController;
  late final GlobalKey<FormState> formKey;
  late IconData selectedIcon;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    balanceController = TextEditingController();
    formKey = GlobalKey<FormState>();
    selectedIcon =
        Constants.availableIcons.isNotEmpty
            ? Constants.availableIcons[0]['icon']
            : Icons.wallet;
  }

  @override
  void dispose() {
    nameController.dispose();
    balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.addWalletDialogTitle),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InputFields.buildTextField(
                controller: nameController,
                label: l10n.walletNameLabel,
                hint: l10n.walletNameHint,
                validator:
                    (value) => Validators.validateNotEmpty(
                      value,
                      fieldName: l10n.walletNameLabel,
                    ),
                isRequired: true,
              ),
              const SizedBox(height: 16),
              InputFields.buildBalanceInputField(
                balanceController,
                validator:
                    (value) =>
                        Validators.validateBalance(value, currentBalance: 0),
              ),
              const SizedBox(height: 16),
              _buildIconSelection(
                context: context,
                selectedIconGetter: () => selectedIcon,
                onIconSelected:
                    (newIcon) => setState(() => selectedIcon = newIcon),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        ElevatedButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              context.read<WalletBloc>().add(
                AddWallet(
                  Wallet(
                    id: '',
                    name: nameController.text.trim(),
                    balance: Formatter.getRawCurrencyValue(
                      balanceController.text,
                    ),
                    icon: selectedIcon,
                    type: widget.walletType,
                  ),
                ),
              );
              Navigator.of(context).pop();
            }
          },
          child: Text(l10n.addWalletButton),
        ),
      ],
    );
  }

  Widget _buildIconSelection({
    required BuildContext context,
    required IconData Function() selectedIconGetter,
    required Function(IconData) onIconSelected,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return StatefulBuilder(
      builder: (dialogContext, setStateDialog) {
        final currentIcon = selectedIconGetter();
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            l10n.iconLabel,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          trailing: Icon(currentIcon, color: theme.colorScheme.primary),
          onTap: () async {
            final newIcon = await Dialogs.showIconSelectionDialog(
              context: dialogContext,
              currentIcon: currentIcon,
              availableIcons: Constants.availableIcons,
              title: l10n.selectIconTitle,
            );
            if (newIcon != null) {
              onIconSelected(newIcon);
              setStateDialog(() {});
            }
          },
        );
      },
    );
  }
}

class _EditWalletDialog extends StatefulWidget {
  final Wallet wallet;

  const _EditWalletDialog({required this.wallet});

  @override
  State<_EditWalletDialog> createState() => _EditWalletDialogState();
}

class _EditWalletDialogState extends State<_EditWalletDialog> {
  late final TextEditingController nameController;
  late final TextEditingController balanceController;
  late final GlobalKey<FormState> formKey;
  late IconData selectedIcon;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.wallet.name);
    balanceController = TextEditingController(
      text: Formatter.formatCurrency(
        widget.wallet.balance.toDouble(),
        locale: Localizations.localeOf(context),
      ),
    );
    formKey = GlobalKey<FormState>();
    selectedIcon = widget.wallet.icon;
  }

  @override
  void dispose() {
    nameController.dispose();
    balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.editWalletDialogTitle),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InputFields.buildTextField(
                controller: nameController,
                label: l10n.walletNameLabel,
                hint: l10n.walletNameHint,
                validator:
                    (value) => Validators.validateNotEmpty(
                      value,
                      fieldName: l10n.walletNameLabel,
                    ),
                isRequired: true,
              ),
              const SizedBox(height: 16),
              InputFields.buildBalanceInputField(
                balanceController,
                validator:
                    (value) => Validators.validateBalance(
                      value,
                      currentBalance: widget.wallet.balance.toDouble(),
                    ),
              ),
              const SizedBox(height: 16),
              _buildIconSelection(
                context: context,
                selectedIconGetter: () => selectedIcon,
                onIconSelected:
                    (newIcon) => setState(() => selectedIcon = newIcon),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        ElevatedButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              context.read<WalletBloc>().add(
                EditWallet(
                  Wallet(
                    id: widget.wallet.id,
                    name: nameController.text.trim(),
                    balance: Formatter.getRawCurrencyValue(
                      balanceController.text,
                    ),
                    icon: selectedIcon,
                    type: widget.wallet.type,
                  ),
                ),
              );
              Navigator.of(context).pop();
            }
          },
          child: Text(l10n.saveButton),
        ),
      ],
    );
  }

  Widget _buildIconSelection({
    required BuildContext context,
    required IconData Function() selectedIconGetter,
    required Function(IconData) onIconSelected,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return StatefulBuilder(
      builder: (dialogContext, setStateDialog) {
        final currentIcon = selectedIconGetter();
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            l10n.iconLabel,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          trailing: Icon(currentIcon, color: theme.colorScheme.primary),
          onTap: () async {
            final newIcon = await Dialogs.showIconSelectionDialog(
              context: dialogContext,
              currentIcon: currentIcon,
              availableIcons: Constants.availableIcons,
              title: l10n.selectIconTitle,
            );
            if (newIcon != null) {
              onIconSelected(newIcon);
              setStateDialog(() {});
            }
          },
        );
      },
    );
  }
}
