import 'dart:convert';

class ModalConfigMap {
  final Map<String, ModalConfig> configs;

  ModalConfigMap(this.configs);

  Map<String, dynamic> toJson() => {
    'configs': configs.map((key, value) => MapEntry(key, value.toJson())),
  };
}

class ModalConfig {
  final Options options;
  final Map<String, List<ConditionalOption>> conditionalOptions;
  final Scopes scopes;
  final Map<String, List<String>> validationRules;
  final Map<String, ReadRouteConfig> readRoutes;
  final dynamic aiQualityChecks;

  ModalConfig({
    required this.options,
    required this.conditionalOptions,
    required this.scopes,
    required this.validationRules,
    required this.readRoutes,
    required this.aiQualityChecks,
  });

  Map<String, dynamic> toJson() => {
    'options': options.toJson(),
    'conditionalOptions': conditionalOptions.map((key, value) => MapEntry(key, value.map((e) => e.toJson()).toList())),
    'scopes': scopes.toJson(),
    'validationRules': validationRules,
    'readRoutes': readRoutes.map((key, value) => MapEntry(key, value.toJson())),
    'aiQualityChecks': aiQualityChecks,
  };
}

class ReadRouteConfig {
  final bool belongsToUserId;

  ReadRouteConfig({required this.belongsToUserId});

  factory ReadRouteConfig.fromJson(Map<String, dynamic> json) {
    return ReadRouteConfig(
      belongsToUserId: json['belongs_to_user_id'],
    );
  }

  Map<String, dynamic> toJson() => {
    'belongs_to_user_id': belongsToUserId,
  };
}

class Options {
  final Map<String, List<String>> xorOptions;
  final Map<String, List<String>> orOptions;

  Options(Map<String, List<String>> options)
      : xorOptions = _extractOptions(options, 'XOR', 5),
        orOptions = _extractOptions(options, 'OR', 4) {
  }

  static Map<String, List<String>> _extractOptions(
      Map<String, List<String>> options, String type, int lengthToRemove) {
    final Map<String, List<String>> result = {};
    options.forEach((key, value) {
      if (key.endsWith('[$type]')) {
        final cleanedKey = key.substring(0, key.length - lengthToRemove);
        //print('Found $type option: $cleanedKey');  // Debug statement
        result[cleanedKey] = value;
      }
    });
    return result;
  }

  Map<String, dynamic> toJson() => {
    'xorOptions': xorOptions,
    'orOptions': orOptions,
  };
}

class ConditionalOption {
  final String condition;
  final List<String> options;

  ConditionalOption({
    required this.condition,
    required this.options,
  });

  Map<String, dynamic> toJson() => {
    'condition': condition,
    'options': options,
  };
}

class Scopes {
  final bool create;
  final List<String> read;
  final List<String> read_summary;
  final List<String> update;
  final bool delete;

  Scopes({
    required this.create,
    required this.read,
    required this.read_summary,
    required this.update,
    required this.delete,
  });

  Map<String, dynamic> toJson() => {
    'create': create,
    'read': read,
    'read_summary': read_summary,
    'update': update,
    'delete': delete,
  };
}

