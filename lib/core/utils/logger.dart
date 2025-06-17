class Logger {
  static const bool _isDebug = true; // Set to false for production

  static void d(String tag, String message) {
    if (_isDebug) {
      print('🔍 $tag: $message');
    }
  }

  static void i(String tag, String message) {
    if (_isDebug) {
      print('ℹ️ $tag: $message');
    }
  }

  static void w(String tag, String message) {
    if (_isDebug) {
      print('⚠️ $tag: $message');
    }
  }

  static void e(String tag, String message) {
    if (_isDebug) {
      print('❌ $tag: $message');
    }
  }

  static void s(String tag, String message) {
    if (_isDebug) {
      print('✅ $tag: $message');
    }
  }
}
