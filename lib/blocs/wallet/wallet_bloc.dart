import 'package:bloc/bloc.dart';
import 'package:finance_app/data/models/wallet.dart';
import 'package:finance_app/data/repositories/wallet_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final WalletRepository walletRepository;

  WalletBloc({required this.walletRepository})
      : super(WalletState(wallets: [], savingsWallets: [], investmentWallets: [])) {
    on<LoadWallets>(_onLoadWallets);
    on<AddWallet>(_onAddWallet);
    on<EditWallet>(_onEditWallet);
    on<DeleteWallet>(_onDeleteWallet);
    on<TabChanged>(_onTabChanged);
    on<SearchWallets>(_onSearchWallets);
    on<ToggleSearch>(_onToggleSearch);
  }

  Future<void> _onLoadWallets(LoadWallets event, Emitter<WalletState> emit) async {
    emit(state.copyWith(isLoading: true)); // Bắt đầu loading
    try {
      final allWallets = await walletRepository.getWallets();
      debugPrint("Loaded wallets: ${allWallets.length}");
      emit(state.copyWith(
        wallets: allWallets.where((w) => w.type == 0).toList(),
        savingsWallets: allWallets.where((w) => w.type == 1).toList(),
        investmentWallets: allWallets.where((w) => w.type == 2).toList(),
        searchQuery: '',
        isSearching: false,
        isLoading: false, // Kết thúc loading
        error: null,
      ));
    } catch (e) {
      debugPrint("Error in Bloc loading wallets: $e");
      emit(state.copyWith(
        wallets: [],
        savingsWallets: [],
        investmentWallets: [],
        isLoading: false, // Kết thúc loading ngay cả khi lỗi
        error: (context) => AppLocalizations.of(context)!.errorLoadingWallets,
      ));
    }
  }

  Future<void> _onAddWallet(AddWallet event, Emitter<WalletState> emit) async {
    try {
      final newWallet = await walletRepository.addWallet(event.wallet);
      if (newWallet.type == 0) {
        emit(state.copyWith(wallets: List.from(state.wallets)..add(newWallet)));
      } else if (newWallet.type == 1) {
        emit(state.copyWith(savingsWallets: List.from(state.savingsWallets)..add(newWallet)));
      } else if (newWallet.type == 2) {
        emit(state.copyWith(investmentWallets: List.from(state.investmentWallets)..add(newWallet)));
      }
    } catch (e) {
      debugPrint("Error in Bloc adding wallet: $e");
      emit(state.copyWith(
        error: (context) => AppLocalizations.of(context)!.genericErrorWithMessage(e.toString()),
      ));
    }
  }

  Future<void> _onEditWallet(EditWallet event, Emitter<WalletState> emit) async {
    try {
      await walletRepository.updateWallet(event.wallet);
      List<Wallet> updatedList;
      if (event.wallet.type == 0) {
        updatedList = List.from(state.wallets);
      } else if (event.wallet.type == 1) {
        updatedList = List.from(state.savingsWallets);
      } else {
        updatedList = List.from(state.investmentWallets);
      }
      final index = updatedList.indexWhere((w) => w.id == event.wallet.id);
      if (index != -1) {
        updatedList[index] = event.wallet;
        emit(state.copyWith(
          wallets: event.wallet.type == 0 ? updatedList : state.wallets,
          savingsWallets: event.wallet.type == 1 ? updatedList : state.savingsWallets,
          investmentWallets: event.wallet.type == 2 ? updatedList : state.investmentWallets,
        ));
      }
    } catch (e) {
      debugPrint("Error in Bloc editing wallet: $e");
      emit(state.copyWith(
        error: (context) => AppLocalizations.of(context)!.genericErrorWithMessage(e.toString()),
      ));
    }
  }

  Future<void> _onDeleteWallet(DeleteWallet event, Emitter<WalletState> emit) async {
    try {
      await walletRepository.deleteWallet(event.walletId);
      if (event.type == 0) {
        emit(state.copyWith(wallets: List.from(state.wallets)..removeWhere((w) => w.id == event.walletId)));
      } else if (event.type == 1) {
        emit(state.copyWith(savingsWallets: List.from(state.savingsWallets)..removeWhere((w) => w.id == event.walletId)));
      } else if (event.type == 2) {
        emit(state.copyWith(investmentWallets: List.from(state.investmentWallets)..removeWhere((w) => w.id == event.walletId)));
      }
    } catch (e) {
      debugPrint("Error in Bloc deleting wallet: $e");
      emit(state.copyWith(
        error: (context) => AppLocalizations.of(context)!.genericErrorWithMessage(e.toString()),
      ));
    }
  }

  void _onTabChanged(TabChanged event, Emitter<WalletState> emit) {
    emit(state.copyWith(selectedTab: event.newIndex));
  }

  void _onSearchWallets(SearchWallets event, Emitter<WalletState> emit) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onToggleSearch(ToggleSearch event, Emitter<WalletState> emit) {
    emit(state.copyWith(isSearching: event.isSearching, searchQuery: event.isSearching ? state.searchQuery : ''));
  }

  List<Wallet> filterWallets(String query, List<Wallet> wallets) {
    if (query.isEmpty) {
      return wallets;
    }
    final lowerCaseQuery = query.toLowerCase();
    return wallets.where((wallet) => wallet.name.toLowerCase().contains(lowerCaseQuery)).toList();
  }
}