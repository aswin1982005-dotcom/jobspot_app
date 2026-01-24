import 'dart:io';
import 'package:flutter/material.dart';
import 'package:jobspot_app/core/theme/app_theme.dart';
import 'package:jobspot_app/data/services/profile_service.dart';
import 'package:jobspot_app/core/utils/supabase_service.dart';
import 'package:file_picker/file_picker.dart';

class EditSeekerProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? profile;

  const EditSeekerProfileScreen({super.key, required this.profile});

  @override
  State<EditSeekerProfileScreen> createState() =>
      _EditSeekerProfileScreenState();
}

class _EditSeekerProfileScreenState extends State<EditSeekerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _cityController;
  late final TextEditingController _educationController;
  late final TextEditingController _skillsController;

  bool _isLoading = false;
  String? _resumeFileName;
  String? _uploadedResumeUrl;

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
    _educationController = TextEditingController(
      text: profile?['education_level'] ?? '',
    );
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

  Future<void> _pickResume() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _isLoading = true);

        final file = File(result.files.single.path!);
        final userId = SupabaseService.getCurrentUser()?.id;

        if (userId != null) {
          try {
            final url = await ProfileService.uploadResume(
              userId,
              file,
              result.files.single.extension ?? 'pdf',
            );

            setState(() {
              _resumeFileName = result.files.single.name;
              // We will save the URL when user clicks Save, store it in a temp variable
              // Or better, we can update the profile map or a separate variable
            });
            // We need a variable to store the uploaded URL to send it during save
            // Let's add that variable to the class state
            _uploadedResumeUrl = url;

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Resume uploaded successfully')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

      // Determine if profile is now complete
      // We consider it complete if name and city are provided (basic info)
      final name = _nameController.text.trim();
      final city = _cityController.text.trim();
      if (name.isNotEmpty && city.isNotEmpty && name != 'User') {
        updateData['profile_completed'] = true;
      }

      if (_uploadedResumeUrl != null) {
        updateData['resume_url'] = _uploadedResumeUrl;
      }

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleSave,
            child: const Text('Save', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: theme.colorScheme.primary.withValues(
                        alpha: 0.1,
                      ),
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text('Personal Information', style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City / Location',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text('Professional Details', style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              TextFormField(
                controller: _educationController,
                decoration: const InputDecoration(
                  labelText: 'Education Level',
                  prefixIcon: Icon(Icons.school_outlined),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _skillsController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Skills (comma separated)',
                  prefixIcon: Icon(Icons.bolt_outlined),
                  hintText: 'Flutter, Dart, UI Design...',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedJobType,
                decoration: const InputDecoration(
                  labelText: 'Preferred Job Type',
                  prefixIcon: Icon(Icons.work_outline),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _jobTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: _isLoading
                    ? null
                    : (value) => setState(() => _selectedJobType = value),
              ),
              const SizedBox(height: 32),
              Text('Resume', style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickResume,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.surface,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.upload_file,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _resumeFileName ?? 'Upload Resume (PDF/DOC)',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_resumeFileName == null)
                              Text(
                                'Tap to select file',
                                style: TextStyle(
                                  color: theme.hintColor,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.darkPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save Profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
