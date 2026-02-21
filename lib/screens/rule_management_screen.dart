import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import '../models/text_transformation.dart';
import '../widgets/rule_editor.dart';
import '../widgets/rule_item.dart';

class RuleManagementScreen extends StatefulWidget {
  final List<TransformationRule> rules;
  final Function(List<TransformationRule>) onRulesChanged;

  const RuleManagementScreen({
    super.key,
    required this.rules,
    required this.onRulesChanged,
  });

  @override
  State<RuleManagementScreen> createState() => _RuleManagementScreenState();
}

class _RuleManagementScreenState extends State<RuleManagementScreen> {
  late List<TransformationRule> _rules;

  @override
  void initState() {
    super.initState();
    _rules = List.from(widget.rules);
  }

  void _addRule() {
    _showRuleEditor(null);
  }

  void _editRule(int index) {
    _showRuleEditor(_rules[index], index: index);
  }

  void _deleteRule(int index) {
    setState(() {
      _rules.removeAt(index);
    });
    widget.onRulesChanged(_rules);
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _rules.removeAt(oldIndex);
      _rules.insert(newIndex, item);
    });
    widget.onRulesChanged(_rules);
  }

  void _showRuleEditor(TransformationRule? rule, {int? index}) {
    final editor = RuleEditor(
      rule: rule,
      onSave: (updatedRule) {
        setState(() {
          if (index != null) {
            _rules[index] = updatedRule;
          } else {
            _rules.add(updatedRule);
          }
        });
        widget.onRulesChanged(_rules);
      },
    );

    if (Platform.isIOS || Platform.isMacOS) {
      Navigator.of(context).push(CupertinoPageRoute(builder: (_) => editor));
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => editor));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isApple = Platform.isIOS || Platform.isMacOS;

    if (isApple) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Manage Rules'),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _addRule,
            child: const Icon(CupertinoIcons.add),
          ),
        ),
        child: SafeArea(child: _buildBody(true)),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Manage Rules'),
          actions: [
            IconButton(onPressed: _addRule, icon: const Icon(Icons.add)),
          ],
        ),
        body: _buildBody(false),
      );
    }
  }

  Widget _buildBody(bool isApple) {
    if (_rules.isEmpty) {
      return Center(
        child: Text(
          'No rules yet. Add one to start!',
          style: isApple
              ? const TextStyle(color: CupertinoColors.secondaryLabel)
              : const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ReorderableListView.builder(
      itemCount: _rules.length,
      onReorder: _onReorder,
      itemBuilder: (context, index) {
        return Dismissible(
          key: ValueKey(_rules[index].id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => _deleteRule(index),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _editRule(index),
              child: RuleItem(
                rule: _rules[index],
                onToggle: (value) {
                  setState(() {
                    _rules[index] = _rules[index].copyWith(
                      isEnabled: value ?? false,
                    );
                  });
                  widget.onRulesChanged(_rules);
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
