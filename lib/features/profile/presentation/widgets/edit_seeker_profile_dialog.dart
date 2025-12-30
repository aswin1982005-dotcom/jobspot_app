import 'package:flutter/material.dart';
import 'package:jobspot_app/data/services/profile_service.dart';
import 'package:jobspot_app/core/utils/supabase_service.dart';

class EditSeekerProfileDialog extends StatefulWidget {
  final Map<String, dynamic>? profile;

  const EditSeekerProfileDialog({super.key, required this.profile});

  @override
  State<EditSeekerProfileDialog> createState() => _EditSeekerProfileDialogState();
}

class _EditSeekerProfileDialogState extends State<EditSeekerProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _cityController;
  late final TextEditingController _educationController;
  late final TextEditingController _skillsController;

  bool _isLoading = false;

  final List<String> _jobTypes = [
    'Full-time',
    'Part-time',
    'Contract',
    'Freelance',
    'Internship',
  ];

  String? _selectedJobType;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _nameController = TextEditingController(text: profile?['full_name'] ?? '');
    _cityController = TextEditingController(text: profile?['city'] ?? '');
    _educationController = TextEditingController(text: profile?['education_level'] ?? '');
    _skillsController = TextEditingController(
      text: (profile?['skills'] as List?)?.join(', ') ?? '',
    );
    _selectedJobType = profile?['preferred_job_type'];
    if (!_jobTypes.contains(_selectedJobType)) {
      _selectedJobType = 'Part-time';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _educationController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = SupabaseService.getCurrentUser()?.id;
      if (userId == null) throw Exception('User not found');

      final skillsList = _skillsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final updateData = {
        'user_id': userId,
        'full_name': _nameController.text.trim(),
        'city': _cityController.text.trim(),
        'education_level': _educationController.text.trim(),
        'skills': skillsList,
        'preferred_job_type': _selectedJobType,
      };

      await ProfileService.updateSeekerProfile(userId, updateData);
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Edit Profile'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile Photo Placeholder
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      child: Icon(Icons.person, size: 40, color: theme.colorScheme.primary),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _educationController,
                decoration: const InputDecoration(
                  labelText: 'Education Level',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _skillsController,
                decoration: const InputDecoration(
                  labelText: 'Skills (comma separated)',
                  prefixIcon: Icon(Icons.bolt_outlined),
                  hintText: 'Flutter, Dart, UI Design',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedJobType,
                decoration: const InputDecoration(
                  labelText: 'Preferred Job Type',
                  prefixIcon: Icon(Icons.work_outline),
                ),
                items: _jobTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: _isLoading ? null : (value) => setState(() => _selectedJobType = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSave,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save Changes'),
        ),
      ],
    );
  }
}
