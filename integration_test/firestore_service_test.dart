import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_app/blocs/wallet/wallet_bloc.dart';
import 'package:finance_app/blocs/wallet/wallet_event.dart';
import 'package:finance_app/blocs/wallet/wallet_state.dart';
import 'package:finance_app/data/models/wallet.dart';
import 'package:finance_app/data/repositories/wallet_repository.dart';
import 'package:finance_app/data/services/firebase_auth_service.dart';
import 'package:finance_app/data/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FirebaseAuthService authService;
  late WalletBloc walletBloc;
  late WalletRepository walletRepository;
  late FirestoreService firestoreService;
  late String testEmail;
  const testPassword = 'testpassword';

  setUpAll(() async {
    // Khởi tạo Firebase
    TestWidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();

    // Thiết lập emulator cho Firebase Auth và Firestore
    await FirebaseAuth.instance.useAuthEmulator('10.0.2.2', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('10.0.2.2', 8080);

    // Khởi tạo các service
    authService = FirebaseAuthService();
    firestoreService = FirestoreService();
    walletRepository = WalletRepository(firestoreService);
    walletBloc = WalletBloc(walletRepository: walletRepository);
  });

  setUp(() async {
    // Tạo email mới cho mỗi test
    testEmail = "testuser${DateTime.now().millisecondsSinceEpoch}@example.com";

    // Đảm bảo user chưa đăng nhập
    await FirebaseAuth.instance.signOut();

    // Xóa dữ liệu Firestore trước mỗi test
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final walletsCollection = FirebaseFirestore.instance.collection('users/$userId/wallets');
      final wallets = await walletsCollection.get();
      for (var doc in wallets.docs) {
        await doc.reference.delete();
      }
    }
  });

  tearDown(() {
    // Đóng WalletBloc để reset trạng thái
    walletBloc.close();
    walletBloc = WalletBloc(walletRepository: walletRepository);
  });

  group('Wallet Integration Test with Authentication and Firestore', () {
    test('Full Wallet Flow: Sign up -> Sign in -> Add Wallet -> Edit Wallet -> Delete Wallet -> Sign out', () async {
      // Đăng ký
      final userSignUp = await authService.createUserWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );
      expect(userSignUp.email, testEmail);
      expect(userSignUp.id.isNotEmpty, true);
      expect(userSignUp.loginMethod, 'email');

      // Đăng nhập
      final userSignIn = await authService.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );
      expect(userSignIn.email, testEmail);
      expect(userSignIn.id.isNotEmpty, true);
      expect(userSignIn.loginMethod, 'email');

      // Tạo wallet
      final newWallet = Wallet(
        id: '',
        name: 'Test Wallet',
        balance: 1000,
        icon: Icons.account_balance_wallet_outlined,
        type: 0,
      );
      walletBloc.add(AddWallet(newWallet));

      // Chờ và kiểm tra trạng thái sau khi thêm wallet
      await expectLater(
        walletBloc.stream,
        emitsThrough(
          predicate<WalletState>((state) {
            return state.wallets.isNotEmpty &&
                state.wallets.any((w) => w.name == 'Test Wallet' && w.balance == 1000);
          }),
        ),
      );

      // Lấy wallet vừa tạo
      final addedWallet = walletBloc.state.wallets.first;

      // Chỉnh sửa wallet
      final updatedWallet = addedWallet.copyWith(
        name: 'Updated Wallet',
        balance: 2000,
      );
      walletBloc.add(EditWallet(updatedWallet));

      // Chờ và kiểm tra trạng thái sau khi chỉnh sửa
      await expectLater(
        walletBloc.stream,
        emitsThrough(
          predicate<WalletState>((state) {
            return state.wallets.isNotEmpty &&
                state.wallets.any((w) => w.name == 'Updated Wallet' && w.balance == 2000);
          }),
        ),
      );

      // Xóa wallet
      walletBloc.add(DeleteWallet(addedWallet.id, addedWallet.type));

      // Chờ và kiểm tra trạng thái sau khi xóa
      await expectLater(
        walletBloc.stream,
        emitsThrough(
          predicate<WalletState>((state) {
            return state.wallets.isEmpty;
          }),
        ),
      );

      // Đăng xuất
      await authService.signOut();
      expect(FirebaseAuth.instance.currentUser, isNull);
    });

    test('Cannot interact with wallets without authentication', () async {
      // Đảm bảo không có user đăng nhập
      await FirebaseAuth.instance.signOut();

      // Thử thêm wallet khi chưa đăng nhập
      final newWallet = Wallet(
        id: '',
        name: 'Unauthorized Wallet',
        balance: 500,
        icon

: Icons.account_balance_wallet_outlined,
        type: 0,
      );
      walletBloc.add(AddWallet(newWallet));

      // Chờ và kiểm tra lỗi
      await expectLater(
        walletBloc.stream,
        emitsThrough(
          predicate<WalletState>((state) {
            return state.error != null && state.wallets.isEmpty;
          }),
        ),
      );
    });

    test('Load wallets after sign in', () async {
      // Đăng ký và đăng nhập
      await authService.createUserWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );
      await authService.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );

      // Thêm wallet trực tiếp vào Firestore
      final userId = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('users/$userId/wallets')
          .add({
            'name': 'Preloaded Wallet',
            'balance': 3000,
            'icon_code_point': Icons.account_balance_wallet_outlined.codePoint,
            'icon_font_family': 'MaterialIcons',
            'type': 0,
          });

      // Load wallets
      walletBloc.add(LoadWallets());

      // Chờ và kiểm tra trạng thái
      await expectLater(
        walletBloc.stream,
        emitsThrough(
          predicate<WalletState>((state) {
            return state.wallets.isNotEmpty &&
                state.wallets.any((w) => w.name == 'Preloaded Wallet' && w.balance == 3000);
          }),
        ),
      );
    });
  });
}