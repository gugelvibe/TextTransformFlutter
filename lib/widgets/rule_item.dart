import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import '../models/text_transformation.dart';

class RuleItem extends StatelessWidget {
  final TransformationRule rule;
  final ValueChanged<bool?> onToggle;
  final bool isCompact;

  const RuleItem({
    super.key,
    required this.rule,
    required this.onToggle,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    bool isApple = Platform.isIOS || Platform.isMacOS;

    if (isApple) {
      return CupertinoListTile(
        title: Text(
          rule.description,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: isCompact
            ? null
            : Text(
                'Find: ${rule.pattern}\nReplace: ${rule.replacement}',
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
        trailing: isCompact
            ? null
            : CupertinoSwitch(
                value: rule.isEnabled,
                onChanged: (val) => onToggle(val),
              ),
      );
    } else {
      return ListTile(
        title: Text(rule.description),
        subtitle: isCompact
            ? null
            : Text(
                'Find: ${rule.pattern}\nReplace: ${rule.replacement}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'monospace',
                ),
              ),
        isThreeLine: !isCompact,
        trailing: isCompact
            ? null
            : Switch(value: rule.isEnabled, onChanged: onToggle),
      );
    }
  }
}
