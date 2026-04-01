// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kora_database.dart';

// ignore_for_file: type=lint
class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _packageNameMeta = const VerificationMeta(
    'packageName',
  );
  @override
  late final GeneratedColumn<String> packageName = GeneratedColumn<String>(
    'package_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appNameMeta = const VerificationMeta(
    'appName',
  );
  @override
  late final GeneratedColumn<String> appName = GeneratedColumn<String>(
    'app_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _openReasonMeta = const VerificationMeta(
    'openReason',
  );
  @override
  late final GeneratedColumn<String> openReason = GeneratedColumn<String>(
    'open_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _extensionCountMeta = const VerificationMeta(
    'extensionCount',
  );
  @override
  late final GeneratedColumn<int> extensionCount = GeneratedColumn<int>(
    'extension_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _didResistMeta = const VerificationMeta(
    'didResist',
  );
  @override
  late final GeneratedColumn<bool> didResist = GeneratedColumn<bool>(
    'did_resist',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("did_resist" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _risingTideStageReachedMeta =
      const VerificationMeta('risingTideStageReached');
  @override
  late final GeneratedColumn<int> risingTideStageReached = GeneratedColumn<int>(
    'rising_tide_stage_reached',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    packageName,
    appName,
    startedAt,
    endedAt,
    durationSeconds,
    openReason,
    extensionCount,
    didResist,
    risingTideStageReached,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Session> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('package_name')) {
      context.handle(
        _packageNameMeta,
        packageName.isAcceptableOrUnknown(
          data['package_name']!,
          _packageNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_packageNameMeta);
    }
    if (data.containsKey('app_name')) {
      context.handle(
        _appNameMeta,
        appName.isAcceptableOrUnknown(data['app_name']!, _appNameMeta),
      );
    } else if (isInserting) {
      context.missing(_appNameMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('open_reason')) {
      context.handle(
        _openReasonMeta,
        openReason.isAcceptableOrUnknown(data['open_reason']!, _openReasonMeta),
      );
    }
    if (data.containsKey('extension_count')) {
      context.handle(
        _extensionCountMeta,
        extensionCount.isAcceptableOrUnknown(
          data['extension_count']!,
          _extensionCountMeta,
        ),
      );
    }
    if (data.containsKey('did_resist')) {
      context.handle(
        _didResistMeta,
        didResist.isAcceptableOrUnknown(data['did_resist']!, _didResistMeta),
      );
    }
    if (data.containsKey('rising_tide_stage_reached')) {
      context.handle(
        _risingTideStageReachedMeta,
        risingTideStageReached.isAcceptableOrUnknown(
          data['rising_tide_stage_reached']!,
          _risingTideStageReachedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      packageName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}package_name'],
      )!,
      appName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_name'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      ),
      openReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}open_reason'],
      ),
      extensionCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}extension_count'],
      )!,
      didResist: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}did_resist'],
      )!,
      risingTideStageReached: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rising_tide_stage_reached'],
      )!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  final int id;
  final String packageName;
  final String appName;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? durationSeconds;
  final String? openReason;
  final int extensionCount;
  final bool didResist;
  final int risingTideStageReached;
  const Session({
    required this.id,
    required this.packageName,
    required this.appName,
    required this.startedAt,
    this.endedAt,
    this.durationSeconds,
    this.openReason,
    required this.extensionCount,
    required this.didResist,
    required this.risingTideStageReached,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['package_name'] = Variable<String>(packageName);
    map['app_name'] = Variable<String>(appName);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    if (!nullToAbsent || openReason != null) {
      map['open_reason'] = Variable<String>(openReason);
    }
    map['extension_count'] = Variable<int>(extensionCount);
    map['did_resist'] = Variable<bool>(didResist);
    map['rising_tide_stage_reached'] = Variable<int>(risingTideStageReached);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      packageName: Value(packageName),
      appName: Value(appName),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      openReason: openReason == null && nullToAbsent
          ? const Value.absent()
          : Value(openReason),
      extensionCount: Value(extensionCount),
      didResist: Value(didResist),
      risingTideStageReached: Value(risingTideStageReached),
    );
  }

  factory Session.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<int>(json['id']),
      packageName: serializer.fromJson<String>(json['packageName']),
      appName: serializer.fromJson<String>(json['appName']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      openReason: serializer.fromJson<String?>(json['openReason']),
      extensionCount: serializer.fromJson<int>(json['extensionCount']),
      didResist: serializer.fromJson<bool>(json['didResist']),
      risingTideStageReached: serializer.fromJson<int>(
        json['risingTideStageReached'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'packageName': serializer.toJson<String>(packageName),
      'appName': serializer.toJson<String>(appName),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'openReason': serializer.toJson<String?>(openReason),
      'extensionCount': serializer.toJson<int>(extensionCount),
      'didResist': serializer.toJson<bool>(didResist),
      'risingTideStageReached': serializer.toJson<int>(risingTideStageReached),
    };
  }

  Session copyWith({
    int? id,
    String? packageName,
    String? appName,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    Value<int?> durationSeconds = const Value.absent(),
    Value<String?> openReason = const Value.absent(),
    int? extensionCount,
    bool? didResist,
    int? risingTideStageReached,
  }) => Session(
    id: id ?? this.id,
    packageName: packageName ?? this.packageName,
    appName: appName ?? this.appName,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    durationSeconds: durationSeconds.present
        ? durationSeconds.value
        : this.durationSeconds,
    openReason: openReason.present ? openReason.value : this.openReason,
    extensionCount: extensionCount ?? this.extensionCount,
    didResist: didResist ?? this.didResist,
    risingTideStageReached:
        risingTideStageReached ?? this.risingTideStageReached,
  );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      packageName: data.packageName.present
          ? data.packageName.value
          : this.packageName,
      appName: data.appName.present ? data.appName.value : this.appName,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      openReason: data.openReason.present
          ? data.openReason.value
          : this.openReason,
      extensionCount: data.extensionCount.present
          ? data.extensionCount.value
          : this.extensionCount,
      didResist: data.didResist.present ? data.didResist.value : this.didResist,
      risingTideStageReached: data.risingTideStageReached.present
          ? data.risingTideStageReached.value
          : this.risingTideStageReached,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('packageName: $packageName, ')
          ..write('appName: $appName, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('openReason: $openReason, ')
          ..write('extensionCount: $extensionCount, ')
          ..write('didResist: $didResist, ')
          ..write('risingTideStageReached: $risingTideStageReached')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    packageName,
    appName,
    startedAt,
    endedAt,
    durationSeconds,
    openReason,
    extensionCount,
    didResist,
    risingTideStageReached,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.packageName == this.packageName &&
          other.appName == this.appName &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.durationSeconds == this.durationSeconds &&
          other.openReason == this.openReason &&
          other.extensionCount == this.extensionCount &&
          other.didResist == this.didResist &&
          other.risingTideStageReached == this.risingTideStageReached);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<int> id;
  final Value<String> packageName;
  final Value<String> appName;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<int?> durationSeconds;
  final Value<String?> openReason;
  final Value<int> extensionCount;
  final Value<bool> didResist;
  final Value<int> risingTideStageReached;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.packageName = const Value.absent(),
    this.appName = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.openReason = const Value.absent(),
    this.extensionCount = const Value.absent(),
    this.didResist = const Value.absent(),
    this.risingTideStageReached = const Value.absent(),
  });
  SessionsCompanion.insert({
    this.id = const Value.absent(),
    required String packageName,
    required String appName,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.openReason = const Value.absent(),
    this.extensionCount = const Value.absent(),
    this.didResist = const Value.absent(),
    this.risingTideStageReached = const Value.absent(),
  }) : packageName = Value(packageName),
       appName = Value(appName),
       startedAt = Value(startedAt);
  static Insertable<Session> custom({
    Expression<int>? id,
    Expression<String>? packageName,
    Expression<String>? appName,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? durationSeconds,
    Expression<String>? openReason,
    Expression<int>? extensionCount,
    Expression<bool>? didResist,
    Expression<int>? risingTideStageReached,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (packageName != null) 'package_name': packageName,
      if (appName != null) 'app_name': appName,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (openReason != null) 'open_reason': openReason,
      if (extensionCount != null) 'extension_count': extensionCount,
      if (didResist != null) 'did_resist': didResist,
      if (risingTideStageReached != null)
        'rising_tide_stage_reached': risingTideStageReached,
    });
  }

  SessionsCompanion copyWith({
    Value<int>? id,
    Value<String>? packageName,
    Value<String>? appName,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<int?>? durationSeconds,
    Value<String?>? openReason,
    Value<int>? extensionCount,
    Value<bool>? didResist,
    Value<int>? risingTideStageReached,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      openReason: openReason ?? this.openReason,
      extensionCount: extensionCount ?? this.extensionCount,
      didResist: didResist ?? this.didResist,
      risingTideStageReached:
          risingTideStageReached ?? this.risingTideStageReached,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (packageName.present) {
      map['package_name'] = Variable<String>(packageName.value);
    }
    if (appName.present) {
      map['app_name'] = Variable<String>(appName.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (openReason.present) {
      map['open_reason'] = Variable<String>(openReason.value);
    }
    if (extensionCount.present) {
      map['extension_count'] = Variable<int>(extensionCount.value);
    }
    if (didResist.present) {
      map['did_resist'] = Variable<bool>(didResist.value);
    }
    if (risingTideStageReached.present) {
      map['rising_tide_stage_reached'] = Variable<int>(
        risingTideStageReached.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('packageName: $packageName, ')
          ..write('appName: $appName, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('openReason: $openReason, ')
          ..write('extensionCount: $extensionCount, ')
          ..write('didResist: $didResist, ')
          ..write('risingTideStageReached: $risingTideStageReached')
          ..write(')'))
        .toString();
  }
}

class $MoodsTable extends Moods with TableInfo<$MoodsTable, Mood> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MoodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _loggedAtMeta = const VerificationMeta(
    'loggedAt',
  );
  @override
  late final GeneratedColumn<DateTime> loggedAt = GeneratedColumn<DateTime>(
    'logged_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contextMeta = const VerificationMeta(
    'context',
  );
  @override
  late final GeneratedColumn<String> context = GeneratedColumn<String>(
    'context',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    loggedAt,
    score,
    label,
    context,
    sessionId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'moods';
  @override
  VerificationContext validateIntegrity(
    Insertable<Mood> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('logged_at')) {
      context.handle(
        _loggedAtMeta,
        loggedAt.isAcceptableOrUnknown(data['logged_at']!, _loggedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_loggedAtMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('context')) {
      context.handle(
        _contextMeta,
        this.context.isAcceptableOrUnknown(data['context']!, _contextMeta),
      );
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Mood map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Mood(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      loggedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}logged_at'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      context: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context'],
      ),
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      ),
    );
  }

  @override
  $MoodsTable createAlias(String alias) {
    return $MoodsTable(attachedDatabase, alias);
  }
}

class Mood extends DataClass implements Insertable<Mood> {
  final int id;
  final DateTime loggedAt;
  final int score;
  final String? label;
  final String? context;
  final int? sessionId;
  const Mood({
    required this.id,
    required this.loggedAt,
    required this.score,
    this.label,
    this.context,
    this.sessionId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['logged_at'] = Variable<DateTime>(loggedAt);
    map['score'] = Variable<int>(score);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    if (!nullToAbsent || context != null) {
      map['context'] = Variable<String>(context);
    }
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<int>(sessionId);
    }
    return map;
  }

  MoodsCompanion toCompanion(bool nullToAbsent) {
    return MoodsCompanion(
      id: Value(id),
      loggedAt: Value(loggedAt),
      score: Value(score),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      context: context == null && nullToAbsent
          ? const Value.absent()
          : Value(context),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
    );
  }

  factory Mood.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Mood(
      id: serializer.fromJson<int>(json['id']),
      loggedAt: serializer.fromJson<DateTime>(json['loggedAt']),
      score: serializer.fromJson<int>(json['score']),
      label: serializer.fromJson<String?>(json['label']),
      context: serializer.fromJson<String?>(json['context']),
      sessionId: serializer.fromJson<int?>(json['sessionId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'loggedAt': serializer.toJson<DateTime>(loggedAt),
      'score': serializer.toJson<int>(score),
      'label': serializer.toJson<String?>(label),
      'context': serializer.toJson<String?>(context),
      'sessionId': serializer.toJson<int?>(sessionId),
    };
  }

  Mood copyWith({
    int? id,
    DateTime? loggedAt,
    int? score,
    Value<String?> label = const Value.absent(),
    Value<String?> context = const Value.absent(),
    Value<int?> sessionId = const Value.absent(),
  }) => Mood(
    id: id ?? this.id,
    loggedAt: loggedAt ?? this.loggedAt,
    score: score ?? this.score,
    label: label.present ? label.value : this.label,
    context: context.present ? context.value : this.context,
    sessionId: sessionId.present ? sessionId.value : this.sessionId,
  );
  Mood copyWithCompanion(MoodsCompanion data) {
    return Mood(
      id: data.id.present ? data.id.value : this.id,
      loggedAt: data.loggedAt.present ? data.loggedAt.value : this.loggedAt,
      score: data.score.present ? data.score.value : this.score,
      label: data.label.present ? data.label.value : this.label,
      context: data.context.present ? data.context.value : this.context,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Mood(')
          ..write('id: $id, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('score: $score, ')
          ..write('label: $label, ')
          ..write('context: $context, ')
          ..write('sessionId: $sessionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, loggedAt, score, label, context, sessionId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Mood &&
          other.id == this.id &&
          other.loggedAt == this.loggedAt &&
          other.score == this.score &&
          other.label == this.label &&
          other.context == this.context &&
          other.sessionId == this.sessionId);
}

class MoodsCompanion extends UpdateCompanion<Mood> {
  final Value<int> id;
  final Value<DateTime> loggedAt;
  final Value<int> score;
  final Value<String?> label;
  final Value<String?> context;
  final Value<int?> sessionId;
  const MoodsCompanion({
    this.id = const Value.absent(),
    this.loggedAt = const Value.absent(),
    this.score = const Value.absent(),
    this.label = const Value.absent(),
    this.context = const Value.absent(),
    this.sessionId = const Value.absent(),
  });
  MoodsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime loggedAt,
    required int score,
    this.label = const Value.absent(),
    this.context = const Value.absent(),
    this.sessionId = const Value.absent(),
  }) : loggedAt = Value(loggedAt),
       score = Value(score);
  static Insertable<Mood> custom({
    Expression<int>? id,
    Expression<DateTime>? loggedAt,
    Expression<int>? score,
    Expression<String>? label,
    Expression<String>? context,
    Expression<int>? sessionId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (loggedAt != null) 'logged_at': loggedAt,
      if (score != null) 'score': score,
      if (label != null) 'label': label,
      if (context != null) 'context': context,
      if (sessionId != null) 'session_id': sessionId,
    });
  }

  MoodsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? loggedAt,
    Value<int>? score,
    Value<String?>? label,
    Value<String?>? context,
    Value<int?>? sessionId,
  }) {
    return MoodsCompanion(
      id: id ?? this.id,
      loggedAt: loggedAt ?? this.loggedAt,
      score: score ?? this.score,
      label: label ?? this.label,
      context: context ?? this.context,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (loggedAt.present) {
      map['logged_at'] = Variable<DateTime>(loggedAt.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (context.present) {
      map['context'] = Variable<String>(context.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MoodsCompanion(')
          ..write('id: $id, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('score: $score, ')
          ..write('label: $label, ')
          ..write('context: $context, ')
          ..write('sessionId: $sessionId')
          ..write(')'))
        .toString();
  }
}

class $DecisionsTable extends Decisions
    with TableInfo<$DecisionsTable, Decision> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DecisionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _decidedAtMeta = const VerificationMeta(
    'decidedAt',
  );
  @override
  late final GeneratedColumn<DateTime> decidedAt = GeneratedColumn<DateTime>(
    'decided_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _packageNameMeta = const VerificationMeta(
    'packageName',
  );
  @override
  late final GeneratedColumn<String> packageName = GeneratedColumn<String>(
    'package_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openedMeta = const VerificationMeta('opened');
  @override
  late final GeneratedColumn<bool> opened = GeneratedColumn<bool>(
    'opened',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("opened" IN (0, 1))',
    ),
  );
  static const VerificationMeta _resistedCompletelyMeta =
      const VerificationMeta('resistedCompletely');
  @override
  late final GeneratedColumn<bool> resistedCompletely = GeneratedColumn<bool>(
    'resisted_completely',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("resisted_completely" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _tookAlternativeMeta = const VerificationMeta(
    'tookAlternative',
  );
  @override
  late final GeneratedColumn<bool> tookAlternative = GeneratedColumn<bool>(
    'took_alternative',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("took_alternative" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _extensionReasonMeta = const VerificationMeta(
    'extensionReason',
  );
  @override
  late final GeneratedColumn<String> extensionReason = GeneratedColumn<String>(
    'extension_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    decidedAt,
    packageName,
    reason,
    opened,
    resistedCompletely,
    tookAlternative,
    extensionReason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'decisions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Decision> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('decided_at')) {
      context.handle(
        _decidedAtMeta,
        decidedAt.isAcceptableOrUnknown(data['decided_at']!, _decidedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_decidedAtMeta);
    }
    if (data.containsKey('package_name')) {
      context.handle(
        _packageNameMeta,
        packageName.isAcceptableOrUnknown(
          data['package_name']!,
          _packageNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_packageNameMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('opened')) {
      context.handle(
        _openedMeta,
        opened.isAcceptableOrUnknown(data['opened']!, _openedMeta),
      );
    } else if (isInserting) {
      context.missing(_openedMeta);
    }
    if (data.containsKey('resisted_completely')) {
      context.handle(
        _resistedCompletelyMeta,
        resistedCompletely.isAcceptableOrUnknown(
          data['resisted_completely']!,
          _resistedCompletelyMeta,
        ),
      );
    }
    if (data.containsKey('took_alternative')) {
      context.handle(
        _tookAlternativeMeta,
        tookAlternative.isAcceptableOrUnknown(
          data['took_alternative']!,
          _tookAlternativeMeta,
        ),
      );
    }
    if (data.containsKey('extension_reason')) {
      context.handle(
        _extensionReasonMeta,
        extensionReason.isAcceptableOrUnknown(
          data['extension_reason']!,
          _extensionReasonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Decision map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Decision(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      decidedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}decided_at'],
      )!,
      packageName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}package_name'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      opened: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}opened'],
      )!,
      resistedCompletely: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}resisted_completely'],
      )!,
      tookAlternative: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}took_alternative'],
      )!,
      extensionReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extension_reason'],
      ),
    );
  }

  @override
  $DecisionsTable createAlias(String alias) {
    return $DecisionsTable(attachedDatabase, alias);
  }
}

class Decision extends DataClass implements Insertable<Decision> {
  final int id;
  final DateTime decidedAt;
  final String packageName;
  final String reason;
  final bool opened;
  final bool resistedCompletely;
  final bool tookAlternative;
  final String? extensionReason;
  const Decision({
    required this.id,
    required this.decidedAt,
    required this.packageName,
    required this.reason,
    required this.opened,
    required this.resistedCompletely,
    required this.tookAlternative,
    this.extensionReason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['decided_at'] = Variable<DateTime>(decidedAt);
    map['package_name'] = Variable<String>(packageName);
    map['reason'] = Variable<String>(reason);
    map['opened'] = Variable<bool>(opened);
    map['resisted_completely'] = Variable<bool>(resistedCompletely);
    map['took_alternative'] = Variable<bool>(tookAlternative);
    if (!nullToAbsent || extensionReason != null) {
      map['extension_reason'] = Variable<String>(extensionReason);
    }
    return map;
  }

  DecisionsCompanion toCompanion(bool nullToAbsent) {
    return DecisionsCompanion(
      id: Value(id),
      decidedAt: Value(decidedAt),
      packageName: Value(packageName),
      reason: Value(reason),
      opened: Value(opened),
      resistedCompletely: Value(resistedCompletely),
      tookAlternative: Value(tookAlternative),
      extensionReason: extensionReason == null && nullToAbsent
          ? const Value.absent()
          : Value(extensionReason),
    );
  }

  factory Decision.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Decision(
      id: serializer.fromJson<int>(json['id']),
      decidedAt: serializer.fromJson<DateTime>(json['decidedAt']),
      packageName: serializer.fromJson<String>(json['packageName']),
      reason: serializer.fromJson<String>(json['reason']),
      opened: serializer.fromJson<bool>(json['opened']),
      resistedCompletely: serializer.fromJson<bool>(json['resistedCompletely']),
      tookAlternative: serializer.fromJson<bool>(json['tookAlternative']),
      extensionReason: serializer.fromJson<String?>(json['extensionReason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'decidedAt': serializer.toJson<DateTime>(decidedAt),
      'packageName': serializer.toJson<String>(packageName),
      'reason': serializer.toJson<String>(reason),
      'opened': serializer.toJson<bool>(opened),
      'resistedCompletely': serializer.toJson<bool>(resistedCompletely),
      'tookAlternative': serializer.toJson<bool>(tookAlternative),
      'extensionReason': serializer.toJson<String?>(extensionReason),
    };
  }

  Decision copyWith({
    int? id,
    DateTime? decidedAt,
    String? packageName,
    String? reason,
    bool? opened,
    bool? resistedCompletely,
    bool? tookAlternative,
    Value<String?> extensionReason = const Value.absent(),
  }) => Decision(
    id: id ?? this.id,
    decidedAt: decidedAt ?? this.decidedAt,
    packageName: packageName ?? this.packageName,
    reason: reason ?? this.reason,
    opened: opened ?? this.opened,
    resistedCompletely: resistedCompletely ?? this.resistedCompletely,
    tookAlternative: tookAlternative ?? this.tookAlternative,
    extensionReason: extensionReason.present
        ? extensionReason.value
        : this.extensionReason,
  );
  Decision copyWithCompanion(DecisionsCompanion data) {
    return Decision(
      id: data.id.present ? data.id.value : this.id,
      decidedAt: data.decidedAt.present ? data.decidedAt.value : this.decidedAt,
      packageName: data.packageName.present
          ? data.packageName.value
          : this.packageName,
      reason: data.reason.present ? data.reason.value : this.reason,
      opened: data.opened.present ? data.opened.value : this.opened,
      resistedCompletely: data.resistedCompletely.present
          ? data.resistedCompletely.value
          : this.resistedCompletely,
      tookAlternative: data.tookAlternative.present
          ? data.tookAlternative.value
          : this.tookAlternative,
      extensionReason: data.extensionReason.present
          ? data.extensionReason.value
          : this.extensionReason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Decision(')
          ..write('id: $id, ')
          ..write('decidedAt: $decidedAt, ')
          ..write('packageName: $packageName, ')
          ..write('reason: $reason, ')
          ..write('opened: $opened, ')
          ..write('resistedCompletely: $resistedCompletely, ')
          ..write('tookAlternative: $tookAlternative, ')
          ..write('extensionReason: $extensionReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    decidedAt,
    packageName,
    reason,
    opened,
    resistedCompletely,
    tookAlternative,
    extensionReason,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Decision &&
          other.id == this.id &&
          other.decidedAt == this.decidedAt &&
          other.packageName == this.packageName &&
          other.reason == this.reason &&
          other.opened == this.opened &&
          other.resistedCompletely == this.resistedCompletely &&
          other.tookAlternative == this.tookAlternative &&
          other.extensionReason == this.extensionReason);
}

class DecisionsCompanion extends UpdateCompanion<Decision> {
  final Value<int> id;
  final Value<DateTime> decidedAt;
  final Value<String> packageName;
  final Value<String> reason;
  final Value<bool> opened;
  final Value<bool> resistedCompletely;
  final Value<bool> tookAlternative;
  final Value<String?> extensionReason;
  const DecisionsCompanion({
    this.id = const Value.absent(),
    this.decidedAt = const Value.absent(),
    this.packageName = const Value.absent(),
    this.reason = const Value.absent(),
    this.opened = const Value.absent(),
    this.resistedCompletely = const Value.absent(),
    this.tookAlternative = const Value.absent(),
    this.extensionReason = const Value.absent(),
  });
  DecisionsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime decidedAt,
    required String packageName,
    required String reason,
    required bool opened,
    this.resistedCompletely = const Value.absent(),
    this.tookAlternative = const Value.absent(),
    this.extensionReason = const Value.absent(),
  }) : decidedAt = Value(decidedAt),
       packageName = Value(packageName),
       reason = Value(reason),
       opened = Value(opened);
  static Insertable<Decision> custom({
    Expression<int>? id,
    Expression<DateTime>? decidedAt,
    Expression<String>? packageName,
    Expression<String>? reason,
    Expression<bool>? opened,
    Expression<bool>? resistedCompletely,
    Expression<bool>? tookAlternative,
    Expression<String>? extensionReason,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (decidedAt != null) 'decided_at': decidedAt,
      if (packageName != null) 'package_name': packageName,
      if (reason != null) 'reason': reason,
      if (opened != null) 'opened': opened,
      if (resistedCompletely != null) 'resisted_completely': resistedCompletely,
      if (tookAlternative != null) 'took_alternative': tookAlternative,
      if (extensionReason != null) 'extension_reason': extensionReason,
    });
  }

  DecisionsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? decidedAt,
    Value<String>? packageName,
    Value<String>? reason,
    Value<bool>? opened,
    Value<bool>? resistedCompletely,
    Value<bool>? tookAlternative,
    Value<String?>? extensionReason,
  }) {
    return DecisionsCompanion(
      id: id ?? this.id,
      decidedAt: decidedAt ?? this.decidedAt,
      packageName: packageName ?? this.packageName,
      reason: reason ?? this.reason,
      opened: opened ?? this.opened,
      resistedCompletely: resistedCompletely ?? this.resistedCompletely,
      tookAlternative: tookAlternative ?? this.tookAlternative,
      extensionReason: extensionReason ?? this.extensionReason,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (decidedAt.present) {
      map['decided_at'] = Variable<DateTime>(decidedAt.value);
    }
    if (packageName.present) {
      map['package_name'] = Variable<String>(packageName.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (opened.present) {
      map['opened'] = Variable<bool>(opened.value);
    }
    if (resistedCompletely.present) {
      map['resisted_completely'] = Variable<bool>(resistedCompletely.value);
    }
    if (tookAlternative.present) {
      map['took_alternative'] = Variable<bool>(tookAlternative.value);
    }
    if (extensionReason.present) {
      map['extension_reason'] = Variable<String>(extensionReason.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DecisionsCompanion(')
          ..write('id: $id, ')
          ..write('decidedAt: $decidedAt, ')
          ..write('packageName: $packageName, ')
          ..write('reason: $reason, ')
          ..write('opened: $opened, ')
          ..write('resistedCompletely: $resistedCompletely, ')
          ..write('tookAlternative: $tookAlternative, ')
          ..write('extensionReason: $extensionReason')
          ..write(')'))
        .toString();
  }
}

class $IntentionsTable extends Intentions
    with TableInfo<$IntentionsTable, Intention> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IntentionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intentionTextMeta = const VerificationMeta(
    'intentionText',
  );
  @override
  late final GeneratedColumn<String> intentionText = GeneratedColumn<String>(
    'intention_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wasHonouredMeta = const VerificationMeta(
    'wasHonoured',
  );
  @override
  late final GeneratedColumn<bool> wasHonoured = GeneratedColumn<bool>(
    'was_honoured',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("was_honoured" IN (0, 1))',
    ),
  );
  static const VerificationMeta _totalScreenMinutesThatDayMeta =
      const VerificationMeta('totalScreenMinutesThatDay');
  @override
  late final GeneratedColumn<int> totalScreenMinutesThatDay =
      GeneratedColumn<int>(
        'total_screen_minutes_that_day',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _morningMoodLabelMeta = const VerificationMeta(
    'morningMoodLabel',
  );
  @override
  late final GeneratedColumn<String> morningMoodLabel = GeneratedColumn<String>(
    'morning_mood_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    intentionText,
    wasHonoured,
    totalScreenMinutesThatDay,
    morningMoodLabel,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'intentions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Intention> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('intention_text')) {
      context.handle(
        _intentionTextMeta,
        intentionText.isAcceptableOrUnknown(
          data['intention_text']!,
          _intentionTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_intentionTextMeta);
    }
    if (data.containsKey('was_honoured')) {
      context.handle(
        _wasHonouredMeta,
        wasHonoured.isAcceptableOrUnknown(
          data['was_honoured']!,
          _wasHonouredMeta,
        ),
      );
    }
    if (data.containsKey('total_screen_minutes_that_day')) {
      context.handle(
        _totalScreenMinutesThatDayMeta,
        totalScreenMinutesThatDay.isAcceptableOrUnknown(
          data['total_screen_minutes_that_day']!,
          _totalScreenMinutesThatDayMeta,
        ),
      );
    }
    if (data.containsKey('morning_mood_label')) {
      context.handle(
        _morningMoodLabelMeta,
        morningMoodLabel.isAcceptableOrUnknown(
          data['morning_mood_label']!,
          _morningMoodLabelMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Intention map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Intention(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      intentionText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}intention_text'],
      )!,
      wasHonoured: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}was_honoured'],
      ),
      totalScreenMinutesThatDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_screen_minutes_that_day'],
      ),
      morningMoodLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}morning_mood_label'],
      ),
    );
  }

  @override
  $IntentionsTable createAlias(String alias) {
    return $IntentionsTable(attachedDatabase, alias);
  }
}

class Intention extends DataClass implements Insertable<Intention> {
  final int id;
  final DateTime date;
  final String intentionText;
  final bool? wasHonoured;
  final int? totalScreenMinutesThatDay;
  final String? morningMoodLabel;
  const Intention({
    required this.id,
    required this.date,
    required this.intentionText,
    this.wasHonoured,
    this.totalScreenMinutesThatDay,
    this.morningMoodLabel,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['intention_text'] = Variable<String>(intentionText);
    if (!nullToAbsent || wasHonoured != null) {
      map['was_honoured'] = Variable<bool>(wasHonoured);
    }
    if (!nullToAbsent || totalScreenMinutesThatDay != null) {
      map['total_screen_minutes_that_day'] = Variable<int>(
        totalScreenMinutesThatDay,
      );
    }
    if (!nullToAbsent || morningMoodLabel != null) {
      map['morning_mood_label'] = Variable<String>(morningMoodLabel);
    }
    return map;
  }

  IntentionsCompanion toCompanion(bool nullToAbsent) {
    return IntentionsCompanion(
      id: Value(id),
      date: Value(date),
      intentionText: Value(intentionText),
      wasHonoured: wasHonoured == null && nullToAbsent
          ? const Value.absent()
          : Value(wasHonoured),
      totalScreenMinutesThatDay:
          totalScreenMinutesThatDay == null && nullToAbsent
          ? const Value.absent()
          : Value(totalScreenMinutesThatDay),
      morningMoodLabel: morningMoodLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(morningMoodLabel),
    );
  }

  factory Intention.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Intention(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      intentionText: serializer.fromJson<String>(json['intentionText']),
      wasHonoured: serializer.fromJson<bool?>(json['wasHonoured']),
      totalScreenMinutesThatDay: serializer.fromJson<int?>(
        json['totalScreenMinutesThatDay'],
      ),
      morningMoodLabel: serializer.fromJson<String?>(json['morningMoodLabel']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'intentionText': serializer.toJson<String>(intentionText),
      'wasHonoured': serializer.toJson<bool?>(wasHonoured),
      'totalScreenMinutesThatDay': serializer.toJson<int?>(
        totalScreenMinutesThatDay,
      ),
      'morningMoodLabel': serializer.toJson<String?>(morningMoodLabel),
    };
  }

  Intention copyWith({
    int? id,
    DateTime? date,
    String? intentionText,
    Value<bool?> wasHonoured = const Value.absent(),
    Value<int?> totalScreenMinutesThatDay = const Value.absent(),
    Value<String?> morningMoodLabel = const Value.absent(),
  }) => Intention(
    id: id ?? this.id,
    date: date ?? this.date,
    intentionText: intentionText ?? this.intentionText,
    wasHonoured: wasHonoured.present ? wasHonoured.value : this.wasHonoured,
    totalScreenMinutesThatDay: totalScreenMinutesThatDay.present
        ? totalScreenMinutesThatDay.value
        : this.totalScreenMinutesThatDay,
    morningMoodLabel: morningMoodLabel.present
        ? morningMoodLabel.value
        : this.morningMoodLabel,
  );
  Intention copyWithCompanion(IntentionsCompanion data) {
    return Intention(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      intentionText: data.intentionText.present
          ? data.intentionText.value
          : this.intentionText,
      wasHonoured: data.wasHonoured.present
          ? data.wasHonoured.value
          : this.wasHonoured,
      totalScreenMinutesThatDay: data.totalScreenMinutesThatDay.present
          ? data.totalScreenMinutesThatDay.value
          : this.totalScreenMinutesThatDay,
      morningMoodLabel: data.morningMoodLabel.present
          ? data.morningMoodLabel.value
          : this.morningMoodLabel,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Intention(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('intentionText: $intentionText, ')
          ..write('wasHonoured: $wasHonoured, ')
          ..write('totalScreenMinutesThatDay: $totalScreenMinutesThatDay, ')
          ..write('morningMoodLabel: $morningMoodLabel')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    intentionText,
    wasHonoured,
    totalScreenMinutesThatDay,
    morningMoodLabel,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Intention &&
          other.id == this.id &&
          other.date == this.date &&
          other.intentionText == this.intentionText &&
          other.wasHonoured == this.wasHonoured &&
          other.totalScreenMinutesThatDay == this.totalScreenMinutesThatDay &&
          other.morningMoodLabel == this.morningMoodLabel);
}

class IntentionsCompanion extends UpdateCompanion<Intention> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<String> intentionText;
  final Value<bool?> wasHonoured;
  final Value<int?> totalScreenMinutesThatDay;
  final Value<String?> morningMoodLabel;
  const IntentionsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.intentionText = const Value.absent(),
    this.wasHonoured = const Value.absent(),
    this.totalScreenMinutesThatDay = const Value.absent(),
    this.morningMoodLabel = const Value.absent(),
  });
  IntentionsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required String intentionText,
    this.wasHonoured = const Value.absent(),
    this.totalScreenMinutesThatDay = const Value.absent(),
    this.morningMoodLabel = const Value.absent(),
  }) : date = Value(date),
       intentionText = Value(intentionText);
  static Insertable<Intention> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<String>? intentionText,
    Expression<bool>? wasHonoured,
    Expression<int>? totalScreenMinutesThatDay,
    Expression<String>? morningMoodLabel,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (intentionText != null) 'intention_text': intentionText,
      if (wasHonoured != null) 'was_honoured': wasHonoured,
      if (totalScreenMinutesThatDay != null)
        'total_screen_minutes_that_day': totalScreenMinutesThatDay,
      if (morningMoodLabel != null) 'morning_mood_label': morningMoodLabel,
    });
  }

  IntentionsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<String>? intentionText,
    Value<bool?>? wasHonoured,
    Value<int?>? totalScreenMinutesThatDay,
    Value<String?>? morningMoodLabel,
  }) {
    return IntentionsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      intentionText: intentionText ?? this.intentionText,
      wasHonoured: wasHonoured ?? this.wasHonoured,
      totalScreenMinutesThatDay:
          totalScreenMinutesThatDay ?? this.totalScreenMinutesThatDay,
      morningMoodLabel: morningMoodLabel ?? this.morningMoodLabel,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (intentionText.present) {
      map['intention_text'] = Variable<String>(intentionText.value);
    }
    if (wasHonoured.present) {
      map['was_honoured'] = Variable<bool>(wasHonoured.value);
    }
    if (totalScreenMinutesThatDay.present) {
      map['total_screen_minutes_that_day'] = Variable<int>(
        totalScreenMinutesThatDay.value,
      );
    }
    if (morningMoodLabel.present) {
      map['morning_mood_label'] = Variable<String>(morningMoodLabel.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IntentionsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('intentionText: $intentionText, ')
          ..write('wasHonoured: $wasHonoured, ')
          ..write('totalScreenMinutesThatDay: $totalScreenMinutesThatDay, ')
          ..write('morningMoodLabel: $morningMoodLabel')
          ..write(')'))
        .toString();
  }
}

