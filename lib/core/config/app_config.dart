class AppConfig {
  static const String odooBaseUrl = 'https://vps.arihantai.com';
  static const String odooDatabase = 'vps.arihantai.com';
  static const Duration requestTimeout = Duration(seconds: 25);
  static const bool isProduction = true;

  // Development / debug logger flag
  static const bool enableNetworkLogs = true;
}
