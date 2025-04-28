class FlavorConfig {
  static bool isTest() {
    return const bool.fromEnvironment('IS_TEST_ENV', defaultValue: false);
  }
}