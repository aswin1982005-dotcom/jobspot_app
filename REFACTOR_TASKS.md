# Project Refactoring Tasks

This file tracks important refactoring tasks, tech debt, and improvements identified during code reviews.

## `lib/core` Folder

- [ ] **`utils/profile_completion_manager.dart`**: Replace `Future.delayed` anti-pattern with `WidgetsBinding.instance.addPostFrameCallback`.
- [ ] **`utils/supabase_service.dart`**: Extract hardcoded redirect URLs (e.g., `'io.supabase.flutterquickstart://login-callback/'`) to environment variables or config.
- [ ] **`sync/sync_service.dart`**: Decouple offline sync logic from direct Supabase database calls (`supabase.from('job_applications').insert(...)`) by using a repository pattern.
- [ ] **`utils/global_refresh_manager.dart`**: Improve provider refresh logic; currently relies on generic try-catch blocks which may fail silently or unexpectedly. Consider an event bus.
- [ ] **`network/connectivity_service.dart`**: Integrate `internet_connection_checker_plus` for actual internet reachability checks, not just network interface checks.
- [ ] **`theme/map_styles.dart`**: Consider moving the large raw JSON string to an asset file in `assets/` to declutter Dart code.

## `lib/data` Folder

- [ ] **`services/job_service.dart` & `services/profile_service.dart`**: Extract `SharedPreferences` caching logic to a dedicated local storage repository or interceptor layer.
- [ ] **`services/review_service.dart`**: Replace N+1 manual fetch queries with a single nested query `.select('..., reviewer:job_seeker_profiles(...)')` or an RPC for joining data server-side.
- [ ] **`services/application_service.dart`**: Avoid client-side joins for `fetchJobApplications` by eagerly loading the applicant relation.
- [ ] **`services/auth_service.dart`**: Consolidate hardcoded redirect URLs into a central configuration.
