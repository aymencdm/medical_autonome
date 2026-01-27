import 'package:flutter/material.dart';

class ConnectionCard extends StatelessWidget {
  final TextEditingController ipController;
  final bool isLoading;
  final bool isConnected;
  final VoidCallback onConnect;

  const ConnectionCard({
    super.key,
    required this.ipController,
    required this.isLoading,
    required this.isConnected,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
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
                    color: isConnected
                        ? Colors.green.withOpacity(0.2)
                        : const Color(0xFF2196F3).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isConnected ? Icons.check_circle : Icons.settings_input_antenna,
                    color: isConnected ? Colors.green : const Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isConnected ? 'Connected' : 'Connect to Server',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isConnected
                            ? 'Ready to stream'
                            : 'Enter Raspberry Pi IP address',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isConnected)
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: ipController,
              enabled: !isConnected,
              decoration: InputDecoration(
                labelText: 'Server IP Address',
                hintText: 'e.g., 192.168.1.100',
                prefixIcon: const Icon(Icons.computer, color: Color(0xFF2196F3)),
                suffixIcon: isConnected
                    ? const Icon(Icons.lock, color: Colors.white38)
                    : null,
              ),
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: isLoading || isConnected ? null : onConnect,
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(isConnected ? Icons.check : Icons.link),
              label: Text(
                isLoading
                    ? 'Connecting...'
                    : isConnected
                        ? 'Connected'
                        : 'Connect',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isConnected ? Colors.green : const Color(0xFF2196F3),
                disabledBackgroundColor: Colors.grey.shade700,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            if (!isConnected) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade300,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Make sure your Raspberry Pi is on the same network',
                        style: TextStyle(
                          color: Colors.blue.shade300,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
