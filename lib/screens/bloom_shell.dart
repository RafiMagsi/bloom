import 'package:flutter/material.dart';

import '../theme/bloom_theme.dart';
import '../widgets/bloom_bottom_nav.dart';
import 'home_screen.dart';
import 'mood_screen.dart';
import 'progress_screen.dart';
import 'routine_screen.dart';

/// Root shell: four tabs + the frosted bottom navigation.
class BloomShell extends StatefulWidget {
  const BloomShell({super.key});

  @override
  State<BloomShell> createState() => _BloomShellState();
}

class _BloomShellState extends State<BloomShell> {
  int _index = 0;

  void _go(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BloomPalette.cream,
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onNavigate: _go),
          const RoutineScreen(),
          const MoodScreen(),
          const ProgressScreen(),
        ],
      ),
      bottomNavigationBar: BloomBottomNav(
        index: _index,
        onChanged: _go,
      ),
    );
  }
}
