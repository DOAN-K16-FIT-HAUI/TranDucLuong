class TransactionModel {
  final String id; // Firestore document ID
  final String userId; // ID of the user who owns the transaction
  final String description;
  final double amount;
  final DateTime date;
  final String type; // Thu nhập, Chi tiêu, Chuyển khoản, Đi vay, Cho vay, Điều chỉnh số dư
  final String category; // Only for Chi tiêu
  final String wallet; // Wallet for most types
  final String? fromWallet; // For Chuyển khoản
  final String? toWallet; // For Chuyển khoản
  final String? lender; // For Đi vay
  final String? borrower; // For Cho vay
  final DateTime? repaymentDate; // For Đi vay and Cho vay
  final double? balanceAfter; // For Điều chỉnh số dư

  TransactionModel({
    required this.id,
    required this.userId,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
    required this.wallet,
    this.fromWallet,
    this.toWallet,
    this.lender,
    this.borrower,
    this.repaymentDate,
    this.balanceAfter,
  });

  // Convert Transaction to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type,
      'category': category,
      'wallet': wallet,
      'fromWallet': fromWallet,
      'toWallet': toWallet,
      'lender': lender,
      'borrower': borrower,
      'repaymentDate': repaymentDate?.toIso8601String(),
      'balanceAfter': balanceAfter,
    };
  }

  // Create Transaction from Firestore document
  factory TransactionModel.fromJson(Map<String, dynamic> json, String id) {
    return TransactionModel(
      id: id,
      userId: json['userId'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      type: json['type'] as String,
      category: json['category'] as String,
      wallet: json['wallet'] as String,
      fromWallet: json['fromWallet'] as String?,
      toWallet: json['toWallet'] as String?,
      lender: json['lender'] as String?,
      borrower: json['borrower'] as String?,
      repaymentDate: json['repaymentDate'] != null
          ? DateTime.parse(json['repaymentDate'] as String)
          : null,
      balanceAfter: json['balanceAfter'] != null
          ? (json['balanceAfter'] as num).toDouble()
          : null,
    );
  }
}