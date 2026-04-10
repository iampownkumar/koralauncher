import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'kora_database.g.dart';

// ─────────────────────────────────────────────
// TABLE 1: SESSIONS
// Every time user opens a flagged app.
// Powers: Rising Tide timer, open count, AI context
// ─────────────────────────────────────────────
class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get packageName => text()();
  TextColumn get appName => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  TextColumn get openReason => text().nullable()(); // 'habit','quick_task','important'
  IntColumn get extensionCount => integer().withDefault(const Constant(0))();
  BoolColumn get didResist => boolean().withDefault(const Constant(false))();
  IntColumn get risingTideStageReached => integer().withDefault(const Constant(0))(); // 0-4
}

// ─────────────────────────────────────────────
// TABLE 2: MOODS
// Lightweight emoji check-in before/after sessions.
// Powers: emotion → usage correlation (the invisible trigger)
// ─────────────────────────────────────────────
class Moods extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get loggedAt => dateTime()();
  IntColumn get score => integer()(); // 1-5 (1=terrible, 5=great)
  TextColumn get label => text().nullable()(); // 'stressed','bored','lonely','fine'
  TextColumn get context => text().nullable()(); // 'before_session','morning','evening'
  IntColumn get sessionId => integer().nullable()(); // FK to sessions if linked
}

// ─────────────────────────────────────────────
// TABLE 3: DECISIONS
// Every interception gate outcome.
// Powers: resist rate tracking, AI prompt personalization
// ─────────────────────────────────────────────
class Decisions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get decidedAt => dateTime()();
  TextColumn get packageName => text()();
  TextColumn get reason => text()(); // 'habit','quick_task','important'
  BoolColumn get opened => boolean()(); // true = opened anyway
  BoolColumn get resistedCompletely => boolean().withDefault(const Constant(false))();
  BoolColumn get tookAlternative => boolean().withDefault(const Constant(false))(); // took micro-habit
  TextColumn get extensionReason => text().nullable()(); // typed reason for Stage 3 extension
}

// ─────────────────────────────────────────────
// TABLE 4: INTENTIONS
// Daily intention + whether it was honoured.
// Powers: intention vs usage correlation, AI weekly insight
// ─────────────────────────────────────────────
class Intentions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get intentionText => text()();
  BoolColumn get wasHonoured => boolean().nullable()(); // set at end of day
  IntColumn get totalScreenMinutesThatDay => integer().nullable()(); // filled by end-of-day job
  TextColumn get morningMoodLabel => text().nullable()(); // from first mood log of day
}

// ─────────────────────────────────────────────
// TABLE 5: TIDE EVENTS
// Granular audit log for every Rising Tide event.
// Powers: 30-day insights, pattern detection
// ─────────────────────────────────────────────
class TideEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get packageName => text().nullable()();
  TextColumn get eventType => text()(); // 'intention_set', 'app_open_stage1', etc.
  TextColumn get detail => text().nullable()(); // 'mood:bored', 'decision:continue'
  IntColumn get stage => integer().nullable()(); // 0-4
}

// ─────────────────────────────────────────────
// TABLE 6: TODOS
// Powers: daily task list, linked to goals
// ─────────────────────────────────────────────
class Todos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get priority => integer().withDefault(const Constant(0))(); // 0=none, 1=low, 2=med, 3=high
  // 'manual' or 'intention' — intention-linked tasks sync back to the daily goal
  TextColumn get source => text().withDefault(const Constant('manual'))();
}

// ─────────────────────────────────────────────
// TABLE 7: DAILY TODO SNAPSHOTS
// Saved before midnight reset so we can review yesterday's completion.
// ─────────────────────────────────────────────
class DailySnapshots extends Table {
  IntColumn get id    => integer().autoIncrement()();
  DateTimeColumn get date             => dateTime()();  // start-of-day (midnight)
  TextColumn get taskTitle            => text()();
  BoolColumn get completed            => boolean()();
  TextColumn get source               => text().withDefault(const Constant('manual'))(); // 'manual'/'intention'
}

// ─────────────────────────────────────────────
// DATABASE CLASS
// ─────────────────────────────────────────────
@DriftDatabase(tables: [Sessions, Moods, Decisions, Intentions, TideEvents, Todos, DailySnapshots])
class KoraDatabase extends _$KoraDatabase {
  KoraDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  // ── SESSION QUERIES ──────────────────────

