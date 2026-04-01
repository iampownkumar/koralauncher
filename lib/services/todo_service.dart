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
    
    // Refetch the purged list
    final finalList = await db.getTodos();
    _todos.clear();
    _todos.addAll(finalList);
  }

  static Future<void> addTodo(String title, {int priority = 0}) async {
    await db.addTodo(title, priority: priority);
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

  static int get pendingCount => _todos.where((t) => !t.isCompleted).length;
  
  static bool hasPendingTodos() => pendingCount > 0;
}
