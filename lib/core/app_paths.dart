class AppPaths {
  static const String loginPath = '/login';
  static const String registerPath = '/register';
  static const String forgotPasswordPath = '/forgot-password';
  static const String dashboardPath = '/top';
  static const String walletListPath = '/top/wallets';
  static const String appNotificationListPath = '/top/notifications';
  static const String addTransactionPath = '/top/transactions/add';
  static const String transactionListPath = '/top/transactions';
  static const String accountPath = '/top/account';
  static const String reportsPath = '/top/reports';
  static const String groupNoteListPath = '/top/group-notes';
  static const String addEditGroupNotePath = '/top/group-notes/edit';
  static const String barcodeScannerPath = '/top/barcode-scanner';
  static String groupNoteDetailPath(String noteId) => '/top/group-notes/detail/$noteId';
  static const String savingsReminderPath = '/top/savings-reminder';  // Fixed the path definition
}