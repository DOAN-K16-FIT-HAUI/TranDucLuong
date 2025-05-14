import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_app/data/models/transaction.dart';
import 'package:finance_app/data/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class TransactionRepository {
  final FirestoreService firestoreService;
  final FirebaseAuth _auth;

  // Default pagination size
  static const int defaultPageSize = 20;
  static const String transactionCollectionName = 'transactions';

  // Sửa constructor để nhận FirebaseAuth
  TransactionRepository(this.firestoreService, {FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  // Verify if the user account is active
  Future<bool> _verifyAccountActive() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Force reload user to get latest account status
      await user.reload();

      // Get fresh user object after reload
      final freshUser = _auth.currentUser;
      if (freshUser == null) return false;

      try {
        // This will throw an error if account is disabled
        await freshUser.getIdToken(true);
        return true;
      } catch (e) {
        if (e is FirebaseAuthException && e.code == 'user-disabled') {
          return false;
        }
        rethrow;
      }
    } catch (e) {
      debugPrint("Error verifying account status: $e");
      return false;
    }
  }

  // Enhanced getUserId with account status check
  Future<String> _getVerifiedUserId() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw SecurityException("User not logged in");
    }

    // Check if account is disabled
    if (!await _verifyAccountActive()) {
      throw SecurityException("Account is disabled");
    }

    return user.uid;
  }

  // Lấy userId hiện tại (without verification - for read operations)
  String? _getUserId() {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint("TransactionRepository: User is not logged in.");
    }
    return user?.uid;
  }

  // Lấy đường dẫn collection transactions của người dùng
  String _userTransactionsPath(String userId) {
    return 'users/$userId/$transactionCollectionName';
  }

  // Lấy đường dẫn collection ví của người dùng
  String _userWalletCollectionPath(String userId) {
    // Quan trọng: Đảm bảo đường dẫn này khớp với WalletRepository
    return 'users/$userId/wallets';
  }

  // Lấy document Reference của ví từ tên ví
  Future<DocumentReference?> _getWalletRefByName({
    required FirebaseFirestore firestore,
    required String userId,
    required String walletName,
  }) async {
    debugPrint("Looking up wallet reference for name: '$walletName'");

    final querySnapshot =
        await firestore
            .collection(_userWalletCollectionPath(userId))
            .where('name', isEqualTo: walletName)
            .limit(1)
            .get();

    if (querySnapshot.docs.isNotEmpty) {
      final ref = querySnapshot.docs.first.reference;
      debugPrint("Found wallet reference: ${ref.path}");
      return ref;
    }

    debugPrint("Warning: No wallet found with name '$walletName'");
    return null;
  }

  // --- Hàm trợ giúp cập nhật số dư ví (sử dụng trong Batch hoặc Transaction) ---
  Future<void> _updateWalletBalance({
    required FirebaseFirestore firestore, // Instance Firestore
    required WriteBatch batch, // Batch đang thực thi
    required String userId,
    required String walletName, // Tìm ví theo tên
    required double amountChange, // Số tiền thay đổi (+ hoặc -)
    bool isAdjustment = false, // True nếu là loại 'Điều chỉnh số dư'
    double? newBalance, // Số dư mới cho 'Điều chỉnh số dư'
  }) async {
    // Tìm document ví dựa trên tên trong collection của user
    final querySnapshot =
        await firestore
            .collection(_userWalletCollectionPath(userId))
            .where('name', isEqualTo: walletName)
            .limit(1)
            .get();

    if (querySnapshot.docs.isNotEmpty) {
      final walletDocRef = querySnapshot.docs.first.reference;
      if (isAdjustment && newBalance != null) {
        // Điều chỉnh số dư: Đặt giá trị mới
        batch.update(walletDocRef, {'balance': newBalance});
      } else {
        // Các loại khác: Tăng/giảm bằng FieldValue.increment
        batch.update(walletDocRef, {
          'balance': FieldValue.increment(amountChange),
        });
      }
      debugPrint(
        "Scheduled update for wallet '$walletName' (${walletDocRef.path}): change=$amountChange, adjustment=$isAdjustment, newBalance=$newBalance",
      );
    } else {
      // Ví không tìm thấy! Đây là lỗi nghiêm trọng.
      debugPrint(
        "Error: Wallet with name '$walletName' not found for user '$userId'. Balance not updated.",
      );
      // Nên throw lỗi để ngăn chặn việc commit batch/transaction không hoàn chỉnh
      throw Exception("Wallet '$walletName' not found. Transaction aborted.");
    }
  }

  // --- Phiên bản hàm trợ giúp dùng cho Firestore Transaction ---
  Future<void> _updateWalletBalanceInTransaction({
    required FirebaseFirestore firestore,
    required Transaction transaction, // Đối tượng Transaction
    required String userId,
    required String walletPath, // Đường dẫn đến document ví, không còn là tên
    required double amountChange,
    bool isAdjustment = false,
    double? newBalance,
  }) async {
    final walletDocRef = firestore.doc(walletPath);

    try {
      if (isAdjustment && newBalance != null) {
        transaction.update(walletDocRef, {'balance': newBalance});
      } else {
        // Sử dụng FieldValue.increment trong transaction là an toàn
        transaction.update(walletDocRef, {
          'balance': FieldValue.increment(amountChange),
        });
      }
      debugPrint(
        "Scheduled update via Transaction for wallet '${walletDocRef.path}': change=$amountChange, adjustment=$isAdjustment, newBalance=$newBalance",
      );
    } catch (e) {
      debugPrint(
        "Error: Failed to update wallet ${walletDocRef.path} in transaction: $e",
      );
      throw Exception(
        "Failed to update wallet balance. Transaction will fail: $e",
      ); // Throw để hủy transaction
    }
  }

  // --- Add a new transaction AND update wallet balance ---
  Future<void> addTransaction(TransactionModel transaction) async {
    final userId = await _getVerifiedUserId();

    // Gán userId cho giao dịch nếu chưa có
    final transactionWithUser =
        transaction.userId.isEmpty
            ? _copyWithUserId(transaction, userId)
            : transaction;

    final firestore = firestoreService.firestore;
    final batch = firestore.batch();

    try {
      // Convert wallet names to wallet paths (document references)
      TransactionModel transactionToSave = transactionWithUser;

      // Handle standard wallet field (used for income, expense, borrow, lend, adjustment)
      if (transactionWithUser.wallet != null &&
          !transactionWithUser.wallet!.contains('/')) {
        final walletRef = await _getWalletRefByName(
          firestore: firestore,
          userId: userId,
          walletName: transactionWithUser.wallet!,
        );
        if (walletRef != null) {
          transactionToSave = transactionToSave.copyWith(
            wallet: walletRef.path,
          );
        }
      }

      // Handle fromWallet (used by transfer)
      if (transactionWithUser.fromWallet != null &&
          !transactionWithUser.fromWallet!.contains('/')) {
        final fromWalletRef = await _getWalletRefByName(
          firestore: firestore,
          userId: userId,
          walletName: transactionWithUser.fromWallet!,
        );
        if (fromWalletRef != null) {
          transactionToSave = transactionToSave.copyWith(
            fromWallet: fromWalletRef.path,
          );
        }
      }

      // Handle toWallet (used by transfer)
      if (transactionWithUser.toWallet != null &&
          !transactionWithUser.toWallet!.contains('/')) {
        final toWalletRef = await _getWalletRefByName(
          firestore: firestore,
          userId: userId,
          walletName: transactionWithUser.toWallet!,
        );
        if (toWalletRef != null) {
          transactionToSave = transactionToSave.copyWith(
            toWallet: toWalletRef.path,
          );
        }
      }

      // Đặc biệt xử lý cho adjustment transaction để lưu balanceBefore
      if (transactionToSave.typeKey == 'adjustment' &&
          transactionToSave.wallet != null &&
          transactionToSave.balanceAfter != null) {
        // Đọc số dư hiện tại để lưu vào balanceBefore
        final walletRef = firestore.doc(transactionToSave.wallet!);
        final walletDoc = await walletRef.get();

        if (walletDoc.exists) {
          final currentBalance =
              (walletDoc.data() as Map<String, dynamic>)['balance'] ?? 0.0;
          transactionToSave = transactionToSave.copyWith(
            balanceBefore:
                currentBalance is int
                    ? currentBalance.toDouble()
                    : (currentBalance as num).toDouble(),
          );
        }
      }

      // 1. Thêm document giao dịch mới vào batch - sử dụng subcollection
      final newTransactionRef =
          firestore.collection(_userTransactionsPath(userId)).doc();

      // Tạo transaction với ID mới trước khi lưu
      final finalTransaction = _copyWithId(
        transactionToSave,
        newTransactionRef.id,
      );
      batch.set(newTransactionRef, finalTransaction.toJson());

      // 2. Cập nhật số dư ví dựa trên loại giao dịch
      // Functionality is the same but needs to update paths instead of names
      switch (finalTransaction.typeKey) {
        case 'income':
          if (finalTransaction.wallet != null) {
            await _updateWalletBalanceInTransaction(
              firestore: firestore,
              transaction: await firestore.runTransaction((transaction) async {
                transaction.update(firestore.doc(finalTransaction.wallet!), {
                  'balance': FieldValue.increment(finalTransaction.amount),
                });
                return transaction;
              }),
              userId: userId,
              walletPath: finalTransaction.wallet!,
              amountChange: finalTransaction.amount,
            );
          } else {
            throw Exception("Wallet is required for Income transaction.");
          }
          break;
        case 'expense':
          if (finalTransaction.wallet != null) {
            await _updateWalletBalanceInTransaction(
              firestore: firestore,
              transaction: await firestore.runTransaction((transaction) async {
                transaction.update(firestore.doc(finalTransaction.wallet!), {
                  'balance': FieldValue.increment(-finalTransaction.amount),
                });
                return transaction;
              }),
              userId: userId,
              walletPath: finalTransaction.wallet!,
              amountChange: -finalTransaction.amount,
            );
          } else {
            throw Exception("Wallet is required for Expense transaction.");
          }
          break;
        case 'transfer':
          if (finalTransaction.fromWallet != null &&
              finalTransaction.toWallet != null) {
            await _updateWalletBalanceInTransaction(
              firestore: firestore,
              transaction: await firestore.runTransaction((transaction) async {
                transaction.update(
                  firestore.doc(finalTransaction.fromWallet!),
                  {'balance': FieldValue.increment(-finalTransaction.amount)},
                );
                transaction.update(firestore.doc(finalTransaction.toWallet!), {
                  'balance': FieldValue.increment(finalTransaction.amount),
                });
                return transaction;
              }),
              userId: userId,
              walletPath: finalTransaction.fromWallet!,
              amountChange: -finalTransaction.amount,
            );
            await _updateWalletBalanceInTransaction(
              firestore: firestore,
              transaction: await firestore.runTransaction((transaction) async {
                transaction.update(firestore.doc(finalTransaction.toWallet!), {
                  'balance': FieldValue.increment(finalTransaction.amount),
                });
                return transaction;
              }),
              userId: userId,
              walletPath: finalTransaction.toWallet!,
              amountChange: finalTransaction.amount,
            );
          } else {
            throw Exception(
              "FromWallet and ToWallet are required for Transfer transaction.",
            );
          }
          break;
        case 'borrow':
          if (finalTransaction.wallet != null) {
            await _updateWalletBalanceInTransaction(
              firestore: firestore,
              transaction: await firestore.runTransaction((transaction) async {
                transaction.update(firestore.doc(finalTransaction.wallet!), {
                  'balance': FieldValue.increment(finalTransaction.amount),
                });
                return transaction;
              }),
              userId: userId,
              walletPath: finalTransaction.wallet!,
              amountChange: finalTransaction.amount,
            );
          } else {
            throw Exception(
              "Wallet is required for Loan (Borrow) transaction.",
            );
          }
          break;
        case 'lend':
          if (finalTransaction.wallet != null) {
            await _updateWalletBalanceInTransaction(
              firestore: firestore,
              transaction: await firestore.runTransaction((transaction) async {
                transaction.update(firestore.doc(finalTransaction.wallet!), {
                  'balance': FieldValue.increment(-finalTransaction.amount),
                });
                return transaction;
              }),
              userId: userId,
              walletPath: finalTransaction.wallet!,
              amountChange: -finalTransaction.amount,
            );
          } else {
            throw Exception("Wallet is required for Loan (Lend) transaction.");
          }
          break;
        case 'adjustment':
          if (finalTransaction.wallet != null &&
              finalTransaction.balanceAfter != null) {
            await _updateWalletBalanceInTransaction(
              firestore: firestore,
              transaction: await firestore.runTransaction((transaction) async {
                transaction.update(firestore.doc(finalTransaction.wallet!), {
                  'balance': finalTransaction.balanceAfter,
                });
                return transaction;
              }),
              userId: userId,
              walletPath: finalTransaction.wallet!,
              amountChange: 0,
              isAdjustment: true,
              newBalance: finalTransaction.balanceAfter!,
            );
          } else {
            throw Exception(
              "Wallet and BalanceAfter are required for Balance Adjustment transaction.",
            );
          }
          break;
        default:
          debugPrint(
            "Warning: Unknown transaction type '${finalTransaction.typeKey}'. Wallet balance not updated.",
          );
      }

      // 3. Commit batch
      await batch.commit();

      // 4. Cập nhật dữ liệu tổng hợp nếu cần
      await _updateTransactionSummary(finalTransaction);

      debugPrint(
        "Transaction added and wallet balance(s) updated successfully (ID: ${newTransactionRef.id}).",
      );
    } catch (e) {
      debugPrint("Error during addTransaction batch: $e");
      throw Exception('Failed to add transaction and update balance: $e');
    }
  }

  // --- Helper functions for reversing/applying effects in transactions ---
  Future<void> _reverseTransactionEffect(
    FirebaseFirestore firestore,
    Transaction transaction,
    String userId,
    TransactionModel oldTransaction,
  ) async {
    double amountChange = 0;
    switch (oldTransaction.typeKey) {
      case 'income':
        amountChange = -oldTransaction.amount; // Hoàn tác thu nhập là trừ đi
        if (oldTransaction.wallet != null) {
          await _updateWalletBalanceInTransaction(
            firestore: firestore,
            transaction: transaction,
            userId: userId,
            walletPath: oldTransaction.wallet!,
            amountChange: amountChange,
          );
        }
        break;
      case 'expense':
        amountChange = oldTransaction.amount; // Hoàn tác chi tiêu là cộng lại
        if (oldTransaction.wallet != null) {
          await _updateWalletBalanceInTransaction(
            firestore: firestore,
            transaction: transaction,
            userId: userId,
            walletPath: oldTransaction.wallet!,
            amountChange: amountChange,
          );
        }
        break;
      case 'transfer':
        if (oldTransaction.fromWallet != null &&
            oldTransaction.toWallet != null) {
          // Hoàn tác ví nguồn (cộng lại)
          await _updateWalletBalanceInTransaction(
            firestore: firestore,
            transaction: transaction,
            userId: userId,
            walletPath: oldTransaction.fromWallet!,
            amountChange: oldTransaction.amount,
          );
          // Hoàn tác ví đích (trừ đi)
          await _updateWalletBalanceInTransaction(
            firestore: firestore,
            transaction: transaction,
            userId: userId,
            walletPath: oldTransaction.toWallet!,
            amountChange: -oldTransaction.amount,
          );
        }
        break;
      case 'borrow':
        amountChange = -oldTransaction.amount; // Hoàn tác vay là trừ đi
        if (oldTransaction.wallet != null) {
          await _updateWalletBalanceInTransaction(
            firestore: firestore,
            transaction: transaction,
            userId: userId,
            walletPath: oldTransaction.wallet!,
            amountChange: amountChange,
          );
        }
        break;
      case 'lend':
        amountChange = oldTransaction.amount; // Hoàn tác cho vay là cộng lại
        if (oldTransaction.wallet != null) {
          await _updateWalletBalanceInTransaction(
            firestore: firestore,
            transaction: transaction,
            userId: userId,
            walletPath: oldTransaction.wallet!,
            amountChange: amountChange,
          );
        }
        break;
      case 'adjustment':
        // Cải thiện hỗ trợ cho hoàn tác điều chỉnh số dư
        if (oldTransaction.wallet != null) {
          if (oldTransaction.balanceBefore != null) {
            // Nếu có balanceBefore, khôi phục về giá trị đó
            await _updateWalletBalanceInTransaction(
              firestore: firestore,
              transaction: transaction,
              userId: userId,
              walletPath: oldTransaction.wallet!,
              isAdjustment: true,
              newBalance: oldTransaction.balanceBefore!,
              amountChange: amountChange,
            );
            debugPrint(
              "Reversed adjustment by restoring previous balance: ${oldTransaction.balanceBefore}",
            );
          } else {
            // Nếu không có balanceBefore, hiển thị cảnh báo rõ ràng hơn
            debugPrint(
              "Warning: Cannot properly reverse 'Balance Adjustment' transaction because 'balanceBefore' is not available. "
              "This was likely created before this feature was implemented. Balance might be incorrect.",
            );
            // Không throw lỗi, nhưng developer cần biết về vấn đề này
          }
        }
        break;
      default:
        debugPrint(
          "Warning: Unknown transaction type '${oldTransaction.typeKey}' during reverse effect. Balance not adjusted.",
        );
    }
  }

  Future<void> _applyTransactionEffect(
    FirebaseFirestore firestore,
    Transaction transaction,
    String userId,
    TransactionModel newTransaction,
  ) async {
    double amountChange = 0;
    switch (newTransaction.typeKey) {
      case 'income':
        amountChange = newTransaction.amount;
        if (newTransaction.wallet != null) {
          await _updateWalletBalanceInTransaction(
            firestore: firestore,
            transaction: transaction,
            userId: userId,
            walletPath: newTransaction.wallet!,
            amountChange: amountChange,
          );
        } else {
          throw Exception("Wallet is required for Income transaction.");
        }
        break;
      case 'expense':
        amountChange = -newTransaction.amount;
        if (newTransaction.wallet != null) {
          await _updateWalletBalanceInTransaction(
            firestore: firestore,
            transaction: transaction,
            userId: userId,
            walletPath: newTransaction.wallet!,
            amountChange: amountChange,
          );
        } else {
          throw Exception("Wallet is required for Expense transaction.");
        }
        break;
      case 'transfer':
        if (newTransaction.fromWallet != null &&
            newTransaction.toWallet != null) {
          await _updateWalletBalanceInTransaction(
            firestore: firestore,
            transaction: transaction,
            userId: userId,
            walletPath: newTransaction.fromWallet!,
            amountChange: -newTransaction.amount,
          );
          await _updateWalletBalanceInTransaction(
            firestore: firestore,
            transaction: transaction,
            userId: userId,
            walletPath: newTransaction.toWallet!,
            amountChange: newTransaction.amount,
          );
        } else {
          throw Exception(
            "FromWallet and ToWallet are required for Transfer transaction.",
          );
        }
        break;
      case 'borrow':
        amountChange = newTransaction.amount;
        if (newTransaction.wallet != null) {
          await _updateWalletBalanceInTransaction(
            firestore: firestore,
            transaction: transaction,
            userId: userId,
            walletPath: newTransaction.wallet!,
            amountChange: amountChange,
          );
        } else {
          throw Exception("Wallet is required for Loan (Borrow) transaction.");
        }
        break;
      case 'lend':
        amountChange = -newTransaction.amount;
        if (newTransaction.wallet != null) {
          await _updateWalletBalanceInTransaction(
            firestore: firestore,
            transaction: transaction,
            userId: userId,
            walletPath: newTransaction.wallet!,
            amountChange: amountChange,
          );
        } else {
          throw Exception("Wallet is required for Loan (Lend) transaction.");
        }
        break;
      case 'adjustment':
        if (newTransaction.wallet != null &&
            newTransaction.balanceAfter != null) {
          await _updateWalletBalanceInTransaction(
            firestore: firestore,
            transaction: transaction,
            userId: userId,
            walletPath: newTransaction.wallet!,
            amountChange: 0, // Không dùng
            isAdjustment: true,
            newBalance: newTransaction.balanceAfter!,
          );
        } else {
          throw Exception(
            "Wallet and BalanceAfter are required for Balance Adjustment transaction.",
          );
        }
        break;
      default:
        debugPrint(
          "Warning: Unknown transaction type '${newTransaction.typeKey}' during apply effect. Balance not adjusted.",
        );
    }
  }

  // --- Update an existing transaction AND adjust wallet balances ---
  Future<void> updateTransaction(TransactionModel newTransaction) async {
    final userId = await _getVerifiedUserId();

    if (newTransaction.id.isEmpty) {
      throw ArgumentError("Transaction ID is required for update.");
    }

    // Đặc biệt xử lý cho loại giao dịch adjustment
    if (newTransaction.typeKey == 'adjustment') {
      throw UnsupportedError(
        "Updating 'Balance Adjustment' transactions is not supported. "
        "Please create a new adjustment transaction instead.",
      );
    }

    // Gán userId cho giao dịch nếu chưa có (đảm bảo)
    final transactionWithUser =
        newTransaction.userId.isEmpty
            ? _copyWithUserId(newTransaction, userId)
            : newTransaction;

    final firestore = firestoreService.firestore;

    // Convert wallet names to paths if needed (similar to addTransaction)
    TransactionModel transactionToUpdate = transactionWithUser;

    // Handle standard wallet field
    if (transactionToUpdate.wallet != null &&
        !transactionToUpdate.wallet!.contains('/')) {
      final walletRef = await _getWalletRefByName(
        firestore: firestore,
        userId: userId,
        walletName: transactionToUpdate.wallet!,
      );
      if (walletRef != null) {
        transactionToUpdate = transactionToUpdate.copyWith(
          wallet: walletRef.path,
        );
      }
    }

    // Handle fromWallet
    if (transactionToUpdate.fromWallet != null &&
        !transactionToUpdate.fromWallet!.contains('/')) {
      final fromWalletRef = await _getWalletRefByName(
        firestore: firestore,
        userId: userId,
        walletName: transactionToUpdate.fromWallet!,
      );
      if (fromWalletRef != null) {
        transactionToUpdate = transactionToUpdate.copyWith(
          fromWallet: fromWalletRef.path,
        );
      }
    }

    // Handle toWallet
    if (transactionToUpdate.toWallet != null &&
        !transactionToUpdate.toWallet!.contains('/')) {
      final toWalletRef = await _getWalletRefByName(
        firestore: firestore,
        userId: userId,
        walletName: transactionToUpdate.toWallet!,
      );
      if (toWalletRef != null) {
        transactionToUpdate = transactionToUpdate.copyWith(
          toWallet: toWalletRef.path,
        );
      }
    }

    final transactionRef = firestore
        .collection(_userTransactionsPath(userId))
        .doc(transactionToUpdate.id);

    try {
      await firestore.runTransaction((transaction) async {
        // 1. Đọc giao dịch cũ trong transaction
        final oldTransactionSnapshot = await transaction.get(transactionRef);
        if (!oldTransactionSnapshot.exists) {
          throw Exception(
            "Transaction with ID ${transactionWithUser.id} not found for update!",
          );
        }
        final oldTransaction = TransactionModel.fromJson(
          oldTransactionSnapshot.data()!,
          oldTransactionSnapshot.id,
        );

        // --- Cảnh báo về sửa/xóa Điều chỉnh số dư ---
        if (oldTransaction.typeKey == 'Điều chỉnh số dư' ||
            newTransaction.typeKey == 'Điều chỉnh số dư') {
          debugPrint(
            "Warning: Updating a 'Balance Adjustment' transaction or changing a transaction to/from this type can lead to incorrect balances due to the complexity of reversal.",
          );
          // Cân nhắc throw lỗi ở đây để ngăn chặn:
          // throw UnsupportedError("Updating 'Balance Adjustment' transactions is not recommended. Create a new adjustment instead.");
        }

        // 2. Hoàn tác ảnh hưởng của giao dịch cũ lên số dư ví
        await _reverseTransactionEffect(
          firestore,
          transaction,
          userId,
          oldTransaction,
        );

        // 3. Áp dụng ảnh hưởng của giao dịch mới lên số dư ví
        await _applyTransactionEffect(
          firestore,
          transaction,
          userId,
          transactionToUpdate, // Use the updated transaction with proper paths
        );

        // 4. Cập nhật document giao dịch với dữ liệu mới
        transaction.update(transactionRef, transactionToUpdate.toJson());
      });
      debugPrint(
        "Transaction updated and wallet balance(s) adjusted successfully (ID: ${transactionToUpdate.id}).",
      );
    } catch (e) {
      debugPrint("Error during updateTransaction Firestore transaction: $e");
      throw Exception('Failed to update transaction and adjust balance: $e');
    }
  }

  // --- Delete a transaction AND reverse its effect on wallet balance ---
  Future<void> deleteTransaction(String transactionId) async {
    final userId = await _getVerifiedUserId();

    if (transactionId.isEmpty) {
      throw ArgumentError("Transaction ID is required for delete.");
    }

    final firestore = firestoreService.firestore;
    final transactionRef = firestore
        .collection(_userTransactionsPath(userId))
        .doc(transactionId);

    try {
      await firestore.runTransaction((transaction) async {
        // 1. Đọc giao dịch sẽ bị xóa trong transaction
        final transactionSnapshot = await transaction.get(transactionRef);
        if (!transactionSnapshot.exists) {
          // Giao dịch có thể đã bị xóa bởi một thao tác khác. Không cần làm gì.
          debugPrint(
            "Transaction $transactionId not found for deletion (might be already deleted).",
          );
          return; // Kết thúc transaction thành công mà không làm gì cả.
          // Hoặc throw lỗi nếu bạn muốn báo lỗi rõ ràng:
          // throw Exception("Transaction with ID $transactionId not found for delete!");
        }
        final transactionToDelete = TransactionModel.fromJson(
          transactionSnapshot.data()!,
          transactionSnapshot.id,
        );

        // Không cho phép xóa giao dịch điều chỉnh số dư
        if (transactionToDelete.typeKey == 'adjustment') {
          throw UnsupportedError(
            "Deleting 'Balance Adjustment' transactions is not supported. "
            "Please create a new adjustment transaction to correct the balance if needed.",
          );
        }

        // 2. Hoàn tác ảnh hưởng của giao dịch lên số dư ví
        await _reverseTransactionEffect(
          firestore,
          transaction,
          userId,
          transactionToDelete,
        );

        // 3. Xóa document giao dịch
        transaction.delete(transactionRef);

        // 4. Cập nhật dữ liệu tổng hợp
        await _updateTransactionSummary(transactionToDelete, isDelete: true);
      });

      debugPrint(
        "Transaction deleted and wallet balance(s) reversed successfully (ID: $transactionId).",
      );
    } catch (e) {
      debugPrint("Error during deleteTransaction Firestore transaction: $e");
      throw Exception('Failed to delete transaction and reverse balance: $e');
    }
  }

  // --- Get a transaction by ID ---
  Future<TransactionModel> getTransaction(String transactionId) async {
    final userId = _getUserId();
    if (userId == null) {
      throw Exception('User not logged in. Cannot get transaction.');
    }

    if (transactionId.isEmpty) {
      throw ArgumentError("Transaction ID cannot be empty.");
    }

    try {
      final doc =
          await firestoreService.firestore
              .collection(_userTransactionsPath(userId))
              .doc(transactionId)
              .get();

      if (!doc.exists || doc.data() == null) {
        throw Exception('Transaction not found with ID: $transactionId');
      }

      return TransactionModel.fromJson(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (e) {
      debugPrint("Error getting transaction $transactionId: $e");
      throw Exception('Failed to get transaction: $e');
    }
  }

  // --- Get transactions with pagination ---
  Future<List<TransactionModel>> getTransactions({
    int limit = defaultPageSize,
    DocumentSnapshot? startAfter,
    DateTime? startDate,
    DateTime? endDate,
    String? type,
    String? categoryKey,
    String? walletId,
  }) async {
    final userId = _getUserId();
    if (userId == null) {
      throw Exception('User not logged in. Cannot get transactions.');
    }

    try {
      // Start with base query on user's transactions collection
      Query query = firestoreService.firestore.collection(
        _userTransactionsPath(userId),
      );

      // Add date range filter if provided
      if (startDate != null) {
        query = query.where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }
      if (endDate != null) {
        query = query.where(
          'date',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      // Add type filter if provided
      if (type != null) {
        query = query.where('typeKey', isEqualTo: type);
      }

      // Add category filter if provided
      if (categoryKey != null) {
        query = query.where('categoryKey', isEqualTo: categoryKey);
      }

      // Add wallet filter if provided
      if (walletId != null) {
        final walletPath = 'users/$userId/wallets/$walletId';
        // Need to check in all wallet fields
        query = query.where(
          Filter.or(
            Filter('wallet', isEqualTo: walletPath),
            Filter.or(
              Filter('fromWallet', isEqualTo: walletPath),
              Filter('toWallet', isEqualTo: walletPath),
            ),
          ),
        );
      }

      // Order by date, newest first
      query = query.orderBy('date', descending: true);

      // Add pagination
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      query = query.limit(limit);

      // Hint about index requirements in debug print
      debugPrint(
        "Note: This query might require a composite index. If you see a Firestore error,"
        "check the Firebase console for index creation link.",
      );

      // Execute query
      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map(
            (doc) => TransactionModel.fromJson(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint("Error getting transactions: $e");
      throw Exception('Failed to get transactions: $e');
    }
  }

  // --- Get a stream of transactions for a user with pagination ---
  Stream<List<TransactionModel>> getUserTransactions(
    String userId, {
    int limit = defaultPageSize,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (userId.isEmpty) {
      debugPrint("Cannot get transactions for empty userId.");
      return Stream.value([]);
    }

    try {
      // Start with base query on user's transactions collection
      Query query = firestoreService.firestore.collection(
        _userTransactionsPath(userId),
      );

      // Add date filters if provided
      if (startDate != null) {
        query = query.where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }
      if (endDate != null) {
        query = query.where(
          'date',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      // Order by date, newest first
      query = query.orderBy('date', descending: true);

      // Apply limit for pagination
      query = query.limit(limit);

      return query
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) {
                  try {
                    return TransactionModel.fromJson(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    );
                  } catch (e) {
                    debugPrint(
                      "Error parsing transaction ${doc.id}: $e. Data: ${doc.data()}",
                    );
                    return null;
                  }
                })
                .whereType<TransactionModel>()
                .toList();
          })
          .handleError((error) {
            debugPrint(
              "Error in getUserTransactions stream for user $userId: $error",
            );
            return <TransactionModel>[];
          });
    } catch (e) {
      debugPrint(
        "Error setting up getUserTransactions stream for user $userId: $e",
      );
      throw Exception('Failed to get transactions stream: $e');
    }
  }

  // Helper method to update transaction summaries
  Future<void> _updateTransactionSummary(
    TransactionModel transaction, {
    bool isDelete = false,
  }) async {
    try {
      // This would be implemented in TransactionSummaryRepository
      // We're just making a stub call here
      debugPrint(
        "Updating transaction summary for ${transaction.date.year}-${transaction.date.month}",
      );
      // In a real implementation, you would get an instance of TransactionSummaryRepository
      // and call its updateSummaryForTransaction method
    } catch (e) {
      // Non-critical error, just log it
      debugPrint("Error updating transaction summary: $e");
    }
  }

  // --- Helper functions to copy TransactionModel instances ---
  TransactionModel _copyWithId(TransactionModel transaction, String id) {
    // Không thể dùng copyWith vì model chưa có, phải tạo instance mới
    return TransactionModel(
      id: id, // ID mới
      userId: transaction.userId,
      description: transaction.description,
      amount: transaction.amount,
      date: transaction.date,
      typeKey: transaction.typeKey,
      categoryKey: transaction.categoryKey,
      wallet: transaction.wallet,
      fromWallet: transaction.fromWallet,
      toWallet: transaction.toWallet,
      lender: transaction.lender,
      borrower: transaction.borrower,
      repaymentDate: transaction.repaymentDate,
      balanceAfter: transaction.balanceAfter,
    );
  }

  // --- Hàm helper để tạo bản sao TransactionModel với UserID ---
  TransactionModel _copyWithUserId(
    TransactionModel transaction,
    String userId,
  ) {
    return TransactionModel(
      id: transaction.id,
      userId: userId, // UserID mới
      description: transaction.description,
      amount: transaction.amount,
      date: transaction.date,
      typeKey: transaction.typeKey,
      categoryKey: transaction.categoryKey,
      wallet: transaction.wallet,
      fromWallet: transaction.fromWallet,
      toWallet: transaction.toWallet,
      lender: transaction.lender,
      borrower: transaction.borrower,
      repaymentDate: transaction.repaymentDate,
      balanceAfter: transaction.balanceAfter,
    );
  }
}

// Add custom exceptions for better error handling
class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}
