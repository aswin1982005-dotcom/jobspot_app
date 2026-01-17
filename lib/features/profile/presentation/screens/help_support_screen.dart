import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Frequently Asked Questions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildFAQItem(
              'How do I apply for a job?',
              'Simply find a job you like, tap on it to view details, and click the "Apply Now" button. You can track your application status in the "My Applications" section.',
            ),
            _buildFAQItem(
              'Can I update my profile?',
              'Yes, go to the Profile tab and click the "Edit Profile" button to update your skills, education, and other details.',
            ),
            _buildFAQItem(
              'How do I contact an employer?',
              'Currently, you can only contact employers if they initiate a conversation after reviewed your application.',
            ),
            _buildFAQItem(
              'Is my data safe?',
              'We take your privacy seriously. Your data is encrypted and only shared with employers you apply to.',
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contact Support initiating...'),
                    ),
                  );
                },
                icon: const Icon(Icons.headset_mic),
                label: const Text('Contact Support'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [Text(answer, style: const TextStyle(height: 1.5))],
      ),
    );
  }
}
