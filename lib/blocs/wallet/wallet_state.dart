import 'package:finance_app/data/models/wallet.dart';
import 'package:flutter/material.dart';

class WalletState {
  final List<Wallet> wallets;
  final List<Wallet> savingsWallets;
  final List<Wallet> investmentWallets;
  final int selectedTab;
  final String searchQuery;
  final bool isSearching;
  final String Function(BuildContext)? error;

  WalletState({
    required this.wallets,
    required this.savingsWallets,
    required this.investmentWallets,
    this.selectedTab = 0,
    this.searchQuery = '',
    this.isSearching = false,
    this.error,
  });

  WalletState copyWith({
    List<Wallet>? wallets,
    List<Wallet>? savingsWallets,
    List<Wallet>? investmentWallets,
    int? selectedTab,
    String? searchQuery,
    bool? isSearching,
    String Function(BuildContext)? error,
  }) {
    return WalletState(
      wallets: wallets ?? this.wallets,
      savingsWallets: savingsWallets ?? this.savingsWallets,
      investmentWallets: investmentWallets ?? this.investmentWallets,
      selectedTab: selectedTab ?? this.selectedTab,
      searchQuery: searchQuery ?? this.searchQuery,
      isSearching: isSearching ?? this.isSearching,
      error: error ?? this.error,
    );
  }
}