import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_app/blocs/transaction/transaction_event.dart';
import 'package:finance_app/blocs/transaction/transaction_state.dart';
import 'package:finance_app/data/models/transaction.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository transactionRepository;

  TransactionBloc({required this.transactionRepository})
    : super(TransactionInitial()) {
    on<AddTransaction>(_onAddTransaction);
    on<UpdateTransaction>(_onUpdateTransaction);
    on<DeleteTransaction>(_onDeleteTransaction);
    on<LoadTransactions>(_onLoadTransactions);
    on<LoadMoreTransactions>(_onLoadMoreTransactions);
    on<FilterTransactions>(_onFilterTransactions);
  }

  Future<void> _onAddTransaction(
    AddTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      await transactionRepository.addTransaction(event.transaction);
      emit(
        TransactionSuccess(
          (context) => AppLocalizations.of(context)!.transactionAddedSuccess,
        ),
      );
    } catch (e) {
      emit(
        TransactionError(
          (context) => AppLocalizations.of(
            context,
          )!.genericErrorWithMessage(e.toString()),
        ),
      );
    }
  }

  Future<void> _onUpdateTransaction(
    UpdateTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      await transactionRepository.updateTransaction(event.transaction);
      emit(
        TransactionSuccess(
          (context) => AppLocalizations.of(context)!.transactionUpdatedSuccess,
        ),
      );
    } catch (e) {
      emit(
        TransactionError(
          (context) => AppLocalizations.of(
            context,
          )!.genericErrorWithMessage(e.toString()),
        ),
      );
    }
  }

  Future<void> _onDeleteTransaction(
    DeleteTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      await transactionRepository.deleteTransaction(event.transactionId);
      emit(
        TransactionSuccess(
          (context) => AppLocalizations.of(context)!.transactionDeletedSuccess,
        ),
      );
    } catch (e) {
      emit(
        TransactionError(
          (context) => AppLocalizations.of(
            context,
          )!.genericErrorWithMessage(e.toString()),
        ),
      );
    }
  }

  Future<void> _onLoadTransactions(
    LoadTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      final stream = transactionRepository.getUserTransactions(
        event.userId,
        limit: 20, // Default page size
      );
      await for (final transactions in stream) {
        emit(
          TransactionLoaded(
            transactions,
            hasMoreTransactions: transactions.length >= 20,
            lastDocument:
                transactions.isEmpty
                    ? null
                    : await _getLastDocumentSnapshot(transactions.last),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error loading transactions: $e");
      emit(
        TransactionError(
          (context) => AppLocalizations.of(
            context,
          )!.genericErrorWithMessage(e.toString()),
        ),
      );
    }
  }

  Future<void> _onLoadMoreTransactions(
    LoadMoreTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    // Only proceed if we're in a loaded state and have a lastDocument
    if (state is TransactionLoaded) {
      final currentState = state as TransactionLoaded;

      if (currentState.lastDocument == null ||
          !currentState.hasMoreTransactions) {
        // No more transactions to load
        return;
      }

      try {
        // Use pagination to get more transactions
        final newTransactions = await transactionRepository.getTransactions(
          limit: 20,
          startAfter: currentState.lastDocument,
        );

        // Combine with existing transactions
        final combinedTransactions = [
          ...currentState.transactions,
          ...newTransactions,
        ];

        emit(
          TransactionLoaded(
            combinedTransactions,
            hasMoreTransactions: newTransactions.length >= 20,
            lastDocument:
                newTransactions.isEmpty
                    ? currentState.lastDocument
                    : await _getLastDocumentSnapshot(newTransactions.last),
          ),
        );
      } catch (e) {
        debugPrint("Error loading more transactions: $e");
        emit(
          TransactionError(
            (context) => AppLocalizations.of(
              context,
            )!.genericErrorWithMessage(e.toString()),
          ),
        );
      }
    }
  }

  Future<void> _onFilterTransactions(
    FilterTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());

    try {
      final transactions = await transactionRepository.getTransactions(
        startDate: event.startDate,
        endDate: event.endDate,
        type: event.transactionType,
        categoryKey: event.categoryKey,
        walletId: event.walletId,
      );

      emit(
        TransactionLoaded(
          transactions,
          hasMoreTransactions: transactions.length >= 20,
          lastDocument:
              transactions.isEmpty
                  ? null
                  : await _getLastDocumentSnapshot(transactions.last),
          // Pass along filter criteria so they can be used in LoadMoreTransactions
          filterCriteria: FilterCriteria(
            startDate: event.startDate,
            endDate: event.endDate,
            transactionType: event.transactionType,
            categoryKey: event.categoryKey,
            walletId: event.walletId,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error filtering transactions: $e");
      emit(
        TransactionError(
          (context) => AppLocalizations.of(
            context,
          )!.genericErrorWithMessage(e.toString()),
        ),
      );
    }
  }

  // Helper method to get document snapshot for a transaction
  Future<DocumentSnapshot?> _getLastDocumentSnapshot(
    TransactionModel transaction,
  ) async {
    try {
      final userId = transaction.userId;
      if (userId.isEmpty) return null;

      return await FirebaseFirestore.instance
          .collection('users/$userId/transactions')
          .doc(transaction.id)
          .get();
    } catch (e) {
      debugPrint("Error getting document snapshot: $e");
      return null;
    }
  }
}
