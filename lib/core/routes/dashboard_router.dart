import 'package:flutter/material.dart';
import 'package:jobspot_app/core/constants/user_role.dart';
import 'package:jobspot_app/features/employer_dashboard/presentation/employer_dashboard_screen.dart';
import 'package:jobspot_app/features/admin_dashboard/presentation/admin_dashboard_screen.dart';

import '../../features/seeker_dashboard/presentation/seeker_dashboard_screen.dart';

class DashboardRouter extends StatelessWidget {
  final UserRole? role;

  const DashboardRouter({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    switch (role) {
      case UserRole.seeker:
        return const SeekerDashboardScreen();
      case UserRole.employer:
        return const EmployerDashboardScreen();
      case UserRole.admin:
        return const AdminDashboardScreen();
      case null:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }
}
