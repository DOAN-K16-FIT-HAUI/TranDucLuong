import 'package:shared_preferences/shared_preferences.dart';

class OnboardingStatus {
  static const String _onboardingKey = 'has_seen_onboarding';

  // Check if the user has seen the onboarding screen
  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  // Mark the onboarding screen as seen
  static Future<void> setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }
}