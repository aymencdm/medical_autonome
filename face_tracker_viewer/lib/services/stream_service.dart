import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class StreamService extends ChangeNotifier {
  String _serverIp = '';
  bool _isConnected = false;
  bool _isStreaming = false;
  Map<String, dynamic>? _streamInfo;
  String? _errorMessage;

  String get serverIp => _serverIp;
  bool get isConnected => _isConnected;
  bool get isStreaming => _isStreaming;
  Map<String, dynamic>? get streamInfo => _streamInfo;
  String? get errorMessage => _errorMessage;

  // Get RTP stream URL for desktop VLC
  String get rtpUrl {
    if (_streamInfo != null && _serverIp.isNotEmpty) {
      final port = _streamInfo!['rtp_port'] ?? 5000;
      return 'rtp://@:$port';  // Listen on all interfaces
    }
    return '';
  }

  // Get SDP URL for stream configuration
  String get sdpUrl {
    if (_serverIp.isNotEmpty) {
      return 'http://$_serverIp:8080/stream.sdp';
    }
    return '';
  }

  void setServerIp(String ip) {
    _serverIp = ip;
    notifyListeners();
  }

  Future<bool> checkConnection() async {
    if (_serverIp.isEmpty) {
      _errorMessage = 'Please enter server IP address';
      _isConnected = false;
      notifyListeners();
      return false;
    }

    try {
      final response = await http
          .get(Uri.parse('http://$_serverIp:8080/health'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        _isConnected = true;
        _errorMessage = null;
        await fetchStreamInfo();
        notifyListeners();
        return true;
      } else {
        _isConnected = false;
        _errorMessage = 'Server returned status ${response.statusCode}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isConnected = false;
      _errorMessage = 'Connection failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchStreamInfo() async {
    if (_serverIp.isEmpty) return;

    try {
      final response = await http
          .get(Uri.parse('http://$_serverIp:8080/api/stream/info'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        _streamInfo = json.decode(response.body);
        _isStreaming = _streamInfo!['streaming'] ?? false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to fetch stream info: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<bool> startStream() async {
    if (_serverIp.isEmpty || !_isConnected) {
      _errorMessage = 'Not connected to server';
      notifyListeners();
      return false;
    }

    try {
      final response = await http
          .post(Uri.parse('http://$_serverIp:8080/api/stream/start'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _isStreaming = data['streaming'] ?? false;
        _errorMessage = null;
        await fetchStreamInfo();
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to start stream: ${response.statusCode}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error starting stream: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> stopStream() async {
    if (_serverIp.isEmpty || !_isConnected) {
      return false;
    }

    try {
      final response = await http
          .post(Uri.parse('http://$_serverIp:8080/api/stream/stop'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        _isStreaming = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Error stopping stream: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
