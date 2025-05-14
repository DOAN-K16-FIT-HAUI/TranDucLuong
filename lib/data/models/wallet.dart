import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Wallet {
  final String id;
  final String name;
  final int balance;
  final IconData icon;
  final int type;

  Wallet({
    required this.id,
    required this.name,
    required this.balance,
    required this.icon,
    required this.type,
  }) {
    // Validate wallet data on instantiation
    if (name.trim().isEmpty) {
      throw ArgumentError('Wallet name cannot be empty');
    }

    if (type < 0 || type > 5) {
      // Assuming valid type values are 0-5
      throw ArgumentError('Invalid wallet type: $type');
    }
  }

  Wallet copyWith({
    String? id,
    String? name,
    int? balance,
    IconData? icon,
    int? type,
    int? orderIndex,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      icon: icon ?? this.icon,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'balance': balance,
      'icon_code_point': icon.codePoint,
      'icon_font_family': icon.fontFamily,
      'icon_font_package': icon.fontPackage,
      'type': type,
    };
  }

  factory Wallet.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception("Wallet data is null for document ${snap.id}");
    }

    return Wallet(
      id: snap.id,
      name: data['name'] ?? 'Unknown Name',
      balance: (data['balance'] ?? 0).toInt(),
      icon: IconData(
        data['icon_code_point'] ?? Icons.error.codePoint,
        fontFamily: data['icon_font_family'] ?? 'MaterialIcons',
        fontPackage: data['icon_font_package'],
      ),
      type: (data['type'] ?? 0).toInt(),
    );
  }

  // Validator function that can be used before committing changes
  static void validateWallet(Wallet wallet) {
    if (wallet.name.trim().isEmpty) {
      throw ArgumentError('Wallet name cannot be empty');
    }

    if (wallet.type < 0 || wallet.type > 5) {
      // Adjust range as needed
      throw ArgumentError('Invalid wallet type: ${wallet.type}');
    }
  }

  static IconData findIconByName(String name) {
    switch (name) {
      case 'account_balance_wallet_outlined':
        return Icons.account_balance_wallet_outlined;
      case 'credit_card_outlined':
        return Icons.credit_card_outlined;
      case 'savings_outlined':
        return Icons.savings_outlined;
      case 'trending_up_outlined':
        return Icons.trending_up_outlined;
      case 'currency_bitcoin_outlined':
        return Icons.currency_bitcoin_outlined;
      default:
        return Icons.help_outline;
    }
  }

  String get iconName {
    if (icon == Icons.account_balance_wallet_outlined) {
      return 'account_balance_wallet_outlined';
    }
    if (icon == Icons.credit_card_outlined) return 'credit_card_outlined';
    if (icon == Icons.savings_outlined) return 'savings_outlined';
    if (icon == Icons.trending_up_outlined) return 'trending_up_outlined';
    if (icon == Icons.currency_bitcoin_outlined) {
      return 'currency_bitcoin_outlined';
    }
    return 'help_outline';
  }

  /// Creates an empty Wallet instance
  factory Wallet.empty() {
    return Wallet(
      id: '',
      name: '',
      balance: 0,
      icon: Icons.help_outline,
      type: 0,
    );
  }
}