  Future<int> startSession(String packageName, String appName) =>
      into(sessions).insert(SessionsCompanion.insert(
        packageName: packageName,
        appName: appName,
        startedAt: DateTime.now(),
      ));

  Future<void> endSession(int id, int durationSeconds, {
    int risingTideStage = 0,
    bool didResist = false,
  }) =>
      (update(sessions)..where((s) => s.id.equals(id))).write(
        SessionsCompanion(
          endedAt: Value(DateTime.now()),
          durationSeconds: Value(durationSeconds),
          risingTideStageReached: Value(risingTideStage),
          didResist: Value(didResist),
        ),
      );

  Future<void> incrementExtension(int id) async {
    final session = await (select(sessions)..where((s) => s.id.equals(id))).getSingle();
    await (update(sessions)..where((s) => s.id.equals(id))).write(
      SessionsCompanion(extensionCount: Value(session.extensionCount + 1)),
    );
  }

  Future<int> getTodayOpenCount(String packageName) async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final result = await (select(sessions)
          ..where((s) =>
              s.packageName.equals(packageName) &
              s.startedAt.isBiggerOrEqualValue(start)))
        .get();
    return result.length;
  }

  Future<int> getTodayTotalMinutes(String packageName) async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final result = await (select(sessions)
          ..where((s) =>
              s.packageName.equals(packageName) &
              s.startedAt.isBiggerOrEqualValue(start) &
              s.durationSeconds.isNotNull()))
        .get();
    
    int totalSeconds = 0;
    for (var s in result) {
      totalSeconds += s.durationSeconds ?? 0;
    }
    return (totalSeconds / 60).round();
  }

  Future<List<Session>> getSessionsForAIContext(String packageName, {int days = 30}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return (select(sessions)
          ..where((s) =>
              s.packageName.equals(packageName) &
              s.startedAt.isBiggerOrEqualValue(cutoff))
          ..orderBy([(s) => OrderingTerm.desc(s.startedAt)]))
        .get();
  }

  // ── DECISION QUERIES ─────────────────────

  Future<int> logDecision({
    required String packageName,
    required String reason,
    required bool opened,
    bool resistedCompletely = false,
    bool tookAlternative = false,
    String? extensionReason,
  }) =>
      into(decisions).insert(DecisionsCompanion.insert(
        decidedAt: DateTime.now(),
        packageName: packageName,
        reason: reason,
        opened: opened,
        resistedCompletely: Value(resistedCompletely),
        tookAlternative: Value(tookAlternative),
        extensionReason: Value(extensionReason),
      ));

  Future<double> getResistRate(String packageName, {int days = 7}) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final all = await (select(decisions)
          ..where((d) =>
              d.packageName.equals(packageName) &
              d.decidedAt.isBiggerOrEqualValue(cutoff)))
        .get();
    if (all.isEmpty) return 0.0;
    final resisted = all.where((d) => !d.opened).length;
    return resisted / all.length;
  }

  // ── MOOD QUERIES ─────────────────────────

  Future<int> logMood({
    required int score,
    String? label,
    String? context,
    int? sessionId,
  }) =>
      into(moods).insert(MoodsCompanion.insert(
        loggedAt: DateTime.now(),
        score: score,
        label: Value(label),
        context: Value(context),
        sessionId: Value(sessionId),
      ));

  // ── INTENTION QUERIES ────────────────────

  Future<int> saveIntention(String text) {
    final today = DateTime.now();
    return into(intentions).insertOnConflictUpdate(IntentionsCompanion.insert(
      date: DateTime(today.year, today.month, today.day),
      intentionText: text,
    ));
  }
  // ── TIDE EVENT QUERIES ───────────────────

  Future<int> logTideEvent({
    String? packageName,
    required String eventType,
    String? detail,
    int? stage,
  }) =>
      into(tideEvents).insert(TideEventsCompanion.insert(
        timestamp: DateTime.now(),
        packageName: Value(packageName),
        eventType: eventType,
        detail: Value(detail),
        stage: Value(stage),
      ));

  Future<List<TideEvent>> getRecentTideEvents({int limit = 100}) =>
      (select(tideEvents)
            ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
            ..limit(limit))
          .get();

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from <= 1) {
            await m.createTable(todos);
          }
          if (from <= 2) {
            // Add source column to todos (defaults to 'manual')
            await m.addColumn(todos, todos.source);
            // Create the new daily snapshots table
            await m.createTable(dailySnapshots);
          }
        },
      );

  // ── TODO QUERIES ─────────────────────────

  Future<List<Todo>> getTodos() =>
      (select(todos)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

  Future<int> addTodo(String title, {int priority = 0, String source = 'manual'}) =>
      into(todos).insert(TodosCompanion.insert(
        title: title,
        createdAt: DateTime.now(),
        priority: Value(priority),
        source: Value(source),
      ));

  Future<void> toggleTodo(int id) async {
    final todo = await (select(todos)..where((t) => t.id.equals(id))).getSingle();
    await (update(todos)..where((t) => t.id.equals(id))).write(
      TodosCompanion(
        isCompleted: Value(!todo.isCompleted),
        completedAt: Value(!todo.isCompleted ? DateTime.now() : null),
      ),
    );
  }

  Future<void> deleteTodo(int id) =>
      (delete(todos)..where((t) => t.id.equals(id))).go();

  Future<void> updateTodoTitle(int id, String newTitle) =>
      (update(todos)..where((t) => t.id.equals(id))).write(
        TodosCompanion(title: Value(newTitle)),
      );

  Future<void> updateTodoPriority(int id, int priority) =>
      (update(todos)..where((t) => t.id.equals(id))).write(
        TodosCompanion(priority: Value(priority)),
      );

  // ── DAILY SNAPSHOT QUERIES ───────────────

  /// Persist all of today's todos before the midnight purge.
  Future<void> saveDailySnapshot(List<Todo> todayTodos) async {
    if (todayTodos.isEmpty) return;
    final today = DateTime.now();
    final midnight = DateTime(today.year, today.month, today.day);
    for (final t in todayTodos) {
      await into(dailySnapshots).insert(DailySnapshotsCompanion.insert(
        date: midnight,
        taskTitle: t.title,
        completed: t.isCompleted,
        source: Value(t.source),
      ));
    }
  }

  /// Retrieve the snapshot for a given day (pass DateTime.now() for yesterday etc.).
  Future<List<DailySnapshot>> getSnapshotForDay(DateTime day) {
    final midnight = DateTime(day.year, day.month, day.day);
    final next = midnight.add(const Duration(days: 1));
    return (select(dailySnapshots)
          ..where((s) =>
              s.date.isBiggerOrEqualValue(midnight) &
              s.date.isSmallerThanValue(next)))
        .get();
  }

  Future<Intention?> getTodayIntention() async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    return (select(intentions)
          ..where((i) =>
              i.date.isBiggerOrEqualValue(start) &
              i.date.isSmallerThanValue(end)))
        .getSingleOrNull();
  }

  // ── AI CONTEXT BUILDER ───────────────────
  // Call this at month 1+ to feed Claude API
  Future<Map<String, dynamic>> buildAIContext(String packageName) async {
    final sessions30 = await getSessionsForAIContext(packageName, days: 30);
    final resistRate = await getResistRate(packageName, days: 7);
    final todayOpens = await getTodayOpenCount(packageName);
    final todayIntention = await getTodayIntention();

    return {
      'packageName': packageName,
      'todayOpens': todayOpens,
      'weeklyResistRate': resistRate,
      'avgSessionSeconds': sessions30.isEmpty
          ? 0
          : sessions30
                  .where((s) => s.durationSeconds != null)
                  .fold(0, (sum, s) => sum + s.durationSeconds!) /
              sessions30.length,
      'totalSessionsLast30Days': sessions30.length,
      'todayIntention': todayIntention?.intentionText ?? 'not set',
      'peakOpenHour': _getPeakHour(sessions30),
    };
  }

  int _getPeakHour(List<Session> sessions) {
    if (sessions.isEmpty) return -1;
    final hourCounts = <int, int>{};
    for (final s in sessions) {
      final h = s.startedAt.hour;
      hourCounts[h] = (hourCounts[h] ?? 0) + 1;
    }
    return hourCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'kora.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
