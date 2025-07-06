import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userProfileImageKey = 'user_profile_image';
  static const String _isPremiumKey = 'is_premium';
  
  // Default values
  static const String _defaultUserName = 'John Doe';
  static const String _defaultUserEmail = 'john.doe@example.com';
  static const bool _defaultIsPremium = false;

  static String? _cachedUserName;
  static String? _cachedUserEmail;
  static String? _cachedProfileImageBase64;
  static bool? _cachedIsPremium;

  // Initialize and load user data
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedUserName = prefs.getString(_userNameKey) ?? _defaultUserName;
    _cachedUserEmail = prefs.getString(_userEmailKey) ?? _defaultUserEmail;
    _cachedProfileImageBase64 = prefs.getString(_userProfileImageKey);
    _cachedIsPremium = prefs.getBool(_isPremiumKey) ?? _defaultIsPremium;
  }

  // Getters
  static String get userName => _cachedUserName ?? _defaultUserName;
  static String get userEmail => _cachedUserEmail ?? _defaultUserEmail;
  static bool get isPremiumUser => _cachedIsPremium ?? _defaultIsPremium;
  static String get membershipStatus => isPremiumUser ? 'Premium Member' : 'Free Member';
  
  static Uint8List? get profileImageBytes {
    if (_cachedProfileImageBase64 != null && _cachedProfileImageBase64!.isNotEmpty) {
      try {
        return base64Decode(_cachedProfileImageBase64!);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Admin functionality
  static const String _adminEmail = 'nikhil@fylez.com';
  static bool get isAdmin => userEmail == _adminEmail;

  // Setters
  static Future<void> updateUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
    _cachedUserName = name;
  }

  static Future<void> updateUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userEmailKey, email);
    _cachedUserEmail = email;
  }

  static Future<void> updateProfileImage(Uint8List? imageBytes) async {
    final prefs = await SharedPreferences.getInstance();
    if (imageBytes != null) {
      final base64String = base64Encode(imageBytes);
      await prefs.setString(_userProfileImageKey, base64String);
      _cachedProfileImageBase64 = base64String;
    } else {
      await prefs.remove(_userProfileImageKey);
      _cachedProfileImageBase64 = null;
    }
  }

  static Future<void> updatePremiumStatus(bool isPremium) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isPremiumKey, isPremium);
    _cachedIsPremium = isPremium;
  }

  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userProfileImageKey);
    await prefs.remove(_isPremiumKey);
    
    _cachedUserName = null;
    _cachedUserEmail = null;
    _cachedProfileImageBase64 = null;
    _cachedIsPremium = null;
  }
}
