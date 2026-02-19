# Project TODOs

## Features to Implement

### Notifications
- [ ] **Navigation Logic**: Implement intelligent navigation when clicking a notification (e.g., go to specific Job Details or Application Status).
  - *Reference*: `lib/features/notifications/presentation/screens/notifications_screen.dart` (`_handleNavigation`)

### Admin Dashboard
- [ ] **User Profile View**: Create a detailed view for inspecting user profiles (seekers/employers) from the admin list.
  - *Reference*: `lib/features/dashboard/presentation/tabs/admin/user_management_tab.dart`
- [ ] **Messaging System**: Implement direct messaging between Admins and Users.
  - *Reference*: `lib/features/dashboard/presentation/tabs/admin/user_management_tab.dart`
- [ ] **Activity Log UI**: detailed view for Admin Activity Logs.
  - *Reference*: `lib/features/dashboard/presentation/tabs/admin/user_management_tab.dart`

### General
- [ ] **Error Handling**: Improve global error handling for Supabase calls.
- [ ] **Offline Mode**: Add caching for offline access to critical data (jobs, profile).

## Technical Debt
- [ ] **Hardcoded Strings**: Extract UI strings to a localization file (l10n).
- [ ] **State Management**: Review `UserManagementProvider` for optimization (currently refreshes full list on actions).
