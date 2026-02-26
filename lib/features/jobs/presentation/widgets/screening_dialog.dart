import 'package:flutter/material.dart';

class ScreeningDialog extends StatefulWidget {
  final List<String> questions;
  final String jobTitle;

  const ScreeningDialog({
    super.key,
    required this.questions,
    required this.jobTitle,
  });

  @override
  State<ScreeningDialog> createState() => _ScreeningDialogState();
}

class _ScreeningDialogState extends State<ScreeningDialog> {
  late final List<TextEditingController> _controllers;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controllers = widget.questions
        .map((q) => TextEditingController())
        .toList();
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pre-Screening Questions'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The employer requires you to answer a few questions before applying to ${widget.jobTitle}.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ...widget.questions.asMap().entries.map((entry) {
                  int idx = entry.key;
                  String question = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: TextFormField(
                      controller: _controllers[idx],
                      decoration: InputDecoration(
                        labelText: 'Q: $question',
                        alignLabelWithHint: true,
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'This answer is required to proceed'
                          : null,
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final StringBuffer sb = StringBuffer();
              sb.writeln(
                "Hi, I am interested in the ${widget.jobTitle} position. Please review my profile.\n",
              );
              sb.writeln("--- Screening Answers ---");
              for (int i = 0; i < widget.questions.length; i++) {
                sb.writeln("Q: ${widget.questions[i]}");
                sb.writeln("A: ${_controllers[i].text.trim()}\n");
              }
              Navigator.pop(context, sb.toString());
            }
          },
          child: const Text('Submit Application'),
        ),
      ],
    );
  }
}
