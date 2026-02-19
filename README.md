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
- **Dashboard Overview**: View key metrics (Total Users, Active Jobs, Reports).
- **User Management**: Disable/Enable users, view user details.
- **Job Management**: Monitor and moderate job postings.
- **Content Moderation**: Review and resolve user/job reports.

### General
- **Notifications**: Real-time updates for job applications and status changes.

---

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **Backend & Auth**: [Supabase](https://supabase.com/) (PostgreSQL)
- **Maps**: [Google Maps Flutter](https://pub.dev/packages/google_maps_flutter)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Notifications**: [OneSignal](https://onesignal.com/)

---

## 🗄️ Database Schema

The app uses Supabase (PostgreSQL) with the following relational structure:

### `user_profiles`
| Column | Type | Description |
| :--- | :--- | :--- |
| `user_id` | uuid | Primary Key |
| `role` | text | 'seeker', 'employer', 'admin' |
| `profile_completed` | boolean | Status flag |

### `job_seeker_profiles`
| Column | Type | Description |
| :--- | :--- | :--- |
| `user_id` | uuid | PK, FK -> auth.users |
| `full_name` | text | - |
| `avatar_url` | text | Profile picture URL |
| `skills` | text[] | Array of skills |
| `education_level` | text | - |
| `resume_url` | text | URL to PDF resume |

### `employer_profiles`
| Column | Type | Description |
| :--- | :--- | :--- |
| `user_id` | uuid | PK, FK -> auth.users |
| `company_name` | text | - |
| `avatar_url` | text | Company logo URL |
| `industry` | text | - |
| `website` | text | - |

### `job_posts`
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | uuid | Primary Key |
| `employer_id` | uuid | FK -> auth.users |
| `title` | text | Job Title |
| `pay_amount_min` | int | Minimum Salary |
| `pay_amount_max` | int | Maximum Salary |
| `is_active` | boolean | Open/Closed status |

### `job_applications`
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | uuid | Primary Key |
| `job_post_id` | uuid | FK -> job_posts.id |
| `applicant_id` | uuid | FK -> auth.users |
| `status` | text | 'pending', 'shortlisted', 'hired' |

### `reviews`
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | uuid | Primary Key |
| `reviewer_id` | uuid | FK -> auth.users |
| `reviewee_id` | uuid | FK -> auth.users |
| `rating` | int | 1-5 Stars |
| `comment` | text | Review text |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.10.0)
- Dart SDK
- Android Studio / Xcode
- A Supabase project
- A Google Maps API Key

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
    ```
    *Note: Ensure you enable Maps SDK for Android/iOS in Google Cloud Console.*

4.  **Run the app**:
    ```bash
    flutter run
    ```

---

## 📂 Project Structure

```
lib/
├── core/                   # Global utilities, themes, and constants
│   ├── theme/
│   └── utils/
├── data/                   # Data layer (Services, Models)
│   ├── services/           # Supabase calls (Auth, Job, Profile)
│   └── models/             # Data models
├── features/               # Feature-based organization
│   ├── auth/               # Login, Signup, Onboarding
│   ├── dashboard/          # Main Shell, Home Tabs, Map Tab
│   ├── jobs/               # Job Listing, Creation, Details
│   ├── applications/       # Application management
│   └── profile/            # User Profile, Settings
└── main.dart               # App Entry point
```

---

## 🛡️ Safety & Compliance

JobSpot is designed to meet App Store and Play Store requirements:
- **Account Deletion**: Users can delete their data via Settings.
- **Reporting**: Tools to report abusive jobs or employers.
- **Privacy**: Transparent data usage policies.

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
