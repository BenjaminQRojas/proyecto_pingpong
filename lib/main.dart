import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/models/ping_pong_shot.dart';
import 'services/mqtt_service.dart';
import 'services/database_service.dart';
import 'features/control/control_screen.dart';
import 'features/stats/stats_screen.dart';

void main() {
  runApp(const PingPongApp());
}

class PingPongApp extends StatelessWidget {
  const PingPongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<MqttService>(create: (_) => MqttService()),
        Provider<DatabaseService>(create: (_) => DatabaseService()),
        ChangeNotifierProvider<ShotProvider>(create: (_) => ShotProvider()),
      ],
      child: MaterialApp(
        title: 'PingPong IoT',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [ControlScreen(), StatsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.settings_remote),
            label: 'Control',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: 'Historial',
          ),
        ],
      ),
    );
  }
}

class ShotProvider extends ChangeNotifier {
  PingPongShot _currentShot = const PingPongShot(
    topMotorSpeed: 50,
    bottomMotorSpeed: 50,
    horizontalAngle: 90,
    interval: 1.0,
  );

  PingPongShot get currentShot => _currentShot;

  void updateShot(PingPongShot shot) {
    _currentShot = shot;
    notifyListeners();
  }
}
