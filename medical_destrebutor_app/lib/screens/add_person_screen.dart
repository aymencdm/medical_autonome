import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/stream_service.dart';

class AddPersonScreen extends StatefulWidget {
  const AddPersonScreen({super.key});

  @override
  State<AddPersonScreen> createState() => _AddPersonScreenState();
}

class _AddPersonScreenState extends State<AddPersonScreen> {
  final TextEditingController _nameController = TextEditingController();
  int _capturedCount = 0;
  bool _isTraining = false;
  String? _statusMessage;

  void _capture() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name first')),
      );
      return;
    }

    final service = context.read<StreamService>();
    if (service.currentFrame == null) return;

    // Send capture command
    service.captureImage(name, service.currentFrame!);
    
    setState(() {
      _capturedCount++;
      _statusMessage = "Captured $_capturedCount images";
    });
  }

  void _startTraining() {
    if (_capturedCount < 1) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Capture at least 1 image')),
      );
      return;
    }

    setState(() {
      _isTraining = true;
      _statusMessage = "Training model... Please wait.";
    });

    context.read<StreamService>().trainModel();
    
    // In a real app we would listen for 'training_complete'
    // For now, let's just simulate a delay or rely on user to go back
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isTraining = false;
          _statusMessage = "Training Request Sent!";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Training initiated on RPi')),
        );
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<StreamService>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F111A), // Dark bg
      appBar: AppBar(title: const Text('Add Person')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Person Name',
                filled: true,
                fillColor: Color(0xFF1D1E33),
              ),
            ),
            const SizedBox(height: 20),
            
            // Camera Preview
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: service.currentFrame != null
                    ? Image.memory(
                        service.currentFrame!,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      )
                    : const Center(child: Text("Waiting for stream...", style: TextStyle(color: Colors.white54))),
              ),
            ),
            
            const SizedBox(height: 20),
            if (_statusMessage != null)
              Text(_statusMessage!, style: const TextStyle(color: Colors.greenAccent, fontSize: 16)),
            
            const SizedBox(height: 20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isTraining ? null : _capture,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Capture Photo"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: (_isTraining || _capturedCount == 0) ? null : _startTraining,
                  icon: const Icon(Icons.save),
                  label: Text(_isTraining ? "Training..." : "Finish & Train"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 10),
            const Text(
              "Tip: Move your head slightly between captures.",
              style: TextStyle(color: Colors.white30, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
