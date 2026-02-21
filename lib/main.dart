import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'models/text_transformation.dart';
import 'widgets/rule_editor.dart';
import 'widgets/rule_item.dart';

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
  List<TransformationRule> _rules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialRules();
  }

  Future<void> _loadInitialRules() async {
    final rules = await TextTransformer.loadRules();
    setState(() {
      _rules = rules;
      _isLoading = false;
    });
  }

  Future<void> _saveRules() async {
    await TextTransformer.saveRules(_rules);
  }

  void _transformText() {
    setState(() {
      _outputController.text = TextTransformer.transform(
        _inputController.text,
        _rules,
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
    _saveRules();
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
        _saveRules();
      },
    );

    if (Platform.isIOS || Platform.isMacOS) {
      Navigator.of(context).push(CupertinoPageRoute(builder: (_) => editor));
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => editor));
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _rules.removeAt(oldIndex);
      _rules.insert(newIndex, item);
    });
    _saveRules();
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
            onPressed: _addRule,
            child: const Icon(CupertinoIcons.add),
          ),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _clearAll,
            child: const Icon(CupertinoIcons.delete),
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
          leading: IconButton(onPressed: _addRule, icon: const Icon(Icons.add)),
          actions: [
            IconButton(
              onPressed: _clearAll,
              icon: const Icon(Icons.delete_outline),
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
    if (constraints.maxWidth > 900) {
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
                  padding: const EdgeInsets.all(16.0),
                  child: _buildSectionHeader(
                    'Rules (Drag to Reorder)',
                    isApple,
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
          _buildSectionHeader('Rules (Drag to Reorder)', isApple),
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
          border: Border.all(color: CupertinoColors.separator),
          borderRadius: BorderRadius.circular(8),
          color: CupertinoColors.systemBackground,
        ),
        child: CupertinoTextField(
          controller: _inputController,
          placeholder: 'Paste text...',
          maxLines: null,
          expands: height == null,
          padding: const EdgeInsets.all(12),
          decoration: null,
          style: CupertinoTheme.of(
            context,
          ).textTheme.textStyle.copyWith(fontFamily: 'monospace', fontSize: 15),
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
              border: Border.all(color: CupertinoColors.separator),
              borderRadius: BorderRadius.circular(8),
              color: CupertinoColors.systemGroupedBackground,
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
                color: CupertinoColors.label
                    .resolveFrom(context)
                    .withOpacity(0.8),
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
                fillColor: Colors.blue[50]?.withOpacity(0.3),
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
                    Icon(CupertinoIcons.doc_on_doc, size: 18),
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
    return ReorderableListView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
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
                  setState(
                    () => _rules[index] = _rules[index].copyWith(
                      isEnabled: value ?? false,
                    ),
                  );
                  _saveRules();
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
