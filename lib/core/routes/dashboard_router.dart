import 'package:flutter/material.dart';
import 'package:jobspot_app/core/constants/user_role.dart';
import 'package:jobspot_app/features/dashboard/presentation/screens/admin_dashboard.dart';
import 'package:jobspot_app/features/dashboard/presentation/screens/employer_dashboard.dart';
import 'package:jobspot_app/features/dashboard/presentation/screens/seeker_dashboard.dart';

class DashboardRouter extends StatelessWidget {
  final UserRole? role;

  const DashboardRouter({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    switch (role) {
      case UserRole.seeker:
        return const SeekerDashboard();
      case UserRole.employer:
        return const EmployerDashboard();
      case UserRole.admin:
        return const AdminDashboard();
      case null:
        // TODO: Handle this case better, maybe redirect to login or role selection
        return const Center(child: Text("Error: Role is null"));
    }
  }
}
