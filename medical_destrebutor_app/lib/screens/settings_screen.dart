import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';

/// Settings screen for configuring server connection and preferences.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController();
  final _portController = TextEditingController();
  String _selectedMode = 'normal';
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final settings = context.read<SettingsService>();
    _ipController.text = settings.serverIp;
    _portController.text = settings.serverPort.toString();
    _selectedMode = settings.defaultMode;
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final settings = context.read<SettingsService>();
    
    await settings.setServerIp(_ipController.text.trim());
    await settings.setServerPort(int.tryParse(_portController.text) ?? 8080);
    await settings.setDefaultMode(_selectedMode);

    setState(() => _hasChanges = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Settings saved successfully'),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_hasChanges)
            TextButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save, color: Colors.green),
              label: const Text('Save', style: TextStyle(color: Colors.green)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Server Connection Section
              _buildSectionHeader('Server Connection', Icons.wifi),
              const SizedBox(height: 16),
              _buildConnectionCard(),
              
              const SizedBox(height: 32),
              
              // Default Mode Section
              _buildSectionHeader('Default Stream Mode', Icons.videocam),
              const SizedBox(height: 16),
              _buildModeCard(),
              
              const SizedBox(height: 32),
              
              // Actions Section
              _buildActionsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // IP Address Field
          TextFormField(
            controller: _ipController,
            decoration: InputDecoration(
              labelText: 'Raspberry Pi IP Address',
              hintText: '192.168.1.100',
              prefixIcon: const Icon(Icons.computer, color: Colors.blue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 16),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an IP address';
              }
              // Basic IP validation
              final parts = value.split('.');
              if (parts.length != 4) {
                return 'Invalid IP format (e.g., 192.168.1.100)';
              }
              return null;
            },
            onChanged: (_) => setState(() => _hasChanges = true),
          ),
          
          const SizedBox(height: 16),
          
          // Port Field
          TextFormField(
            controller: _portController,
            decoration: InputDecoration(
              labelText: 'Port',
              hintText: '8080',
              prefixIcon: const Icon(Icons.lan, color: Colors.blue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 16),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a port number';
              }
              final port = int.tryParse(value);
              if (port == null || port <= 0 || port > 65535) {
                return 'Port must be between 1 and 65535';
              }
              return null;
            },
            onChanged: (_) => setState(() => _hasChanges = true),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildModeOption(
            title: 'Normal Stream',
            subtitle: 'Pure video streaming without face tracking',
            value: 'normal',
            icon: Icons.videocam,
          ),
          const Divider(color: Colors.white24, height: 24),
          _buildModeOption(
            title: 'Face Tracking',
            subtitle: 'AI-powered tracking with servo control',
            value: 'face_tracking',
            icon: Icons.face,
          ),
        ],
      ),
    );
  }

  Widget _buildModeOption({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _selectedMode == value;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedMode = value;
          _hasChanges = true;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 2,
          ),
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
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
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedMode,
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _selectedMode = v;
                    _hasChanges = true;
                  });
                }
              },
              activeColor: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save),
              label: const Text('Save Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Reset Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF1D1E33),
                    title: const Text('Reset Settings?', style: TextStyle(color: Colors.white)),
                    content: const Text(
                      'This will reset all settings to their default values.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true) {
                  await context.read<SettingsService>().resetToDefaults();
                  _loadSettings();
                  setState(() => _hasChanges = false);
                }
              },
              icon: const Icon(Icons.restore, color: Colors.orange),
              label: const Text('Reset to Defaults', style: TextStyle(color: Colors.orange)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.orange),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
