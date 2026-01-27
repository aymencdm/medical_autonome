import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/stream_service.dart';
import '../widgets/connection_card.dart';
import '../widgets/stream_player.dart';
import '../widgets/stream_controls.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _ipController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _ipController.dispose();
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
          content: Text('✓ Connected to server'),
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
        child: SafeArea(
          child: Consumer<StreamService>(
            builder: (context, streamService, _) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    _buildHeader(),
                    const SizedBox(height: 30),
                    
                    // Connection Card
                    ConnectionCard(
                      ipController: _ipController,
                      isLoading: _isLoading,
                      isConnected: streamService.isConnected,
                      onConnect: _connect,
                    ),
                    const SizedBox(height: 20),
                    
                    // Stream Player (only show when connected)
                    if (streamService.isConnected) ...[
                      const StreamPlayer(),
                      const SizedBox(height: 20),
                      
                      // Stream Controls
                      const StreamControls(),
                      const SizedBox(height: 20),
                      
                      // Stream Info
                      _buildStreamInfo(streamService),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF2196F3).withOpacity(0.3),
                const Color(0xFF1976D2).withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF2196F3).withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
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
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStreamInfo(StreamService streamService) {
    if (streamService.streamInfo == null) return const SizedBox.shrink();

    final info = streamService.streamInfo!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF2196F3)),
                const SizedBox(width: 8),
                Text(
                  'Stream Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
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
}
