import 'package:flutter/material.dart';
import 'package:jobspot_app/core/theme/app_theme.dart';
import 'package:jobspot_app/features/dashboard/presentation/screens/employer_dashboard.dart';
import 'package:jobspot_app/features/dashboard/presentation/screens/seeker_dashboard.dart';
import 'package:provider/provider.dart';
import 'package:jobspot_app/features/profile/presentation/providers/profile_provider.dart';

class ProfileLoadingScreen extends StatefulWidget {
  final String role;
  const ProfileLoadingScreen({super.key, required this.role});

  @override
  State<ProfileLoadingScreen> createState() => _ProfileLoadingScreenState();
}

class _ProfileLoadingScreenState extends State<ProfileLoadingScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToDashboard();
  }

  Future<void> _navigateToDashboard() async {
    // 1. Simulate additional loading/creation time for UX
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    // 2. Refresh the ProfileProvider to get the latest data (isProfileCompleted = true)
    try {
      await Provider.of<ProfileProvider>(
        context,
        listen: false,
      ).refreshProfile();
    } catch (e) {
      debugPrint("Error refreshing profile: $e");
    }

    if (!mounted) return;

    if (widget.role == 'seeker') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SeekerDashboard()),
        (route) => false, // Remove all previous routes
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const EmployerDashboard()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.purple),
            const SizedBox(height: 24),
            Text(
              'Setting up your profile...',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.darkPurple,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we prepare your dashboard.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
