import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:imoon/theme.dart';
import 'package:imoon/screens/home/home_screen.dart';
import 'package:imoon/screens/calendar/calendar_screen.dart';
import 'package:imoon/screens/insights/insights_screen.dart';
import 'package:imoon/screens/settings/settings_screen.dart';

class IMoonApp extends StatelessWidget {
  const IMoonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:        'iMoon',
      theme:        buildTheme(),
      debugShowCheckedModeBanner: false,
      home:         const _Shell(),
    );
  }
}

class _Shell extends StatefulWidget {
  const _Shell();

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    CalendarScreen(),
    InsightsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:            Colors.transparent,
      statusBarIconBrightness:   Brightness.light,
      systemNavigationBarColor:  IMoonColors.surface,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon:          Icon(Icons.nightlight_outlined),
            selectedIcon:  Icon(Icons.nightlight_round),
            label:         'Today',
          ),
          NavigationDestination(
            icon:          Icon(Icons.calendar_month_outlined),
            selectedIcon:  Icon(Icons.calendar_month),
            label:         'Calendar',
          ),
          NavigationDestination(
            icon:          Icon(Icons.bar_chart_outlined),
            selectedIcon:  Icon(Icons.bar_chart),
            label:         'Insights',
          ),
          NavigationDestination(
            icon:          Icon(Icons.settings_outlined),
            selectedIcon:  Icon(Icons.settings),
            label:         'Settings',
          ),
        ],
      ),
    );
  }
}
