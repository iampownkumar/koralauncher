import 'package:flutter/material.dart';
import '../services/todo_service.dart';

class TodoListCard extends StatefulWidget {
  final VoidCallback onTap;

  const TodoListCard({super.key, required this.onTap});

  @override
  State<TodoListCard> createState() => _TodoListCardState();
}

class _TodoListCardState extends State<TodoListCard> {
  @override
  Widget build(BuildContext context) {
    final todos = TodoService.todos;
    final total = todos.length;
    final completed = todos.where((t) => t.isCompleted).length;
    final pending = total - completed;

    String motivationMessage = "No tasks yet. Tap to add.";
    if (total > 0) {
      if (completed == total) {
        motivationMessage = "All done! 🎉";
      } else if (completed > 0) {
        motivationMessage = "$completed/$total done. $pending remaining.";
      } else {
        motivationMessage = "$total tasks today. Let's start.";
      }
    }

    return GestureDetector(
      onTap: widget
          .onTap, // Still allow tap on the card header to open full screen
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row
            Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.blueAccent,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  "TO-DO LIST",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    letterSpacing: 2,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (pending > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "$pending pending",
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Subtle Progress Bar
            if (total > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : completed / total,
                    minHeight: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.greenAccent.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),

            // Motivational Message
            Text(
              motivationMessage,
              style: TextStyle(
                color: completed == total && total > 0
                    ? Colors.greenAccent
                    : Colors.white.withValues(alpha: 0.4),
                fontSize: 14,
                fontWeight: completed == total && total > 0
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 16),

            // Scrollable List of Tasks
            if (todos.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: todos.length,
                  padding: EdgeInsets.zero,
                  itemBuilder: (context, index) {
                    final todo = todos[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () async {
                          await TodoService.toggleTodo(todo.id);
                          setState(() {});
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: todo.isCompleted
                                ? Colors.white.withValues(alpha: 0.02)
                                : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: todo.isCompleted
                                  ? Colors.transparent
                                  : Colors.white10,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                todo.isCompleted
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: todo.isCompleted
                                    ? Colors.greenAccent
                                    : Colors.white54,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  todo.title,
                                  style: TextStyle(
                                    color: todo.isCompleted
                                        ? Colors.white38
                                        : Colors.white,
                                    fontSize: 15,
                                    decoration: todo.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
