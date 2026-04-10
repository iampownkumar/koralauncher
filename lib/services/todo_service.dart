import '../database/database_provider.dart';
import '../database/kora_database.dart';
import 'storage_service.dart';

class TodoService {
  static final List<Todo> _todos = [];

  static List<Todo> get todos => _todos;

  static Future<void> init() async {
    await refreshTodos();
  }

  static Future<void> refreshTodos() async {
    final list = await db.getTodos();
    final today = DateTime.now();

    // Identify stale todos (not from today)
    final staleTodos = list.where((t) =>
        t.createdAt.year != today.year ||
        t.createdAt.month != today.month ||
        t.createdAt.day != today.day).toList();

    // ── Nightly Reset: snapshot BEFORE deleting ──────────────────
    if (staleTodos.isNotEmpty) {
      await db.saveDailySnapshot(staleTodos);
      for (var t in staleTodos) {
        await db.deleteTodo(t.id);
      }
    }

    // Refetch \u2014 ordered by priority (lower = higher up)
    final finalList = await db.getTodos();
    _todos.clear();
    _todos.addAll(finalList);
    _todos.sort((a, b) => a.priority.compareTo(b.priority));
  }

  static Future<void> addTodo(String title, {int priority = 0}) async {
    // Append at end: find current max priority
    final maxPriority = _todos.isEmpty
        ? 0
        : _todos.map((t) => t.priority).reduce((a, b) => a > b ? a : b) + 1;
    await db.addTodo(title, priority: maxPriority);
    await refreshTodos();
  }

  /// Add the intention as the first (pinned) todo and store its ID for sync.
  static Future<void> addIntentionTodo(String intention) async {
    // If a linked todo already exists for today, update it instead
    final existingId = StorageService.getIntentionTodoId();
    if (existingId != null) {
      await db.updateTodoTitle(existingId, intention);
      await refreshTodos();
      return;
    }

    // Insert at priority 0 (top of list) — shift existing todos down
    for (int i = 0; i < _todos.length; i++) {
      await db.updateTodoPriority(_todos[i].id, i + 1);
    }
    final newId = await db.addTodo(intention, priority: 0, source: 'intention');
    await StorageService.setIntentionTodoId(newId);
    await refreshTodos();
  }

  /// Update the intention-linked todo title (called when intention is edited).
  static Future<void> updateIntentionTodo(String newTitle) async {
    final existingId = StorageService.getIntentionTodoId();
    if (existingId == null) return;
    await db.updateTodoTitle(existingId, newTitle);
    await refreshTodos();
  }

  /// Called from TodoScreen when the user edits a todo that has source='intention'.
  /// Updates both the todo title and the stored daily intention.
  static Future<void> editTodo(int id, String newTitle) async {
    await db.updateTodoTitle(id, newTitle);
    // If this is the intention-linked todo, also sync back to StorageService
    final linkedId = StorageService.getIntentionTodoId();
    if (linkedId == id) {
      await StorageService.setDailyIntention(newTitle);
      await db.saveIntention(newTitle);
    }
    await refreshTodos();
  }

  static Future<void> toggleTodo(int id) async {
    await db.toggleTodo(id);
    await refreshTodos();
  }

  static Future<void> deleteTodo(int id) async {
    // If deleting the intention-linked todo, clear the link
    final linkedId = StorageService.getIntentionTodoId();
    if (linkedId == id) {
      await StorageService.clearIntentionTodoId();
    }
    await db.deleteTodo(id);
    await refreshTodos();
  }

  /// Reorder: assign new priority indices after a drag.
  static Future<void> reorder(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;
    // Adjust for ReorderableListView's off-by-one on downward moves
    if (newIndex > oldIndex) newIndex--;
    final item = _todos.removeAt(oldIndex);
    _todos.insert(newIndex, item);
    // Persist new order using priority field
    for (int i = 0; i < _todos.length; i++) {
      await db.updateTodoPriority(_todos[i].id, i);
    }
    // Refresh to sync DB state
    await refreshTodos();
  }

  static int get pendingCount => _todos.where((t) => !t.isCompleted).length;

  static bool hasPendingTodos() => pendingCount > 0;
}