class $TideEventsTable extends TideEvents
    with TableInfo<$TideEventsTable, TideEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TideEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _packageNameMeta = const VerificationMeta(
    'packageName',
  );
  @override
  late final GeneratedColumn<String> packageName = GeneratedColumn<String>(
    'package_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detailMeta = const VerificationMeta('detail');
  @override
  late final GeneratedColumn<String> detail = GeneratedColumn<String>(
    'detail',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stageMeta = const VerificationMeta('stage');
  @override
  late final GeneratedColumn<int> stage = GeneratedColumn<int>(
    'stage',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    timestamp,
    packageName,
    eventType,
    detail,
    stage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tide_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<TideEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('package_name')) {
      context.handle(
        _packageNameMeta,
        packageName.isAcceptableOrUnknown(
          data['package_name']!,
          _packageNameMeta,
        ),
      );
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('detail')) {
      context.handle(
        _detailMeta,
        detail.isAcceptableOrUnknown(data['detail']!, _detailMeta),
      );
    }
    if (data.containsKey('stage')) {
      context.handle(
        _stageMeta,
        stage.isAcceptableOrUnknown(data['stage']!, _stageMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TideEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TideEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      packageName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}package_name'],
      ),
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      detail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detail'],
      ),
      stage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage'],
      ),
    );
  }

  @override
  $TideEventsTable createAlias(String alias) {
    return $TideEventsTable(attachedDatabase, alias);
  }
}

