import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/system_provider.dart';
import '../models/robot_mode.dart';
import 'patient_management_screen.dart';
import 'medicine_wheel_screen.dart';
import 'assignment_screen.dart';
import 'live_camera_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;

  final List<Widget> _screens = [
    const PatientManagementScreen(),
    const MedicineWheelScreen(),
    const AssignmentScreen(),
    const LiveCameraScreen(),
  ];

  final List<String> _titles = [
    'Patient Management',
    'Medicine Wheel',
    'Assignments',
    'Live System',
  ];

  final List<IconData> _icons = [
    Icons.people,
    Icons.rotate_right,
    Icons.assignment,
    Icons.videocam,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedIndex = _tabController.index;
      });
    });

    // Auto-connect on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SystemProvider>().connect();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
              Colors.grey.shade900,
              Colors.black,
              Colors.grey.shade900,
            ],
          ),
        ),
        child: Column(
          children: [
            // Custom App Bar
            _buildAppBar(),
            
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _screens,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Title and Status
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Logo/Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.cyan.shade400, Colors.blue.shade600],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyan.withOpacity(0.5),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_hospital,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 15),

                  // Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Medical Delivery Robot',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..shader = LinearGradient(
                                colors: [Colors.cyan.shade300, Colors.blue.shade500],
                              ).createShader(const Rect.fromLTWH(0, 0, 300, 30)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _titles[_selectedIndex],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // System Status
                  _buildSystemStatus(),

                  // Settings Button
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white24,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white70),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
                        );
                      },
                      tooltip: 'Settings',
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.cyan.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.cyan.shade600, Colors.blue.shade700],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyan.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey.shade500,
                tabs: List.generate(4, (index) {
                  return Tab(
                    icon: Icon(_icons[index]),
                    text: _titles[index].split(' ')[0],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatus() {
    return Consumer<SystemProvider>(
      builder: (context, systemProvider, child) {
        final isConnected = systemProvider.isConnected;
        final mode = systemProvider.systemState.mode;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isConnected ? Colors.green.shade400 : Colors.red.shade400,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isConnected ? Colors.green.shade400 : Colors.red.shade400,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isConnected ? Colors.green : Colors.red).withOpacity(0.6),
                      blurRadius: 10,
                      spreadRadius: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isConnected ? 'CONNECTED' : 'OFFLINE',
                    style: TextStyle(
                      color: isConnected ? Colors.green.shade400 : Colors.red.shade400,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!isConnected && systemProvider.error != null)
                     Padding(
                       padding: const EdgeInsets.only(top: 2.0),
                       child: Text(
                         systemProvider.error!.length > 30 
                             ? '${systemProvider.error!.substring(0, 30)}...' 
                             : systemProvider.error!,
                         style: TextStyle(
                           color: Colors.red.shade200,
                           fontSize: 9,
                         ),
                       ),
                     ),
                  if (isConnected)
                    Text(
                      mode.displayName,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 5),
              Text(
                mode.icon,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        );
      },
    );
  }
}
