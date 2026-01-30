import 'package:flutter/material.dart';

class PatientManagementScreen extends StatelessWidget {
  const PatientManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 80, color: Colors.cyan.shade400),
          const SizedBox(height: 20),
          Text(
            'Patient Management',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Add patients, capture faces, train recognition',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement patient management
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Patient'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
          ),
        ],
      ),
    );
  }
}
