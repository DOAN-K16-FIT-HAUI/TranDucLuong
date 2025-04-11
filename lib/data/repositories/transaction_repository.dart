import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_app/data/models/transaction.dart';
import 'package:finance_app/data/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class TransactionRepository {
  final FirestoreService firestoreService;
  final FirebaseAuth _auth; // Inject FirebaseAuth
  static const String transactionCollectionPath = 'transactions'; // Collection gốc

  // Sửa constructor để nhận FirebaseAuth
  TransactionRepository(this.firestoreService, {FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  // Lấy userId hiện tại
  String? _getUserId() {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint("TransactionRepository: User is not logged in.");
    }
    return user?.uid;
  }

  // Lấy đường dẫn collection ví của người dùng
  String _userWalletCollectionPath(String userId) {
    // Quan trọng: Đảm bảo đường dẫn này khớp với WalletRepository
    return 'users/$userId/wallets';
  }

  // --- Hàm trợ giúp cập nhật số dư ví (sử dụng trong Batch hoặc Transaction) ---
  Future<void> _updateWalletBalance({
    required FirebaseFirestore firestore, // Instance Firestore
    required WriteBatch batch, // Batch đang thực thi
    // Hoặc Transaction transaction object nếu dùng Firestore Transaction
    // required dynamic transactionOrBatch, // Có thể truyền Transaction hoặc WriteBatch
    required String userId,
    required String walletName, // Tìm ví theo tên
    required double amountChange, // Số tiền thay đổi (+ hoặc -)
    bool isAdjustment = false,   // True nếu là loại 'Điều chỉnh số dư'
    double? newBalance,          // Số dư mới cho 'Điều chỉnh số dư'
  }) async {
    // Tìm document ví dựa trên tên trong collection của user
    final querySnapshot = await firestore
        .collection(_userWalletCollectionPath(userId))
        .where('name', isEqualTo: walletName)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final walletDocRef = querySnapshot.docs.first.reference;
      if (isAdjustment && newBalance != null) {
        // Điều chỉnh số dư: Đặt giá trị mới
        batch.update(walletDocRef, {'balance': newBalance});
        // if (transactionOrBatch is WriteBatch) {
        //   transactionOrBatch.update(walletDocRef, {'balance': newBalance});
        // } else if (transactionOrBatch is Transaction) {
        //   transactionOrBatch.update(walletDocRef, {'balance': newBalance});
        // }
      } else {
        // Các loại khác: Tăng/giảm bằng FieldValue.increment
        batch.update(walletDocRef, {'balance': FieldValue.increment(amountChange)});
        // if (transactionOrBatch is WriteBatch) {
        //   transactionOrBatch.update(walletDocRef, {'balance': FieldValue.increment(amountChange)});
        // } else if (transactionOrBatch is Transaction) {
        //    // Đọc số dư hiện tại trong transaction để đảm bảo tính đúng đắn nếu cần kiểm tra logic phức tạp
        // final walletSnapshot = await transactionOrBatch.get(walletDocRef);
        // final currentBalance = (walletSnapshot.data() as Map<String, dynamic>?)?['balance'] ?? 0.0;
        // transactionOrBatch.update(walletDocRef, {'balance': currentBalance + amountChange});
        //    // Hoặc đơn giản nếu chỉ cần tăng/giảm:
        //    transactionOrBatch.update(walletDocRef, {'balance': FieldValue.increment(amountChange)});
        // }
      }
      debugPrint("Scheduled update for wallet '$walletName': change=$amountChange, adjustment=$isAdjustment, newBalance=$newBalance");
    } else {
      // Ví không tìm thấy! Đây là lỗi nghiêm trọng.
      debugPrint("Error: Wallet with name '$walletName' not found for user '$userId'. Balance not updated.");
      // Nên throw lỗi để ngăn chặn việc commit batch/transaction không hoàn chỉnh
      throw Exception("Wallet '$walletName' not found. Transaction aborted.");
    }
  }
  // --- Phiên bản hàm trợ giúp dùng cho Firestore Transaction ---
  Future<void> _updateWalletBalanceInTransaction({
    required FirebaseFirestore firestore,
    required Transaction transaction, // Đối tượng Transaction
    required String userId,
    required String walletName,
    required double amountChange,
    bool isAdjustment = false,
    double? newBalance,
  }) async {
    final querySnapshot = await firestore // Query bên ngoài transaction không được khuyến nghị, nhưng get thì được
        .collection(_userWalletCollectionPath(userId))
        .where('name', isEqualTo: walletName)
        .limit(1)
        .get(); // Get có thể chạy bên ngoài transaction

    if (querySnapshot.docs.isNotEmpty) {
      final walletDocRef = querySnapshot.docs.first.reference;
      if (isAdjustment && newBalance != null) {
        transaction.update(walletDocRef, {'balance': newBalance});
      } else {
        // Sử dụng FieldValue.increment trong transaction là an toàn
        transaction.update(walletDocRef, {'balance': FieldValue.increment(amountChange)});
      }
      debugPrint("Scheduled update via Transaction for wallet '$walletName': change=$amountChange, adjustment=$isAdjustment, newBalance=$newBalance");
    } else {
      debugPrint("Error: Wallet with name '$walletName' not found during transaction for user '$userId'. Transaction will fail.");
      throw Exception("Wallet '$walletName' not found."); // Throw để hủy transaction
    }
  }

  // --- Add a new transaction AND update wallet balance ---
  Future<void> addTransaction(TransactionModel transaction) async {
    final userId = _getUserId();
    if (userId == null) {
      throw Exception('User not logged in. Cannot add transaction.');
    }

    // Gán userId cho giao dịch nếu chưa có (đảm bảo)
    final transactionWithUser = transaction.userId.isEmpty
        ? _copyWithUserId(transaction, userId)
        : transaction;

    final firestore = firestoreService.firestore;
    final batch = firestore.batch();

    try {
      // 1. Thêm document giao dịch mới vào batch
      // Collection gốc 'transactions'
      final newTransactionRef = firestore.collection(transactionCollectionPath).doc(); // Để Firestore tạo ID
      // Tạo transaction với ID mới trước khi lưu để có thể tham chiếu nếu cần
      final transactionToSave = _copyWithId(transactionWithUser, newTransactionRef.id);
      batch.set(newTransactionRef, transactionToSave.toJson());

      // 2. Cập nhật số dư ví dựa trên loại giao dịch
      switch (transactionToSave.typeKey) {
        case 'Thu nhập':
          if (transactionToSave.wallet != null) {
            await _updateWalletBalance(
              firestore: firestore, batch: batch, userId: userId,
              walletName: transactionToSave.wallet!,
              amountChange: transactionToSave.amount,
            );
          } else { throw Exception("Wallet is required for Income transaction."); }
          break;
        case 'Chi tiêu':
          if (transactionToSave.wallet != null) {
            await _updateWalletBalance(
              firestore: firestore, batch: batch, userId: userId,
              walletName: transactionToSave.wallet!,
              amountChange: -transactionToSave.amount, // Trừ đi
            );
          } else { throw Exception("Wallet is required for Expense transaction."); }
          break;
        case 'Chuyển khoản':
          if (transactionToSave.fromWallet != null && transactionToSave.toWallet != null) {
            // Giảm số dư ví nguồn
            await _updateWalletBalance(
              firestore: firestore, batch: batch, userId: userId,
              walletName: transactionToSave.fromWallet!,
              amountChange: -transactionToSave.amount,
            );
            // Tăng số dư ví đích
            await _updateWalletBalance(
              firestore: firestore, batch: batch, userId: userId,
              walletName: transactionToSave.toWallet!,
              amountChange: transactionToSave.amount,
            );
          } else { throw Exception("FromWallet and ToWallet are required for Transfer transaction."); }
          break;
        case 'Đi vay':
          if (transactionToSave.wallet != null) {
            await _updateWalletBalance(
              firestore: firestore, batch: batch, userId: userId,
              walletName: transactionToSave.wallet!,
              amountChange: transactionToSave.amount, // Tăng số dư
            );
          } else { throw Exception("Wallet is required for Loan (Borrow) transaction."); }
          break;
        case 'Cho vay':
          if (transactionToSave.wallet != null) {
            await _updateWalletBalance(
              firestore: firestore, batch: batch, userId: userId,
              walletName: transactionToSave.wallet!,
              amountChange: -transactionToSave.amount, // Giảm số dư
            );
          } else { throw Exception("Wallet is required for Loan (Lend) transaction."); }
          break;
        case 'Điều chỉnh số dư':
          if (transactionToSave.wallet != null && transactionToSave.balanceAfter != null) {
            await _updateWalletBalance(
              firestore: firestore, batch: batch, userId: userId,
              walletName: transactionToSave.wallet!,
              amountChange: 0, // Không dùng amountChange
              isAdjustment: true,
              newBalance: transactionToSave.balanceAfter!,
            );
          } else { throw Exception("Wallet and BalanceAfter are required for Balance Adjustment transaction."); }
          break;
        default:
          debugPrint("Warning: Unknown transaction type '${transactionToSave.typeKey}'. Wallet balance not updated.");
      // Hoặc throw lỗi nếu type không hợp lệ là nghiêm trọng
      // throw Exception("Invalid transaction typeKey: ${transactionToSave.typeKey}");
      }

      // 3. Commit batch
      await batch.commit();
      debugPrint("Transaction added and wallet balance(s) updated successfully (ID: ${newTransactionRef.id}).");

    } catch (e) {
      debugPrint("Error during addTransaction batch: $e");
      // Ném lại lỗi để Bloc có thể bắt và hiển thị cho người dùng
      throw Exception('Failed to add transaction and update balance: $e');
    }
  }

  // --- Helper functions for reversing/applying effects in transactions ---
  Future<void> _reverseTransactionEffect(
      FirebaseFirestore firestore, Transaction transaction, String userId, TransactionModel oldTransaction) async {
    double amountChange = 0;
    switch (oldTransaction.typeKey) {
      case 'Thu nhập':
        amountChange = -oldTransaction.amount; // Hoàn tác thu nhập là trừ đi
        if (oldTransaction.wallet != null) {
          await _updateWalletBalanceInTransaction(firestore: firestore, transaction: transaction, userId: userId, walletName: oldTransaction.wallet!, amountChange: amountChange);
        }
        break;
      case 'Chi tiêu':
        amountChange = oldTransaction.amount; // Hoàn tác chi tiêu là cộng lại
        if (oldTransaction.wallet != null) {
          await _updateWalletBalanceInTransaction(firestore: firestore, transaction: transaction, userId: userId, walletName: oldTransaction.wallet!, amountChange: amountChange);
        }
        break;
      case 'Chuyển khoản':
        if (oldTransaction.fromWallet != null && oldTransaction.toWallet != null) {
          // Hoàn tác ví nguồn (cộng lại)
          await _updateWalletBalanceInTransaction(firestore: firestore, transaction: transaction, userId: userId, walletName: oldTransaction.fromWallet!, amountChange: oldTransaction.amount);
          // Hoàn tác ví đích (trừ đi)
          await _updateWalletBalanceInTransaction(firestore: firestore, transaction: transaction, userId: userId, walletName: oldTransaction.toWallet!, amountChange: -oldTransaction.amount);
        }
        break;
      case 'Đi vay':
        amountChange = -oldTransaction.amount; // Hoàn tác vay là trừ đi
        if (oldTransaction.wallet != null) {
          await _updateWalletBalanceInTransaction(firestore: firestore, transaction: transaction, userId: userId, walletName: oldTransaction.wallet!, amountChange: amountChange);
        }
        break;
      case 'Cho vay':
        amountChange = oldTransaction.amount; // Hoàn tác cho vay là cộng lại
        if (oldTransaction.wallet != null) {
          await _updateWalletBalanceInTransaction(firestore: firestore, transaction: transaction, userId: userId, walletName: oldTransaction.wallet!, amountChange: amountChange);
        }
        break;
      case 'Điều chỉnh số dư':
      // Hoàn tác điều chỉnh rất phức tạp vì không biết số dư *trước* đó.
      // Cách an toàn nhất là không cho phép sửa/xóa giao dịch này hoặc yêu cầu tạo giao dịch điều chỉnh mới để sửa.
      // Tạm thời không làm gì hoặc throw lỗi nếu cố gắng sửa/xóa loại này.
        debugPrint("Warning: Reversing 'Balance Adjustment' is complex and not fully implemented. Balance may become incorrect if this transaction is updated or deleted.");
        // throw UnsupportedError("Updating or deleting 'Balance Adjustment' transactions is not recommended.");
        break;
      default:
        debugPrint("Warning: Unknown transaction type '${oldTransaction.typeKey}' during reverse effect. Balance not adjusted.");
    }
  }

  Future<void> _applyTransactionEffect(
      FirebaseFirestore firestore, Transaction transaction, String userId, TransactionModel newTransaction) async {
    double amountChange = 0;
    switch (newTransaction.typeKey) {
      case 'Thu nhập':
        amountChange = newTransaction.amount;
        if (newTransaction.wallet != null) {
          await _updateWalletBalanceInTransaction(firestore: firestore, transaction: transaction, userId: userId, walletName: newTransaction.wallet!, amountChange: amountChange);
        } else { throw Exception("Wallet is required for Income transaction."); }
        break;
      case 'Chi tiêu':
        amountChange = -newTransaction.amount;
        if (newTransaction.wallet != null) {
          await _updateWalletBalanceInTransaction(firestore: firestore, transaction: transaction, userId: userId, walletName: newTransaction.wallet!, amountChange: amountChange);
        } else { throw Exception("Wallet is required for Expense transaction."); }
        break;
      case 'Chuyển khoản':
        if (newTransaction.fromWallet != null && newTransaction.toWallet != null) {
          await _updateWalletBalanceInTransaction(firestore: firestore, transaction: transaction, userId: userId, walletName: newTransaction.fromWallet!, amountChange: -newTransaction.amount);
          await _updateWalletBalanceInTransaction(firestore: firestore, transaction: transaction, userId: userId, walletName: newTransaction.toWallet!, amountChange: newTransaction.amount);
        } else { throw Exception("FromWallet and ToWallet are required for Transfer transaction."); }
        break;
      case 'Đi vay':
        amountChange = newTransaction.amount;
        if (newTransaction.wallet != null) {
          await _updateWalletBalanceInTransaction(firestore: firestore, transaction: transaction, userId: userId, walletName: newTransaction.wallet!, amountChange: amountChange);
        } else { throw Exception("Wallet is required for Loan (Borrow) transaction."); }
        break;
      case 'Cho vay':
        amountChange = -newTransaction.amount;
        if (newTransaction.wallet != null) {
          await _updateWalletBalanceInTransaction(firestore: firestore, transaction: transaction, userId: userId, walletName: newTransaction.wallet!, amountChange: amountChange);
        } else { throw Exception("Wallet is required for Loan (Lend) transaction."); }
        break;
      case 'Điều chỉnh số dư':
        if (newTransaction.wallet != null && newTransaction.balanceAfter != null) {
          await _updateWalletBalanceInTransaction(
            firestore: firestore, transaction: transaction, userId: userId,
            walletName: newTransaction.wallet!,
            amountChange: 0, // Không dùng
            isAdjustment: true,
            newBalance: newTransaction.balanceAfter!,
          );
        } else { throw Exception("Wallet and BalanceAfter are required for Balance Adjustment transaction."); }
        break;
      default:
        debugPrint("Warning: Unknown transaction type '${newTransaction.typeKey}' during apply effect. Balance not adjusted.");
    }
  }


  // --- Update an existing transaction AND adjust wallet balances ---
  Future<void> updateTransaction(TransactionModel newTransaction) async {
    final userId = _getUserId();
    if (userId == null) {
      throw Exception('User not logged in. Cannot update transaction.');
    }
    if (newTransaction.id.isEmpty) {
      throw ArgumentError("Transaction ID is required for update.");
    }
    // Gán userId cho giao dịch nếu chưa có (đảm bảo)
    final transactionWithUser = newTransaction.userId.isEmpty
        ? _copyWithUserId(newTransaction, userId)
        : newTransaction;


    final firestore = firestoreService.firestore;
    final transactionRef = firestore.collection(transactionCollectionPath).doc(transactionWithUser.id);

    try {
      await firestore.runTransaction((transaction) async {
        // 1. Đọc giao dịch cũ trong transaction
        final oldTransactionSnapshot = await transaction.get(transactionRef);
        if (!oldTransactionSnapshot.exists) {
          throw Exception("Transaction with ID ${transactionWithUser.id} not found for update!");
        }
        final oldTransaction = TransactionModel.fromJson(
            oldTransactionSnapshot.data()!, oldTransactionSnapshot.id);

        // --- Cảnh báo về sửa/xóa Điều chỉnh số dư ---
        if (oldTransaction.typeKey == 'Điều chỉnh số dư' || newTransaction.typeKey == 'Điều chỉnh số dư') {
          debugPrint("Warning: Updating a 'Balance Adjustment' transaction or changing a transaction to/from this type can lead to incorrect balances due to the complexity of reversal.");
          // Cân nhắc throw lỗi ở đây để ngăn chặn:
          // throw UnsupportedError("Updating 'Balance Adjustment' transactions is not recommended. Create a new adjustment instead.");
        }

        // 2. Hoàn tác ảnh hưởng của giao dịch cũ lên số dư ví
        await _reverseTransactionEffect(firestore, transaction, userId, oldTransaction);

        // 3. Áp dụng ảnh hưởng của giao dịch mới lên số dư ví
        await _applyTransactionEffect(firestore, transaction, userId, transactionWithUser); // Sử dụng transaction đã có userId

        // 4. Cập nhật document giao dịch với dữ liệu mới
        transaction.update(transactionRef, transactionWithUser.toJson());

      });
      debugPrint("Transaction updated and wallet balance(s) adjusted successfully (ID: ${transactionWithUser.id}).");
    } catch (e) {
      debugPrint("Error during updateTransaction Firestore transaction: $e");
      throw Exception('Failed to update transaction and adjust balance: $e');
    }
  }

  // --- Delete a transaction AND reverse its effect on wallet balance ---
  Future<void> deleteTransaction(String transactionId) async {
    final userId = _getUserId();
    if (userId == null) {
      throw Exception('User not logged in. Cannot delete transaction.');
    }
    if (transactionId.isEmpty) {
      throw ArgumentError("Transaction ID is required for delete.");
    }

    final firestore = firestoreService.firestore;
    final transactionRef = firestore.collection(transactionCollectionPath).doc(transactionId);

    try {
      await firestore.runTransaction((transaction) async {
        // 1. Đọc giao dịch sẽ bị xóa trong transaction
        final transactionSnapshot = await transaction.get(transactionRef);
        if (!transactionSnapshot.exists) {
          // Giao dịch có thể đã bị xóa bởi một thao tác khác. Không cần làm gì.
          debugPrint("Transaction $transactionId not found for deletion (might be already deleted).");
          return; // Kết thúc transaction thành công mà không làm gì cả.
          // Hoặc throw lỗi nếu bạn muốn báo lỗi rõ ràng:
          // throw Exception("Transaction with ID $transactionId not found for delete!");
        }
        final transactionToDelete = TransactionModel.fromJson(
            transactionSnapshot.data()!, transactionSnapshot.id);

        // --- Cảnh báo về sửa/xóa Điều chỉnh số dư ---
        if (transactionToDelete.typeKey == 'Điều chỉnh số dư') {
          debugPrint("Warning: Deleting a 'Balance Adjustment' transaction can lead to incorrect balances due to the complexity of reversal.");
          // Cân nhắc throw lỗi ở đây để ngăn chặn:
          // throw UnsupportedError("Deleting 'Balance Adjustment' transactions is not recommended. Create a new adjustment instead.");
        }

        // 2. Hoàn tác ảnh hưởng của giao dịch lên số dư ví
        await _reverseTransactionEffect(firestore, transaction, userId, transactionToDelete);

        // 3. Xóa document giao dịch
        transaction.delete(transactionRef);
      });
      debugPrint("Transaction deleted and wallet balance(s) reversed successfully (ID: $transactionId).");
    } catch (e) {
      debugPrint("Error during deleteTransaction Firestore transaction: $e");
      throw Exception('Failed to delete transaction and reverse balance: $e');
    }
  }

  // --- Get a transaction by ID (Không thay đổi nhiều) ---
  Future<TransactionModel> getTransaction(String transactionId) async {
    if (transactionId.isEmpty) {
      throw ArgumentError("Transaction ID cannot be empty.");
    }
    try {
      final doc = await firestoreService.getDocument(transactionCollectionPath, transactionId);
      if (!doc.exists || doc.data() == null) {
        throw Exception('TransactionModel not found with ID: $transactionId');
      }
      return TransactionModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      debugPrint("Error getting transaction $transactionId: $e");
      throw Exception('Failed to get transaction: $e');
    }
  }

  // --- Get a stream of transactions for a user ---
  Stream<List<TransactionModel>> getUserTransactions(String userId) {
    if (userId.isEmpty) {
      debugPrint("Cannot get transactions for empty userId.");
      return Stream.value([]); // Trả về stream rỗng
    }
    try {
      // Query collection gốc 'transactions' và lọc theo 'userId'
      return firestoreService.firestore
          .collection(transactionCollectionPath)
          .where('userId', isEqualTo: userId)
      // .orderBy('date', descending: true) // Sắp xếp theo ngày giảm dần (mới nhất trước) - tùy chọn
          .snapshots()
          .map((snapshot) {
        // Log số lượng documents tìm thấy
        // debugPrint("getUserTransactions stream received ${snapshot.docs.length} docs for user $userId");
        return snapshot.docs.map((doc) {
          try {
            return TransactionModel.fromJson(doc.data(), doc.id);
          } catch (e) {
            debugPrint("Error parsing transaction ${doc.id}: $e. Data: ${doc.data()}");
            // Trả về một giá trị mặc định hoặc bỏ qua document lỗi
            // Hoặc return null và lọc ra sau: .where((item) => item != null).toList();
            // Để đơn giản, tạm thời bỏ qua:
            return null;
          }
        }).whereType<TransactionModel>().toList(); // Lọc bỏ các giá trị null nếu có lỗi parsing
      })
          .handleError((error) { // Bắt lỗi từ stream
        debugPrint("Error in getUserTransactions stream for user $userId: $error");
        // Có thể emit một trạng thái lỗi ở đây nếu Bloc lắng nghe trực tiếp stream này
        // Hoặc chỉ log lỗi và trả về danh sách rỗng
        return <TransactionModel>[];
      });
    } catch (e) {
      debugPrint("Error setting up getUserTransactions stream for user $userId: $e");
      throw Exception('Failed to get transactions stream: $e');
    }
  }

  // --- Hàm helper để tạo bản sao TransactionModel với ID ---
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
  TransactionModel _copyWithUserId(TransactionModel transaction, String userId) {
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