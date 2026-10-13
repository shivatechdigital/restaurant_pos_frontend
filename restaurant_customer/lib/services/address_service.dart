import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SavedAddress {
  final String id;
  final String address;
  final String landmark;
  final String pincode;
  final String tag; // 'Home', 'Office', 'Other'

  SavedAddress({
    required this.id,
    required this.address,
    required this.landmark,
    required this.pincode,
    this.tag = 'Home',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'address': address,
    'landmark': landmark,
    'pincode': pincode,
    'tag': tag,
  };

  factory SavedAddress.fromJson(Map<String, dynamic> json) => SavedAddress(
    id: json['id']?.toString() ?? '',
    address: json['address']?.toString() ?? '',
    landmark: json['landmark']?.toString() ?? '',
    pincode: json['pincode']?.toString() ?? '',
    tag: json['tag']?.toString() ?? 'Home',
  );
}

class AddressService {
  static const _kAddressPrefix = 'saved_addresses_';
  static const _kDefaultAddressPrefix = 'default_address_';

  static Future<List<SavedAddress>> getAddresses(String phone) async {
    if (phone.isEmpty) return [];
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_kAddressPrefix$phone');
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((i) => SavedAddress.fromJson(Map<String, dynamic>.from(i))).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAddress(String phone, SavedAddress address) async {
    if (phone.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final addresses = await getAddresses(phone);

    // If already exists, update
    final index = addresses.indexWhere((a) => a.id == address.id || (a.address == address.address && a.pincode == address.pincode));
    if (index >= 0) {
      addresses[index] = address;
    } else {
      addresses.insert(0, address);
    }

    await prefs.setString(
      '$_kAddressPrefix$phone',
      jsonEncode(addresses.map((a) => a.toJson()).toList()),
    );
    await setDefaultAddressId(phone, address.id);
  }

  static Future<String?> getDefaultAddressId(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_kDefaultAddressPrefix$phone');
  }

  static Future<void> setDefaultAddressId(String phone, String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_kDefaultAddressPrefix$phone', id);
  }
}
