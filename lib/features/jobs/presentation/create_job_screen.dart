import 'package:flutter/material.dart';
import 'package:jobspot_app/data/services/job_service.dart';
import 'package:jobspot_app/core/utils/supabase_service.dart';
import 'package:jobspot_app/core/models/location_address.dart';
import 'package:jobspot_app/features/jobs/presentation/address_search_page.dart';
import 'package:jobspot_app/features/jobs/presentation/map_picker_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CreateJobScreen extends StatefulWidget {
  final Map<String, dynamic>? job;

  const CreateJobScreen({super.key, this.job});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _jobService = JobService();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _minPayController;
  late final TextEditingController _maxPayController;
  late final TextEditingController _vacanciesController;
  late final TextEditingController _skillsController;
  late final TextEditingController _minAgeController;
  late final TextEditingController _maxAgeController;

  late String _workMode;
  late String _payType;
  late String _genderPreference;
  late List<String> _selectedDays;
  late TimeOfDay _shiftStart;
  late TimeOfDay _shiftEnd;
  late bool _sameDayPay;
  bool _isLoading = false;

  LocationAddress? _selectedAddress;

  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    final job = widget.job;

    _titleController = TextEditingController(text: job?['title']);
    _descriptionController = TextEditingController(text: job?['description']);
    _locationController = TextEditingController(text: job?['location']);
    _minPayController = TextEditingController(
      text: job?['pay_amount_min']?.toString(),
    );
    _maxPayController = TextEditingController(
      text: job?['pay_amount_max']?.toString(),
    );
    _vacanciesController = TextEditingController(
      text: (job?['vacancies'] ?? '1').toString(),
    );
    _skillsController = TextEditingController(
      text: (job?['skills'] as List?)?.join(', '),
    );
    _minAgeController = TextEditingController(
      text: job?['age_min']?.toString(),
    );
    _maxAgeController = TextEditingController(
      text: job?['age_max']?.toString(),
    );

    _workMode = job?['work_mode'] ?? 'onsite';
    _payType = job?['pay_type'] ?? 'monthly';
    _genderPreference = job?['gender_preference'] ?? 'any';
    _selectedDays = List<String>.from(job?['working_days'] ?? []);
    _sameDayPay = job?['same_day_pay'] ?? false;

    if (job?['latitude'] != null && job?['longitude'] != null) {
      _selectedAddress = LocationAddress(
        addressLine: job?['location'] ?? '',
        latitude: job?['latitude'],
        longitude: job?['longitude'],
        city: '',
        state: '',
        country: '',
        postalCode: '',
      );
    }

    _shiftStart =
        _parseTimeOfDay(job?['shift_start']) ??
        const TimeOfDay(hour: 9, minute: 0);
    _shiftEnd =
        _parseTimeOfDay(job?['shift_end']) ??
        const TimeOfDay(hour: 17, minute: 0);
  }

  TimeOfDay? _parseTimeOfDay(String? timeStr) {
    if (timeStr == null) return null;
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _titleController,
      _descriptionController,
      _locationController,
      _minPayController,
      _maxPayController,
      _vacanciesController,
      _skillsController,
      _minAgeController,
      _maxAgeController,
    ]) {
      controller.dispose();
    }
    super.dispose();
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
        : const LatLng(19.0760, 72.8777);

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
      _locationController.text = result.addressLine.isNotEmpty
          ? '${result.addressLine}, ${result.city}'
          : result.city;
    });
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _shiftStart : _shiftEnd,
    );
    if (picked != null) {
      setState(() => isStart ? _shiftStart = picked : _shiftEnd = picked);
    }
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    return '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}:00';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDays.isEmpty) {
      _showError('Please select at least one working day');
      return;
    }
    if (_workMode != 'remote' && _selectedAddress == null) {
      _showError('Please pick a location on the map or search');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userId = SupabaseService.getCurrentUser()?.id;
      if (userId == null) throw Exception('User not authenticated');

      final jobData = {
        'employer_id': userId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'work_mode': _workMode,
        'location': _locationController.text.trim(),
        'latitude': _selectedAddress?.latitude,
        'longitude': _selectedAddress?.longitude,
        'pay_type': _payType,
        'pay_amount_min': int.parse(_minPayController.text),
        'pay_amount_max': _maxPayController.text.isNotEmpty
            ? int.parse(_maxPayController.text)
            : null,
        'working_days': _selectedDays,
        'shift_start': _formatTimeOfDay(_shiftStart),
        'shift_end': _formatTimeOfDay(_shiftEnd),
        'vacancies': int.parse(_vacanciesController.text),
        'gender_preference': _genderPreference,
        'skills': _skillsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        'age_min': _minAgeController.text.isNotEmpty
            ? int.parse(_minAgeController.text)
            : null,
        'age_max': _maxAgeController.text.isNotEmpty
            ? int.parse(_maxAgeController.text)
            : null,
        'same_day_pay': _sameDayPay,
      };

      final Map<String, dynamic> result;
      if (widget.job != null) {
        result = await _jobService.updateJobPost(widget.job!['id'], jobData);
      } else {
        result = await _jobService.createJobPost(jobData);
      }

      if (mounted) {
        Navigator.pop(context, result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.job != null ? 'Job updated!' : 'Job posted!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.job != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Job' : 'Post New Job')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionCard(
                      title: 'Basic Details',
                      icon: Icons.article_outlined,
                      children: [
                        _buildTextField(
                          controller: _titleController,
                          label: 'Job Title*',
                          icon: Icons.work_outline,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _descriptionController,
                          label: 'Job Description*',
                          icon: Icons.description_outlined,
                          maxLines: 4,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                    _buildSectionCard(
                      title: 'Work Location & Mode',
                      icon: Icons.location_on_outlined,
                      children: [
                        _buildDropdown(
                          value: _workMode,
                          label: 'Work Mode',
                          icon: Icons.laptop_chromebook,
                          items: ['onsite', 'remote', 'hybrid'],
                          onChanged: (v) => setState(() => _workMode = v!),
                        ),
                        if (_workMode != 'remote') ...[
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: _pickLocationFromSearch,
                            child: IgnorePointer(
                              child: _buildTextField(
                                controller: _locationController,
                                label: 'Search Address',
                                icon: Icons.search,
                                validator: (v) =>
                                    (_workMode != 'remote' && v!.isEmpty)
                                    ? 'Required'
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _pickLocationFromMap,
                            icon: const Icon(Icons.map),
                            label: const Text('Pick on Map'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                    _buildSectionCard(
                      title: 'Pay & Vacancies',
                      icon: Icons.payments_outlined,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildDropdown(
                                value: _payType,
                                label: 'Pay Type',
                                icon: Icons.calendar_month,
                                items: [
                                  'hourly',
                                  'daily',
                                  'weekly',
                                  'monthly',
                                  'task_based',
                                ],
                                onChanged: (v) => setState(() => _payType = v!),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: _buildTextField(
                                controller: _vacanciesController,
                                label: 'Openings',
                                icon: Icons.people_alt_outlined,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _minPayController,
                                label: 'Min (₹)*',
                                icon: Icons.currency_rupee,
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    v!.isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: _maxPayController,
                                label: 'Max (₹)',
                                icon: Icons.currency_rupee,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        SwitchListTile(
                          title: const Text('Same Day Payout?'),
                          value: _sameDayPay,
                          onChanged: (v) => setState(() => _sameDayPay = v),
                        ),
                      ],
                    ),
                    _buildSectionCard(
                      title: 'Schedule & Shifts',
                      icon: Icons.access_time,
                      children: [
                        const Text(
                          'Working Days',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: _daysOfWeek.map((day) {
                            final isSelected = _selectedDays.contains(day);
                            return FilterChip(
                              label: Text(day.substring(0, 3)),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(
                                  () => selected
                                      ? _selectedDays.add(day)
                                      : _selectedDays.remove(day),
                                );
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTimePickerField(
                                'Start Time',
                                _shiftStart,
                                true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTimePickerField(
                                'End Time',
                                _shiftEnd,
                                false,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    _buildSectionCard(
                      title: 'Requirements',
                      icon: Icons.rule,
                      children: [
                        _buildTextField(
                          controller: _skillsController,
                          label: 'Skills Required (comma separated)',
                          icon: Icons.stars_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildDropdown(
                          value: _genderPreference,
                          label: 'Gender Preference',
                          icon: Icons.person_outline,
                          items: ['any', 'male', 'female'],
                          onChanged: (v) =>
                              setState(() => _genderPreference = v!),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _minAgeController,
                                label: 'Min Age',
                                icon: Icons.remove_circle_outline,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: _maxAgeController,
                                label: 'Max Age',
                                icon: Icons.add_circle_outline,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        isEditing ? 'Update Job Posting' : 'Post Job Now',
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      items: items
          .map((m) => DropdownMenuItem(value: m, child: Text(m.toUpperCase())))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTimePickerField(String label, TimeOfDay time, bool isStart) {
    return InkWell(
      onTap: () => _selectTime(context, isStart),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.access_time),
        ),
        child: Text(time.format(context)),
      ),
    );
  }
}
