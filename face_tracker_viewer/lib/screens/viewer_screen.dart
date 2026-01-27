import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dart_vlc/dart_vlc.dart';
import '../services/stream_service.dart';

class ViewerScreen extends StatefulWidget {
  const ViewerScreen({super.key});

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  final TextEditingController _ipController = TextEditingController();
  bool _isLoading = false;
  Player? _player;
  bool _isPlayerInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    try {
      DartVLC.initialize();
      _player = Player(id: 69420);
      _isPlayerInitialized = true;
    } catch (e) {
      debugPrint('Error initializing VLC: $e');
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    _player?.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final streamService = context.read<StreamService>();
    
    setState(() => _isLoading = true);
    
    streamService.setServerIp(_ipController.text.trim());
    final success = await streamService.checkConnection();
    
    setState(() => _isLoading = false);
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Connected to Raspberry Pi'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(streamService.errorMessage ?? 'Connection failed'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _startStream() async {
    final streamService = context.read<StreamService>();
    
    setState(() => _isLoading = true);
    final success = await streamService.startStream();
    setState(() => _isLoading = false);
    
    if (!mounted) return;
    
    if (success && _isPlayerInitialized && _player != null) {
      // Start playing RTP stream
      final sdpUrl = streamService.sdpUrl;
      _player!.open(
        Media.network(sdpUrl),
        autoStart: true,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Stream started'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(streamService.errorMessage ?? 'Failed to start stream'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _stopStream() async {
    final streamService = context.read<StreamService>();
    
    if (_player != null) {
      _player!.stop();
    }
    
    setState(() => _isLoading = true);
    await streamService.stopStream();
    setState(() => _isLoading = false);
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Stream stopped'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0A0E21),
              const Color(0xFF1D1E33).withOpacity(0.8),
            ],
          ),
        ),
        child: Consumer<StreamService>(
          builder: (context, streamService, _) {
            return Row(
              children: [
                // Left sidebar - Controls
                Container(
                  width: 400,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D1E33).withOpacity(0.5),
                    border: Border(
                      right: BorderSide(
                        color: const Color(0xFF2196F3).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 30),
                        _buildConnectionCard(streamService),
                        const SizedBox(height: 20),
                        if (streamService.isConnected) ...[
                          _buildStreamControls(streamService),
                          const SizedBox(height: 20),
                          _buildStreamInfo(streamService),
                        ],
                      ],
                    ),
                  ),
                ),
                
                // Right side - Video player
                Expanded(
                  child: _buildVideoPlayer(streamService),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2196F3).withOpacity(0.3),
            const Color(0xFF1976D2).withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2196F3).withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2196F3).withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.videocam,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Face Tracker',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'RTP Stream Viewer',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionCard(StreamService streamService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: streamService.isConnected
                        ? Colors.green.withOpacity(0.2)
                        : const Color(0xFF2196F3).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    streamService.isConnected ? Icons.check_circle : Icons.settings_input_antenna,
                    color: streamService.isConnected ? Colors.green : const Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        streamService.isConnected ? 'Connected' : 'Connect to Server',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        streamService.isConnected
                            ? 'Ready to stream'
                            : 'Enter Raspberry Pi IP',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _ipController,
              enabled: !streamService.isConnected,
              decoration: InputDecoration(
                labelText: 'Server IP Address',
                hintText: 'e.g., 192.168.1.100',
                prefixIcon: const Icon(Icons.computer, color: Color(0xFF2196F3)),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading || streamService.isConnected ? null : _connect,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(streamService.isConnected ? Icons.check : Icons.link),
              label: Text(
                _isLoading
                    ? 'Connecting...'
                    : streamService.isConnected
                        ? 'Connected'
                        : 'Connect',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: streamService.isConnected ? Colors.green : const Color(0xFF2196F3),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamControls(StreamService streamService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Stream Controls',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading || streamService.isStreaming ? null : _startStream,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Stream'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading || !streamService.isStreaming ? null : _stopStream,
              icon: const Icon(Icons.stop),
              label: const Text('Stop Stream'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamInfo(StreamService streamService) {
    if (streamService.streamInfo == null) return const SizedBox.shrink();

    final info = streamService.streamInfo!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stream Information',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const Divider(height: 24, color: Colors.white24),
            _buildInfoRow('Protocol', info['protocol']?.toString().toUpperCase() ?? 'N/A'),
            _buildInfoRow('Codec', info['codec']?.toString().toUpperCase() ?? 'N/A'),
            _buildInfoRow('Resolution', '${info['width']}x${info['height']}'),
            _buildInfoRow('FPS', '${info['fps']}'),
            _buildInfoRow('RTP Port', '${info['rtp_port']}'),
            _buildInfoRow('Status', info['streaming'] == true ? 'Streaming' : 'Stopped',
                statusColor: info['streaming'] == true ? Colors.green : Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor?.withOpacity(0.2) ?? Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: statusColor ?? Colors.white24,
                width: 1,
              ),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: statusColor ?? Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer(StreamService streamService) {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: streamService.isStreaming
              ? const Color(0xFF2196F3)
              : Colors.white24,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: streamService.isStreaming
                ? const Color(0xFF2196F3).withOpacity(0.3)
                : Colors.black.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Video player
            if (_isPlayerInitialized && _player != null)
              Video(
                player: _player!,
                showControls: false,
              )
            else
              _buildPlaceholder(streamService),
            
            // Live indicator
            if (streamService.isStreaming)
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.5),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(StreamService streamService) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              streamService.isStreaming
                  ? Icons.hourglass_empty
                  : Icons.videocam_off,
              size: 80,
              color: Colors.white38,
            ),
            const SizedBox(height: 24),
            Text(
              streamService.isStreaming
                  ? 'Loading stream...'
                  : streamService.isConnected
                      ? 'Press Start Stream to begin'
                      : 'Connect to Raspberry Pi to start',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 20,
              ),
            ),
            if (streamService.isStreaming) ...[
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                color: Color(0xFF2196F3),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
