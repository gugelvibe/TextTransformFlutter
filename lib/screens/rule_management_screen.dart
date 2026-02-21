import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import '../models/text_transformation.dart';
import '../widgets/rule_editor.dart';

class RuleManagementScreen extends StatefulWidget {
  final List<TransformationRule> masterRules;
  final List<RuleSet> ruleSets;
  final String? activeSetId;
  final Function(List<TransformationRule>, List<RuleSet>, String?)
  onDataChanged;

  const RuleManagementScreen({
    super.key,
    required this.masterRules,
    required this.ruleSets,
    required this.activeSetId,
    required this.onDataChanged,
  });

  @override
  State<RuleManagementScreen> createState() => _RuleManagementScreenState();
}

class _RuleManagementScreenState extends State<RuleManagementScreen> {
  late List<TransformationRule> _masterRules;
  late List<RuleSet> _ruleSets;
  late String? _activeSetId;

  RuleSet? get _selectedSet => _ruleSets.isEmpty
      ? null
      : _ruleSets.firstWhere(
          (s) => s.id == _activeSetId,
          orElse: () => _ruleSets.first,
        );

  @override
  void initState() {
    super.initState();
    _masterRules = List.from(widget.masterRules);
    _ruleSets = List.from(widget.ruleSets);
    _activeSetId = widget.activeSetId;
  }

  void _createNewSet() {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newSet = RuleSet(id: newId, name: 'New Set', ruleIds: []);
    setState(() {
      _ruleSets.add(newSet);
      _activeSetId = newId;
    });
    _notifyChanges();
  }

  void _deleteSet(String id) {
    setState(() {
      _ruleSets.removeWhere((s) => s.id == id);
      if (_activeSetId == id) {
        _activeSetId = _ruleSets.isNotEmpty ? _ruleSets.first.id : null;
      }
    });
    _notifyChanges();
  }

  void _addRuleToMaster() {
    _showRuleEditor(null);
  }

  void _editMasterRule(TransformationRule rule) {
    _showRuleEditor(rule);
  }

  void _deleteMasterRule(String id) {
    setState(() {
      _masterRules.removeWhere((r) => r.id == id);
      for (var set in _ruleSets) {
        set.ruleIds.remove(id);
      }
    });
    _notifyChanges();
  }

  void _addRuleToSet(String ruleId) {
    final selectedSet = _selectedSet;
    if (selectedSet == null) return;

    if (!selectedSet.ruleIds.contains(ruleId)) {
      setState(() {
        final index = _ruleSets.indexOf(selectedSet);
        _ruleSets[index] = selectedSet.copyWith(
          ruleIds: [...selectedSet.ruleIds, ruleId],
        );
      });
      _notifyChanges();
    }
  }

  void _removeRuleFromSet(String ruleId) {
    final selectedSet = _selectedSet;
    if (selectedSet == null) return;

    setState(() {
      final index = _ruleSets.indexOf(selectedSet);
      final newIds = List<String>.from(selectedSet.ruleIds)..remove(ruleId);
      _ruleSets[index] = selectedSet.copyWith(ruleIds: newIds);
    });
    _notifyChanges();
  }

