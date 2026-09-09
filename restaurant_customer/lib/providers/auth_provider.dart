import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  String phone = '';
  bool isLoading = false;
  String error = '';
  bool isLoggedIn = false;

  Future<bool> sendOtp(String phoneNumber) async {
    isLoading = true;
    error = '';
    phone = phoneNumber;
    notifyListeners();

    try {
      final result = await _api.sendOtp(phone);
      isLoading = false;
      if (result['success'] == true) {
        notifyListeners();
        return true;
      }
      error = result['message'] ?? 'OTP bhejne mein error';
      notifyListeners();
      return false;
    } catch (e) {
      isLoading = false;
      error = 'Network error. Server check karo.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String otp) async {
    isLoading = true;
    error = '';
    notifyListeners();

    try {
      final result = await _api.verifyOtp(phone, otp);
      isLoading = false;
      if (result['success'] == true) {
        isLoggedIn = true;
        notifyListeners();
        return true;
      }
      error = result['message'] ?? 'Galat OTP';
      notifyListeners();
      return false;
    } catch (e) {
      isLoading = false;
      error = 'Network error';
      notifyListeners();
      return false;
    }
  }

  // Stored token/phone hatao aur state reset karo
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('phone');
    phone = '';
    isLoggedIn = false;
    error = '';
    notifyListeners();
  }
}
