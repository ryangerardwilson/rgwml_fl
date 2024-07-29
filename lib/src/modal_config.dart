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
  final List<String> readRoutes;
  final Map<String, List<String>>? aiQualityChecks;

  ModalConfig({
    required this.options,
    required this.conditionalOptions,
    required this.scopes,
    required this.validationRules,
    required this.readRoutes,
    this.aiQualityChecks,
  });

  Map<String, dynamic> toJson() => {
    'options': options.toJson(),
    'conditionalOptions': conditionalOptions.map((key, value) => MapEntry(key, value.map((e) => e.toJson()).toList())),
    'scopes': scopes.toJson(),
    'validationRules': validationRules,
    'readRoutes': readRoutes,
    'aiQualityChecks': aiQualityChecks,
  };
}

class Options {
  final Map<String, List<String>> xorOptions;

  Options(this.xorOptions);

  Map<String, dynamic> toJson() => {
    'xorOptions': xorOptions,
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
  final List<String> update;
  final bool delete;

  Scopes({
    required this.create,
    required this.read,
    required this.update,
    required this.delete,
  });

  Map<String, dynamic> toJson() => {
    'create': create,
    'read': read,
    'update': update,
    'delete': delete,
  };
}

