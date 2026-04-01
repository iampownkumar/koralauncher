import 'package:flutter/material.dart';
import '../services/todo_service.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final TextEditingController _taskController = TextEditingController();

  void _addTodo() async {
    if (_taskController.text.trim().isNotEmpty) {
      await TodoService.addTodo(_taskController.text.trim());
      _taskController.clear();
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    TodoService.init().then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "To-Do List",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w300),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Add a task...",
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _addTodo(),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  onPressed: _addTodo,
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TodoService.todos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline, size: 64, color: Colors.white.withValues(alpha: 0.1)),
                        const SizedBox(height: 16),
                        Text(
                          "Your list is clear.",
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: TodoService.todos.length,
                    itemBuilder: (context, index) {
                      final todo = TodoService.todos[index];
                      return Dismissible(
                        key: Key(todo.id.toString()),
                        onDismissed: (_) async {
                          await TodoService.deleteTodo(todo.id);
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          child: const Icon(Icons.delete, color: Colors.redAccent),
                        ),
                        child: Card(
                          color: todo.isCompleted ? Colors.white.withValues(alpha: 0.02) : Colors.white.withValues(alpha: 0.06),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            leading: IconButton(
                              icon: Icon(
                                todo.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                                color: todo.isCompleted ? Colors.blueAccent : Colors.white38,
                              ),
                              onPressed: () async {
                                await TodoService.toggleTodo(todo.id);
                                setState(() {});
                              },
                            ),
                            title: Text(
                              todo.title,
                              style: TextStyle(
                                color: todo.isCompleted ? Colors.white24 : Colors.white,
                                decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            trailing: todo.isCompleted ? null : const Icon(Icons.drag_handle, color: Colors.white12),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
