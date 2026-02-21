import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import '../models/text_transformation.dart';

class RuleEditor extends StatefulWidget {
  final TransformationRule? rule;
  final Function(TransformationRule) onSave;

  const RuleEditor({super.key, this.rule, required this.onSave});

  @override
  State<RuleEditor> createState() => _RuleEditorState();
}

class _RuleEditorState extends State<RuleEditor> {
  late TextEditingController _descriptionController;
  late TextEditingController _patternController;
  late TextEditingController _replacementController;
  late bool _isEnabled;
  late bool _isRegex;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.rule?.description ?? '',
    );
    _patternController = TextEditingController(
      text: widget.rule?.pattern ?? '',
    );
    _replacementController = TextEditingController(
      text: widget.rule?.replacement ?? '',
    );
    _isEnabled = widget.rule?.isEnabled ?? true;
    _isRegex = widget.rule?.isRegex ?? true;
  }

  void _handleSave() {
    final rule = TransformationRule(
      id: widget.rule?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      description: _descriptionController.text,
      pattern: _patternController.text,
      replacement: _replacementController.text,
      isEnabled: _isEnabled,
      isRegex: _isRegex,
    );
    widget.onSave(rule);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    bool isApple = Platform.isIOS || Platform.isMacOS;

    if (isApple) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(widget.rule == null ? 'New Rule' : 'Edit Rule'),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _handleSave,
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildAppleField('Description', _descriptionController),
              const SizedBox(height: 16),
              _buildAppleField('Pattern (Regex)', _patternController),
              const SizedBox(height: 16),
              _buildAppleField('Replacement', _replacementController),
              const SizedBox(height: 24),
              CupertinoListTile(
                title: const Text('Enabled'),
                trailing: CupertinoSwitch(
                  value: _isEnabled,
                  onChanged: (val) => setState(() => _isEnabled = val),
                ),
              ),
              CupertinoListTile(
                title: const Text('Use Regular Expression'),
                trailing: CupertinoSwitch(
                  value: _isRegex,
                  onChanged: (val) => setState(() => _isRegex = val),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.rule == null ? 'New Rule' : 'Edit Rule'),
          actions: [
            IconButton(onPressed: _handleSave, icon: const Icon(Icons.check)),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _patternController,
              decoration: const InputDecoration(
                labelText: 'Pattern',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _replacementController,
              decoration: const InputDecoration(
                labelText: 'Replacement',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enabled'),
              value: _isEnabled,
              onChanged: (val) => setState(() => _isEnabled = val),
            ),
            SwitchListTile(
              title: const Text('Use Regular Expression'),
              value: _isRegex,
              onChanged: (val) => setState(() => _isRegex = val),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildAppleField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ),
        CupertinoTextField(
          controller: controller,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: CupertinoColors.separator),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }
}
