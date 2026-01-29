import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/stream_service.dart';

class ViewerScreen extends StatefulWidget {
  const ViewerScreen({super.key});

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  final TextEditingController _ipController = TextEditingController();
  double _panValue = 90;
  double _tiltValue = 90;

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  void _connect() {
    final streamService = context.read<StreamService>();
    streamService.setServerIp(_ipController.text.trim());
    streamService.connect();
  }

  void _disconnect() {
    context.read<StreamService>().disconnect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0A0E21),
        ),
        child: Consumer<StreamService>(
          builder: (context, streamService, _) {
            return Row(
              children: [
                // Left sidebar - Controls
                Container(
                  width: 350,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D1E33),
                    border: Border(
                      right: BorderSide(
                        color: Colors.blue.withOpacity(0.3),
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
                        const SizedBox(height: 20),
                        _buildConnectionSection(streamService),
                        const SizedBox(height: 20),
                        if (streamService.isConnected) ...[
                          _buildStreamControls(streamService),
                          const SizedBox(height: 20),
                          _buildServoControls(streamService),
                        ],
                      ],
                    ),
                  ),
                ),
                
                // Right side - Video display
                Expanded(
                  child: _buildVideoDisplay(streamService),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Icon(Icons.radar, color: Colors.blue, size: 50),
        const SizedBox(height: 10),
        const Text(
          'Face Tracker',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          'WebSocket Edition',
          style: TextStyle(color: Colors.blue.withOpacity(0.7), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildConnectionSection(StreamService streamService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _ipController,
          decoration: const InputDecoration(
            labelText: 'Raspberry Pi IP',
            labelStyle: TextStyle(color: Colors.white70),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: streamService.isConnected ? _disconnect : _connect,
          style: ElevatedButton.styleFrom(
            backgroundColor: streamService.isConnected ? Colors.red : Colors.blue,
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          child: Text(streamService.isConnected ? 'Disconnect' : 'Connect'),
        ),
        if (streamService.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(streamService.errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildStreamControls(StreamService streamService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Stream Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Active:', style: TextStyle(color: Colors.white70)),
            Switch(
              value: streamService.isStreaming,
              onChanged: (val) => val ? streamService.startStreaming() : streamService.stopStreaming(),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Auto-Tracking:', style: TextStyle(color: Colors.white70)),
            Switch(
              value: streamService.isTracking,
              onChanged: (val) => streamService.toggleTracking(val),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServoControls(StreamService streamService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Manual Control', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text('Pan (Horizontal)', style: TextStyle(color: Colors.white70, fontSize: 12)),
        Slider(
          value: _panValue,
          min: 0,
          max: 180,
          onChanged: (val) {
            setState(() => _panValue = val);
            streamService.moveServo(val, _tiltValue);
          },
        ),
        const Text('Tilt (Vertical)', style: TextStyle(color: Colors.white70, fontSize: 12)),
        Slider(
          value: _tiltValue,
          min: 30,
          max: 150,
          onChanged: (val) {
            setState(() => _tiltValue = val);
            streamService.moveServo(_panValue, val);
          },
        ),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _panValue = 90;
              _tiltValue = 90;
            });
            streamService.centerServo();
          },
          icon: const Icon(Icons.center_focus_strong),
          label: const Text('Center'),
        ),
      ],
    );
  }

  Widget _buildVideoDisplay(StreamService streamService) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue.withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 20, spreadRadius: 5),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: 640 / 480,
            child: streamService.currentFrame != null
                ? Image.memory(
                    streamService.currentFrame!,
                    gaplessPlayback: true,
                    fit: BoxFit.cover,
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 20),
                      Text('Waiting for stream...', style: TextStyle(color: Colors.white54)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
