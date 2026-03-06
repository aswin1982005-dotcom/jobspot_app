import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
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
              '1. Acceptance of Terms',
              'By accessing or using JobSpot, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the application.',
            ),
            _buildSection(
              context,
              '2. Use of the App',
              'You agree to use JobSpot only for lawful purposes and in a way that does not infringe on the rights of others. You must not use the app to post false, misleading, or fraudulent job listings or applications.',
            ),
            _buildSection(
              context,
              '3. Account Responsibility',
              'You are responsible for maintaining the confidentiality of your account credentials. You agree to notify us immediately of any unauthorized use of your account. We are not liable for any loss or damage arising from your failure to protect your account information.',
            ),
            _buildSection(
              context,
              '4. Job Listings and Applications',
              'Employers are responsible for the accuracy of job postings. Job seekers are responsible for the accuracy of their application information. JobSpot does not guarantee employment or the quality of job listings.',
            ),
            _buildSection(
              context,
              '5. Content',
              'Users retain ownership of content they submit. By posting content, you grant JobSpot a non-exclusive, royalty-free license to use, display, and distribute your content in connection with the service.',
            ),
            _buildSection(
              context,
              '6. Termination',
              'We reserve the right to suspend or terminate your account at any time for violation of these terms or for any other reason at our sole discretion.',
            ),
            _buildSection(
              context,
              '7. Limitation of Liability',
              'JobSpot is provided "as is" without warranties of any kind. We shall not be liable for any indirect, incidental, or consequential damages arising from your use of the service.',
            ),
            _buildSection(
              context,
              '8. Changes to Terms',
              'We may update these terms from time to time. Continued use of the app after changes constitutes acceptance of the new terms.',
            ),
            _buildSection(
              context,
              '9. Contact',
              'If you have any questions about these Terms of Service, please contact us at support@jobspot.app.',
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
