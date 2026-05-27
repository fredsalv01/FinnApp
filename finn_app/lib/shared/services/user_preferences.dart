import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static const _keyOnboardingDone = 'onboarding_done';
  static const _keyUserName = 'user_name';
  static const _keyUserIncome = 'user_income';

  Future<bool> isOnboardingDone() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_keyOnboardingDone) ?? false;
  }

  Future<void> setOnboardingDone(bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_keyOnboardingDone, value);
  }

  Future<String?> getUserName() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_keyUserName);
  }

  Future<void> setUserName(String name) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_keyUserName, name);
  }

  Future<double?> getUserIncome() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getDouble(_keyUserIncome);
  }

  Future<void> setUserIncome(double income) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setDouble(_keyUserIncome, income);
  }

  Future<void> clearAll() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_keyOnboardingDone);
    await sp.remove(_keyUserName);
    await sp.remove(_keyUserIncome);
  }
}
