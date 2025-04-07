import 'package:bloc/bloc.dart';
import 'package:finance_app/blocs/transaction/transaction_event.dart';
import 'package:finance_app/blocs/transaction/transaction_state.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository transactionRepository;

  TransactionBloc({required this.transactionRepository}) : super(TransactionInitial()) {
    on<AddTransaction>(_onAddTransaction);
    on<UpdateTransaction>(_onUpdateTransaction);
    on<DeleteTransaction>(_onDeleteTransaction);
    on<LoadTransactions>(_onLoadTransactions);
  }

  Future<void> _onAddTransaction(AddTransaction event, Emitter<TransactionState> emit) async {
    emit(TransactionLoading());
    try {
      await transactionRepository.addTransaction(event.transaction);
      emit(TransactionSuccess('Transaction added successfully'));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onUpdateTransaction(UpdateTransaction event, Emitter<TransactionState> emit) async {
    emit(TransactionLoading());
    try {
      await transactionRepository.updateTransaction(event.transaction);
      emit(TransactionSuccess('Transaction updated successfully'));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onDeleteTransaction(DeleteTransaction event, Emitter<TransactionState> emit) async {
    emit(TransactionLoading());
    try {
      await transactionRepository.deleteTransaction(event.transactionId);
      emit(TransactionSuccess('Transaction deleted successfully'));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onLoadTransactions(LoadTransactions event, Emitter<TransactionState> emit) async {
    emit(TransactionLoading());
    try {
      final stream = transactionRepository.getUserTransactions(event.userId);
      await for (final transactions in stream) {
        emit(TransactionLoaded(transactions));
      }
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }
}