import 'package:flutter/material.dart';
import 'package:jobspot_app/data/services/profile_service.dart';
import 'package:jobspot_app/core/utils/supabase_service.dart';

class EditBusinessProfileDialog extends StatefulWidget {
  final Map<String, dynamic>? profile;

  const EditBusinessProfileDialog({super.key, required this.profile});

  @override
  State<EditBusinessProfileDialog> createState() =>
      _EditBusinessProfileDialogState();
}

class _EditBusinessProfileDialogState extends State<EditBusinessProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _contactController;
  late final TextEditingController _emailController;
  late final TextEditingController _cityController;
  late final TextEditingController _otherIndustryController;

  bool _isLoading = false;

  final List<String> _industries = [
    'Technology',
    'Hotel & Hospitality',
    'Service & Retail',
    'Delivery & Logistics',
    'Healthcare',
    'Education',
    'Construction',
    'Others',
  ];

  String? _selectedIndustry;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _nameController = TextEditingController(
      text: profile?['company_name'] ?? '',
    );
    _contactController = TextEditingController(
      text: profile?['contact_mobile'] ?? '',
    );
    _emailController = TextEditingController(
      text: profile?['official_email'] ?? '',
    );
    _cityController = TextEditingController(text: profile?['city'] ?? '');
    _otherIndustryController = TextEditingController();

    final industry = profile?['industry'];
    if (industry != null) {
      if (_industries.contains(industry)) {
        _selectedIndustry = industry;
      } else {
        _selectedIndustry = 'Others';
        _otherIndustryController.text = industry;
      }
    } else {
      _selectedIndustry = 'Technology';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _otherIndustryController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final finalIndustry = _selectedIndustry == 'Others'
          ? _otherIndustryController.text.trim()
          : _selectedIndustry;

      final profileId = SupabaseService.getCurrentUser()?.id;

      final updateData = {
        'user_id': profileId,
        'company_name': _nameController.text.trim(),
        'contact_mobile': _contactController.text.trim(),
        'official_email': _emailController.text.trim(),
        'city': _cityController.text.trim(),
        'industry': finalIndustry,
      };

      if (profileId != null) {
        await ProfileService.updateEmployerProfile(profileId, updateData);
        if (mounted) {
          Navigator.pop(context, true); // Pass true to indicate success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      } else {
        throw Exception('Profile ID not found');
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
      title: const Text('Edit Business Profile'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo Placeholder
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: theme.colorScheme.primary.withValues(
                        alpha: 0.1,
                      ),
                      child: Icon(
                        Icons.business,
                        size: 40,
                        color: theme.colorScheme.primary,
                      ),
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
                        child: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Company Name',
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(
                  labelText: 'Contact No',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Official Email',
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City/Location',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedIndustry,
                decoration: const InputDecoration(
                  labelText: 'Industry',
                  prefixIcon: Icon(Icons.category),
                ),
                items: _industries.map((String i) {
                  return DropdownMenuItem<String>(value: i, child: Text(i));
                }).toList(),
                onChanged: _isLoading
                    ? null
                    : (String? value) {
                        setState(() {
                          _selectedIndustry = value;
                        });
                      },
              ),
              if (_selectedIndustry == 'Others') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _otherIndustryController,
                  decoration: const InputDecoration(
                    labelText: 'Specify Industry',
                    hintText: 'e.g. Photography',
                    prefixIcon: Icon(Icons.edit_note),
                  ),
                  validator: (value) {
                    if (_selectedIndustry == 'Others' &&
                        (value == null || value.isEmpty)) {
                      return 'Please specify your industry';
                    }
                    return null;
                  },
                ),
              ],
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
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Changes'),
        ),
      ],
    );
  }
}
