import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TransactionModel {
  final String id; // Firestore document ID
  final String userId; // ID of the user who owns the transaction
  final String description;
  final double amount; // Nên là double cho tiền tệ
  final DateTime date;
  final String
  typeKey; // Thu nhập, Chi tiêu, Chuyển khoản, Đi vay, Cho vay, Điều chỉnh số dư
  final String categoryKey; // Chỉ sử dụng cho 'Chi tiêu'

  // Thay đổi từ tên ví thành document path
  // Ví dụ: 'users/{userId}/wallets/{walletId}'
  final String? wallet; // Document path thay vì tên ví
  final String? fromWallet; // Document path
  final String? toWallet; // Document path

  final String? lender;
  final String? borrower;
  final DateTime? repaymentDate;

  // Thêm balanceBefore để giúp hoàn tác giao dịch adjustment
  final double? balanceBefore; // Số dư trước khi điều chỉnh
  final double? balanceAfter;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.description,
    required this.amount,
    required this.date,
    required this.typeKey,
    this.categoryKey = '',
    this.wallet,
    this.fromWallet,
    this.toWallet,
    this.lender,
    this.borrower,
    this.repaymentDate,
    this.balanceBefore, // Thêm balanceBefore
    this.balanceAfter,
  });

  // Convert Transaction to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'description': description,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'typeKey': typeKey,
      'categoryKey': categoryKey,
      'wallet': wallet, // Lưu trữ đường dẫn document
      'fromWallet': fromWallet,
      'toWallet': toWallet,
      'lender': lender,
      'borrower': borrower,
      'repaymentDate':
          repaymentDate != null ? Timestamp.fromDate(repaymentDate!) : null,
      'balanceBefore': balanceBefore, // Thêm balanceBefore
      'balanceAfter': balanceAfter,
    };
  }

  // Create Transaction from Firestore document
  factory TransactionModel.fromJson(Map<String, dynamic> json, String id) {
    // Chuyển đổi Timestamp thành DateTime an toàn
    DateTime? parseTimestamp(dynamic timestamp) {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is String) {
        return DateTime.tryParse(timestamp);
      }
      return null;
    }

    // Lấy giá trị số một cách an toàn
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    DateTime? parsedDate = parseTimestamp(json['date']);
    if (parsedDate == null) {
      // Xử lý trường hợp date không hợp lệ
      debugPrint(
        "Warning: Invalid date format found for transaction $id. Using current date.",
      );
      parsedDate = DateTime.now();
    }

    return TransactionModel(
      id: id,
      userId: json['userId'] as String? ?? '',
      description: json['description'] as String? ?? '',
      amount: parseDouble(json['amount']),
      date: parsedDate,
      typeKey: json['typeKey'] as String? ?? 'Unknown',
      categoryKey: json['categoryKey'] as String? ?? '',
      wallet: json['wallet'] as String?,
      fromWallet: json['fromWallet'] as String?,
      toWallet: json['toWallet'] as String?,
      lender: json['lender'] as String?,
      borrower: json['borrower'] as String?,
      repaymentDate: parseTimestamp(json['repaymentDate']),
      balanceBefore:
          json['balanceBefore'] != null
              ? parseDouble(json['balanceBefore'])
              : null,
      balanceAfter:
          json['balanceAfter'] != null
              ? parseDouble(json['balanceAfter'])
              : null,
    );
  }

  // Enhanced copyWith to include all fields
  TransactionModel copyWith({
    String? id,
    String? userId,
    String? description,
    double? amount,
    DateTime? date,
    String? typeKey,
    String? categoryKey,
    String? wallet,
    String? fromWallet,
    String? toWallet,
    String? lender,
    String? borrower,
    DateTime? repaymentDate,
    double? balanceBefore,
    double? balanceAfter,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      typeKey: typeKey ?? this.typeKey,
      categoryKey: categoryKey ?? this.categoryKey,
      wallet: wallet ?? this.wallet,
      fromWallet: fromWallet ?? this.fromWallet,
      toWallet: toWallet ?? this.toWallet,
      lender: lender ?? this.lender,
      borrower: borrower ?? this.borrower,
      repaymentDate: repaymentDate ?? this.repaymentDate,
      balanceBefore: balanceBefore ?? this.balanceBefore,
      balanceAfter: balanceAfter ?? this.balanceAfter,
    );
  }

  // Helper method to get wallet name from path
  String? getWalletNameFromPath(String? path) {
    if (path == null || path.isEmpty) return null;
    try {
      // Extract wallet document ID from path
      final docId = path.split('/').last;
      // In real implementation, you would query Firestore to get the name
      // This is a placeholder
      return docId;
    } catch (e) {
      debugPrint("Error extracting wallet name from path: $e");
      return path;
    }
  }

  // Utility method to get display names for wallets (instead of paths)
  String? get walletDisplayName => getWalletNameFromPath(wallet);
  String? get fromWalletDisplayName => getWalletNameFromPath(fromWallet);
  String? get toWalletDisplayName => getWalletNameFromPath(toWallet);
}