class TideEvent extends DataClass implements Insertable<TideEvent> {
  final int id;
  final DateTime timestamp;
  final String? packageName;
  final String eventType;
  final String? detail;
  final int? stage;
  const TideEvent({
    required this.id,
    required this.timestamp,
    this.packageName,
    required this.eventType,
    this.detail,
    this.stage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || packageName != null) {
      map['package_name'] = Variable<String>(packageName);
    }
    map['event_type'] = Variable<String>(eventType);
    if (!nullToAbsent || detail != null) {
      map['detail'] = Variable<String>(detail);
    }
    if (!nullToAbsent || stage != null) {
      map['stage'] = Variable<int>(stage);
    }
    return map;
  }

  TideEventsCompanion toCompanion(bool nullToAbsent) {
    return TideEventsCompanion(
      id: Value(id),
      timestamp: Value(timestamp),
      packageName: packageName == null && nullToAbsent
          ? const Value.absent()
          : Value(packageName),
      eventType: Value(eventType),
      detail: detail == null && nullToAbsent
          ? const Value.absent()
          : Value(detail),
      stage: stage == null && nullToAbsent
          ? const Value.absent()
          : Value(stage),
    );
  }

  factory TideEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TideEvent(
      id: serializer.fromJson<int>(json['id']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      packageName: serializer.fromJson<String?>(json['packageName']),
      eventType: serializer.fromJson<String>(json['eventType']),
      detail: serializer.fromJson<String?>(json['detail']),
      stage: serializer.fromJson<int?>(json['stage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'packageName': serializer.toJson<String?>(packageName),
      'eventType': serializer.toJson<String>(eventType),
      'detail': serializer.toJson<String?>(detail),
      'stage': serializer.toJson<int?>(stage),
    };
  }

  TideEvent copyWith({
    int? id,
    DateTime? timestamp,
    Value<String?> packageName = const Value.absent(),
    String? eventType,
    Value<String?> detail = const Value.absent(),
    Value<int?> stage = const Value.absent(),
  }) => TideEvent(
    id: id ?? this.id,
    timestamp: timestamp ?? this.timestamp,
    packageName: packageName.present ? packageName.value : this.packageName,
    eventType: eventType ?? this.eventType,
    detail: detail.present ? detail.value : this.detail,
    stage: stage.present ? stage.value : this.stage,
  );
  TideEvent copyWithCompanion(TideEventsCompanion data) {
    return TideEvent(
      id: data.id.present ? data.id.value : this.id,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      packageName: data.packageName.present
          ? data.packageName.value
          : this.packageName,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      detail: data.detail.present ? data.detail.value : this.detail,
      stage: data.stage.present ? data.stage.value : this.stage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TideEvent(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('packageName: $packageName, ')
          ..write('eventType: $eventType, ')
          ..write('detail: $detail, ')
          ..write('stage: $stage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, timestamp, packageName, eventType, detail, stage);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TideEvent &&
          other.id == this.id &&
          other.timestamp == this.timestamp &&
          other.packageName == this.packageName &&
          other.eventType == this.eventType &&
          other.detail == this.detail &&
          other.stage == this.stage);
}

class TideEventsCompanion extends UpdateCompanion<TideEvent> {
  final Value<int> id;
  final Value<DateTime> timestamp;
  final Value<String?> packageName;
  final Value<String> eventType;
  final Value<String?> detail;
  final Value<int?> stage;
  const TideEventsCompanion({
    this.id = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.packageName = const Value.absent(),
    this.eventType = const Value.absent(),
    this.detail = const Value.absent(),
    this.stage = const Value.absent(),
  });
  TideEventsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime timestamp,
    this.packageName = const Value.absent(),
    required String eventType,
    this.detail = const Value.absent(),
    this.stage = const Value.absent(),
  }) : timestamp = Value(timestamp),
       eventType = Value(eventType);
  static Insertable<TideEvent> custom({
    Expression<int>? id,
    Expression<DateTime>? timestamp,
    Expression<String>? packageName,
    Expression<String>? eventType,
    Expression<String>? detail,
    Expression<int>? stage,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timestamp != null) 'timestamp': timestamp,
      if (packageName != null) 'package_name': packageName,
      if (eventType != null) 'event_type': eventType,
      if (detail != null) 'detail': detail,
      if (stage != null) 'stage': stage,
    });
  }

  TideEventsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? timestamp,
    Value<String?>? packageName,
    Value<String>? eventType,
    Value<String?>? detail,
    Value<int?>? stage,
  }) {
    return TideEventsCompanion(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      packageName: packageName ?? this.packageName,
      eventType: eventType ?? this.eventType,
      detail: detail ?? this.detail,
      stage: stage ?? this.stage,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (packageName.present) {
      map['package_name'] = Variable<String>(packageName.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (detail.present) {
      map['detail'] = Variable<String>(detail.value);
    }
    if (stage.present) {
      map['stage'] = Variable<int>(stage.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TideEventsCompanion(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('packageName: $packageName, ')
          ..write('eventType: $eventType, ')
          ..write('detail: $detail, ')
          ..write('stage: $stage')
          ..write(')'))
        .toString();
  }
}

class $TodosTable extends Todos with TableInfo<$TodosTable, Todo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TodosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    isCompleted,
    createdAt,
    completedAt,
    priority,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'todos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Todo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Todo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Todo(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
    );
  }

  @override
  $TodosTable createAlias(String alias) {
    return $TodosTable(attachedDatabase, alias);
  }
}

class Todo extends DataClass implements Insertable<Todo> {
  final int id;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int priority;
  const Todo({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.createdAt,
    this.completedAt,
    required this.priority,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['is_completed'] = Variable<bool>(isCompleted);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['priority'] = Variable<int>(priority);
    return map;
  }

  TodosCompanion toCompanion(bool nullToAbsent) {
    return TodosCompanion(
      id: Value(id),
      title: Value(title),
      isCompleted: Value(isCompleted),
      createdAt: Value(createdAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      priority: Value(priority),
    );
  }

  factory Todo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Todo(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      priority: serializer.fromJson<int>(json['priority']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'priority': serializer.toJson<int>(priority),
    };
  }

  Todo copyWith({
    int? id,
    String? title,
    bool? isCompleted,
    DateTime? createdAt,
    Value<DateTime?> completedAt = const Value.absent(),
    int? priority,
  }) => Todo(
    id: id ?? this.id,
    title: title ?? this.title,
    isCompleted: isCompleted ?? this.isCompleted,
    createdAt: createdAt ?? this.createdAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    priority: priority ?? this.priority,
  );
  Todo copyWithCompanion(TodosCompanion data) {
    return Todo(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      priority: data.priority.present ? data.priority.value : this.priority,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Todo(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('priority: $priority')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, isCompleted, createdAt, completedAt, priority);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Todo &&
          other.id == this.id &&
          other.title == this.title &&
          other.isCompleted == this.isCompleted &&
          other.createdAt == this.createdAt &&
          other.completedAt == this.completedAt &&
          other.priority == this.priority);
}

class TodosCompanion extends UpdateCompanion<Todo> {
  final Value<int> id;
  final Value<String> title;
  final Value<bool> isCompleted;
  final Value<DateTime> createdAt;
  final Value<DateTime?> completedAt;
  final Value<int> priority;
  const TodosCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.priority = const Value.absent(),
  });
  TodosCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.isCompleted = const Value.absent(),
    required DateTime createdAt,
    this.completedAt = const Value.absent(),
    this.priority = const Value.absent(),
  }) : title = Value(title),
       createdAt = Value(createdAt);
  static Insertable<Todo> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<bool>? isCompleted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? completedAt,
    Expression<int>? priority,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (createdAt != null) 'created_at': createdAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (priority != null) 'priority': priority,
    });
  }

  TodosCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<bool>? isCompleted,
    Value<DateTime>? createdAt,
    Value<DateTime?>? completedAt,
    Value<int>? priority,
  }) {
    return TodosCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      priority: priority ?? this.priority,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TodosCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('priority: $priority')
          ..write(')'))
        .toString();
  }
}

