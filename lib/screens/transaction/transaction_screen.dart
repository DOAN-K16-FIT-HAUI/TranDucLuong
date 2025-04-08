import 'package:finance_app/blocs/auth/auth_bloc.dart';
import 'package:finance_app/blocs/auth/auth_state.dart';
import 'package:finance_app/blocs/transaction/transaction_bloc.dart';
import 'package:finance_app/blocs/transaction/transaction_event.dart';
import 'package:finance_app/blocs/transaction/transaction_state.dart';
import 'package:finance_app/blocs/wallet/wallet_bloc.dart';
import 'package:finance_app/blocs/wallet/wallet_event.dart';
import 'package:finance_app/blocs/wallet/wallet_state.dart';
import 'package:finance_app/core/app_routes.dart';
import 'package:finance_app/core/app_theme.dart';
import 'package:finance_app/data/models/transaction.dart';
import 'package:finance_app/data/models/wallet.dart';
import 'package:finance_app/utils/common_widget.dart';
import 'package:finance_app/utils/constants.dart';
import 'package:finance_app/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  TransactionScreenState createState() => TransactionScreenState();
}

class TransactionScreenState extends State<TransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _balanceAfterController = TextEditingController();
  final TextEditingController _lenderController = TextEditingController();
  final TextEditingController _borrowerController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  DateTime? _repaymentDate;
  String _selectedCategory = 'Ẩn uống';
  String _selectedType = 'Chi tiêu'; // Mặc định
  String _selectedWallet = ''; // Tên ví được chọn cho giao dịch đơn lẻ
  String _selectedFromWallet = ''; // Tên ví nguồn cho chuyển khoản
  String _selectedToWallet = ''; // Tên ví đích cho chuyển khoản

  String? _dateError;
  String? _repaymentDateError;

  // Danh sách ví đầy đủ lấy từ WalletBloc state
  List<Wallet> _allWallets = [];

  // Map số dư ví để kiểm tra
  Map<String, double> _walletBalances = {};

  bool _isSaving = false; // Cờ để vô hiệu hóa nút lưu khi đang xử lý
  bool _isLoadingWallets = true; // Cờ cho lần tải ví đầu tiên

  // Danh sách danh mục và loại (nên lấy từ nguồn đáng tin cậy hơn, ví dụ Constants hoặc Remote Config)
  final List<String> _categories = Constants.availableCategories;
  final List<String> _types = Constants.transactionTypes;

  @override
  void initState() {
    super.initState();
    _selectedCategory = _categories.isNotEmpty ? _categories.first : '';
    _selectedType = _types.isNotEmpty ? _types.first : '';

    // Lấy userId và yêu cầu tải ví
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<WalletBloc>().add(LoadWallets());
    } else {
      setState(() {
        _isLoadingWallets = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vui lòng đăng nhập để thêm giao dịch.'),
            ),
          );
        }
      });
    }
  }

  Future<void> _selectDate(
    BuildContext context, {
    bool isRepaymentDate = false,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          isRepaymentDate ? (_repaymentDate ?? DateTime.now()) : _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.lightTheme.colorScheme.primary,
              onPrimary: AppTheme.lightTheme.colorScheme.surface,
              onSurface: AppTheme.lightTheme.colorScheme.onSurface,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isRepaymentDate) {
          _repaymentDate = picked;
          // Validate ngay khi chọn
          _repaymentDateError = Validators.validateRepaymentDate(
            _repaymentDate,
            _selectedDate,
          );
        } else {
          _selectedDate = picked;
          _dateError = Validators.validateDate(_selectedDate);
          // Validate lại ngày trả nợ nếu ngày giao dịch thay đổi
          if (_repaymentDate != null) {
            _repaymentDateError = Validators.validateRepaymentDate(
              _repaymentDate,
              _selectedDate,
            );
          }
        }
      });
    }
  }

  void _saveTransaction() {
    // Đảm bảo không lưu khi đang lưu hoặc đang tải ví
    if (_isSaving || _isLoadingWallets) return;

    setState(() {
      _dateError = Validators.validateDate(_selectedDate);
      if (_selectedType == 'Đi vay' || _selectedType == 'Cho vay') {
        _repaymentDateError = Validators.validateRepaymentDate(
          _repaymentDate,
          _selectedDate,
        );
      } else {
        _repaymentDateError = null; // Xóa lỗi nếu không phải loại vay/cho vay
      }
    });

    if (_formKey.currentState?.validate() ?? false) {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Người dùng chưa đăng nhập.')),
        );
        return;
      }
      final userId = authState.user.id;

      if (_selectedType == 'Chuyển khoản') {
        if (_selectedFromWallet.isEmpty || _selectedToWallet.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vui lòng chọn cả ví nguồn và ví đích.'),
            ),
          );
          return;
        }
        if (_allWallets.length > 1 &&
            _selectedFromWallet == _selectedToWallet) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ví nguồn và ví đích không được trùng nhau.'),
            ),
          );
          return;
        }
      } else if (_selectedType != 'Thu nhập') {
        // Các loại khác (trừ Thu nhập) cần chọn 1 ví
        if (_selectedWallet.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vui lòng chọn ví cho giao dịch $_selectedType.'),
            ),
          );
          return;
        }
      }

      final amount =
          double.tryParse(
            _amountController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
          ) ??
          0.0;
      final balanceAfter =
          _selectedType == 'Điều chỉnh số dư'
              ? (double.tryParse(
                    _balanceAfterController.text.replaceAll(
                      RegExp(r'[^0-9.]'),
                      '',
                    ),
                  ) ??
                  0.0)
              : null;

      // Kiểm tra số dư ví nguồn nếu cần
      String sourceWalletName = '';
      if (_selectedType == 'Chi tiêu' || _selectedType == 'Cho vay') {
        sourceWalletName = _selectedWallet;
      } else if (_selectedType == 'Chuyển khoản') {
        sourceWalletName = _selectedFromWallet;
      }

      if (sourceWalletName.isNotEmpty) {
        final sourceBalance = _walletBalances[sourceWalletName] ?? 0.0;
        if (amount > sourceBalance) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Số dư trong ví "$sourceWalletName" không đủ ($sourceBalance) để thực hiện giao dịch $amount.',
              ),
            ),
          );
          return;
        }
      }

      // Tạo đối tượng TransactionModel
      final transaction = TransactionModel(
        id: '',
        // ID sẽ được tạo bởi Repository/Firestore
        userId: userId,
        description: _descriptionController.text.trim(),
        amount: amount,
        date: _selectedDate,
        type: _selectedType,
        category: _selectedType == 'Chi tiêu' ? _selectedCategory : '',
        // Gán ví chính xác dựa trên loại giao dịch
        wallet: (_selectedType != 'Chuyển khoản') ? _selectedWallet : null,
        fromWallet:
            (_selectedType == 'Chuyển khoản') ? _selectedFromWallet : null,
        toWallet: (_selectedType == 'Chuyển khoản') ? _selectedToWallet : null,
        lender:
            (_selectedType == 'Đi vay') ? _lenderController.text.trim() : null,
        borrower:
            (_selectedType == 'Cho vay')
                ? _borrowerController.text.trim()
                : null,
        repaymentDate:
            (_selectedType == 'Đi vay' || _selectedType == 'Cho vay')
                ? _repaymentDate
                : null,
        balanceAfter: balanceAfter,
      );

      // Bắt đầu trạng thái đang lưu và dispatch event
      setState(() {
        _isSaving = true;
      });
      context.read<TransactionBloc>().add(AddTransaction(transaction));
    } else {
      // Form không hợp lệ hoặc có lỗi ngày tháng
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng kiểm tra lại thông tin đã nhập.'),
        ),
      );
    }
  }

  // Hàm reset form
  void _resetForm() {
    _formKey.currentState?.reset(); // Reset trạng thái validation
    if (mounted) {
      setState(() {
        _descriptionController.clear();
        _amountController.clear();
        _balanceAfterController.clear();
        _lenderController.clear();
        _borrowerController.clear();
        _selectedDate = DateTime.now();
        _repaymentDate = null;
        _selectedCategory = _categories.isNotEmpty ? _categories.first : '';
        _selectedType = _types.isNotEmpty ? _types.first : '';
        _dateError = null;
        _repaymentDateError = null;
        // Thiết lập lại ví mặc định dựa trên _allWallets hiện tại
        _setDefaultWallets();
      });
    }
  }

  // Hàm thiết lập ví mặc định (gọi khi ví tải xong hoặc reset form)
  void _setDefaultWallets() {
    if (!mounted) return;
    setState(() {
      if (_allWallets.isNotEmpty) {
        // Ưu tiên giữ lại lựa chọn cũ nếu còn hợp lệ
        if (!_allWallets.any((w) => w.name == _selectedWallet)) {
          _selectedWallet = _allWallets.first.name;
        }
        if (!_allWallets.any((w) => w.name == _selectedFromWallet)) {
          _selectedFromWallet = _allWallets.first.name;
        }

        // Chọn ví đích khác ví nguồn nếu có thể
        final availableToWallets =
            _allWallets.where((w) => w.name != _selectedFromWallet).toList();
        if (!_allWallets.any((w) => w.name == _selectedToWallet) ||
            (_allWallets.length > 1 &&
                _selectedToWallet == _selectedFromWallet)) {
          if (availableToWallets.isNotEmpty) {
            _selectedToWallet = availableToWallets.first.name;
          } else {
            // Chỉ có 1 ví
            _selectedToWallet = _allWallets.first.name;
          }
        }
      } else {
        // Không có ví nào
        _selectedWallet = '';
        _selectedFromWallet = '';
        _selectedToWallet = '';
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _balanceAfterController.dispose();
    _lenderController.dispose();
    _borrowerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Lắng nghe trạng thái TransactionBloc
        BlocListener<TransactionBloc, TransactionState>(
          listener: (context, state) {
            // Kết thúc trạng thái đang lưu khi có kết quả
            if (state is! TransactionLoading) {
              if (mounted) {
                setState(() {
                  _isSaving = false;
                });
              }
            }

            if (state is TransactionSuccess) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppTheme.incomeColor,
                  ),
                );
                // Giao dịch thành công -> Yêu cầu WalletBloc tải lại
                final authState = context.read<AuthBloc>().state;
                if (authState is AuthAuthenticated) {
                  context.read<WalletBloc>().add(LoadWallets());
                }
                _resetForm(); // Reset form sau khi thành công
                // Có thể đóng màn hình: Navigator.of(context).pop();
              }
            } else if (state is TransactionError) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Lỗi: ${state.message}"),
                    backgroundColor: AppTheme.lightTheme.colorScheme.error,
                  ),
                );
              }
            }
          },
        ),
        // Lắng nghe trạng thái WalletBloc
        BlocListener<WalletBloc, WalletState>(
          listener: (context, state) {
            // Cập nhật danh sách ví và số dư khi WalletBloc thay đổi
            if (mounted) {
              setState(() {
                _isLoadingWallets =
                    false; // Đánh dấu đã tải xong (dù thành công hay lỗi)
                // Gộp tất cả các loại ví và sắp xếp nếu cần
                _allWallets =
                    [
                          ...state.wallets,
                          ...state.savingsWallets,
                          ...state.investmentWallets,
                        ]
                        .where((w) => w.id.isNotEmpty)
                        .toList(); // Lọc ví rỗng nếu có
                _allWallets.sort(
                  (a, b) => a.orderIndex.compareTo(b.orderIndex),
                );

                _walletBalances = Map.fromEntries(
                  _allWallets.map(
                    (wallet) =>
                        MapEntry(wallet.name, wallet.balance.toDouble()),
                  ),
                );
                // Thiết lập lại các lựa chọn ví mặc định
                _setDefaultWallets();
                debugPrint(
                  "WalletBloc updated: ${_allWallets.length} wallets loaded.",
                );
              });
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        // Sử dụng BlocBuilder để rebuild UI dựa trên WalletState (ví dụ: khi đang tải ví)
        body: BlocBuilder<WalletBloc, WalletState>(
          builder: (context, walletState) {
            // Lấy danh sách tên ví từ state nội bộ đã được listener cập nhật
            final walletNames =
                _allWallets.map((wallet) => wallet.name).toList();

            // === Xử lý trạng thái UI ===
            Widget bodyContent;
            if (_isLoadingWallets) {
              bodyContent = CommonWidgets.buildLoadingIndicator(context);
            } else if (_allWallets.isEmpty &&
                context.read<AuthBloc>().state is AuthAuthenticated) {
              // Đã đăng nhập nhưng không có ví
              bodyContent = Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 60,
                        color: AppTheme.lightTheme.colorScheme.surface
                            .withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Bạn chưa có ví nào!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Vui lòng tạo ví trong phần Quản lý Ví trước khi thêm giao dịch.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 25),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_card),
                        label: const Text('Đến Quản lý Ví'),
                        onPressed: () {
                          // Chắc chắn rằng bạn đã định nghĩa route này
                          AppRoutes.navigateToWallet(context);
                        },
                      ),
                    ],
                  ),
                ),
              );
            } else if (context.read<AuthBloc>().state is! AuthAuthenticated) {
              // Chưa đăng nhập
              bodyContent = const Center(
                child: Text('Vui lòng đăng nhập để quản lý giao dịch.'),
              );
            } else {
              // Có ví và đã đăng nhập -> Hiển thị Form
              bodyContent = Column(
                children: [
                  // --- AppBar ---
                  CommonWidgets.buildAppBar(
                    context: context,
                    showDropdown: true,
                    dropdownItems: _types,
                    dropdownValue: _selectedType,
                    onDropdownChanged: (String? newValue) {
                      if (newValue != null && mounted) {
                        setState(() {
                          _selectedType = newValue;
                          // Reset các trường không liên quan & validate lại form
                          _formKey.currentState?.reset();
                          _balanceAfterController.clear();
                          _lenderController.clear();
                          _borrowerController.clear();
                          _repaymentDate = null;
                          _repaymentDateError = null;
                          _setDefaultWallets(); // Đặt lại ví khi đổi type
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _formKey.currentState?.validate();
                          });
                        });
                      }
                    },
                    backIcon: Icons.arrow_back,
                    onBackPressed: () {
                      AppRoutes.navigateToDashboard(context);
                    },
                    actions: [
                      // Nút Lưu - vô hiệu hóa khi đang lưu
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: IconButton(
                          icon:
                              _isSaving
                                  ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CommonWidgets.buildLoadingIndicator(context),
                                  )
                                  : Icon(
                                    Icons.check,
                                    color:
                                        AppTheme.lightTheme.colorScheme.surface,
                                  ),
                          onPressed: _isSaving ? null : _saveTransaction,
                          tooltip: 'Lưu giao dịch',
                        ),
                      ),
                    ],
                  ),
                  // --- Form nhập liệu ---
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- Các trường nhập liệu (đã có trong code trước đó) ---
                            CommonWidgets.buildTextField(
                              controller: _descriptionController,
                              label: 'Diễn giải',
                              hint: 'Nhập mô tả (vd: Ăn trưa, Tiền nhà)',
                              validator: Validators.validateDescription,
                            ),
                            const SizedBox(height: 16),

                            CommonWidgets.buildDatePickerField(
                              context: context,
                              date: _selectedDate,
                              label: 'Ngày giao dịch',
                              onTap: () => _selectDate(context),
                              errorText: _dateError,
                            ),
                            const SizedBox(height: 16),

                            // --- Các trường tùy thuộc loại giao dịch ---
                            if (_selectedType == 'Chi tiêu') ...[
                              CommonWidgets.buildDropdownField(
                                label: 'Danh mục chi tiêu',
                                value: _selectedCategory,
                                items: _categories,
                                onChanged: (String? newValue) {
                                  if (newValue != null && mounted) {
                                    setState(() {
                                      _selectedCategory = newValue;
                                    });
                                  }
                                },
                                validator: Validators.validateCategory,
                              ),
                              const SizedBox(height: 10),
                              // CommonWidgets.buildCategoryChips(...), // Tùy chọn thêm chips
                              CommonWidgets.buildDropdownField(
                                label: 'Từ ví',
                                value: _selectedWallet,
                                items: walletNames,
                                onChanged: (String? newValue) {
                                  if (newValue != null && mounted) {
                                    setState(() {
                                      _selectedWallet = newValue;
                                    });
                                  }
                                },
                                validator:
                                    (v) => Validators.validateWallet(
                                      v,
                                      fieldName: "Ví chi tiêu",
                                    ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            if (_selectedType == 'Thu nhập') ...[
                              CommonWidgets.buildDropdownField(
                                label: 'Vào ví',
                                value: _selectedWallet,
                                items: walletNames,
                                onChanged: (String? newValue) {
                                  if (newValue != null && mounted) {
                                    setState(() {
                                      _selectedWallet = newValue;
                                    });
                                  }
                                },
                                validator:
                                    (v) => Validators.validateWallet(
                                      v,
                                      fieldName: "Ví nhận tiền",
                                    ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            if (_selectedType == 'Chuyển khoản') ...[
                              CommonWidgets.buildDropdownField(
                                label: 'Từ ví (Nguồn)',
                                value: _selectedFromWallet,
                                items: walletNames,
                                onChanged: (String? newValue) {
                                  if (newValue != null && mounted) {
                                    setState(() {
                                      _selectedFromWallet = newValue;
                                      // Tự động chọn ví đích khác nếu trùng
                                      if (_allWallets.length > 1 &&
                                          _selectedToWallet == newValue) {
                                        final otherWallets =
                                            _allWallets
                                                .where(
                                                  (w) => w.name != newValue,
                                                )
                                                .toList();
                                        _selectedToWallet =
                                            otherWallets.isNotEmpty
                                                ? otherWallets.first.name
                                                : '';
                                      }
                                    });
                                  }
                                },
                                validator:
                                    (v) => Validators.validateWallet(
                                      v,
                                      fieldName: "Ví nguồn",
                                    ),
                              ),
                              const SizedBox(height: 16),
                              CommonWidgets.buildDropdownField(
                                label: 'Đến ví (Đích)',
                                value: _selectedToWallet,
                                // Lọc bỏ ví nguồn khỏi danh sách chọn
                                items:
                                    walletNames
                                        .where(
                                          (name) => name != _selectedFromWallet,
                                        )
                                        .toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null && mounted) {
                                    setState(() {
                                      _selectedToWallet = newValue;
                                    });
                                  }
                                },
                                validator:
                                    (v) => Validators.validateWallet(
                                      v,
                                      fieldName: "Ví đích",
                                      checkAgainst: _selectedFromWallet,
                                    ), // Thêm check trùng
                              ),
                              const SizedBox(height: 16),
                            ],

                            if (_selectedType == 'Đi vay') ...[
                              CommonWidgets.buildTextField(
                                controller: _lenderController,
                                label: 'Người cho vay',
                                hint: 'Tên người hoặc tổ chức cho vay',
                                validator: Validators.validateNotEmpty,
                              ),
                              const SizedBox(height: 16),
                              CommonWidgets.buildDropdownField(
                                label: 'Vào ví',
                                value: _selectedWallet,
                                items: walletNames,
                                onChanged: (String? newValue) {
                                  if (newValue != null && mounted) {
                                    setState(() {
                                      _selectedWallet = newValue;
                                    });
                                  }
                                },
                                validator:
                                    (v) => Validators.validateWallet(
                                      v,
                                      fieldName: "Ví nhận tiền vay",
                                    ),
                              ),
                              const SizedBox(height: 16),
                              CommonWidgets.buildDatePickerField(
                                context: context,
                                date: _repaymentDate ?? DateTime.now(),
                                label: 'Ngày hẹn trả (tùy chọn)',
                                onTap:
                                    () => _selectDate(
                                      context,
                                      isRepaymentDate: true,
                                    ),
                                errorText: _repaymentDateError,
                              ),
                              const SizedBox(height: 16),
                            ],

                            if (_selectedType == 'Cho vay') ...[
                              CommonWidgets.buildTextField(
                                controller: _borrowerController,
                                label: 'Người vay tiền',
                                hint: 'Tên người hoặc tổ chức vay',
                                validator: Validators.validateNotEmpty,
                              ),
                              const SizedBox(height: 16),
                              CommonWidgets.buildDropdownField(
                                label: 'Từ ví',
                                value: _selectedWallet,
                                items: walletNames,
                                onChanged: (String? newValue) {
                                  if (newValue != null && mounted) {
                                    setState(() {
                                      _selectedWallet = newValue;
                                    });
                                  }
                                },
                                validator:
                                    (v) => Validators.validateWallet(
                                      v,
                                      fieldName: "Ví cho vay",
                                    ),
                              ),
                              const SizedBox(height: 16),
                              CommonWidgets.buildDatePickerField(
                                context: context,
                                date: _repaymentDate ?? DateTime.now(),
                                label: 'Ngày hẹn trả (tùy chọn)',
                                onTap:
                                    () => _selectDate(
                                      context,
                                      isRepaymentDate: true,
                                    ),
                                errorText: _repaymentDateError,
                              ),
                              const SizedBox(height: 16),
                            ],

                            if (_selectedType == 'Điều chỉnh số dư') ...[
                              CommonWidgets.buildDropdownField(
                                label: 'Ví cần điều chỉnh',
                                value: _selectedWallet,
                                items: walletNames,
                                onChanged: (String? newValue) {
                                  if (newValue != null && mounted) {
                                    setState(() {
                                      _selectedWallet = newValue;
                                    });
                                  }
                                },
                                validator:
                                    (v) => Validators.validateWallet(
                                      v,
                                      fieldName: "Ví điều chỉnh",
                                    ),
                              ),
                              const SizedBox(height: 16),
                              CommonWidgets.buildLabel(
                                context,
                                text: 'Số dư thực tế sau điều chỉnh',
                              ),
                              const SizedBox(height: 8),
                              CommonWidgets.buildBalanceInputField(
                                // Dùng lại widget nhập số tiền
                                _balanceAfterController,
                                validator:
                                    Validators
                                        .validateBalanceAfterAdjustment, // Validator riêng
                              ),
                              const SizedBox(height: 16),
                            ],

                            // --- Số tiền (chung cho các loại trừ Điều chỉnh) ---
                            if (_selectedType != 'Điều chỉnh số dư') ...[
                              CommonWidgets.buildBalanceInputField(
                                _amountController,
                                validator: (value) {
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            // Trả về Scaffold với nội dung phù hợp
            return bodyContent;
          },
        ),
      ),
    );
  }
}
