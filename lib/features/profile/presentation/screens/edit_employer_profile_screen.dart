import 'package:flutter/material.dart';
import 'package:jobspot_app/core/theme/app_theme.dart';
import 'package:jobspot_app/data/services/profile_service.dart';
import 'package:jobspot_app/features/profile/presentation/screens/profile_loading_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditEmployerProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? profile;

  const EditEmployerProfileScreen({super.key, this.profile});

  @override
  State<EditEmployerProfileScreen> createState() =>
      _EditEmployerProfileScreenState();
}

class _EditEmployerProfileScreenState extends State<EditEmployerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _companyNameController;
  late TextEditingController _industryController;
  late TextEditingController _cityController;
  late TextEditingController _addressController;
  late TextEditingController _websiteController;
  late TextEditingController _contactEmailController;
  late TextEditingController _contactMobileController;
  late TextEditingController _descriptionController;

  bool _useLoginEmail = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile ?? {};
    _companyNameController = TextEditingController(
      text: profile['company_name'] ?? '',
    );
    _industryController = TextEditingController(
      text: profile['industry'] ?? '',
    );
    _cityController = TextEditingController(text: profile['city'] ?? '');
    _addressController = TextEditingController(text: profile['address'] ?? '');
    _websiteController = TextEditingController(text: profile['website'] ?? '');
    _contactEmailController = TextEditingController(
      text: profile['official_email'] ?? '',
    );
    _contactMobileController = TextEditingController(
      text: profile['contact_mobile'] ?? '',
    );
    _descriptionController = TextEditingController(
      text: profile['company_description'] ?? '',
    );
    _checkIfUsingLoginEmail();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _industryController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _contactEmailController.dispose();
    _contactMobileController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _checkIfUsingLoginEmail() {
    final loginEmail = Supabase.instance.client.auth.currentUser?.email;
    if (loginEmail != null && _contactEmailController.text == loginEmail) {
      _useLoginEmail = true;
    }
  }

  void _toggleLoginEmail(bool? value) {
    setState(() {
      _useLoginEmail = value ?? false;
      if (_useLoginEmail) {
        final loginEmail = Supabase.instance.client.auth.currentUser?.email;
        if (loginEmail != null) {
          _contactEmailController.text = loginEmail;
        }
      }
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final updates = {
        'company_name': _companyNameController.text.trim(),
        'industry': _industryController.text.trim(),
        'city': _cityController.text.trim(),
        'address': _addressController.text.trim(),
        'website': _websiteController.text.trim(),
        'official_email': _contactEmailController.text.trim(),
        'contact_mobile': _contactMobileController.text.trim(),
        'company_description': _descriptionController.text.trim(),
      };

      // Check for completion (Basic info)
      if (_companyNameController.text.trim().isNotEmpty &&
          _cityController.text.trim().isNotEmpty) {
        updates['profile_completed'] = 'True';
      }

      await ProfileService.updateEmployerProfile(userId, updates);

      if (mounted) {
        if (widget.profile == null) {
          // New Profile Creation Flow
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const ProfileLoadingScreen(role: 'employer'),
            ),
          );
        } else {
          // Edit Profile Flow
          Navigator.pop(context, true); // Return true to indicate success
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.purple, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Company Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.purple,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Basic Info
            Text(
              'Company Details',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _companyNameController,
              decoration: _buildInputDecoration('Company Name', Icons.business),
              validator: (value) => value?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _industryController,
              decoration: _buildInputDecoration('Industry', Icons.category),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: _buildInputDecoration(
                'Description',
                Icons.description,
              ).copyWith(alignLabelWithHint: true),
            ),

            const SizedBox(height: 24),

            // Contact Info
            Text(
              'Contact Information',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactEmailController,
              keyboardType: TextInputType.emailAddress,
              readOnly: _useLoginEmail,
              decoration: _buildInputDecoration('Official Email', Icons.email),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Use Login Email',
                style: TextStyle(fontSize: 14),
              ),
              value: _useLoginEmail,
              onChanged: _toggleLoginEmail,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactMobileController,
              keyboardType: TextInputType.phone,
              decoration: _buildInputDecoration('Mobile Number', Icons.phone),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _websiteController,
              keyboardType: TextInputType.url,
              decoration: _buildInputDecoration('Website', Icons.language),
            ),

            const SizedBox(height: 24),

            // Location
            Text(
              'Location',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cityController,
              decoration: _buildInputDecoration('City', Icons.location_city),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              decoration: _buildInputDecoration(
                'Full Address',
                Icons.location_on,
              ).copyWith(alignLabelWithHint: true),
            ),
          ],
        ),
      ),
    );
  }
}
