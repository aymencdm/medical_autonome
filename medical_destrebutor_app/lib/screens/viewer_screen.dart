import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/stream_service.dart';
import '../services/settings_service.dart';
import 'settings_screen.dart';
import 'persons_screen.dart';

/// Main viewer screen with mode switching between Normal and Manual Control.
class ViewerScreen extends StatefulWidget {
  const ViewerScreen({super.key});

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  final TextEditingController _ipController = TextEditingController();
  Timer? _moveTimer;
  
  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    final settings = context.read<SettingsService>();
    await settings.initialize();
    
    setState(() {
      _ipController.text = settings.serverIp;
    });
  }

  @override
  void dispose() {
    _ipController.dispose();
    _stopMoving();
    super.dispose();
  }

  void _connect() {
    final streamService = context.read<StreamService>();
    final settings = context.read<SettingsService>();
    
    // Save the IP for next time
    settings.setServerIp(_ipController.text.trim());
    
    streamService.setServer(
      _ipController.text.trim(),
      port: settings.serverPort,
    );
    streamService.connect();
  }

  void _disconnect() {
    context.read<StreamService>().disconnect();
  }

  // --- Manual Movement Logic ---
  void _startMoving(String direction) {
    if (_moveTimer?.isActive ?? false) return;

    _moveTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final streamService = context.read<StreamService>();
      if (streamService.currentMode != StreamMode.manual) return;

      const double step = 2.0;

      switch (direction) {
        case 'up':
          streamService.adjustTilt(step); // Up increases tilt (towards 180/Up)
          break;
        case 'down':
          streamService.adjustTilt(-step); // Down decreases tilt (towards 90/Down)
          break;
        case 'left':
          streamService.adjustPan(step); // Assume Left increases Pan
          break;
        case 'right':
          streamService.adjustPan(-step); // Assume Right decreases Pan
          break;
      }
    });
  }

  void _stopMoving() {
    _moveTimer?.cancel();
    _moveTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final streamService = context.watch<StreamService>();
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A), // Darker, premium background
      appBar: AppBar(
        title: const Text('Medical Distributor'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PersonsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection Card
            _buildConnectionCard(streamService),
            const SizedBox(height: 20),
            
            // Mode Toggle
            if (streamService.isConnected)
              _buildModeToggle(streamService),
            
            const SizedBox(height: 20),
            
            // Video Stream Area
            _buildVideoDisplay(streamService),

            // D-Pad Controls (Only in Manual Mode)
            if (streamService.currentMode == StreamMode.manual) ...[
               const SizedBox(height: 30),
               _buildControlPad(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionCard(StreamService streamService) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _ipController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Robot IP Address',
              labelStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.router, color: Colors.blueAccent),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blueAccent),
              ),
              filled: true,
              fillColor: const Color(0xFF2A2D45),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: streamService.isConnected ? _disconnect : _connect,
            icon: Icon(streamService.isConnected ? Icons.link_off : Icons.link),
            label: Text(streamService.isConnected ? 'Disconnect' : 'Connect'),
            style: ElevatedButton.styleFrom(
              backgroundColor: streamService.isConnected ? Colors.red : Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 15),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)
              )
            ),
          ),
          if (streamService.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                streamService.errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModeToggle(StreamService streamService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('Select Stream Mode', Icons.switch_camera),
        const SizedBox(height: 12),
        
        // Normal Stream Button
        _buildModeCard(
          title: 'Normal Stream',
          subtitle: 'Video only • Servos OFF',
          icon: Icons.videocam,
          isSelected: streamService.currentMode == StreamMode.normal,
          color: Colors.blue,
          onTap: () => streamService.setStreamMode(StreamMode.normal),
        ),
        
        const SizedBox(height: 10),
        
        // Manual Control Button
        _buildModeCard(
          title: 'Manual Control',
          subtitle: 'Control with On-Screen Buttons',
          icon: Icons.gamepad, 
          isSelected: streamService.currentMode == StreamMode.manual,
          color: Colors.greenAccent,
          onTap: () => streamService.setStreamMode(StreamMode.manual),
        ),

        const SizedBox(height: 10),

        // Recognition Button
        _buildModeCard(
          title: 'Recognition Mode',
          subtitle: 'Identify Faces Only (Servos OFF)',
          icon: Icons.face, 
          isSelected: streamService.currentMode == StreamMode.recognition,
          color: Colors.purpleAccent,
          onTap: () => streamService.setStreamMode(StreamMode.recognition),
        ),
      ],
    );
  }

  Widget _buildModeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(50) : const Color(0xFF2A2D45),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? color : const Color(0xFF1D1E33),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white54,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             _buildDirectionButton('up', Icons.arrow_upward),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDirectionButton('left', Icons.arrow_back),
            const SizedBox(width: 60), // Spacing for "center"
            _buildDirectionButton('right', Icons.arrow_forward),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             _buildDirectionButton('down', Icons.arrow_downward),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          "Hold buttons to move camera",
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDirectionButton(String direction, IconData icon) {
    return GestureDetector(
      onTapDown: (_) => _startMoving(direction),
      onTapUp: (_) => _stopMoving(),
      onTapCancel: () => _stopMoving(),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2D45),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 5,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(icon, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildVideoDisplay(StreamService streamService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('Live Feed', Icons.live_tv),
        const SizedBox(height: 12),
        
        // Video container
        Center(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 800,
              maxHeight: 600,
            ),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: streamService.currentMode == StreamMode.manual
                    ? Colors.greenAccent.withAlpha(130)
                    : Colors.blue.withAlpha(130),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (streamService.currentMode == StreamMode.manual
                          ? Colors.greenAccent
                          : Colors.blue)
                      .withAlpha(50),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Video frame
                    streamService.currentFrame != null
                        ? Image.memory(
                            streamService.currentFrame!,
                            gaplessPlayback: true,
                            fit: BoxFit.contain,
                          )
                        : _buildWaitingState(streamService),
                    
                    // Mode indicator badge
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _buildModeBadge(streamService),
                    ),
                    
                    // Connection status indicator
                    if (!streamService.isConnected)
                      _buildNotConnectedOverlay(),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // Status bar at bottom
        const SizedBox(height: 16),
        _buildStatusBar(streamService),
      ],
    );
  }

  Widget _buildWaitingState(StreamService streamService) {
    return Container(
      color: const Color(0xFF0A0E21),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              streamService.isConnected ? Icons.stream : Icons.videocam_off,
              size: 64,
              color: Colors.white24,
            ),
            const SizedBox(height: 16),
            Text(
              streamService.isConnected 
                  ? 'Waiting for stream...'
                  : 'Not connected',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
            if (streamService.isConnected) ...[
              const SizedBox(height: 16),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModeBadge(StreamService streamService) {
    Color badgeColor;
    IconData badgeIcon;
    String badgeText;

    switch (streamService.currentMode) {
      case StreamMode.manual:
        badgeColor = Colors.greenAccent;
        badgeIcon = Icons.gamepad;
        badgeText = 'Manual Control';
        break;
      case StreamMode.recognition:
        badgeColor = Colors.purpleAccent;
        badgeIcon = Icons.face;
        badgeText = 'Recognition';
        break;
      case StreamMode.normal:
        badgeColor = Colors.blue;
        badgeIcon = Icons.videocam;
        badgeText = 'Normal';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withAlpha(200),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            badgeText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotConnectedOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 48, color: Colors.white54),
            SizedBox(height: 12),
            Text(
              'Connect to start streaming',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(StreamService streamService) {
    Color modeColor;
    IconData modeIcon;
    String modeText;

    switch (streamService.currentMode) {
      case StreamMode.manual:
        modeColor = Colors.greenAccent;
        modeIcon = Icons.gamepad;
        modeText = 'Manual Control';
        break;
      case StreamMode.recognition:
        modeColor = Colors.purpleAccent;
        modeIcon = Icons.face;
        modeText = 'Recognition';
        break;
      case StreamMode.normal:
        modeColor = Colors.blue;
        modeIcon = Icons.videocam;
        modeText = 'Normal Stream';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Connection status
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: streamService.isConnected 
                  ? (streamService.isStreaming ? Colors.green : Colors.orange)
                  : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            streamService.isConnected
                ? (streamService.isStreaming ? 'Streaming' : 'Connected')
                : 'Disconnected',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          
          const SizedBox(width: 16),
          Container(width: 1, height: 16, color: Colors.white24),
          const SizedBox(width: 16),
          
          // Mode indicator
          Icon(
            modeIcon,
            color: modeColor,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            modeText,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
