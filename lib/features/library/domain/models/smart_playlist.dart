import 'library_item.dart';

/// Fields a smart playlist rule can evaluate against.
enum SmartField {
  type,
  genre,
  tag,
  rating,
  year,
  favorite,
  watched,
  playCount,
  duration,
  bitrate,
  resolution,
}

/// Operators used by [SmartRule].
enum SmartOperator {
  equals,
  notEquals,
  contains,
  notContains,
  greaterThan,
  lessThan,
  atLeast,
  atMost,
  between,
  empty,
  notEmpty,
}

/// How the rules of a smart playlist are combined.
enum LogicalConnective { all, any }

/// Optional ordering for a smart playlist result.
class SmartSort {
  final SmartField field;
  final bool ascending;

  const SmartSort({required this.field, this.ascending = true});
}

/// A single predicate of a smart playlist.
///
/// [value] carries the comparison target (string, number, bool or enum name),
/// and [value2] optionally carries the upper bound for [SmartOperator.between].
class SmartRule {
  final SmartField field;
  final SmartOperator operator;
  final Object? value;
  final Object? value2;

  const SmartRule({
    required this.field,
    required this.operator,
    this.value,
    this.value2,
  });

  /// A rule like `rating >= 8.0`.
  factory SmartRule.ratingAtLeast(double rating) => SmartRule(
        field: SmartField.rating,
        operator: SmartOperator.atLeast,
        value: rating,
      );

  /// A rule like `year == 2024`.
  factory SmartRule.year(int year) => SmartRule(
        field: SmartField.year,
        operator: SmartOperator.equals,
        value: year,
      );

  /// A rule like `tag == "lecture"`.
  factory SmartRule.hasTag(String tag) => SmartRule(
        field: SmartField.tag,
        operator: SmartOperator.contains,
        value: tag,
      );

  /// A rule like `genre == "Sci-fi"`.
  factory SmartRule.hasGenre(String genre) => SmartRule(
        field: SmartField.genre,
        operator: SmartOperator.contains,
        value: genre,
      );

  /// A rule like `favorite == true`.
  factory SmartRule.isFavorite() => SmartRule(
        field: SmartField.favorite,
        operator: SmartOperator.equals,
        value: true,
      );

  /// A rule like `watched == false`.
  factory SmartRule.unwatched() => SmartRule(
        field: SmartField.watched,
        operator: SmartOperator.equals,
        value: false,
      );

  Map<String, dynamic> toJson() => {
        'field': field.name,
        'operator': operator.name,
        'value': value,
        'value2': value2,
      };

  factory SmartRule.fromJson(Map<String, dynamic> json) {
    return SmartRule(
      field: SmartField.values.asNameMap()[json['field']] ?? SmartField.type,
      operator: SmartOperator.values.asNameMap()[json['operator']] ??
          SmartOperator.equals,
      value: json['value'],
      value2: json['value2'],
    );
  }

  @override
  String toString() =>
      'SmartRule(field: $field, operator: $operator, value: $value)';
}

/// A named, rule-driven playlist.
///
/// Unlike a manual playlist, a smart playlist's members are computed on
/// demand by evaluating its rules against the library. Example rules that map
/// directly to section 3.1: "Unwatched lectures", "Favorites from 2024",
/// "Sci-fi > 8.0".
class SmartPlaylist {
  /// Stable identifier of this smart playlist.
  final String id;

  /// Display name.
  final String name;

  /// Optional description.
  final String? description;

  /// The rules that define membership.
  final List<SmartRule> rules;

  /// Whether all rules ([LogicalConnective.all]) or any rule
  /// ([LogicalConnective.any]) must match.
  final LogicalConnective connective;

  /// Optional ordering of the result.
  final SmartSort? sort;

  /// Optional cap on the number of results.
  final int? limit;

  /// When the smart playlist was created.
  final DateTime createdAt;

  /// When the smart playlist was last modified.
  final DateTime updatedAt;

  const SmartPlaylist({
    required this.id,
    required this.name,
    this.description,
    this.rules = const [],
    this.connective = LogicalConnective.all,
    this.sort,
    this.limit,
    required this.createdAt,
    required this.updatedAt,
  });

