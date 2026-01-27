import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import '../services/stream_service.dart';

class StreamPlayer extends StatefulWidget {
  const StreamPlayer({super.key});

  @override
  State<StreamPlayer> createState() => _StreamPlayerState();
}

class _StreamPlayerState extends State<StreamPlayer> {
  VlcPlayerController? _vlcController;
  bool _isInitialized = false;
  String? _currentUrl;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    final streamService = context.read<StreamService>();
    
    if (streamService.sdpUrl.isNotEmpty) {
      _currentUrl = streamService.sdpUrl;
      
      _vlcController = VlcPlayerController.network(
        _currentUrl!,
        hwAcc: HwAcc.full,
        autoPlay: false,
        options: VlcPlayerOptions(
          advanced: VlcAdvancedOptions([
            VlcAdvancedOptions.networkCaching(1000),
            VlcAdvancedOptions.clockJitter(0),
            VlcAdvancedOptions.clockSynchro(0),
          ]),
          rtp: VlcRtpOptions([
            '--rtsp-tcp',
            '--network-caching=300',
            '--rtp-client-port=5000',
          ]),
          video: VlcVideoOptions([
            VlcVideoOptions.dropLateFrames(true),
            VlcVideoOptions.skipFrames(true),
          ]),
          extras: [
            '--live-caching=300',
            '--no-audio',
          ],
        ),
      );

      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _vlcController?.dispose();
    super.dispose();
  }

  void _playStream() {
    if (_vlcController != null && _isInitialized) {
      _vlcController!.play();
    }
  }

  void _stopStream() {
    if (_vlcController != null && _isInitialized) {
      _vlcController!.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StreamService>(
      builder: (context, streamService, _) {
        // Auto-play when streaming starts
        if (streamService.isStreaming && _isInitialized) {
          Future.delayed(const Duration(milliseconds: 500), _playStream);
        } else if (!streamService.isStreaming && _isInitialized) {
          _stopStream();
        }

        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.video_library,
                        color: Color(0xFF2196F3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Video Stream',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            streamService.isStreaming
                                ? 'Live stream active'
                                : 'Waiting for stream...',
                            style: TextStyle(
                              color: streamService.isStreaming
                                  ? Colors.green
                                  : Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (streamService.isStreaming)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                height: 400,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: streamService.isStreaming
                        ? const Color(0xFF2196F3)
                        : Colors.white24,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _isInitialized && _vlcController != null
                      ? VlcPlayer(
                          controller: _vlcController!,
                          aspectRatio: 4 / 3,
                          placeholder: _buildPlaceholder(streamService),
                        )
                      : _buildPlaceholder(streamService),
                ),
              ),
            ],
          ),
        );
      },
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
              size: 64,
              color: Colors.white38,
            ),
            const SizedBox(height: 16),
            Text(
              streamService.isStreaming
                  ? 'Loading stream...'
                  : 'No stream available',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 16,
              ),
            ),
            if (streamService.isStreaming) ...[
              const SizedBox(height: 16),
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
