import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/patient.dart';
import '../providers/patient_provider.dart';
import '../providers/system_provider.dart';
import '../providers/video_provider.dart';
import '../services/raspberry_pi_service.dart';

class PatientManagementScreen extends StatefulWidget {
  const PatientManagementScreen({Key? key}) : super(key: key);

  @override
  State<PatientManagementScreen> createState() => _PatientManagementScreenState();
}

class _PatientManagementScreenState extends State<PatientManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Load patients when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatientProvider>().loadPatients();
    });
  }

  void _showAddPatientDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.person_add, color: Colors.cyan.shade400),
            const SizedBox(width: 12),
            const Text('Add Patient', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Patient Name',
                labelStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.person, color: Colors.cyan.shade400),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.cyan.shade400, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You can capture face images after adding the patient.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade400)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a patient name')),
                );
                return;
              }

              try {
                final patient = Patient(name: nameController.text.trim());
                await context.read<PatientProvider>().addPatient(patient);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Patient "${patient.name}" added successfully'),
                    backgroundColor: Colors.green.shade700,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Add Patient'),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePatient(Patient patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade400),
            const SizedBox(width: 12),
            const Text('Delete Patient', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${patient.name}"? This will also remove their face data.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade400)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await context.read<PatientProvider>().deletePatient(patient.id!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Patient "${patient.name}" deleted'),
                    backgroundColor: Colors.orange.shade700,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _startFaceCapture(Patient patient) async {
    if (patient.id == null) return;

    // Start video stream
    context.read<VideoProvider>().startStream();

    // Trigger capture process
    _triggerCapture(patient);

    // Show capture dialog with video stream
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.camera_alt, color: Colors.cyan.shade400),
            const SizedBox(width: 12),
            const Text('Face Capture', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: SizedBox(
          width: 640,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Live Video Feed
              Container(
                height: 480,
                width: 640,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.cyan.shade900, width: 2),
                ),
                child: Consumer<VideoProvider>(
                  builder: (context, videoProvider, _) {
                    if (videoProvider.currentFrame == null) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.memory(
                         videoProvider.currentFrame!,
                         gaplessPlayback: true,
                         fit: BoxFit.contain,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Capturing faces for ${patient.name}...\n\nPlease position the patient in front of the camera.\nThe robot will automatically track and capture images.',
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.camera),
            label: const Text('Take Picture'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
               context.read<RaspberryPiService>().captureFrame(patient.id!);
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Picture taken!')),
               );
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );

    // Stop stream when dialog closes
    if (mounted) {
      context.read<VideoProvider>().stopStream();
    }
  }

  Future<void> _triggerCapture(Patient patient) async {
     try {
      final rpiService = context.read<RaspberryPiService>();
      await rpiService.startFaceCapture(patient.id!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Face capture started for ${patient.name}. Position in front of camera.'),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start face capture: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PatientProvider>(
      builder: (context, patientProvider, child) {
        return Column(
          children: [
            // Header with actions
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people, size: 32, color: Colors.cyan.shade400),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Patient Management',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade200,
                            ),
                          ),
                          Text(
                            '${patientProvider.patients.length} patients registered',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Refresh Connection button
                      IconButton(
                        icon: Icon(Icons.refresh, color: Colors.cyan.shade400),
                        tooltip: 'Refresh Connection',
                        onPressed: () {
                           context.read<SystemProvider>().connect();
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text('Refreshing connection...')),
                           );
                        },
                      ),
                      const SizedBox(width: 8),
                      // Train button
                      ElevatedButton.icon(
                        onPressed: patientProvider.isTraining
                            ? null
                            : () async {
                                try {
                                  await patientProvider.trainFaceRecognition();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Face recognition model trained!'),
                                      backgroundColor: Colors.green.shade700,
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Training failed: $e'),
                                      backgroundColor: Colors.red.shade700,
                                    ),
                                  );
                                }
                              },
                        icon: patientProvider.isTraining
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.model_training),
                        label: Text(patientProvider.isTraining ? 'Training...' : 'Train Model'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Add patient button
                      ElevatedButton.icon(
                        onPressed: _showAddPatientDialog,
                        icon: const Icon(Icons.person_add),
                        label: const Text('Add Patient'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: patientProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : patientProvider.patients.isEmpty
                      ? _buildEmptyState()
                      : _buildPatientList(patientProvider.patients),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline, size: 80, color: Colors.grey.shade600),
          const SizedBox(height: 16),
          Text(
            'No Patients Registered',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first patient to get started',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddPatientDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add First Patient'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientList(List<Patient> patients) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: patients.length,
      itemBuilder: (context, index) {
        final patient = patients[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: Colors.grey.shade800,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.cyan.shade700,
              child: Text(
                patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            title: Text(
              patient.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            subtitle: Row(
              children: [
                Icon(
                  patient.isTrained ? Icons.check_circle : Icons.pending,
                  size: 14,
                  color: patient.isTrained ? Colors.green.shade400 : Colors.orange.shade400,
                ),
                const SizedBox(width: 4),
                Text(
                  patient.isTrained ? 'Face trained' : 'Not trained',
                  style: TextStyle(
                    color: patient.isTrained ? Colors.green.shade400 : Colors.orange.shade400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Capture faces button
                IconButton(
                  icon: Icon(Icons.camera_alt, color: Colors.cyan.shade400),
                  tooltip: 'Capture Face Images',
                  onPressed: () => _startFaceCapture(patient),
                ),
                // Delete button
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                  tooltip: 'Delete Patient',
                  onPressed: () => _confirmDeletePatient(patient),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