abstract class _$KoraDatabase extends GeneratedDatabase {
  _$KoraDatabase(QueryExecutor e) : super(e);
  $KoraDatabaseManager get managers => $KoraDatabaseManager(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $MoodsTable moods = $MoodsTable(this);
  late final $DecisionsTable decisions = $DecisionsTable(this);
  late final $IntentionsTable intentions = $IntentionsTable(this);
  late final $TideEventsTable tideEvents = $TideEventsTable(this);
  late final $TodosTable todos = $TodosTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sessions,
    moods,
    decisions,
    intentions,
    tideEvents,
    todos,
  ];
}

typedef $$SessionsTableCreateCompanionBuilder =
    SessionsCompanion Function({
      Value<int> id,
      required String packageName,
      required String appName,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      Value<int?> durationSeconds,
      Value<String?> openReason,
      Value<int> extensionCount,
      Value<bool> didResist,
      Value<int> risingTideStageReached,
    });
typedef $$SessionsTableUpdateCompanionBuilder =
    SessionsCompanion Function({
      Value<int> id,
      Value<String> packageName,
      Value<String> appName,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<int?> durationSeconds,
      Value<String?> openReason,
      Value<int> extensionCount,
      Value<bool> didResist,
      Value<int> risingTideStageReached,
    });