  void _onReorderInSet(int oldIndex, int newIndex) {
    final selectedSet = _selectedSet;
    if (selectedSet == null) return;

    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final ids = List<String>.from(selectedSet.ruleIds);
      final item = ids.removeAt(oldIndex);
      ids.insert(newIndex, item);

      final index = _ruleSets.indexOf(selectedSet);
      _ruleSets[index] = selectedSet.copyWith(ruleIds: ids);
    });
    _notifyChanges();
  }

  void _notifyChanges() {
    widget.onDataChanged(_masterRules, _ruleSets, _activeSetId);
  }

  void _showRuleEditor(TransformationRule? rule) {
    final editor = RuleEditor(
      rule: rule,
      onSave: (updatedRule) {
        setState(() {
          final index = _masterRules.indexWhere((r) => r.id == updatedRule.id);
          if (index != -1) {
            _masterRules[index] = updatedRule;
          } else {
            _masterRules.add(updatedRule);
          }
        });
        _notifyChanges();
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
          middle: const Text('Manage Rule Sets'),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _createNewSet,
            child: const Icon(CupertinoIcons.folder_badge_plus),
          ),
        ),
        child: SafeArea(child: _buildBody(true)),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Manage Rule Sets'),
          actions: [
            IconButton(
              onPressed: _createNewSet,
              icon: const Icon(Icons.create_new_folder),
            ),
          ],
        ),
        body: _buildBody(false),
      );
    }
  }

  Widget _buildBody(bool isApple) {
    return Column(
      children: [
        _buildSetSelector(isApple),
        const Divider(height: 1),
        Expanded(
          child: Row(
            children: [
              // Left side: Rules in set
              Expanded(flex: 1, child: _buildSetRulesList(isApple)),
              const VerticalDivider(width: 1),
              // Right side: Master list
              Expanded(flex: 1, child: _buildMasterRulesList(isApple)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSetSelector(bool isApple) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          const Text(
            'Active Set: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: isApple
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _ruleSets.isEmpty
                        ? null
                        : () => _showSetPicker(),
                    child: Text(_selectedSet?.name ?? 'No Sets'),
                  )
                : DropdownButton<String>(
                    value: _activeSetId,
                    isExpanded: true,
                    items: _ruleSets
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() {
                      _activeSetId = val;
                      _notifyChanges();
                    }),
                  ),
          ),
          if (_selectedSet != null) ...[
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: () => _editSetName(isApple),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 18,
                color: Colors.red,
              ),
              onPressed: () => _deleteSet(_activeSetId!),
            ),
          ],
        ],
      ),
    );
  }

  void _editSetName(bool isApple) {
    final controller = TextEditingController(text: _selectedSet?.name);
    if (isApple) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Edit Set Name'),
          content: CupertinoTextField(controller: controller),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              child: const Text('Save'),
              onPressed: () {
                setState(() {
                  final index = _ruleSets.indexOf(_selectedSet!);
                  _ruleSets[index] = _selectedSet!.copyWith(
                    name: controller.text,
                  );
                });
                _notifyChanges();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Edit Set Name'),
          content: TextField(controller: controller),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                setState(() {
                  final index = _ruleSets.indexOf(_selectedSet!);
                  _ruleSets[index] = _selectedSet!.copyWith(
                    name: controller.text,
                  );
                });
                _notifyChanges();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    }
  }

  void _showSetPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: _ruleSets
            .map(
              (s) => CupertinoActionSheetAction(
                onPressed: () {
                  setState(() => _activeSetId = s.id);
                  _notifyChanges();
                  Navigator.pop(context);
                },
                child: Text(s.name),
              ),
            )
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Widget _buildSetRulesList(bool isApple) {
    final selectedSet = _selectedSet;
    if (selectedSet == null) return const Center(child: Text('Create a set'));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Rules in Set',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            itemCount: selectedSet.ruleIds.length,
            onReorder: _onReorderInSet,
            itemBuilder: (context, index) {
              final ruleId = selectedSet.ruleIds[index];
              final rule = _masterRules.firstWhere((r) => r.id == ruleId);
              return ListTile(
                key: ValueKey('set_$ruleId'),
                title: Text(
                  rule.description,
                  style: const TextStyle(fontSize: 13),
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  onPressed: () => _removeRuleFromSet(ruleId),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMasterRulesList(bool isApple) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Rules',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                onPressed: _addRuleToMaster,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _masterRules.length,
            itemBuilder: (context, index) {
              final rule = _masterRules[index];
              final inSet = _selectedSet?.ruleIds.contains(rule.id) ?? false;
              return ListTile(
                title: Text(
                  rule.description,
                  style: const TextStyle(fontSize: 13),
                ),
                subtitle: Text(
                  'Find: ${rule.pattern}',
                  style: const TextStyle(fontSize: 10),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () => _editMasterRule(rule),
                    ),
                    IconButton(
                      icon: Icon(
                        inSet ? Icons.check_circle : Icons.add_circle_outline,
                        color: inSet ? Colors.green : Colors.blue,
                        size: 20,
                      ),
                      onPressed: inSet ? null : () => _addRuleToSet(rule.id),
                    ),
                  ],
                ),
                onLongPress: () => _deleteMasterRule(rule.id),
              );
            },
          ),
        ),
      ],
    );
  }
}
