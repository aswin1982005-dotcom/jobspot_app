# JobSpot 🚀

**Hyperlocal Part-Time Job Finder**

JobSpot is a Flutter-based mobile application designed to bridge the gap between part-time job seekers and local employers. It focuses on speed, trust, and simplicity, enabling daily wage workers and students to find jobs nearby and connect with employers instantly.

---

## 📱 Features (v1.0)

### For Job Seekers
- **Fast Apply**: Apply to jobs with a single tap using your profile.
- **Walk-In Mode**: View job locations on a map and call employers directly for immediate hiring.
- **Smart Discovery**: Find jobs based on distance, shift timing, and pay.
- **Trust & Safety**: View verified employer badges and report suspicious listings.
- **Profile Management**: Simple profile with key skills and preferences (no complex resumes).
- **Review System**: Rate and review companies you've worked for.

### For Employers
- **Quick Posting**: Post a job in under 3 minutes.
- **Applicant Management**: View, shortlist, and contact applicants easily.
- **Hyperlocal Reach**: Target candidates in your specific neighborhood.
- **Seeker Ratings**: Rate employees to build a trusted community.

### For Admins
- **Dashboard Overview**: View key metrics (Total Users, Active Jobs, Reports) at a glance.
- **User Management**:
  - View full, read-only profiles of Seekers and Employers.
  - Disable/Enable users to moderate access.
- **Job Management**:
  - Monitor job postings with deep links to full Job Details.
  - View and manage reports specific to each job.
  - Disable/Enable jobs directly from the list.
- **Support & Content Moderation**:
  - Centralized view of all user and job reports.
  - **Deep Linking**: Navigate directly from a report to the full context (Job Details or User Profile) for investigation.
  - **Status Workflow**: Track resolution progress (Pending, In Progress, Resolved, Dismissed) with admin notes.

### General
- **Notifications**: Real-time updates for job applications and status changes.
- **Offline & Sync**: Robust data fetching with global refresh capabilities to ensure state consistency across tabs.

---

## 🏗️ Architecture & How It Works

JobSpot follows a modular, feature-first architecture, loosely based on the **MVVM (Model-View-ViewModel)** pattern. The project is structured to encourage separation of concerns:

- **Frontend Framework**: The app is built with **Flutter**, providing a native-like experience on both iOS and Android from a single codebase.
- **State Management**: **`Provider`** is heavily utilized for state management across the application. Each major feature has a dedicated provider (e.g., `ProfileProvider`, `SeekerHomeProvider`, `NotificationProvider`) that handles business logic, connects to data services, and updates the UI asynchronously.
- **Global Refresh Mechanism**: A centralized `GlobalRefreshManager` handles holistic app state updates across disjoint tabs, preventing stale data.
- **Directory Structure Breakdown**:
  - `core/`: Contains application-wide configurations, constants, routing logic (`DashboardRouter`), themes (`AppTheme`), and utility functions.
  - `data/`: Contains strongly-typed Dart **Models** and **Services**. Services abstract all direct communication with the backend.
  - `features/`: The core application logic. It is split by domain (e.g., `auth`, `dashboard`, `jobs`, `applications`, `profile`, `reviews`, `notifications`). Each feature folder encapsulates its own `presentation/` (screens, tabs, reusable widgets) and `providers/`.

---

## ⚙️ Backend Logic & Infrastructure

JobSpot leverages **Supabase** as its backend-as-a-service (BaaS), providing a robust, scalable, and secure backend infrastructure:

- **Authentication**: Supabase Auth handles secure user registration, login, and session management. Custom metadata is utilized to distinguish user roles (`seeker`, `employer`, `admin`).
- **PostgreSQL Database**: A relational database serves as the single source of truth. 
  - **Row Level Security (RLS)** is strictly enforced to ensure users can only access and modify their own data, or public data as defined by the application's rules.
  - **Custom SQL Functions & Triggers**: Advanced database logic is handled directly in PostgreSQL. Functions calculate admin dashboard statistics, aggregate review scores, and manage complex relational joins (e.g., user reports deep linking).
- **Realtime Updates & Polling**: Supabase Realtime streams are utilized to push instantaneous updates to the app (e.g., new in-app notifications). The app also employs resilient fallback polling mechanisms to maintain data integrity if streams disconnect.
- **Storage**: Supabase Storage securely houses user avatars and file uploads.
- **Push Notifications (OneSignal)**: Integrated with OneSignal to deliver external push notifications. When a notification is tapped, the app captures the intent and refreshes the internal state to reflect the latest changes.

---

## 🗄️ Database Schema

The app uses Supabase (PostgreSQL) with the following relational structure:

### `user_profiles`
| Column | Type | Description |
| :--- | :--- | :--- |
| `user_id` | uuid | Primary Key |
| `role` | text | 'seeker', 'employer', 'admin' |
| `profile_completed` | boolean | Status flag |
| `is_disabled` | boolean | Admin moderation flag |

### `job_seeker_profiles` & `employer_profiles`
Store specific details such as full name, company name, industry, skills array, avatar URLs, and location coordinates (latitude/longitude) for mapping features.

### `job_posts`
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | uuid | Primary Key |
| `employer_id` | uuid | FK -> auth.users |
| `title` | text | Job Title |
| `is_active` | boolean | Open/Closed status |
*(Plus compensation, location, description, and requirements)*

### `job_applications`, `reviews`, `reports`
Relational tables linking users to jobs or other users, tracking statuses, ratings, and moderation flags.

---

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **Backend & Auth**: [Supabase](https://supabase.com/) (PostgreSQL)
- **Maps**: [Google Maps Flutter](https://pub.dev/packages/google_maps_flutter)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Notifications**: [OneSignal](https://onesignal.com/)

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.10.0)
- Dart SDK
- Android Studio / Xcode
- A Supabase project
- A Google Maps API Key
- OneSignal App ID

### Installation

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/yourusername/jobspot.git
    cd jobspot_app
    ```

2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Environment Setup**:
    Create a `.env` file in the root directory and add your keys:
    ```env
    SUPABASE_URL=your_supabase_url
    SUPABASE_ANON_KEY=your_supabase_anon_key
    GOOGLE_MAPS_API_KEY=your_google_maps_key
    ONESIGNAL_APP_ID=your_onesignal_app_id
    ```
    *Note: Ensure you enable Maps SDK for Android/iOS in Google Cloud Console.*

4.  **Run the app**:
    ```bash
    flutter run
    ```

---

## 🛡️ Safety & Compliance

JobSpot is designed to meet App Store and Play Store requirements:
- **Account Deletion**: Users can delete their data via Settings.
- **Reporting**: Tools to report abusive jobs or employers.
- **Privacy**: Transparent data usage policies.
- **Admin Moderation**: Admins can suspend users and take down jobs seamlessly.

---

## 🤝 Contributing

Contributions are welcome! Please fork the repository and submit a Pull Request.

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

**Built with ❤️ for the community.**
