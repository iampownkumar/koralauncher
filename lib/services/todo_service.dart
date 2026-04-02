import '../database/database_provider.dart';
import '../database/kora_database.dart';

class TodoService {
  static final List<Todo> _todos = [];

  static List<Todo> get todos => _todos;

  static Future<void> init() async {
    await refreshTodos();
  }

  static Future<void> refreshTodos() async {
    final list = await db.getTodos();
    final today = DateTime.now();

    // Nightly Reset Logic: purge tasks not from today
    for (var t in list) {
      if (t.createdAt.year != today.year ||
          t.createdAt.month != today.month ||
          t.createdAt.day != today.day) {
        await db.deleteTodo(t.id);
      }
    }

    // Refetch the purged list — ordered by priority (lower = higher up)
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

  static Future<void> toggleTodo(int id) async {
    await db.toggleTodo(id);
    await refreshTodos();
  }

  static Future<void> deleteTodo(int id) async {
    await db.deleteTodo(id);
    await refreshTodos();
  }

  /// Edit the title of a task.
  static Future<void> editTodo(int id, String newTitle) async {
    await db.updateTodoTitle(id, newTitle);
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