class $$SessionsTableFilterComposer
    extends Composer<_$KoraDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appName => $composableBuilder(
    column: $table.appName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get openReason => $composableBuilder(
    column: $table.openReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get extensionCount => $composableBuilder(
    column: $table.extensionCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get didResist => $composableBuilder(
    column: $table.didResist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get risingTideStageReached => $composableBuilder(
    column: $table.risingTideStageReached,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionsTableOrderingComposer
    extends Composer<_$KoraDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appName => $composableBuilder(
    column: $table.appName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get openReason => $composableBuilder(
    column: $table.openReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get extensionCount => $composableBuilder(
    column: $table.extensionCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get didResist => $composableBuilder(
    column: $table.didResist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get risingTideStageReached => $composableBuilder(
    column: $table.risingTideStageReached,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$KoraDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get appName =>
      $composableBuilder(column: $table.appName, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get openReason => $composableBuilder(
    column: $table.openReason,
    builder: (column) => column,
  );

  GeneratedColumn<int> get extensionCount => $composableBuilder(
    column: $table.extensionCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get didResist =>
      $composableBuilder(column: $table.didResist, builder: (column) => column);

  GeneratedColumn<int> get risingTideStageReached => $composableBuilder(
    column: $table.risingTideStageReached,
    builder: (column) => column,
  );
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$KoraDatabase,
          $SessionsTable,
          Session,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (Session, BaseReferences<_$KoraDatabase, $SessionsTable, Session>),
          Session,
          PrefetchHooks Function()
        > {
  $$SessionsTableTableManager(_$KoraDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> packageName = const Value.absent(),
                Value<String> appName = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<String?> openReason = const Value.absent(),
                Value<int> extensionCount = const Value.absent(),
                Value<bool> didResist = const Value.absent(),
                Value<int> risingTideStageReached = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                packageName: packageName,
                appName: appName,
                startedAt: startedAt,
                endedAt: endedAt,
                durationSeconds: durationSeconds,
                openReason: openReason,
                extensionCount: extensionCount,
                didResist: didResist,
                risingTideStageReached: risingTideStageReached,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String packageName,
                required String appName,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<String?> openReason = const Value.absent(),
                Value<int> extensionCount = const Value.absent(),
                Value<bool> didResist = const Value.absent(),
                Value<int> risingTideStageReached = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                packageName: packageName,
                appName: appName,
                startedAt: startedAt,
                endedAt: endedAt,
                durationSeconds: durationSeconds,
                openReason: openReason,
                extensionCount: extensionCount,
                didResist: didResist,
                risingTideStageReached: risingTideStageReached,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$KoraDatabase,
      $SessionsTable,
      Session,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (Session, BaseReferences<_$KoraDatabase, $SessionsTable, Session>),
      Session,
      PrefetchHooks Function()
    >;
typedef $$MoodsTableCreateCompanionBuilder =
    MoodsCompanion Function({
      Value<int> id,
      required DateTime loggedAt,
      required int score,
      Value<String?> label,
      Value<String?> context,
      Value<int?> sessionId,
    });
typedef $$MoodsTableUpdateCompanionBuilder =
    MoodsCompanion Function({
      Value<int> id,
      Value<DateTime> loggedAt,
      Value<int> score,
      Value<String?> label,
      Value<String?> context,
      Value<int?> sessionId,
    });

class $$MoodsTableFilterComposer extends Composer<_$KoraDatabase, $MoodsTable> {
  $$MoodsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get context => $composableBuilder(
    column: $table.context,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MoodsTableOrderingComposer
    extends Composer<_$KoraDatabase, $MoodsTable> {
  $$MoodsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get context => $composableBuilder(
    column: $table.context,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MoodsTableAnnotationComposer
    extends Composer<_$KoraDatabase, $MoodsTable> {
  $$MoodsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get loggedAt =>
      $composableBuilder(column: $table.loggedAt, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get context =>
      $composableBuilder(column: $table.context, builder: (column) => column);

  GeneratedColumn<int> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);
}

class $$MoodsTableTableManager
    extends
        RootTableManager<
          _$KoraDatabase,
          $MoodsTable,
          Mood,
          $$MoodsTableFilterComposer,
          $$MoodsTableOrderingComposer,
          $$MoodsTableAnnotationComposer,
          $$MoodsTableCreateCompanionBuilder,
          $$MoodsTableUpdateCompanionBuilder,
          (Mood, BaseReferences<_$KoraDatabase, $MoodsTable, Mood>),
          Mood,
          PrefetchHooks Function()
        > {
  $$MoodsTableTableManager(_$KoraDatabase db, $MoodsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MoodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MoodsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MoodsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> loggedAt = const Value.absent(),
                Value<int> score = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<String?> context = const Value.absent(),
                Value<int?> sessionId = const Value.absent(),
              }) => MoodsCompanion(
                id: id,
                loggedAt: loggedAt,
                score: score,
                label: label,
                context: context,
                sessionId: sessionId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime loggedAt,
                required int score,
                Value<String?> label = const Value.absent(),
                Value<String?> context = const Value.absent(),
                Value<int?> sessionId = const Value.absent(),
              }) => MoodsCompanion.insert(
                id: id,
                loggedAt: loggedAt,
                score: score,
                label: label,
                context: context,
                sessionId: sessionId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MoodsTableProcessedTableManager =
    ProcessedTableManager<
      _$KoraDatabase,
      $MoodsTable,
      Mood,
      $$MoodsTableFilterComposer,
      $$MoodsTableOrderingComposer,
      $$MoodsTableAnnotationComposer,
      $$MoodsTableCreateCompanionBuilder,
      $$MoodsTableUpdateCompanionBuilder,
      (Mood, BaseReferences<_$KoraDatabase, $MoodsTable, Mood>),
      Mood,
      PrefetchHooks Function()
    >;
typedef $$DecisionsTableCreateCompanionBuilder =
    DecisionsCompanion Function({
      Value<int> id,
      required DateTime decidedAt,
      required String packageName,
      required String reason,
      required bool opened,
      Value<bool> resistedCompletely,
      Value<bool> tookAlternative,
      Value<String?> extensionReason,
    });
typedef $$DecisionsTableUpdateCompanionBuilder =
    DecisionsCompanion Function({
      Value<int> id,
      Value<DateTime> decidedAt,
      Value<String> packageName,
      Value<String> reason,
      Value<bool> opened,
      Value<bool> resistedCompletely,
      Value<bool> tookAlternative,
      Value<String?> extensionReason,
    });

class $$DecisionsTableFilterComposer
    extends Composer<_$KoraDatabase, $DecisionsTable> {
  $$DecisionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get decidedAt => $composableBuilder(
    column: $table.decidedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get opened => $composableBuilder(
    column: $table.opened,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get resistedCompletely => $composableBuilder(
    column: $table.resistedCompletely,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get tookAlternative => $composableBuilder(
    column: $table.tookAlternative,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extensionReason => $composableBuilder(
    column: $table.extensionReason,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DecisionsTableOrderingComposer
    extends Composer<_$KoraDatabase, $DecisionsTable> {
  $$DecisionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get decidedAt => $composableBuilder(
    column: $table.decidedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get opened => $composableBuilder(
    column: $table.opened,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get resistedCompletely => $composableBuilder(
    column: $table.resistedCompletely,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get tookAlternative => $composableBuilder(
    column: $table.tookAlternative,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extensionReason => $composableBuilder(
    column: $table.extensionReason,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DecisionsTableAnnotationComposer
    extends Composer<_$KoraDatabase, $DecisionsTable> {
  $$DecisionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get decidedAt =>
      $composableBuilder(column: $table.decidedAt, builder: (column) => column);

  GeneratedColumn<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<bool> get opened =>
      $composableBuilder(column: $table.opened, builder: (column) => column);

  GeneratedColumn<bool> get resistedCompletely => $composableBuilder(
    column: $table.resistedCompletely,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get tookAlternative => $composableBuilder(
    column: $table.tookAlternative,
    builder: (column) => column,
  );

  GeneratedColumn<String> get extensionReason => $composableBuilder(
    column: $table.extensionReason,
    builder: (column) => column,
  );
}

class $$DecisionsTableTableManager
    extends
        RootTableManager<
          _$KoraDatabase,
          $DecisionsTable,
          Decision,
          $$DecisionsTableFilterComposer,
          $$DecisionsTableOrderingComposer,
          $$DecisionsTableAnnotationComposer,
          $$DecisionsTableCreateCompanionBuilder,
          $$DecisionsTableUpdateCompanionBuilder,
          (Decision, BaseReferences<_$KoraDatabase, $DecisionsTable, Decision>),
          Decision,
          PrefetchHooks Function()
        > {
  $$DecisionsTableTableManager(_$KoraDatabase db, $DecisionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DecisionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DecisionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DecisionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> decidedAt = const Value.absent(),
                Value<String> packageName = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<bool> opened = const Value.absent(),
                Value<bool> resistedCompletely = const Value.absent(),
                Value<bool> tookAlternative = const Value.absent(),
                Value<String?> extensionReason = const Value.absent(),
              }) => DecisionsCompanion(
                id: id,
                decidedAt: decidedAt,
                packageName: packageName,
                reason: reason,
                opened: opened,
                resistedCompletely: resistedCompletely,
                tookAlternative: tookAlternative,
                extensionReason: extensionReason,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime decidedAt,
                required String packageName,
                required String reason,
                required bool opened,
                Value<bool> resistedCompletely = const Value.absent(),
                Value<bool> tookAlternative = const Value.absent(),
                Value<String?> extensionReason = const Value.absent(),
              }) => DecisionsCompanion.insert(
                id: id,
                decidedAt: decidedAt,
                packageName: packageName,
                reason: reason,
                opened: opened,
                resistedCompletely: resistedCompletely,
                tookAlternative: tookAlternative,
                extensionReason: extensionReason,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DecisionsTableProcessedTableManager =
    ProcessedTableManager<
      _$KoraDatabase,
      $DecisionsTable,
      Decision,
      $$DecisionsTableFilterComposer,
      $$DecisionsTableOrderingComposer,
      $$DecisionsTableAnnotationComposer,
      $$DecisionsTableCreateCompanionBuilder,
      $$DecisionsTableUpdateCompanionBuilder,
      (Decision, BaseReferences<_$KoraDatabase, $DecisionsTable, Decision>),
      Decision,
      PrefetchHooks Function()
    >;
typedef $$IntentionsTableCreateCompanionBuilder =
    IntentionsCompanion Function({
      Value<int> id,
      required DateTime date,
      required String intentionText,
      Value<bool?> wasHonoured,
      Value<int?> totalScreenMinutesThatDay,
      Value<String?> morningMoodLabel,
    });
typedef $$IntentionsTableUpdateCompanionBuilder =
    IntentionsCompanion Function({
      Value<int> id,
      Value<DateTime> date,
      Value<String> intentionText,
      Value<bool?> wasHonoured,
      Value<int?> totalScreenMinutesThatDay,
      Value<String?> morningMoodLabel,
    });

class $$IntentionsTableFilterComposer
    extends Composer<_$KoraDatabase, $IntentionsTable> {
  $$IntentionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get intentionText => $composableBuilder(
    column: $table.intentionText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get wasHonoured => $composableBuilder(
    column: $table.wasHonoured,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalScreenMinutesThatDay => $composableBuilder(
    column: $table.totalScreenMinutesThatDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get morningMoodLabel => $composableBuilder(
    column: $table.morningMoodLabel,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IntentionsTableOrderingComposer
    extends Composer<_$KoraDatabase, $IntentionsTable> {
  $$IntentionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get intentionText => $composableBuilder(
    column: $table.intentionText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get wasHonoured => $composableBuilder(
    column: $table.wasHonoured,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalScreenMinutesThatDay => $composableBuilder(
    column: $table.totalScreenMinutesThatDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get morningMoodLabel => $composableBuilder(
    column: $table.morningMoodLabel,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IntentionsTableAnnotationComposer
    extends Composer<_$KoraDatabase, $IntentionsTable> {
  $$IntentionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get intentionText => $composableBuilder(
    column: $table.intentionText,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get wasHonoured => $composableBuilder(
    column: $table.wasHonoured,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalScreenMinutesThatDay => $composableBuilder(
    column: $table.totalScreenMinutesThatDay,
    builder: (column) => column,
  );

  GeneratedColumn<String> get morningMoodLabel => $composableBuilder(
    column: $table.morningMoodLabel,
    builder: (column) => column,
  );
}

class $$IntentionsTableTableManager
    extends
        RootTableManager<
          _$KoraDatabase,
          $IntentionsTable,
          Intention,
          $$IntentionsTableFilterComposer,
          $$IntentionsTableOrderingComposer,
          $$IntentionsTableAnnotationComposer,
          $$IntentionsTableCreateCompanionBuilder,
          $$IntentionsTableUpdateCompanionBuilder,
          (
            Intention,
            BaseReferences<_$KoraDatabase, $IntentionsTable, Intention>,
          ),
          Intention,
          PrefetchHooks Function()
        > {
  $$IntentionsTableTableManager(_$KoraDatabase db, $IntentionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IntentionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IntentionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IntentionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> intentionText = const Value.absent(),
                Value<bool?> wasHonoured = const Value.absent(),
                Value<int?> totalScreenMinutesThatDay = const Value.absent(),
                Value<String?> morningMoodLabel = const Value.absent(),
              }) => IntentionsCompanion(
                id: id,
                date: date,
                intentionText: intentionText,
                wasHonoured: wasHonoured,
                totalScreenMinutesThatDay: totalScreenMinutesThatDay,
                morningMoodLabel: morningMoodLabel,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                required String intentionText,
                Value<bool?> wasHonoured = const Value.absent(),
                Value<int?> totalScreenMinutesThatDay = const Value.absent(),
                Value<String?> morningMoodLabel = const Value.absent(),
              }) => IntentionsCompanion.insert(
                id: id,
                date: date,
                intentionText: intentionText,
                wasHonoured: wasHonoured,
                totalScreenMinutesThatDay: totalScreenMinutesThatDay,
                morningMoodLabel: morningMoodLabel,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IntentionsTableProcessedTableManager =
    ProcessedTableManager<
      _$KoraDatabase,
      $IntentionsTable,
      Intention,
      $$IntentionsTableFilterComposer,
      $$IntentionsTableOrderingComposer,
      $$IntentionsTableAnnotationComposer,
      $$IntentionsTableCreateCompanionBuilder,
      $$IntentionsTableUpdateCompanionBuilder,
      (Intention, BaseReferences<_$KoraDatabase, $IntentionsTable, Intention>),
      Intention,
      PrefetchHooks Function()
    >;
typedef $$TideEventsTableCreateCompanionBuilder =
    TideEventsCompanion Function({
      Value<int> id,
      required DateTime timestamp,
      Value<String?> packageName,
      required String eventType,
      Value<String?> detail,
      Value<int?> stage,
    });
typedef $$TideEventsTableUpdateCompanionBuilder =
    TideEventsCompanion Function({
      Value<int> id,
      Value<DateTime> timestamp,
      Value<String?> packageName,
      Value<String> eventType,
      Value<String?> detail,
      Value<int?> stage,
    });

class $$TideEventsTableFilterComposer
    extends Composer<_$KoraDatabase, $TideEventsTable> {
  $$TideEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TideEventsTableOrderingComposer
    extends Composer<_$KoraDatabase, $TideEventsTable> {
  $$TideEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TideEventsTableAnnotationComposer
    extends Composer<_$KoraDatabase, $TideEventsTable> {
  $$TideEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<String> get detail =>
      $composableBuilder(column: $table.detail, builder: (column) => column);

  GeneratedColumn<int> get stage =>
      $composableBuilder(column: $table.stage, builder: (column) => column);
}

class $$TideEventsTableTableManager
    extends
        RootTableManager<
          _$KoraDatabase,
          $TideEventsTable,
          TideEvent,
          $$TideEventsTableFilterComposer,
          $$TideEventsTableOrderingComposer,
          $$TideEventsTableAnnotationComposer,
          $$TideEventsTableCreateCompanionBuilder,
          $$TideEventsTableUpdateCompanionBuilder,
          (
            TideEvent,
            BaseReferences<_$KoraDatabase, $TideEventsTable, TideEvent>,
          ),
          TideEvent,
          PrefetchHooks Function()
        > {
  $$TideEventsTableTableManager(_$KoraDatabase db, $TideEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TideEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TideEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TideEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String?> packageName = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<String?> detail = const Value.absent(),
                Value<int?> stage = const Value.absent(),
              }) => TideEventsCompanion(
                id: id,
                timestamp: timestamp,
                packageName: packageName,
                eventType: eventType,
                detail: detail,
                stage: stage,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime timestamp,
                Value<String?> packageName = const Value.absent(),
                required String eventType,
                Value<String?> detail = const Value.absent(),
                Value<int?> stage = const Value.absent(),
              }) => TideEventsCompanion.insert(
                id: id,
                timestamp: timestamp,
                packageName: packageName,
                eventType: eventType,
                detail: detail,
                stage: stage,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TideEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$KoraDatabase,
      $TideEventsTable,
      TideEvent,
      $$TideEventsTableFilterComposer,
      $$TideEventsTableOrderingComposer,
      $$TideEventsTableAnnotationComposer,
      $$TideEventsTableCreateCompanionBuilder,
      $$TideEventsTableUpdateCompanionBuilder,
      (TideEvent, BaseReferences<_$KoraDatabase, $TideEventsTable, TideEvent>),
      TideEvent,
      PrefetchHooks Function()
    >;
typedef $$TodosTableCreateCompanionBuilder =
    TodosCompanion Function({
      Value<int> id,
      required String title,
      Value<bool> isCompleted,
      required DateTime createdAt,
      Value<DateTime?> completedAt,
      Value<int> priority,
    });
typedef $$TodosTableUpdateCompanionBuilder =
    TodosCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<bool> isCompleted,
      Value<DateTime> createdAt,
      Value<DateTime?> completedAt,
      Value<int> priority,
    });

class $$TodosTableFilterComposer extends Composer<_$KoraDatabase, $TodosTable> {
  $$TodosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TodosTableOrderingComposer
    extends Composer<_$KoraDatabase, $TodosTable> {
  $$TodosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TodosTableAnnotationComposer
    extends Composer<_$KoraDatabase, $TodosTable> {
  $$TodosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);
}

class $$TodosTableTableManager
    extends
        RootTableManager<
          _$KoraDatabase,
          $TodosTable,
          Todo,
          $$TodosTableFilterComposer,
          $$TodosTableOrderingComposer,
          $$TodosTableAnnotationComposer,
          $$TodosTableCreateCompanionBuilder,
          $$TodosTableUpdateCompanionBuilder,
          (Todo, BaseReferences<_$KoraDatabase, $TodosTable, Todo>),
          Todo,
          PrefetchHooks Function()
        > {
  $$TodosTableTableManager(_$KoraDatabase db, $TodosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TodosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TodosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TodosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> priority = const Value.absent(),
              }) => TodosCompanion(
                id: id,
                title: title,
                isCompleted: isCompleted,
                createdAt: createdAt,
                completedAt: completedAt,
                priority: priority,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<bool> isCompleted = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> priority = const Value.absent(),
              }) => TodosCompanion.insert(
                id: id,
                title: title,
                isCompleted: isCompleted,
                createdAt: createdAt,
                completedAt: completedAt,
                priority: priority,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TodosTableProcessedTableManager =
    ProcessedTableManager<
      _$KoraDatabase,
      $TodosTable,
      Todo,
      $$TodosTableFilterComposer,
      $$TodosTableOrderingComposer,
      $$TodosTableAnnotationComposer,
      $$TodosTableCreateCompanionBuilder,
      $$TodosTableUpdateCompanionBuilder,
      (Todo, BaseReferences<_$KoraDatabase, $TodosTable, Todo>),
      Todo,
      PrefetchHooks Function()
    >;

class $KoraDatabaseManager {
  final _$KoraDatabase _db;
  $KoraDatabaseManager(this._db);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$MoodsTableTableManager get moods =>
      $$MoodsTableTableManager(_db, _db.moods);
  $$DecisionsTableTableManager get decisions =>
      $$DecisionsTableTableManager(_db, _db.decisions);
  $$IntentionsTableTableManager get intentions =>
      $$IntentionsTableTableManager(_db, _db.intentions);
  $$TideEventsTableTableManager get tideEvents =>
      $$TideEventsTableTableManager(_db, _db.tideEvents);
  $$TodosTableTableManager get todos =>
      $$TodosTableTableManager(_db, _db.todos);
}
