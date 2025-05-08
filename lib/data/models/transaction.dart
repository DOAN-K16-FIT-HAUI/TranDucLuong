import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // Cần thiết cho DateTime parsing

class TransactionModel {
  final String id; // Firestore document ID
  final String userId; // ID of the user who owns the transaction
  final String description;
  final double amount; // Nên là double cho tiền tệ
  final DateTime date;
  final String
  typeKey; // Thu nhập, Chi tiêu, Chuyển khoản, Đi vay, Cho vay, Điều chỉnh số dư
  final String categoryKey; // Chỉ sử dụng cho 'Chi tiêu'
  // 'wallet' dùng cho Thu nhập, Chi tiêu, Đi vay, Cho vay, Điều chỉnh số dư
  // Sẽ là null hoặc rỗng đối với 'Chuyển khoản'
  final String? wallet;
  final String? fromWallet; // Chỉ sử dụng cho 'Chuyển khoản'
  final String? toWallet; // Chỉ sử dụng cho 'Chuyển khoản'
  final String? lender; // Chỉ sử dụng cho 'Đi vay'
  final String? borrower; // Chỉ sử dụng cho 'Cho vay'
  final DateTime? repaymentDate; // Chỉ sử dụng cho 'Đi vay' and 'Cho vay'
  final double? balanceAfter; // Chỉ sử dụng cho 'Điều chỉnh số dư'

  TransactionModel({
    required this.id,
    required this.userId,
    required this.description,
    required this.amount,
    required this.date,
    required this.typeKey,
    this.categoryKey = '', // Mặc định là rỗng nếu không phải Chi tiêu
    this.wallet, // Có thể null
    this.fromWallet, // Có thể null
    this.toWallet, // Có thể null
    this.lender, // Có thể null
    this.borrower, // Có thể null
    this.repaymentDate, // Có thể null
    this.balanceAfter, // Có thể null
  });

  // Convert Transaction to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'description': description,
      'amount': amount,
      'date': Timestamp.fromDate(date), // Sử dụng Timestamp cho Firestore
      'typeKey': typeKey,
      'categoryKey': categoryKey,
      'wallet': wallet,
      'fromWallet': fromWallet,
      'toWallet': toWallet,
      'lender': lender,
      'borrower': borrower,
      'repaymentDate':
          repaymentDate != null ? Timestamp.fromDate(repaymentDate!) : null,
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
      // Xử lý trường hợp date không hợp lệ, ví dụ: dùng ngày hiện tại hoặc throw lỗi
      // Ở đây ví dụ dùng ngày hiện tại, nhưng bạn nên xem xét lại dữ liệu
      debugPrint(
        "Warning: Invalid date format found for transaction $id. Using current date.",
      );
      parsedDate = DateTime.now();
      // Hoặc: throw FormatException("Invalid date format in transaction $id");
    }

    return TransactionModel(
      id: id,
      userId: json['userId'] as String? ?? '', // Xử lý null userId nếu có thể
      description: json['description'] as String? ?? '',
      amount: parseDouble(json['amount']),
      date: parsedDate,
      typeKey: json['typeKey'] as String? ?? 'Unknown', // Xử lý null typeKey
      categoryKey: json['categoryKey'] as String? ?? '',
      wallet: json['wallet'] as String?, // Chấp nhận null
      fromWallet: json['fromWallet'] as String?,
      toWallet: json['toWallet'] as String?,
      lender: json['lender'] as String?,
      borrower: json['borrower'] as String?,
      repaymentDate: parseTimestamp(json['repaymentDate']),
      balanceAfter:
          json['balanceAfter'] != null
              ? parseDouble(json['balanceAfter'])
              : null,
    );
  }

  // Add copyWith method to TransactionModel if it doesn't exist
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
      balanceAfter: balanceAfter ?? this.balanceAfter,
    );
  }
}
