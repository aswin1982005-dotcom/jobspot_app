import 'package:flutter/material.dart';
import 'package:jobspot_app/core/theme/app_theme.dart';
import 'package:jobspot_app/data/services/profile_service.dart';
import 'package:jobspot_app/core/utils/supabase_service.dart';
import 'package:jobspot_app/features/profile/presentation/screens/profile_loading_screen.dart';
import 'package:jobspot_app/core/models/location_address.dart';
import 'package:jobspot_app/features/jobs/presentation/address_search_page.dart';
import 'package:jobspot_app/features/jobs/presentation/map_picker_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _skillsController;

  bool _isLoading = false;
  bool _useLoginEmail = false;

  final List<String> _educationLevels = [
    '10th',
    'Plus Two',
    'Diploma',
    'UG Degree',
    'PG Degree',
    'Other',
  ];

  String? _selectedEducation;

  final List<String> _jobTypes = [
    'Full-time',
    'Part-time',
    'Contract',
    'Freelance',
    'Internship',
  ];

  String? _selectedJobType;
  LocationAddress? _selectedAddress;

  final List<String> _commonSkills = [
    'Flutter',
    'Dart',
    'Java',
    'Kotlin',
    'Swift',
    'React',
    'Node.js',
    'Python',
    'Design',
    'Marketing',
    'Sales',
    'Management',
    'Communication',
  ];

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _nameController = TextEditingController(text: profile?['full_name'] ?? '');
    _cityController = TextEditingController(text: profile?['city'] ?? '');
    _phoneController = TextEditingController(
      text: profile?['phone'].toString() ?? '',
    );
    _emailController = TextEditingController(text: profile?['email'] ?? '');

    _checkIfUsingLoginEmail();

    _selectedEducation = profile?['education_level'];
    if (_selectedEducation != null &&
        !_educationLevels.contains(_selectedEducation)) {
      // Handle case where existing value isn't in list, or default to null
      if (_educationLevels.contains(_selectedEducation)) {
        // It's valid
      } else {
        _selectedEducation = null;
      }
    }

    _skillsController = TextEditingController(
      text: (profile?['skills'] as List?)?.join(', ') ?? '',
    );
    _selectedJobType = profile?['preferred_job_type'];
    if (!_jobTypes.contains(_selectedJobType)) {
      _selectedJobType = 'Part-time';
    }

    if (profile?['latitude'] != null && profile?['longitude'] != null) {
      _selectedAddress = LocationAddress(
        addressLine: profile?['address_line'] ?? '',
        city: profile?['city'] ?? '',
        state: '',
        country: '',
        postalCode: '',
        latitude: profile!['latitude'],
        longitude: profile['longitude'],
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  void _checkIfUsingLoginEmail() {
    final loginEmail = SupabaseService.getCurrentUser()?.email;
    if (loginEmail != null && _emailController.text == loginEmail) {
      _useLoginEmail = true;
    }
  }

  void _toggleLoginEmail(bool? value) {
    setState(() {
      _useLoginEmail = value ?? false;
      if (_useLoginEmail) {
        final loginEmail = SupabaseService.getCurrentUser()?.email;
        if (loginEmail != null) {
          _emailController.text = loginEmail;
        }
      }
    });
  }

  Future<void> _pickLocationFromSearch() async {
    final result = await Navigator.push<LocationAddress>(
      context,
      MaterialPageRoute(builder: (context) => const AddressSearchPage()),
    );
    if (result != null) _updateAddress(result);
  }

  Future<void> _pickLocationFromMap() async {
    final initialPos = _selectedAddress != null
        ? LatLng(_selectedAddress!.latitude, _selectedAddress!.longitude)
        : const LatLng(19.0760, 72.8777); // Default to Mumbai

    final result = await Navigator.push<LocationAddress>(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerPage(initialPosition: initialPos),
      ),
    );
    if (result != null) _updateAddress(result);
  }

  void _updateAddress(LocationAddress result) {
    setState(() {
      _selectedAddress = result;
      // If we have a detected city, use it; otherwise let user type it or leave it empty?
      // Previously fell back to addressLine, but that might be a full address string.
      _cityController.text = result.city;
    });
  }

  void _addSkill(String? skill) {
    if (skill == null) return;
    final currentSkills = _skillsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (!currentSkills.contains(skill)) {
      currentSkills.add(skill);
      _skillsController.text = currentSkills.join(', ');
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
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : SupabaseService.getCurrentUser()?.email,
        'education_level': _selectedEducation,
        'skills': skillsList,
        'preferred_job_type': _selectedJobType,
        'latitude': _selectedAddress?.latitude,
        'longitude': _selectedAddress?.longitude,
        'address_line': _selectedAddress?.addressLine,
      };

      await ProfileService.updateSeekerProfile(
        userId,
        updateData,
        complete: true,
      );

      if (mounted) {
        if (widget.profile == null) {
          // New Profile Creation Flow
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfileLoadingScreen(role: 'seeker'),
            ),
          );
        } else {
          // Edit Profile Flow
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
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
              InkWell(
                onTap: _pickLocationFromSearch,
                child: IgnorePointer(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'Preferred Job Location',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickLocationFromMap,
                icon: const Icon(Icons.map),
                label: const Text('Pick on Map'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) => v?.isNotEmpty == true && v!.length < 10
                    ? 'Enter valid phone'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                readOnly: _useLoginEmail,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) => v?.isNotEmpty == true && !v!.contains('@')
                    ? 'Enter valid email'
                    : null,
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
                activeColor: theme.colorScheme.primary,
              ),
              const SizedBox(height: 32),
              Text('Professional Details', style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedEducation,
                decoration: const InputDecoration(
                  labelText: 'Education Level',
                  prefixIcon: Icon(Icons.school_outlined),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _educationLevels.map((level) {
                  return DropdownMenuItem(value: level, child: Text(level));
                }).toList(),
                onChanged: _isLoading
                    ? null
                    : (value) => setState(() => _selectedEducation = value),
                validator: (value) => value == null ? 'Required' : null,
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
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Add Common Skill',
                  prefixIcon: Icon(Icons.add_circle_outline),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _commonSkills
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: _addSkill,
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
