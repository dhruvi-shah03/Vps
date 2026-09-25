import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  static SharedPreferences? _prefs;

  static String? _cachedSessionId;
  static int? _cachedUid;
  static String? _cachedUsername;
  static String? _cachedUserFullName;
  static String? _cachedDatabase;
  static String? _cachedPassword;

  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _cachedSessionId = _prefs?.getString('vps_session_id');
      _cachedUid = _prefs?.getInt('vps_uid');
      _cachedUsername = _prefs?.getString('vps_username');
      _cachedUserFullName = _prefs?.getString('vps_user_full_name');
      _cachedDatabase = _prefs?.getString('vps_database');
      _cachedPassword = _prefs?.getString('vps_password');
    } catch (_) {}
  }

  static Future<void> saveSession({
    required String sessionId,
    required int uid,
    required String username,
    String? userFullName,
    String? database,
    String? password,
  }) async {
    _cachedSessionId = sessionId;
    _cachedUid = uid;
    _cachedUsername = username;
    _cachedUserFullName = userFullName;
    _cachedDatabase = database;
    if (password != null) _cachedPassword = password;

    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs?.setString('vps_session_id', sessionId);
      await _prefs?.setInt('vps_uid', uid);
      await _prefs?.setString('vps_username', username);
      if (userFullName != null) {
        await _prefs?.setString('vps_user_full_name', userFullName);
      }
      if (database != null) {
        await _prefs?.setString('vps_database', database);
      }
      if (password != null) {
        await _prefs?.setString('vps_password', password);
      }
    } catch (_) {}
  }

  static Future<void> clearSession() async {
    _cachedSessionId = null;
    _cachedUid = null;
    _cachedUsername = null;
    _cachedUserFullName = null;
    _cachedDatabase = null;
    _cachedPassword = null;

    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs?.remove('vps_session_id');
      await _prefs?.remove('vps_uid');
      await _prefs?.remove('vps_username');
      await _prefs?.remove('vps_user_full_name');
      await _prefs?.remove('vps_database');
      await _prefs?.remove('vps_password');
    } catch (_) {}
  }

  static String? get sessionId => _cachedSessionId;
  static int? get uid => _cachedUid;
  static String? get username => _cachedUsername;
  static String? get userFullName => _cachedUserFullName;
  static String? get database => _cachedDatabase;
  static String? get password => _cachedPassword;

  static bool get hasActiveSession =>
      _cachedSessionId != null && _cachedSessionId!.isNotEmpty && _cachedUid != null;
}
