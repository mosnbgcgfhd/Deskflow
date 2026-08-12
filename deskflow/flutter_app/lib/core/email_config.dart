/// EmailJS credentials — from your EmailJS dashboard.
class EmailJsConfig {
  static const String serviceId = 'service_x0xzuwm';   // ← حط الـ Service ID
  static const String templateId = 'template_iipboam'; // ← حط الـ Template ID
  static const String publicKey = '9F0zZCsA2VUBcGjo-';      // ← حط الـ Public Key

  /// Fallback URL (used when running as a desktop .exe)
  static const String _fallbackUrl = 'https://deskflow.example.com';

  /// On Web this returns the real app URL automatically,
  /// so invite links always match wherever the app is hosted.
  static String get appUrl {
    final base = Uri.base;
    if (base.scheme == 'http' || base.scheme == 'https') return base.origin;
    return _fallbackUrl;
  }
}