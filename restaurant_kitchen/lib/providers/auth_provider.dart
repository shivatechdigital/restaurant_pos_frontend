import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/socket_service.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  String phone = '';
  bool isLoading = false;
  String error = '';
  bool isLoggedIn = false;
  int restaurantId = 1;
  String? testOtp;

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('kitchen_token');
    await prefs.remove('kitchen_phone');
    await prefs.remove('kitchen_role');
    await prefs.remove('kitchen_restaurant_id');
    SocketService().disconnect();
    isLoggedIn = false;
    phone = '';
    restaurantId = 1;
    notifyListeners();
  }

  Future<bool> sendOtp(String phoneNumber) async {
    isLoading = true;
    error = '';
    phone = phoneNumber;
    notifyListeners();

    try {
      final result = await _api.sendOtp(phone);
      isLoading = false;
      if (result['success'] == true) {
        testOtp = result['data']?['otp']?.toString();
        notifyListeners();
        return true;
      }
      error = result['message'] ?? 'OTP error';
      notifyListeners();
      return false;
    } catch (e) {
      isLoading = false;
      error = 'Network error';
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
        final role = result['data']['user']['role'];
        if (role != 'kitchen' && role != 'admin') {
          error = 'Yeh app sirf Kitchen Staff ke liye hai!';
          notifyListeners();
          return false;
        }
        isLoggedIn = true;
        restaurantId = result['data']['user']['restaurant_id'] ?? 1;
        notifyListeners();
        return true;
      }
      error = result['message'] ?? 'Invalid OTP';
      notifyListeners();
      return false;
    } catch (e) {
      isLoading = false;
      error = 'Network error';
      notifyListeners();
      return false;
    }
  }
}
