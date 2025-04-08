import 'package:finance_app/core/app_routes.dart';
import 'package:finance_app/core/app_theme.dart';
import 'package:finance_app/screens/on_boarding/on_boarding_status.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  OnboardingScreenState createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _onboardingData = [
    {
      'title': 'Theo dõi ngân sách dễ dàng',
      'description':
      'Quản lý chi tiêu hàng ngày, tiết kiệm hiệu quả và đạt được mục tiêu tài chính.',
      'icon': Icons.account_balance_wallet,
    },
    {
      'title': 'Kiểm soát chi tiêu thông minh',
      'description':
      'Theo dõi chi tiêu hàng ngày, phân loại chi phí và tiết kiệm hiệu quả.',
      'icon': Icons.account_balance_wallet,
    },
    {
      'title': 'Lập kế hoạch tài chính dài hạn',
      'description':
      'Xây dựng kế hoạch tài chính, tiết kiệm và đầu tư để đạt được mục tiêu.',
      'icon': Icons.account_balance_wallet,
    },
    {
      'title': 'Quản lý tài chính an toàn',
      'description':
      'Bảo mật thông tin tài chính, quản lý tài khoản dễ dàng và an toàn.',
      'icon': Icons.account_balance_wallet,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _skip() {
    // Mark onboarding as seen and navigate to LoginScreen
    OnboardingStatus.setOnboardingSeen();
    AppRoutes.navigateToLogin(context);
  }

  void _next() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Mark onboarding as seen and navigate to LoginScreen
      OnboardingStatus.setOnboardingSeen();
      AppRoutes.navigateToLogin(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _onboardingData[index]['icon'],
                          size: 150,
                          color: AppTheme.lightTheme.colorScheme.primary,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _onboardingData[index]['title'],
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.lightTheme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _onboardingData[index]['description'],
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _onboardingData.length,
                                (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 8,
                              width: _currentPage == i ? 24 : 8,
                              decoration: BoxDecoration(
                                color: _currentPage == i
                                    ? AppTheme.lightTheme.colorScheme.primary
                                    : AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                    child: Text(
                      _currentPage == _onboardingData.length - 1 ? 'Bắt đầu' : 'Tiếp tục',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  _currentPage < _onboardingData.length - 1
                      ? TextButton(
                    onPressed: _skip,
                    child: Text(
                      'Bỏ qua',
                      style: TextStyle(fontSize: 16, color: AppTheme.lightTheme.colorScheme.primary),
                    ),
                  )
                      : const SizedBox(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}