import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'models/text_transformation.dart';
import 'widgets/rule_item.dart';
import 'screens/rule_management_screen.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const TextTransformApp());
}

class TextTransformApp extends StatelessWidget {
  const TextTransformApp({super.key});

  @override
  Widget build(BuildContext context) {
    bool isApple = Platform.isIOS || Platform.isMacOS;

    const localizationsDelegates = [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];

    if (isApple) {
      return const CupertinoApp(
        title: 'TextTransform',
        theme: CupertinoThemeData(primaryColor: CupertinoColors.activeBlue),
        localizationsDelegates: localizationsDelegates,
        home: TextTransformHome(),
        debugShowCheckedModeBanner: false,
      );
    } else {
      return MaterialApp(
        title: 'TextTransform',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          fontFamily: 'SF Pro Text',
        ),
        localizationsDelegates: localizationsDelegates,
        home: const TextTransformHome(),
        debugShowCheckedModeBanner: false,
      );
    }
  }
}

class TextTransformHome extends StatefulWidget {
  const TextTransformHome({super.key});

  @override
  State<TextTransformHome> createState() => _TextTransformHomeState();
}

class _TextTransformHomeState extends State<TextTransformHome> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  List<TransformationRule> _masterRules = [];
  List<RuleSet> _ruleSets = [];
  String? _activeSetId;
  bool _isLoading = true;

  RuleSet? get _activeSet => _ruleSets.isEmpty
      ? null
      : _ruleSets.firstWhere(
          (s) => s.id == _activeSetId,
          orElse: () => _ruleSets.first,
        );

  List<TransformationRule> get _currentRules {
    final activeSet = _activeSet;
    if (activeSet == null) return [];
    return activeSet.ruleIds
        .map((id) => _masterRules.firstWhere((r) => r.id == id))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final masterRules = await TextTransformer.loadMasterRules();
    final ruleSets = await TextTransformer.loadRuleSets();
    final activeSetId = await TextTransformer.loadActiveSetId();

    setState(() {
      _masterRules = masterRules;
      _ruleSets = ruleSets;
      _activeSetId =
          activeSetId ?? (ruleSets.isNotEmpty ? ruleSets.first.id : null);
      _isLoading = false;
    });
  }

  Future<void> _saveData() async {
    await TextTransformer.saveMasterRules(_masterRules);
    await TextTransformer.saveRuleSets(_ruleSets);
    if (_activeSetId != null) {
      await TextTransformer.saveActiveSetId(_activeSetId!);
    }
  }

  void _transformText() {
    setState(() {
      _outputController.text = TextTransformer.transform(
        _inputController.text,
        _currentRules,
      );
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _outputController.text));
    if (!Platform.isIOS && !Platform.isMacOS) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
    }
  }

  void _clearAll() {
    setState(() {
      _inputController.clear();
      _outputController.clear();
    });
  }

  void _manageRules() {
    if (Platform.isIOS || Platform.isMacOS) {
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (_) => RuleManagementScreen(
            masterRules: _masterRules,
            ruleSets: _ruleSets,
            activeSetId: _activeSetId,
            onDataChanged: (newMasterRules, newRuleSets, newActiveSetId) {
              setState(() {
                _masterRules = newMasterRules;
                _ruleSets = newRuleSets;
                _activeSetId = newActiveSetId;
              });
              _saveData();
            },
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RuleManagementScreen(
            masterRules: _masterRules,
            ruleSets: _ruleSets,
            activeSetId: _activeSetId,
            onDataChanged: (newMasterRules, newRuleSets, newActiveSetId) {
              setState(() {
                _masterRules = newMasterRules;
                _ruleSets = newRuleSets;
                _activeSetId = newActiveSetId;
              });
              _saveData();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    bool isApple = Platform.isIOS || Platform.isMacOS;

    if (isApple) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('TextTransform'),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _manageRules,
            child: const Tooltip(
              message: 'Manage Rule Sets',
              child: Icon(CupertinoIcons.settings),
            ),
          ),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _clearAll,
            child: const Tooltip(
              message: 'Clear Input and Output',
              child: Icon(CupertinoIcons.delete),
            ),
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) =>
                _buildAdaptiveLayout(constraints, true),
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('TextTransform'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          leading: IconButton(
            onPressed: _manageRules,
            icon: const Icon(Icons.settings),
            tooltip: 'Manage Rule Sets',
          ),
          actions: [
            IconButton(
              onPressed: _clearAll,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear Input and Output',
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) =>
              _buildAdaptiveLayout(constraints, false),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _transformText,
          label: const Text('Transform'),
          icon: const Icon(Icons.auto_fix_high),
        ),
      );
    }
  }

  Widget _buildAdaptiveLayout(BoxConstraints constraints, bool isApple) {
    // Landscape if width > height
    if (constraints.maxWidth > constraints.maxHeight) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column: Input
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildSectionHeader('Input', isApple),
                  const SizedBox(height: 8),
                  Expanded(child: _buildInputField(isApple)),
                  if (isApple) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton.filled(
                        onPressed: _transformText,
                        child: const Text('Transform Text'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          // Middle Column: Rules
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader('Rules', isApple),
                      _buildRuleSetSelector(isApple),
                    ],
                  ),
                ),
                Expanded(
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: _buildRulesList(isApple),
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // Right Column: Result
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildSectionHeader('Result', isApple),
                  const SizedBox(height: 8),
                  Expanded(child: _buildOutputField(isApple)),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      return ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader('Input', isApple),
          _buildInputField(isApple, height: 200),
          const SizedBox(height: 24),
          _buildSectionHeader('Rules', isApple),
          _buildRuleSetSelector(isApple),
          const SizedBox(height: 8),
          _buildRulesList(isApple, shrinkWrap: true),
          const SizedBox(height: 24),
          _buildSectionHeader('Result', isApple),
          _buildOutputField(isApple, height: 200),
          if (isApple) ...[
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: _transformText,
              child: const Text('Transform Text'),
            ),
          ],
          const SizedBox(height: 80),
        ],
      );
    }
  }

  Widget _buildSectionHeader(String title, bool isApple) {
    final style = isApple
        ? const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: CupertinoColors.secondaryLabel,
          )
        : Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: style),
      ),
    );
  }

  Widget _buildInputField(bool isApple, {double? height}) {
    if (isApple) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          border: Border.all(
            color: CupertinoColors.separator.resolveFrom(context),
          ),
          borderRadius: BorderRadius.circular(8),
          color: CupertinoColors.systemBackground.resolveFrom(context),
        ),
        child: CupertinoTextField(
          controller: _inputController,
          placeholder: 'Paste text...',
          maxLines: null,
          expands: height == null,
          padding: const EdgeInsets.all(12),
          decoration: null,
          style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
            fontFamily: 'monospace',
            fontSize: 15,
            color: CupertinoColors.label.resolveFrom(context),
          ),
        ),
      );
    } else {
      return SizedBox(
        height: height,
        child: TextField(
          controller: _inputController,
          maxLines: null,
          expands: height == null,
          textAlignVertical: TextAlignVertical.top,
          decoration: InputDecoration(
            hintText: 'Paste text...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          style: const TextStyle(fontFamily: 'monospace', fontSize: 15),
        ),
      );
    }
  }

  Widget _buildOutputField(bool isApple, {double? height}) {
    final field = isApple
        ? Container(
            height: height,
            decoration: BoxDecoration(
              border: Border.all(
                color: CupertinoColors.separator.resolveFrom(context),
              ),
              borderRadius: BorderRadius.circular(8),
              color: CupertinoColors.systemGroupedBackground.resolveFrom(
                context,
              ),
            ),
            child: CupertinoTextField(
              controller: _outputController,
              readOnly: true,
              maxLines: null,
              expands: height == null,
              padding: const EdgeInsets.all(12),
              decoration: null,
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                fontFamily: 'monospace',
                fontSize: 15,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
          )
        : SizedBox(
            height: height,
            child: TextField(
              controller: _outputController,
              readOnly: true,
              maxLines: null,
              expands: height == null,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.blue[50]?.withValues(alpha: 0.3),
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );

    return Column(
      children: [
        if (height == null) Expanded(child: field) else field,
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (isApple)
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _copyToClipboard,
                child: const Row(
                  children: [
                    Tooltip(
                      message: 'Copy to Clipboard',
                      child: Icon(CupertinoIcons.doc_on_doc, size: 18),
                    ),
                    SizedBox(width: 4),
                    Text('Copy Result'),
                  ],
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _copyToClipboard,
                icon: const Icon(Icons.copy),
                label: const Text('Copy Result'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildRulesList(bool isApple, {bool shrinkWrap = false}) {
    final rules = _currentRules;
    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      itemCount: rules.length,
      itemBuilder: (context, index) {
        return RuleItem(
          rule: rules[index],
          onToggle: (_) {}, // No toggling in main view
          isCompact: true,
        );
      },
    );
  }

  Widget _buildRuleSetSelector(bool isApple) {
    if (_ruleSets.isEmpty) return const SizedBox.shrink();

    if (isApple) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _showRuleSetPicker(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _activeSet?.name ?? 'Select Set',
              style: const TextStyle(fontSize: 14),
            ),
            const Icon(CupertinoIcons.chevron_down, size: 14),
          ],
        ),
      );
    } else {
      return DropdownButton<String>(
        value: _activeSetId,
        items: _ruleSets.map((set) {
          return DropdownMenuItem(
            value: set.id,
            child: Text(set.name, style: const TextStyle(fontSize: 14)),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() => _activeSetId = value);
            _saveData();
          }
        },
        underline: const SizedBox.shrink(),
      );
    }
  }

  void _showRuleSetPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Select Rule Set'),
        actions: _ruleSets.map((set) {
          return CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _activeSetId = set.id);
              _saveData();
              Navigator.pop(context);
            },
            child: Text(set.name),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDefaultAction: true,
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}
