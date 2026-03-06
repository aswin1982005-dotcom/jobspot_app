import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Last updated: March 2025',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              context,
              '1. Information We Collect',
              'We collect information you provide directly, such as your name, email address, work experience, skills, and profile photo. We also collect information about your use of the app, including job searches and applications submitted.',
            ),
            _buildSection(
              context,
              '2. How We Use Your Information',
              'We use your information to:\n• Provide and improve our services\n• Match job seekers with relevant job postings\n• Send notifications about your applications\n• Communicate updates and important information about the service',
            ),
            _buildSection(
              context,
              '3. Information Sharing',
              'We do not sell your personal information. We share your profile information only with employers when you apply to their job postings. We may share anonymized, aggregated data for analytical purposes.',
            ),
            _buildSection(
              context,
              '4. Data Security',
              'We take reasonable measures to protect your personal information from unauthorized access, disclosure, or misuse. However, no internet transmission is completely secure, and we cannot guarantee absolute security.',
            ),
            _buildSection(
              context,
              '5. Data Retention',
              'We retain your personal information as long as your account is active or as needed to provide services. You may request deletion of your account and associated data at any time through the app settings.',
            ),
            _buildSection(
              context,
              '6. Your Rights',
              'You have the right to access, correct, or delete your personal information. You can update your profile at any time or contact us to request account deletion.',
            ),
            _buildSection(
              context,
              '7. Cookies and Analytics',
              'We use analytics tools to understand how users interact with our app. This helps us improve features and performance. You can opt out of analytics in the app settings.',
            ),
            _buildSection(
              context,
              '8. Children\'s Privacy',
              'JobSpot is not directed to individuals under 18. We do not knowingly collect personal information from minors.',
            ),
            _buildSection(
              context,
              '9. Changes to This Policy',
              'We may update this Privacy Policy periodically. We will notify you of significant changes through the app or via email.',
            ),
            _buildSection(
              context,
              '10. Contact Us',
              'If you have any questions or concerns about this Privacy Policy, please contact us at privacy@jobspot.app.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String body) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(body, style: theme.textTheme.bodyMedium?.copyWith(height: 1.6)),
        ],
      ),
    );
  }
}
