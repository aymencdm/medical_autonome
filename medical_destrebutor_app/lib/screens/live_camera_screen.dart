import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/system_provider.dart';
import '../models/robot_mode.dart';

class LiveCameraScreen extends StatelessWidget {
  const LiveCameraScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SystemProvider>(
      builder: (context, systemProvider, child) {
        final state = systemProvider.systemState;

        return Row(
          children: [
            // Left: Camera Feed
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.cyan.withOpacity(0.3), width: 2),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.videocam_off, size: 80, color: Colors.grey.shade600),
                      const SizedBox(height: 20),
                      Text(
                        'Camera Feed',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        systemProvider.isConnected ? 'Connecting...' : 'Not Connected',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Right: System Status Panel
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mode Status
                      _buildStatusCard(
                        'System Mode',
                        state.mode.displayName,
                        state.mode.icon,
                        Colors.cyan,
                      ),
                      const SizedBox(height: 15),

                      // Wheel Status
                      _buildStatusCard(
                        'Wheel Angle',
                        '${state.wheelAngle.toStringAsFixed(0)}°',
                        '🎯',
                        Colors.purple,
                      ),
                      const SizedBox(height: 15),

                      // Door Status
                      _buildStatusCard(
                        'Door Status',
                        state.isDoorOpen ? 'OPEN' : 'CLOSED',
                        state.isDoorOpen ? '🚪' : '🔒',
                        state.isDoorOpen ? Colors.green : Colors.red,
                      ),
                      const SizedBox(height: 15),

                      // Patient Recognition
                      if (state.recognizedPatientName != null)
                        _buildStatusCard(
                          'Recognized Patient',
                          state.recognizedPatientName!,
                          '👤',
                          Colors.green,
                        ),

                      const SizedBox(height: 30),

                      // Emergency Stop Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => systemProvider.emergencyStop(),
                          icon: const Icon(Icons.stop_circle),
                          label: const Text('EMERGENCY STOP'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusCard(String title, String value, String icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
