import 'package:flutter/material.dart';

import 'screens/bloom_shell.dart';
import 'screens/welcome_screen.dart';
import 'services/storage_service.dart';
import 'state/bloom_controller.dart';
import 'state/bloom_scope.dart';
import 'theme/bloom_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  runApp(BloomApp(controller: BloomController()));
}

class BloomApp extends StatelessWidget {
  const BloomApp({super.key, required this.controller});

  final BloomController controller;

  @override
  Widget build(BuildContext context) {
    return BloomScope(
      controller: controller,
      child: MaterialApp(
        title: 'Bloom',
        debugShowCheckedModeBanner: false,
        theme: BloomTheme.theme(),
        home: controller.onboardingDone
            ? const BloomShell()
            : const WelcomeScreen(),
      ),
    );
  }
}
