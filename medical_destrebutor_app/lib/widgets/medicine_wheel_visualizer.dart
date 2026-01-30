import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/medicine.dart';

class MedicineWheelVisualizer extends StatefulWidget {
  final List<Medicine> medicines;
  final double currentAngle;
  final double? targetAngle;
  final bool isRotating;
  final Function(Medicine)? onMedicineSelected;
  final double size;

  const MedicineWheelVisualizer({
    Key? key,
    required this.medicines,
    required this.currentAngle,
    this.targetAngle,
    this.isRotating = false,
    this.onMedicineSelected,
    this.size = 400,
  }) : super(key: key);

  @override
  State<MedicineWheelVisualizer> createState() => _MedicineWheelVisualizerState();
}

class _MedicineWheelVisualizerState extends State<MedicineWheelVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            Colors.blue.shade900.withOpacity(0.1),
            Colors.purple.shade900.withOpacity(0.05),
            Colors.transparent,
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background glow when rotating
          if (widget.isRotating)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: widget.size * (0.8 + _pulseController.value * 0.1),
                  height: widget.size * (0.8 + _pulseController.value * 0.1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withOpacity(0.3 * _pulseController.value),
                        blurRadius: 40,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                );
              },
            ),

          // Main wheel
          CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _WheelPainter(
              medicines: widget.medicines,
              currentAngle: widget.currentAngle,
              targetAngle: widget.targetAngle,
              isRotating: widget.isRotating,
            ),
          ),

          // Medicine slots
          ...widget.medicines.map((medicine) {
            return _buildMedicineSlot(medicine);
          }),

          // Center hub
          _buildCenterHub(),

          // Angle indicator
          _buildAngleIndicator(),

          // 180° backward arrow (when rotating)
          if (widget.isRotating && widget.targetAngle != null)
            _buildBackwardArrow(),
        ],
      ),
    );
  }

  Widget _buildMedicineSlot(Medicine medicine) {
    // Calculate position relative to current wheel angle
    final double relativeAngle = (medicine.angle - widget.currentAngle) * math.pi / 180;
    final double radius = widget.size * 0.35;
    final double x = radius * math.cos(relativeAngle - math.pi / 2);
    final double y = radius * math.sin(relativeAngle - math.pi / 2);

    final bool isActive = widget.targetAngle == medicine.angle;
    final bool isNearTop = (medicine.angle - widget.currentAngle).abs() < 30;

    return Positioned(
      left: widget.size / 2 + x - 30,
      top: widget.size / 2 + y - 30,
      child: GestureDetector(
        onTap: () => widget.onMedicineSelected?.call(medicine),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isActive
                  ? [Colors.amber.shade400, Colors.orange.shade600]
                  : isNearTop
                      ? [Colors.green.shade400, Colors.teal.shade600]
                      : [Colors.blue.shade300, Colors.blue.shade700],
            ),
            boxShadow: [
              BoxShadow(
                color: (isActive ? Colors.amber : Colors.blue).withOpacity(0.5),
                blurRadius: isActive ? 20 : 10,
                spreadRadius: isActive ? 5 : 2,
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.medication, color: Colors.white, size: 20),
                const SizedBox(height: 2),
                Text(
                  medicine.slotIndex.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterHub() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.grey.shade800,
            Colors.grey.shade900,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 15,
            spreadRadius: 5,
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 3),
      ),
      child: const Icon(
        Icons.rotate_right,
        color: Colors.white70,
        size: 32,
      ),
    );
  }

  Widget _buildAngleIndicator() {
    return Positioned(
      bottom: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.cyan.withOpacity(0.5), width: 2),
        ),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.rotate_90_degrees_ccw, color: Colors.cyan, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Current: ${widget.currentAngle.toStringAsFixed(1)}°',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (widget.targetAngle != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.my_location, color: Colors.amber, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Target: ${widget.targetAngle!.toStringAsFixed(1)}°',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBackwardArrow() {
    return Positioned(
      top: 40,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Opacity(
            opacity: 0.5 + _pulseController.value * 0.5,
            child: Column(
              children: [
                Icon(
                  Icons.refresh,
                  color: Colors.red.shade400,
                  size: 40,
                ),
                const SizedBox(height: 4),
                Text(
                  '180° Backward',
                  style: TextStyle(
                    color: Colors.red.shade400,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<Medicine> medicines;
  final double currentAngle;
  final double? targetAngle;
  final bool isRotating;

  _WheelPainter({
    required this.medicines,
    required this.currentAngle,
    this.targetAngle,
    this.isRotating = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    // Draw outer ring
    final outerPaint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, outerPaint);

    // Draw inner ring
    final innerPaint = Paint()
      ..color = Colors.grey.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius - 40, innerPaint);

    // Draw spokes
    final spokePaint = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 1.5;

    for (var medicine in medicines) {
      final angle = (medicine.angle - 90) * math.pi / 180; // -90 to start at top
      final x1 = center.dx + (radius - 40) * math.cos(angle);
      final y1 = center.dy + (radius - 40) * math.sin(angle);
      final x2 = center.dx + radius * math.cos(angle);
      final y2 = center.dy + radius * math.sin(angle);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), spokePaint);
    }

    // Draw top marker (dispensing position)
    final markerPaint = Paint()
      ..color = Colors.green.shade400
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx, center.dy - radius - 20),
      Offset(center.dx, center.dy - radius - 5),
      markerPaint,
    );

    // Draw target indicator
    if (targetAngle != null) {
      final targetPaint = Paint()
        ..color = Colors.amber.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6;
      
      final targetAngleRad = (targetAngle! - 90) * math.pi / 180;
      final path = Path();
      path.addArc(
        Rect.fromCircle(center: center, radius: radius + 10),
        targetAngleRad - 0.1,
        0.2,
      );
      canvas.drawPath(path, targetPaint);
    }
  }

  @override
  bool shouldRepaint(_WheelPainter oldDelegate) {
    return currentAngle != oldDelegate.currentAngle ||
        targetAngle != oldDelegate.targetAngle ||
        isRotating != oldDelegate.isRotating;
  }
}
