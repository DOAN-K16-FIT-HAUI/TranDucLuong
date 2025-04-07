import 'package:finance_app/blocs/wallet/wallet_state.dart';
import 'package:finance_app/data/models/wallet.dart';
import 'package:flutter/material.dart';

mixin WalletMixin<T extends StatefulWidget> on State<T> {
  List<Wallet> _allWallets = [];
  Map<String, double> _walletBalances = {};
  String _selectedWallet = '';
  String _selectedFromWallet = '';
  String _selectedToWallet = '';

  List<String> get walletNames => _allWallets.map((wallet) => wallet.name).toList();

  void updateWallets(WalletState state) {
    if (!mounted) return;
    setState(() {
      _allWallets = [
        ...state.wallets,
        ...state.savingsWallets,
        ...state.investmentWallets,
      ].where((w) => w.id.isNotEmpty).toList();
      _allWallets.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      _walletBalances = Map.fromEntries(
        _allWallets.map((wallet) => MapEntry(wallet.name, wallet.balance.toDouble())),
      );
      _setDefaultWallets();
    });
  }

  void _setDefaultWallets() {
    if (!mounted) return;
    setState(() {
      if (_allWallets.isNotEmpty) {
        if (!_allWallets.any((w) => w.name == _selectedWallet)) {
          _selectedWallet = _allWallets.first.name;
        }
        if (!_allWallets.any((w) => w.name == _selectedFromWallet)) {
          _selectedFromWallet = _allWallets.first.name;
        }
        final availableToWallets = _allWallets.where((w) => w.name != _selectedFromWallet).toList();
        if (!_allWallets.any((w) => w.name == _selectedToWallet) ||
            (_allWallets.length > 1 && _selectedToWallet == _selectedFromWallet)) {
          _selectedToWallet = availableToWallets.isNotEmpty
              ? availableToWallets.first.name
              : _allWallets.first.name;
        }
      } else {
        _selectedWallet = '';
        _selectedFromWallet = '';
        _selectedToWallet = '';
      }
    });
  }
}