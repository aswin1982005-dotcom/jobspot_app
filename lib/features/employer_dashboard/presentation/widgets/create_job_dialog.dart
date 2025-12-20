import 'package:flutter/material.dart';
import 'package:jobspot_app/core/theme/app_theme.dart';

class CreateJobDialog extends StatefulWidget {
  const CreateJobDialog({super.key});

  @override
  State<CreateJobDialog> createState() => _CreateJobDialogState();
}

class _CreateJobDialogState extends State<CreateJobDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  // State Variables
  bool _isFixedShift =
      true; // Toggle state: true = Time Picker, false = Duration Input
  String? _selectedJobType;

  // Job Type Options
  final List<String> _jobTypes = [
    'Service',
    'Technical',
    'Accountant',
    'Hotel Management',
    'Packaging',
    'Construction',
    'Administrative',
    'Sales',
    'Other',
  ];

  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  // Helper to pick time
  Future<void> _selectTime(TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.darkPurple,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        controller.text = picked.format(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  const Text(
                    '✨ Post a New Job',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

            // --- BODY ---
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Job Title
                      _buildTextField(
                        label: 'Job Title',
                        hint: 'e.g. Senior Accountant',
                      ),
                      const SizedBox(height: 20),

                      // Job Type Dropdown
                      _buildDropdownField(
                        label: 'Job Sector / Type',
                        hint: 'Select sector',
                        items: _jobTypes,
                        value: _selectedJobType,
                        onChanged: (val) =>
                            setState(() => _selectedJobType = val),
                      ),
                      const SizedBox(height: 20),

                      // --- SCHEDULE SECTION START ---
                      const Text(
                        'Shift Schedule',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Toggle Buttons (Fixed vs Flexible)
                      Row(
                        children: [
                          _buildChoiceChip(
                            label: 'Specific Times',
                            isSelected: _isFixedShift,
                            onTap: () => setState(() => _isFixedShift = true),
                          ),
                          const SizedBox(width: 12),
                          _buildChoiceChip(
                            label: 'Duration / Flexible',
                            isSelected: !_isFixedShift,
                            onTap: () => setState(() => _isFixedShift = false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Conditional Input: Either Time Pickers OR Duration Text Field
                      if (_isFixedShift)
                        Row(
                          children: [
                            Expanded(
                              child: _buildTimePickerField(
                                controller: _startTimeController,
                                hint: 'Start Time',
                                icon: Icons.wb_sunny_outlined,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTimePickerField(
                                controller: _endTimeController,
                                hint: 'End Time',
                                icon: Icons.nightlight_outlined,
                              ),
                            ),
                          ],
                        )
                      else
                        _buildTextField(
                          controller: _durationController,
                          // Pass controller here
                          label: '',
                          // Label handled by parent section
                          hint: 'e.g. 8 hours per day / Flexible',
                          // Removes label space since we just want the box
                          noLabel: true,
                        ),

                      // --- SCHEDULE SECTION END ---
                      const SizedBox(height: 20),

                      // Salary
                      _buildTextField(
                        label: 'Salary Range',
                        hint: 'e.g. \$20/hr or \$40k/yr',
                      ),
                      const SizedBox(height: 20),

                      // Description
                      _buildTextField(
                        label: 'Description',
                        hint: 'Describe the role and requirements...',
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

            // --- FOOTER ---
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // Handle Logic:
                          // if (_isFixedShift) use start/end controllers
                          // else use _durationController
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkPurple,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Post Job',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildTextField({
    required String hint,
    String? label,
    int maxLines = 1,
    TextEditingController? controller,
    bool noLabel = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!noLabel && label != null) ...[
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          decoration: _inputDecoration(hint),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required List<String> items,
    required String? value,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          decoration: _inputDecoration(hint),
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTimePickerField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () => _selectTime(controller),
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      decoration: _inputDecoration(
        hint,
      ).copyWith(prefixIcon: Icon(icon, color: Colors.grey[400], size: 20)),
    );
  }

  // Custom Selection Chip for the Toggle
  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.darkPurple.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.darkPurple : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.darkPurple : Colors.black54,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.darkPurple, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.red.shade200),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
    );
  }
}
