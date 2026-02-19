import 'package:flutter/material.dart';
import 'package:jobspot_app/core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UnableAccountPage extends StatelessWidget {
  final Map<String, dynamic> userProfile;

  const UnableAccountPage({super.key, required this.userProfile});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block_outlined, color: Colors.red, size: 80),
              const SizedBox(height: 24),
              Text(
                'Account Disabled',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.headlineMedium?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Hello ${userProfile['name'] ?? 'User'},\n\nYour account has been disabled. Please contact support if you believe this is a mistake.',
                style: textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await Supabase.instance.client.auth.signOut();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back to Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // TODO: Implement contact support logic
                },
                child: const Text(
                  'Contact Support',
                  style: TextStyle(
                    color: AppColors.purple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