  SmartPlaylist copyWith({
    String? id,
    String? name,
    String? description,
    List<SmartRule>? rules,
    LogicalConnective? connective,
    SmartSort? sort,
    bool clearSort = false,
    int? limit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SmartPlaylist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      rules: rules ?? this.rules,
      connective: connective ?? this.connective,
      sort: clearSort ? null : sort ?? this.sort,
      limit: limit ?? this.limit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'rules': rules.map((r) => r.toJson()).toList(),
        'connective': connective.name,
        'sort': sort == null
            ? null
            : {'field': sort!.field.name, 'ascending': sort!.ascending},
        'limit': limit,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory SmartPlaylist.fromJson(Map<String, dynamic> json) {
    final sortJson = json['sort'] as Map<String, dynamic>?;
    return SmartPlaylist(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      rules: (json['rules'] as List<dynamic>? ?? const [])
          .map((r) => SmartRule.fromJson((r as Map).cast<String, dynamic>()))
          .toList(),
      connective: LogicalConnective.values.asNameMap()[json['connective']] ??
          LogicalConnective.all,
      sort: sortJson == null
          ? null
          : SmartSort(
              field: SmartField.values.asNameMap()[sortJson['field']] ??
                  SmartField.year,
              ascending: sortJson['ascending'] as bool? ?? true,
            ),
      limit: json['limit'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SmartPlaylist && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'SmartPlaylist(id: $id, name: $name, rules: ${rules.length})';
}

/// Pure evaluation logic for smart playlists.
///
/// Kept free of state and side effects so it can be unit-tested in isolation
/// and reused by the library service and any future sync logic.
class SmartPlaylistMatcher {
  SmartPlaylistMatcher._();

  /// Whether [item] matches every rule of [playlist] (or any rule when the
  /// playlist uses [LogicalConnective.any]).
  static bool matches(LibraryItem item, SmartPlaylist playlist) {
    if (playlist.rules.isEmpty) return true;
    return switch (playlist.connective) {
      LogicalConnective.all => playlist.rules.every((r) => matchesRule(item, r)),
      LogicalConnective.any => playlist.rules.any((r) => matchesRule(item, r)),
    };
  }

  /// Whether [item] satisfies a single [rule].
  static bool matchesRule(LibraryItem item, SmartRule rule) {
    switch (rule.operator) {
      case SmartOperator.empty:
        return _fieldValue(item, rule.field) == null;
      case SmartOperator.notEmpty:
        return _fieldValue(item, rule.field) != null;
      default:
        break;
    }

    final value = _fieldValue(item, rule.field);
    if (value == null) return false;

    switch (rule.field) {
      case SmartField.type:
        return _compareString(value as String, rule, null);
      case SmartField.favorite:
      case SmartField.watched:
        final target = rule.value is bool ? rule.value as bool : false;
        return (value as bool) == target;
      case SmartField.tag:
        return _compareMembership(value as List<String>, rule);
      case SmartField.genre:
        return _compareMembership(value as List<String>, rule);
      case SmartField.rating:
      case SmartField.year:
      case SmartField.playCount:
      case SmartField.duration:
      case SmartField.bitrate:
      case SmartField.resolution:
        return _compareNumber(value as num, rule);
    }
  }

  static Object? _fieldValue(LibraryItem item, SmartField field) {
    return switch (field) {
      SmartField.type => item.media.type.name,
      SmartField.genre =>
        item.media.genres.isEmpty ? null : item.media.genres,
      SmartField.tag => item.tags.isEmpty ? null : item.tags.toList(),
      SmartField.rating => item.rating,
      SmartField.year => item.media.year,
      SmartField.favorite => item.isFavorite,
      SmartField.watched => item.isWatched,
      SmartField.playCount => item.playCount,
      SmartField.duration => item.media.duration?.inSeconds,
      SmartField.bitrate => item.media.bitrate,
      SmartField.resolution => item.media.height,
    };
  }

  static bool _compareString(String actual, SmartRule rule, Object? _) {
    final target = rule.value?.toString() ?? '';
    final a = actual.toLowerCase();
    final t = target.toLowerCase();
    return switch (rule.operator) {
      SmartOperator.equals => a == t,
      SmartOperator.notEquals => a != t,
      SmartOperator.contains => a.contains(t),
      SmartOperator.notContains => !a.contains(t),
      _ => false,
    };
  }

  static bool _compareMembership(List<String> actual, SmartRule rule) {
    final target = rule.value?.toString().toLowerCase() ?? '';
    final values = actual.map((v) => v.toLowerCase()).toList();
    return switch (rule.operator) {
      SmartOperator.contains => values.contains(target),
      SmartOperator.notContains => !values.contains(target),
      SmartOperator.equals => values.length == 1 && values.first == target,
      SmartOperator.notEquals => values.length != 1 || values.first != target,
      SmartOperator.empty => values.isEmpty,
      SmartOperator.notEmpty => values.isNotEmpty,
      _ => false,
    };
  }

  static bool _compareNumber(num actual, SmartRule rule) {
    final lower = (rule.value as num?)?.toDouble();
    final upper = (rule.value2 as num?)?.toDouble();
    return switch (rule.operator) {
      SmartOperator.equals => lower != null && actual == lower,
      SmartOperator.notEquals => lower != null && actual != lower,
      SmartOperator.greaterThan => lower != null && actual > lower,
      SmartOperator.lessThan => lower != null && actual < lower,
      SmartOperator.atLeast => lower != null && actual >= lower,
      SmartOperator.atMost => lower != null && actual <= lower,
      SmartOperator.between =>
        lower != null && upper != null && actual >= lower && actual <= upper,
      _ => false,
    };
  }
}
