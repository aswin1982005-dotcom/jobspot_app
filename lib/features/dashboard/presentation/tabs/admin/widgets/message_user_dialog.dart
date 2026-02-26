import 'package:flutter/material.dart';

class MessageUserDialog extends StatefulWidget {
  final String userName;
  final Function(String title, String body) onSend;

  const MessageUserDialog({
    super.key,
    required this.userName,
    required this.onSend,
  });

  @override
  State<MessageUserDialog> createState() => _MessageUserDialogState();
}

class _MessageUserDialogState extends State<MessageUserDialog> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Message ${widget.userName}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Message Title',
                hintText: 'e.g., Important Account Update',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Message Body',
                hintText: 'Type your message here...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSend(
                _titleController.text.trim(),
                _bodyController.text.trim(),
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Send Message'),
        ),
      ],
    );
  }
}
