import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _kIpAddressKey = 'rpi_ip_address';
  static const String _kDefaultIp = 'http://192.168.1.6:8080';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  static Future<SettingsService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsService(prefs);
  }

  String get ipAddress => _prefs.getString(_kIpAddressKey) ?? _kDefaultIp;

  Future<void> setIpAddress(String ip) async {
    // Ensure the URL has a scheme
    String formattedIp = ip;
    if (!formattedIp.startsWith('http')) {
      formattedIp = 'http://$formattedIp';
    }
    // Remove trailing slash if present
    if (formattedIp.endsWith('/')) {
      formattedIp = formattedIp.substring(0, formattedIp.length - 1);
    }
    
    // Auto-append port 8080 if no port is specified
    // Check if the part after 'http://' or 'https://' contains a colon
    String contentToCheck = formattedIp.replaceFirst(RegExp(r'https?://'), '');
    if (!contentToCheck.contains(':')) {
      formattedIp = '$formattedIp:8080';
    }

    await _prefs.setString(_kIpAddressKey, formattedIp);
  }
}
