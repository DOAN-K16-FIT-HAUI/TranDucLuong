import 'package:finance_app/data/models/wallet.dart';

class WalletState {
  final List<Wallet> wallets;
  final List<Wallet> savingsWallets;
  final List<Wallet> investmentWallets;
  final String searchQuery;
  final bool isSearching;
  final int selectedTab;

  WalletState({
    required this.wallets,
    required this.savingsWallets,
    required this.investmentWallets,
    this.searchQuery = '',
    this.isSearching = false,
    this.selectedTab = 0,
  });

  WalletState copyWith({
    List<Wallet>? wallets,
    List<Wallet>? savingsWallets,
    List<Wallet>? investmentWallets,
    String? searchQuery,
    bool? isSearching,
    int? selectedTab,
  }) {
    return WalletState(
      wallets: wallets ?? this.wallets,
      savingsWallets: savingsWallets ?? this.savingsWallets,
      investmentWallets: investmentWallets ?? this.investmentWallets,
      searchQuery: searchQuery ?? this.searchQuery,
      isSearching: isSearching ?? this.isSearching,
      selectedTab: selectedTab ?? this.selectedTab,
    );
  }
}
