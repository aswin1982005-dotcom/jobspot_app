import 'package:flutter/material.dart';
import 'package:jobspot_app/data/services/job_service.dart';
import 'package:jobspot_app/core/utils/supabase_service.dart';

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({super.key});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _jobService = JobService();

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _minPayController = TextEditingController();
  final _maxPayController = TextEditingController();
  final _vacanciesController = TextEditingController(text: '1');
  final _skillsController = TextEditingController();
  final _minAgeController = TextEditingController();
  final _maxAgeController = TextEditingController();

  // Selections
  String _workMode = 'onsite';
  String _payType = 'monthly';
  String _genderPreference = 'any';
  final List<String> _selectedDays = [];
  TimeOfDay _shiftStart = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _shiftEnd = const TimeOfDay(hour: 17, minute: 0);
  bool _sameDayPay = false;
  bool _isLoading = false;

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

      await _jobService.createJobPost(jobData);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job posted successfully!')),
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Post a Job')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Basic Details'),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Job Title*',
                        hintText: 'e.g. Delivery Partner',
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Job Description*',
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 24),

                    _buildSectionHeader('Work Details'),
                    DropdownButtonFormField<String>(
                      initialValue: _workMode,
                      decoration: const InputDecoration(labelText: 'Work Mode'),
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildSectionHeader('Pay & Vacancy'),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _payType,
                            decoration: const InputDecoration(
                              labelText: 'Pay Type',
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
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _vacanciesController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Vacancies',
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
                              labelText: 'Min Pay (INR)*',
                            ),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _maxPayController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Max Pay (INR)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      inactiveTrackColor: Theme.of(context).hintColor,
                      title: const Text('Same Day Pay'),
                      value: _sameDayPay,
                      onChanged: (v) => setState(() => _sameDayPay = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 24),

                    _buildSectionHeader('Working Days'),
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
                    const SizedBox(height: 24),

                    _buildSectionHeader('Shift Timing'),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: const Text('Start Time'),
                            subtitle: Text(_shiftStart.format(context)),
                            onTap: () => _selectTime(context, true),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: theme.dividerColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ListTile(
                            title: const Text('End Time'),
                            subtitle: Text(_shiftEnd.format(context)),
                            onTap: () => _selectTime(context, false),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: theme.dividerColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _buildSectionHeader('Candidate Preferences'),
                    TextFormField(
                      controller: _skillsController,
                      decoration: const InputDecoration(
                        labelText: 'Skills (comma separated)',
                        hintText: 'e.g. Driving, Cooking',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _genderPreference,
                      decoration: const InputDecoration(
                        labelText: 'Gender Preference',
                      ),
                      items: ['any', 'male', 'female']
                          .map(
                            (g) => DropdownMenuItem(
                              value: g,
                              child: Text(g.toUpperCase()),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _genderPreference = v!),
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
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _maxAgeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Max Age',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submit,
                        child: const Text(
                          'POST JOB',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
