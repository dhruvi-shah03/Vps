import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';
import '../core/error/app_exceptions.dart';
import '../core/storage/secure_storage_service.dart';

class OdooClient {
  final String baseUrl;
  String dbName;
  String? sessionId;
  int? uid;
  String? username;
  String? userFullName;

  OdooClient({
    this.baseUrl = AppConfig.odooBaseUrl,
    this.dbName = AppConfig.odooDatabase,
  }) {
    restoreSession();
  }

  void restoreSession() {
    sessionId = SecureStorageService.sessionId;
    uid = SecureStorageService.uid;
    username = SecureStorageService.username;
    userFullName = SecureStorageService.userFullName;
    if (SecureStorageService.database != null && SecureStorageService.database!.isNotEmpty) {
      dbName = SecureStorageService.database!;
    }
  }

  bool get isAuthenticated => sessionId != null && uid != null;

  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (sessionId != null) {
      headers['Cookie'] = 'session_id=$sessionId';
      headers['X-Openerp-Session-Id'] = sessionId!;
    }
    return headers;
  }

  void _safeLog(String message) {
    if (AppConfig.enableNetworkLogs && kDebugMode) {
      debugPrint('[OdooClient] $message');
    }
  }

  /// Get list of databases available on Odoo server
  Future<List<String>> getDatabases() async {
    try {
      final uri = Uri.parse('$baseUrl/web/database/list');
      _safeLog('POST /web/database/list');
      final response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode({}))
          .timeout(AppConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] is List) {
          final list = List<String>.from(data['result']);
          if (list.isNotEmpty) return list;
        }
      }
    } catch (e) {
      _safeLog('getDatabases error: $e');
    }
    return [AppConfig.odooDatabase];
  }

  /// Authenticate user against live Odoo backend
  Future<Map<String, dynamic>> authenticate({
    required String login,
    required String password,
    String? database,
  }) async {
    final targetDb = database ?? dbName;
    final uri = Uri.parse('$baseUrl/web/session/authenticate');

    final payload = {
      'jsonrpc': '2.0',
      'params': {
        'db': targetDb,
        'login': login,
        'password': password,
      }
    };

    _safeLog('POST /web/session/authenticate (db: $targetDb, login: $login)');

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(AppConfig.requestTimeout);

      _safeLog('Auth response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['error'] != null) {
          final errData = data['error']['data'];
          final errMsg = errData?['message'] ?? data['error']['message'] ?? 'Authentication failed';
          _safeLog('Auth RPC error: $errMsg');
          throw OdooAuthException(errMsg, statusCode: 401, code: 'auth_failed');
        }

        final result = data['result'];
        if (result != null && result['uid'] != null && result['uid'] != false) {
          // Extract session cookie from Set-Cookie header if present
          final setCookie = response.headers['set-cookie'];
          if (setCookie != null && setCookie.contains('session_id=')) {
            final cookieParts = setCookie.split(';');
            for (var part in cookieParts) {
              if (part.trim().startsWith('session_id=')) {
                sessionId = part.trim().substring('session_id='.length);
                break;
              }
            }
          }

          if (sessionId == null && result['session_id'] != null) {
            sessionId = result['session_id'];
          }

          dbName = targetDb;
          uid = result['uid'] as int;
          username = login;
          userFullName = result['name'] ?? login;

          if (sessionId != null) {
            await SecureStorageService.saveSession(
              sessionId: sessionId!,
              uid: uid!,
              username: login,
              userFullName: userFullName,
              database: targetDb,
              password: password,
            );
          }

          _safeLog('Authentication successful for UID: $uid');
          return Map<String, dynamic>.from(result);
        } else {
          throw OdooAuthException('Invalid credentials. Please check your username and password.', statusCode: 401);
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw OdooAuthException('Access denied. Please check your credentials.', statusCode: response.statusCode);
      } else {
        throw OdooNetworkException('Server error (${response.statusCode}): ${response.reasonPhrase}', statusCode: response.statusCode);
      }
    } on SocketException catch (e) {
      _safeLog('SocketException during auth: $e');
      throw OdooNetworkException('Unable to reach Odoo server. Please check internet connection.', code: 'network_error');
    } on TimeoutException {
      _safeLog('TimeoutException during auth');
      throw OdooNetworkException('Server connection timed out.', code: 'timeout');
    } on OdooException {
      rethrow;
    } catch (e) {
      _safeLog('Unexpected auth exception: $e');
      throw OdooNetworkException('Connection failed: $e');
    }
  }

  /// Logout and clear session
  Future<void> logout() async {
    try {
      if (sessionId != null) {
        final uri = Uri.parse('$baseUrl/web/session/destroy');
        await http.post(uri, headers: _getHeaders()).timeout(const Duration(seconds: 5));
      }
    } catch (_) {}
    sessionId = null;
    uid = null;
    username = null;
    userFullName = null;
    await SecureStorageService.clearSession();
  }

  /// Execute Odoo model call_kw method (search_read, create, write, unlink, etc.)
  Future<dynamic> callKw({
    required String model,
    required String method,
    List args = const [],
    Map<String, dynamic> kwargs = const {},
  }) async {
    final uri = Uri.parse('$baseUrl/web/dataset/call_kw');

    final payload = {
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'model': model,
        'method': method,
        'args': args,
        'kwargs': kwargs,
      }
    };

    _safeLog('call_kw: model=$model method=$method');

    try {
      final response = await http
          .post(
            uri,
            headers: _getHeaders(),
            body: jsonEncode(payload),
          )
          .timeout(AppConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['error'] != null) {
          final errObj = data['error'];
          final errMsg = errObj['data']?['message'] ?? errObj['message'] ?? 'Odoo RPC Error';
          _safeLog('RPC error in $model.$method: $errMsg');

          if (errMsg.toString().contains('Session expired') || errMsg.toString().contains('Access Denied')) {
            throw OdooAuthException(errMsg.toString(), statusCode: 401, code: 'session_expired');
          }
          throw OdooRpcException(errMsg.toString(), details: errObj);
        }
        return data['result'];
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw OdooAuthException('Access denied or session expired.', statusCode: response.statusCode);
      } else {
        throw OdooNetworkException('HTTP Error ${response.statusCode}: ${response.reasonPhrase}', statusCode: response.statusCode);
      }
    } on SocketException catch (e) {
      _safeLog('SocketException on $model.$method: $e');
      throw OdooNetworkException('Unable to reach server.', code: 'network_error');
    } on TimeoutException {
      _safeLog('Timeout on $model.$method');
      throw OdooNetworkException('Request timed out.', code: 'timeout');
    } on OdooException {
      rethrow;
    } catch (e) {
      _safeLog('Unexpected exception on $model.$method: $e');
      throw OdooRpcException('Operation failed: $e');
    }
  }

  /// search_read helper
  Future<List<Map<String, dynamic>>> searchRead({
    required String model,
    List domain = const [],
    List<String> fields = const [],
    int limit = 0,
    int offset = 0,
    String order = '',
    Map<String, dynamic>? context,
  }) async {
    final Map<String, dynamic> kwargs = {
      'domain': domain,
      'fields': fields,
      if (limit > 0) 'limit': limit,
      if (offset > 0) 'offset': offset,
      if (order.isNotEmpty) 'order': order,
    };
    if (context != null) {
      kwargs['context'] = context;
    }
    final result = await callKw(
      model: model,
      method: 'search_read',
      kwargs: kwargs,
    );
    if (result is List) {
      return List<Map<String, dynamic>>.from(result.map((e) => Map<String, dynamic>.from(e)));
    }
    return [];
  }

  /// create helper
  Future<int> create({
    required String model,
    required Map<String, dynamic> values,
  }) async {
    final res = await callKw(
      model: model,
      method: 'create',
      args: [values],
    );
    return res is int ? res : (res is List ? res.first as int : 0);
  }

  /// write helper
  Future<bool> write({
    required String model,
    required int id,
    required Map<String, dynamic> values,
  }) async {
    final res = await callKw(
      model: model,
      method: 'write',
      args: [
        [id],
        values
      ],
    );
    return res == true;
  }

  /// unlink helper
  Future<bool> unlink({
    required String model,
    required int id,
  }) async {
    final res = await callKw(
      model: model,
      method: 'unlink',
      args: [
        [id]
      ],
    );
    return res == true;
  }

  /// Download PDF report bytes from Odoo
  Future<List<int>> downloadReportPdf({
    required String reportName,
    required dynamic recordId,
  }) async {
    final idParam = recordId is List ? recordId.join(',') : recordId.toString();
    final url = '$baseUrl/report/pdf/$reportName/$idParam';
    _safeLog('GET report PDF: $url');

    final uri = Uri.parse(url);
    final headers = {
      'Accept': 'application/pdf, */*',
    };
    if (sessionId != null) {
      headers['Cookie'] = 'session_id=$sessionId';
    }

    try {
      final response = await http.get(uri, headers: headers).timeout(AppConfig.requestTimeout);

      _safeLog('Report response status: ${response.statusCode}, type: ${response.headers['content-type']}');

      if (response.statusCode == 200) {
        if (response.bodyBytes.isNotEmpty) {
          return response.bodyBytes;
        } else {
          throw OdooRpcException('Report generation returned empty content.');
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw OdooAuthException('Access denied while downloading report.', statusCode: response.statusCode);
      } else {
        throw OdooNetworkException('Failed to download report (${response.statusCode})');
      }
    } on OdooException {
      rethrow;
    } catch (e) {
      throw OdooNetworkException('Network error downloading report: $e');
    }
  }

  /// Download file bytes from Odoo (e.g., attachment URL /web/content/...)
  Future<List<int>> downloadFile(String pathOrUrl) async {
    final fullUrl = pathOrUrl.startsWith('http')
        ? pathOrUrl
        : '$baseUrl${pathOrUrl.startsWith('/') ? '' : '/'}$pathOrUrl';
    _safeLog('GET file: $fullUrl');

    final uri = Uri.parse(fullUrl);
    final headers = {
      'Accept': '*/*',
    };
    if (sessionId != null) {
      headers['Cookie'] = 'session_id=$sessionId';
    }

    try {
      final response = await http.get(uri, headers: headers).timeout(AppConfig.requestTimeout);
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return response.bodyBytes;
      } else {
        throw OdooNetworkException('Failed to download file (${response.statusCode})');
      }
    } on OdooException {
      rethrow;
    } catch (e) {
      throw OdooNetworkException('Network error downloading file: $e');
    }
  }
}
