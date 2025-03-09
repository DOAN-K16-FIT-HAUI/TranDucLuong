import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/transaction_repository.dart';

// Events
abstract class TransactionEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadTransactions extends TransactionEvent {}

class AddTransaction extends TransactionEvent {
  final TransactionModel transaction;
  AddTransaction(this.transaction);
}

class UpdateTransaction extends TransactionEvent {
  final TransactionModel transaction;
  UpdateTransaction(this.transaction);
}

class DeleteTransaction extends TransactionEvent {
  final String transactionId;
  DeleteTransaction(this.transactionId);
}

// States
abstract class TransactionState extends Equatable {
  @override
  List<Object> get props => [];
}

class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {}

class TransactionLoaded extends TransactionState {
  final List<TransactionModel> transactions;
  TransactionLoaded(this.transactions);
}

class TransactionError extends TransactionState {
  final String message;
  TransactionError(this.message);
}

// BLoC
class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository transactionRepository;

  TransactionBloc({required this.transactionRepository})
      : super(TransactionInitial()) {
    on<LoadTransactions>((event, emit) async {
      emit(TransactionLoading());
      try {
        transactionRepository.getTransactions().listen((transactions) {
          add(_TransactionUpdated(transactions));
        });
      } catch (e) {
        emit(TransactionError(e.toString()));
      }
    });

    on<_TransactionUpdated>((event, emit) {
      emit(TransactionLoaded(event.transactions));
    });

    on<AddTransaction>((event, emit) async {
      await transactionRepository.addTransaction(event.transaction);
      add(LoadTransactions()); // Trigger LoadTransactions after adding
    });

    on<UpdateTransaction>((event, emit) async {
      await transactionRepository.updateTransaction(event.transaction);
      add(LoadTransactions()); // Trigger LoadTransactions after updating
    });

    on<DeleteTransaction>((event, emit) async {
      await transactionRepository.deleteTransaction(event.transactionId);
      add(LoadTransactions()); // Trigger LoadTransactions after deleting
    });
  }
}

// Sự kiện nội bộ để cập nhật danh sách transaction
class _TransactionUpdated extends TransactionEvent {
  final List<TransactionModel> transactions;
  _TransactionUpdated(this.transactions);
}
