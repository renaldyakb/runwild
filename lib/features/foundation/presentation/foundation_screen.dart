import 'package:material_ui/material_ui.dart';

import '../../profile/presentation/profile_screen.dart';
import 'home_dashboard.dart';

enum FoundationDestination { home, profile }

class FoundationScreen extends StatelessWidget {
  const FoundationScreen({required this.destination, this.onStart, super.key});
  final FoundationDestination destination;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) => switch (destination) {
    FoundationDestination.home => HomeDashboard(onStart: onStart),
    FoundationDestination.profile => const ProfileScreen(),
  };
}
