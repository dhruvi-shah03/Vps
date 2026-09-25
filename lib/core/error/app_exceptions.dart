class OdooException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final dynamic details;

  OdooException(this.message, {this.statusCode, this.code, this.details});

  @override
  String toString() => message;

  /// User friendly message for SnackBars and UI banners
  String get userFriendlyMessage {
    if (statusCode == 401 || code == 'session_expired') {
      return 'Session expired. Please log in again.';
    }
    if (statusCode == 403 || code == 'access_denied') {
      return 'You do not have permission to perform this action.';
    }
    if (statusCode == 500) {
      return 'Server error. Please try again later.';
    }
    if (code == 'timeout' || code == 'network_error') {
      return 'Unable to connect to VPS server. Please check your internet connection and try again.';
    }
    return message;
  }
}

class OdooAuthException extends OdooException {
  OdooAuthException(super.message, {super.statusCode, super.code});
}

class OdooNetworkException extends OdooException {
  OdooNetworkException(super.message, {super.statusCode, super.code});
}

class OdooRpcException extends OdooException {
  OdooRpcException(super.message, {super.statusCode, super.code, super.details});
}
