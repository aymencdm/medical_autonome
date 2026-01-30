import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medicine_provider.dart';
import '../models/medicine.dart';
import '../widgets/medicine_wheel_visualizer.dart';

class MedicineWheelScreen extends StatefulWidget {
  const MedicineWheelScreen({Key? key}) : super(key: key);

  @override
  State<MedicineWheelScreen> createState() => _MedicineWheelScreenState();
}

class _MedicineWheelScreenState extends State<MedicineWheelScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicineProvider>().loadMedicines();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicineProvider>(
      builder: (context, medicineProvider, child) {
        if (medicineProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Row(
          children: [
            // Left: Wheel Visualizer
            Expanded(
              flex: 3,
              child: _buildWheelSection(medicineProvider),
            ),

            // Right: Medicine List & Controls
            Expanded(
              flex: 2,
              child: _buildControlSection(medicineProvider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWheelSection(MedicineProvider provider) {
    return Container(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '🎡 Medicine Carousel',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              foreground: Paint()
                ..shader = LinearGradient(
                  colors: [Colors.purple.shade300, Colors.blue.shade400],
                ).createShader(const Rect.fromLTWH(0, 0, 300, 30)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '180° Backward Rotation on Selection',
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 40),

          // Wheel Visualizer
          MedicineWheelVisualizer(
            medicines: provider.medicines,
            currentAngle: provider.currentWheelAngle,
            targetAngle: provider.targetWheelAngle,
            isRotating: provider.isRotating,
            size: 450,
            onMedicineSelected: (medicine) {
              _showRotateConfirmation(medicine, provider);
            },
          ),

          const SizedBox(height: 30),

          // Manual Controls
          _buildManualControls(provider),
        ],
      ),
    );
  }

  Widget _buildManualControls(MedicineProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.cyan.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Text(
            'Manual Wheel Control',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade300,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: provider.isRotating ? null : () {
                  // Rotate -45°
                  double newAngle = (provider.currentWheelAngle - 45) % 360;
                  // TODO: Call rotate method
                },
                icon: const Icon(Icons.rotate_left, color: Colors.cyan),
                iconSize: 32,
              ),
              const SizedBox(width: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  '${provider.currentWheelAngle.toStringAsFixed(0)}°',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              IconButton(
                onPressed: provider.isRotating ? null : () {
                  // Rotate +45°
                  double newAngle = (provider.currentWheelAngle + 45) % 360;
                  // TODO: Call rotate method
                },
                icon: const Icon(Icons.rotate_right, color: Colors.cyan),
                iconSize: 32,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlSection(MedicineProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        border: Border(
          left: BorderSide(color: Colors.cyan.withOpacity(0.3), width: 2),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade900, Colors.blue.shade900],
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.medication, color: Colors.white, size: 28),
                const SizedBox(width: 15),
                const Expanded(
                  child: Text(
                    'Medicine Management',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _showAddMedicineDialog(),
                  icon: const Icon(Icons.add_circle, color: Colors.greenAccent),
                  iconSize: 32,
                  tooltip: 'Add Medicine',
                ),
              ],
            ),
          ),

          // Medicine List
          Expanded(
            child: provider.medicines.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: provider.medicines.length,
                    itemBuilder: (context, index) {
                      final medicine = provider.medicines[index];
                      return _buildMedicineCard(medicine, provider);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(Medicine medicine, MedicineProvider provider) {
    final bool isActive = provider.targetWheelAngle == medicine.angle;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [Colors.amber.shade700, Colors.orange.shade800]
              : [Colors.blue.shade800, Colors.blue.shade900],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: (isActive ? Colors.amber : Colors.blue).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => _showRotateConfirmation(medicine, provider),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                // Slot indicator
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      medicine.slotIndex.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),

                // Medicine info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.rotate_right, color: Colors.white70, size: 16),
                          const SizedBox(width: 5),
                          Text(
                            'Angle: ${medicine.angle.toStringAsFixed(0)}°',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _showEditMedicineDialog(medicine),
                      icon: const Icon(Icons.edit, color: Colors.white70),
                    ),
                    IconButton(
                      onPressed: () => _confirmDelete(medicine, provider),
                      icon: Icon(Icons.delete, color: Colors.red.shade300),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medication_outlined, size: 80, color: Colors.grey.shade600),
          const SizedBox(height: 20),
          Text(
            'No Medicines Added',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Click + to add your first medicine',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _showRotateConfirmation(Medicine medicine, MedicineProvider provider) {
    if (provider.isRotating) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.rotate_right, color: Colors.cyan.shade400),
            const SizedBox(width: 10),
            const Text('Rotate to Medicine', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medicine: ${medicine.name}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Target Angle: ${medicine.angle.toStringAsFixed(0)}°',
              style: TextStyle(color: Colors.grey.shade400),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.orange.shade900.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade600, width: 2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Wheel will rotate 180° backward first, then align to target',
                      style: TextStyle(color: Colors.orange.shade200, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade400)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              provider.rotateToMedicine(medicine);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Rotate', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddMedicineDialog() {
    final nameController = TextEditingController();
    final angleController = TextEditingController();
    final slotController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add New Medicine', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogTextField(nameController, 'Medicine Name', Icons.medication),
              const SizedBox(height: 15),
              _buildDialogTextField(slotController, 'Slot Index', Icons.numbers, isNumber: true),
              const SizedBox(height: 15),
              _buildDialogTextField(angleController, 'Servo Angle (0-360°)', Icons.rotate_right, isNumber: true),
              const SizedBox(height: 15),
              _buildDialogTextField(descController, 'Description (optional)', Icons.description),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade400)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  angleController.text.isNotEmpty &&
                  slotController.text.isNotEmpty) {
                final medicine = Medicine(
                  name: nameController.text,
                  angle: double.parse(angleController.text),
                  slotIndex: int.parse(slotController.text),
                  description: descController.text.isEmpty ? null : descController.text,
                );
                context.read<MedicineProvider>().addMedicine(medicine);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditMedicineDialog(Medicine medicine) {
    final nameController = TextEditingController(text: medicine.name);
    final angleController = TextEditingController(text: medicine.angle.toString());
    final slotController = TextEditingController(text: medicine.slotIndex.toString());
    final descController = TextEditingController(text: medicine.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Medicine', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogTextField(nameController, 'Medicine Name', Icons.medication),
              const SizedBox(height: 15),
              _buildDialogTextField(slotController, 'Slot Index', Icons.numbers, isNumber: true),
              const SizedBox(height: 15),
              _buildDialogTextField(angleController, 'Servo Angle (0-360°)', Icons.rotate_right, isNumber: true),
              const SizedBox(height: 15),
              _buildDialogTextField(descController, 'Description (optional)', Icons.description),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade400)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  angleController.text.isNotEmpty &&
                  slotController.text.isNotEmpty) {
                final updatedMedicine = medicine.copyWith(
                  name: nameController.text,
                  angle: double.parse(angleController.text),
                  slotIndex: int.parse(slotController.text),
                  description: descController.text.isEmpty ? null : descController.text,
                );
                context.read<MedicineProvider>().updateMedicine(updatedMedicine);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Medicine medicine, MedicineProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red.shade400),
            const SizedBox(width: 10),
            const Text('Delete Medicine', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${medicine.name}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade400)),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteMedicine(medicine.id!);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: Colors.cyan.shade400),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.cyan.shade400, width: 2),
        ),
      ),
    );
  }
}
