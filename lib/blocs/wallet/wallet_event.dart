import 'package:finance_app/data/models/wallet.dart';

abstract class WalletEvent {}

class LoadWallets extends WalletEvent {}

class SearchWallets extends WalletEvent {
  final String query;

  SearchWallets(this.query);
}

class AddWallet extends WalletEvent {
  final Wallet wallet;

  AddWallet(this.wallet);
}

class EditWallet extends WalletEvent {
  final Wallet wallet;

  EditWallet(this.wallet);
}

class DeleteWallet extends WalletEvent {
  final String walletId;
  final int type;

  DeleteWallet(this.walletId, this.type);
}

class ReorderWallets extends WalletEvent {
  final int type;
  final int oldIndex;
  late final int newIndex;

  ReorderWallets(this.type, this.oldIndex, this.newIndex);
}

class ToggleSearch extends WalletEvent {
  final bool isSearching;

  ToggleSearch(this.isSearching);
}

class TabChanged extends WalletEvent {
  final int newIndex;

  TabChanged(this.newIndex);
}
