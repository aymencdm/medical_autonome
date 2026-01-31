import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../services/raspberry_pi_service.dart';

class VideoProvider with ChangeNotifier {
  final RaspberryPiService _rpiService;
  Uint8List? _currentFrame;
  bool _isStreaming = false;

  VideoProvider(this._rpiService) {
    _rpiService.onVideoFrame = (frame) {
      _currentFrame = frame;
      _isStreaming = true;
      notifyListeners();
    };
  }

  Uint8List? get currentFrame => _currentFrame;
  bool get isStreaming => _isStreaming;

  void startStream() {
    _rpiService.startStream();
    _isStreaming = true;
    notifyListeners();
  }

  void stopStream() {
    _rpiService.stopStream();
    _isStreaming = false;
    _currentFrame = null;
    notifyListeners();
  }
}
