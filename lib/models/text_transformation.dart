import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TransformationRule {
  final String id;
  final String description;
  final String pattern;
  final String replacement;
  final bool isEnabled;
  final bool isRegex;

  TransformationRule({
    required this.id,
    required this.description,
    required this.pattern,
    required this.replacement,
    this.isEnabled = true,
    this.isRegex = true,
  });

  TransformationRule copyWith({
    String? id,
    String? description,
    String? pattern,
    String? replacement,
    bool? isEnabled,
    bool? isRegex,
  }) {
    return TransformationRule(
      id: id ?? this.id,
      description: description ?? this.description,
      pattern: pattern ?? this.pattern,
      replacement: replacement ?? this.replacement,
      isEnabled: isEnabled ?? this.isEnabled,
      isRegex: isRegex ?? this.isRegex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'pattern': pattern,
      'replacement': replacement,
      'isEnabled': isEnabled,
      'isRegex': isRegex,
    };
  }

  factory TransformationRule.fromJson(Map<String, dynamic> json) {
    return TransformationRule(
      id: json['id'] as String,
      description: json['description'] as String,
      pattern: json['pattern'] as String,
      replacement: json['replacement'] as String,
      isEnabled: json['isEnabled'] as bool? ?? true,
      isRegex: json['isRegex'] as bool? ?? true,
    );
  }
}

class RuleSet {
  final String id;
  final String name;
  final List<String> ruleIds;

  RuleSet({required this.id, required this.name, required this.ruleIds});

  RuleSet copyWith({String? id, String? name, List<String>? ruleIds}) {
    return RuleSet(
      id: id ?? this.id,
      name: name ?? this.name,
      ruleIds: ruleIds ?? this.ruleIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'ruleIds': ruleIds};
  }

  factory RuleSet.fromJson(Map<String, dynamic> json) {
    return RuleSet(
      id: json['id'] as String,
      name: json['name'] as String,
      ruleIds: (json['ruleIds'] as List).cast<String>(),
    );
  }
}

class TextTransformer {
  static const String _masterRulesKey = 'master_transformation_rules';
  static const String _ruleSetsKey = 'transformation_rule_sets';
  static const String _activeSetKey = 'active_rule_set_id';

  static String transform(String input, List<TransformationRule> rules) {
    String output = input;
    // For Rule Sets, we assume all rules passed to this function are meant to be applied.
    for (var rule in rules) {
      try {
        if (rule.isRegex) {
          final regex = RegExp(rule.pattern, multiLine: true);
          output = output.replaceAllMapped(regex, (match) {
            String replacement = rule.replacement;
            for (int i = 0; i <= match.groupCount; i++) {
              replacement = replacement.replaceAll(
                '\$$i',
                match.group(i) ?? '',
              );
            }
            return replacement;
          });
        } else {
          output = output.replaceAll(rule.pattern, rule.replacement);
        }
      } catch (e) {
        continue;
      }
    }
    return output;
  }

  static Future<void> saveMasterRules(List<TransformationRule> rules) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = rules.map((r) => r.toJson()).toList();
    await prefs.setString(_masterRulesKey, jsonEncode(jsonList));
  }

  static Future<List<TransformationRule>> loadMasterRules() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_masterRulesKey);
    if (jsonStr == null) {
      return getDefaultRules();
    }
    try {
      final jsonList = jsonDecode(jsonStr) as List;
      return jsonList
          .map((j) => TransformationRule.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return getDefaultRules();
    }
  }

  static Future<void> saveRuleSets(List<RuleSet> sets) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = sets.map((s) => s.toJson()).toList();
    await prefs.setString(_ruleSetsKey, jsonEncode(jsonList));
  }

  static Future<List<RuleSet>> loadRuleSets() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_ruleSetsKey);
    if (jsonStr == null) {
      return [
        RuleSet(
          id: 'default_set',
          name: 'Default Set',
          ruleIds: (await loadMasterRules()).map((r) => r.id).toList(),
        ),
      ];
    }
    try {
      final jsonList = jsonDecode(jsonStr) as List;
      return jsonList
          .map((j) => RuleSet.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveActiveSetId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeSetKey, id);
  }

  static Future<String?> loadActiveSetId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeSetKey);
  }

  static List<TransformationRule> getDefaultRules() {
    return [
      TransformationRule(
        id: 'rule1',
        description: 'Lösche Linebreaks',
        pattern: r'(\n|\r\n|\r)',
        replacement: ' ',
      ),
      TransformationRule(
        id: 'rule2',
        description: 'Ersetze Leerstelle Datum mit Linebreak Datum',
        pattern:
            r' ([0-9]{2}[\.][0-9]{2}[\.][0-9]{2})( |;)([0-9]{2}[\.][0-9]{2}[\.][0-9]{2})',
        replacement: '\n\$1\$2\$3',
      ),
      TransformationRule(
        id: 'rule3',
        description: 'Lösche doppelte Buchungen',
        pattern: r'.* (DAVON DECKUNG|UND DECKUNG|INKL\. 19% VERS).*',
        replacement: '',
      ),
      TransformationRule(
        id: 'rule4a',
        description: 'Doppelte LF entfernen (1)',
        pattern: r'(\n|\r\n|\r)(\n|\r\n|\r)',
        replacement: '\n',
      ),
      TransformationRule(
        id: 'rule4b',
        description: 'Doppelte LF entfernen (2)',
        pattern: r'(\n|\r\n|\r)(\n|\r\n|\r)',
        replacement: '\n',
      ),
      // Jahreszahlen
      ...List.generate(5, (index) {
        final year = 23 + index;
        return TransformationRule(
          id: 'year_$year',
          description: 'Semikolon nach Jahreszahl $year',
          pattern: '.$year ',
          replacement: '.$year;',
          isRegex: false,
        );
      }),
      // Prefix Keywords (rule5)
      ...['FR', 'COFR', 'BFR', 'BBE'].map(
        (kw) => TransformationRule(
          id: 'prefix_$kw',
          description: 'Semikolon nach $kw',
          pattern: ' $kw (-*[0-9]+)',
          replacement: ' $kw;\$1',
        ),
      ),
      // Location Keywords (rule6)
      ...[
        'EHRENFEDE',
        'GARDIT',
        'W-DORF',
        'SCHWADOR',
        'SCHEID',
        'G-DORF',
        'VILL-OBE',
        'M-ST-LUC',
        'KIERBER',
        'FLAMACH',
        'LEUDELAN',
        'M-L-ROCH',
      ].map(
        (kw) => TransformationRule(
          id: 'loc_$kw',
          description: 'Semikolon nach $kw',
          pattern: ' $kw (-*[0-9]+)',
          replacement: ' $kw;\$1',
        ),
      ),
      // Country Codes / Transaction Types (rule7-35)
      ...[
        'DE',
        'AT',
        'LU',
        'MT',
        'BE',
        'CZ',
        'PL',
        'RU',
        'SK',
        'IE',
        'CH',
        'IT',
        'FR',
        'ES',
        'HU',
        'HR',
        'LI',
        'PT',
        'SE',
        'DK',
        'NO',
        'FI',
        'AD',
        'SM',
        'VA',
        'Karteneinsatz',
        'Habenzinsen',
        'Zinsen',
        'Steuer',
        'Provision',
        'Gebühr',
        'Entgelt',
        'Spesen',
        'Kapital',
        'Dividende',
      ].map(
        (kw) => TransformationRule(
          id: 'type_$kw',
          description: 'Semikolon nach $kw',
          pattern: '$kw (-*[0-9]+)',
          replacement: '$kw;\$1',
        ),
      ),
    ];
  }
}
