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
        city: '',
        state: '',
        country: '',
        postalCode: '',
        latitude: job?['latitude'],
        longitude: job?['longitude'],
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
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _minPayController.dispose();
    _maxPayController.dispose();
    _vacanciesController.dispose();
    _skillsController.dispose();
    _minAgeController.dispose();
    _maxAgeController.dispose();
    super.dispose();
  }

  Future<void> _pickLocationFromSearch() async {
    final result = await Navigator.push<LocationAddress>(
      context,
      MaterialPageRoute(builder: (context) => const AddressSearchPage()),
    );

    if (result != null) {
      setState(() {
        _selectedAddress = result;
        _locationController.text = result.addressLine.isNotEmpty 
            ? '${result.addressLine}, ${result.city}' 
            : result.city;
      });
    }
  }

  Future<void> _pickLocationFromMap() async {
    final initialPos = _selectedAddress != null 
        ? LatLng(_selectedAddress!.latitude, _selectedAddress!.longitude)
        : const LatLng(19.0760, 72.8777);

    final result = await Navigator.push<LocationAddress>(
      context,
      MaterialPageRoute(builder: (context) => MapPickerPage(initialPosition: initialPos)),
    );

    if (result != null) {
      setState(() {
        _selectedAddress = result;
        _locationController.text = result.addressLine.isNotEmpty 
            ? '${result.addressLine}, ${result.city}' 
            : result.city;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _shiftStart : _shiftEnd,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _shiftStart = picked;
        } else {
          _shiftEnd = picked;
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hour.toString().padLeft(2, '0');
    final minute = tod.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one working day')),
      );
      return;
    }

    if (_workMode != 'remote' && _selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a location on the map or search')),
      );
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

      if (widget.job != null) {
        await _jobService.updateJobPost(widget.job!['id'], jobData);
      } else {
        await _jobService.createJobPost(jobData);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.job != null ? 'Job updated!' : 'Job posted!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Job Title*',
                            prefixIcon: Icon(Icons.work_outline),
                          ),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Job Description*',
                            prefixIcon: Icon(Icons.description_outlined),
                          ),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                    _buildSectionCard(
                      title: 'Work Location & Mode',
                      icon: Icons.location_on_outlined,
                      children: [
                        DropdownButtonFormField<String>(
                          value: _workMode,
                          decoration: const InputDecoration(
                            labelText: 'Work Mode',
                            prefixIcon: Icon(Icons.laptop_chromebook),
                          ),
                          items: ['onsite', 'remote', 'hybrid']
                              .map(
                                (m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(m.toUpperCase()),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _workMode = v!),
                        ),
                        if (_workMode != 'remote') ...[
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: _pickLocationFromSearch,
                            child: IgnorePointer(
                              child: TextFormField(
                                controller: _locationController,
                                decoration: const InputDecoration(
                                  labelText: 'Search Address',
                                  prefixIcon: Icon(Icons.search),
                                ),
                                validator: (v) => (_workMode != 'remote' && v!.isEmpty) ? 'Required' : null,
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
                              child: DropdownButtonFormField<String>(
                                value: _payType,
                                decoration: const InputDecoration(
                                  labelText: 'Pay Type',
                                  prefixIcon: Icon(Icons.calendar_month),
                                ),
                                items:
                                    [
                                          'hourly',
                                          'daily',
                                          'weekly',
                                          'monthly',
                                          'task_based',
                                        ]
                                        .map(
                                          (t) => DropdownMenuItem(
                                            value: t,
                                            child: Text(t.toUpperCase()),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (v) => setState(() => _payType = v!),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: _vacanciesController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Openings',
                                  prefixIcon: Icon(Icons.people_alt_outlined),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _minPayController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Min (₹)*',
                                  prefixIcon: Icon(Icons.currency_rupee),
                                ),
                                validator: (v) =>
                                    v!.isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _maxPayController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Max (₹)',
                                  prefixIcon: Icon(Icons.currency_rupee),
                                ),
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
                                setState(() {
                                  if (selected) {
                                    _selectedDays.add(day);
                                  } else {
                                    _selectedDays.remove(day);
                                  }
                                });
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
                        TextFormField(
                          controller: _skillsController,
                          decoration: const InputDecoration(
                            labelText: 'Skills Required (comma separated)',
                            prefixIcon: Icon(Icons.stars_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _genderPreference,
                          decoration: const InputDecoration(
                            labelText: 'Gender Preference',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          items: ['any', 'male', 'female']
                              .map(
                                (g) => DropdownMenuItem(
                                  value: g,
                                  child: Text(g.toUpperCase()),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _genderPreference = v!),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _minAgeController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Min Age',
                                  prefixIcon: Icon(Icons.remove_circle_outline),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _maxAgeController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Max Age',
                                  prefixIcon: Icon(Icons.add_circle_outline),
                                ),
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
