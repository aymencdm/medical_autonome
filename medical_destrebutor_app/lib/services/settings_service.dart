import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing app settings with persistent storage.
/// 
/// Handles:
/// - Server IP address persistence
/// - Server port configuration
/// - Stream mode preferences
class SettingsService extends ChangeNotifier {
  // Storage keys
  static const String _keyServerIp = 'server_ip';
  static const String _keyServerPort = 'server_port';
  static const String _keyDefaultMode = 'default_mode';

  // Default values
  static const String _defaultIp = '192.168.1.100';
  static const int _defaultPort = 8080;
  static const String _defaultStreamMode = 'normal';

  // Current values
  String _serverIp = _defaultIp;
  int _serverPort = _defaultPort;
  String _defaultMode = _defaultStreamMode;
  bool _isLoaded = false;

  // Getters
  String get serverIp => _serverIp;
  int get serverPort => _serverPort;
  String get defaultMode => _defaultMode;
  bool get isLoaded => _isLoaded;
  
  /// Full server URL for connection
  String get serverUrl => 'http://$_serverIp:$_serverPort';

  /// Initialize the service and load saved settings
  Future<void> initialize() async {
    if (_isLoaded) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _serverIp = prefs.getString(_keyServerIp) ?? _defaultIp;
      _serverPort = prefs.getInt(_keyServerPort) ?? _defaultPort;
      _defaultMode = prefs.getString(_keyDefaultMode) ?? _defaultStreamMode;
      
      _isLoaded = true;
      notifyListeners();
      
      if (kDebugMode) {
        print('[SettingsService] Loaded: IP=$_serverIp, Port=$_serverPort, Mode=$_defaultMode');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[SettingsService] Error loading settings: $e');
      }
    }
  }

  /// Save server IP address
  Future<void> setServerIp(String ip) async {
    if (ip.isEmpty) return;
    
    _serverIp = ip.trim();
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyServerIp, _serverIp);
    } catch (e) {
      if (kDebugMode) {
        print('[SettingsService] Error saving IP: $e');
      }
    }
  }

  /// Save server port
  Future<void> setServerPort(int port) async {
    if (port <= 0 || port > 65535) return;
    
    _serverPort = port;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyServerPort, _serverPort);
    } catch (e) {
      if (kDebugMode) {
        print('[SettingsService] Error saving port: $e');
      }
    }
  }

  /// Save default stream mode
  Future<void> setDefaultMode(String mode) async {
    if (mode != 'normal' && mode != 'face_tracking') return;
    
    _defaultMode = mode;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyDefaultMode, _defaultMode);
    } catch (e) {
      if (kDebugMode) {
        print('[SettingsService] Error saving mode: $e');
      }
    }
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    _serverIp = _defaultIp;
    _serverPort = _defaultPort;
    _defaultMode = _defaultStreamMode;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyServerIp);
      await prefs.remove(_keyServerPort);
      await prefs.remove(_keyDefaultMode);
    } catch (e) {
      if (kDebugMode) {
        print('[SettingsService] Error resetting settings: $e');
      }
    }
  }
}
