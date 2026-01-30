import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'services/raspberry_pi_service.dart';
import 'providers/medicine_provider.dart';
import 'providers/system_provider.dart';
import 'screens/home_screen.dart';

import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure window for desktop
  await windowManager.ensureInitialized();
  
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1000, 700),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'Medical Delivery Robot Control',
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Initialize Settings
  final settingsService = await SettingsService.init();

  runApp(MedicalRobotApp(settingsService: settingsService));
}

class MedicalRobotApp extends StatelessWidget {
  final SettingsService settingsService;

  const MedicalRobotApp({
    Key? key, 
    required this.settingsService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize Raspberry Pi Service with stored IP
    final rpiService = RaspberryPiService(
      baseUrl: settingsService.ipAddress,
      socketNamespace: '/stream',
    );

    return MultiProvider(
      providers: [
        Provider<SettingsService>.value(value: settingsService),
        Provider<RaspberryPiService>.value(value: rpiService),
        ChangeNotifierProvider(create: (_) => MedicineProvider(rpiService)),
        ChangeNotifierProvider(create: (_) => SystemProvider(rpiService)),
      ],
      child: MaterialApp(
        title: 'Medical Delivery Robot',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.cyan,
          scaffoldBackgroundColor: Colors.black,
          fontFamily: 'Inter',
          textTheme: const TextTheme(
            headlineLarge: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            headlineMedium: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          cardTheme: CardThemeData(
            color: Colors.grey.shade900,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
