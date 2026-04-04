import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/todo_service.dart';
import 'frosted_glass_widget.dart';

class TodoListCard extends StatefulWidget {
  final VoidCallback onTap;
  final double overlayOpacity;

  const TodoListCard({
    super.key, 
    required this.onTap,
    this.overlayOpacity = 0.55,
  });

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: FrostedGlassWidget(
          overlayOpacity: widget.overlayOpacity,
          child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "TO-DO LIST",
                        style: TextStyle(
                          color: colorScheme.primary,
                          letterSpacing: 2,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (pending > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "$pending pending",
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (total > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: total == 0 ? 0 : completed / total,
                          minHeight: 4,
                          backgroundColor: colorScheme.onSurface.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  Text(
                    motivationMessage,
                    style: TextStyle(
                      color: completed == total && total > 0
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontWeight: completed == total && total > 0
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 16),
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
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: todo.isCompleted
                                      ? colorScheme.onSurface.withValues(alpha: 0.05)
                                      : colorScheme.onSurface.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: todo.isCompleted ? Colors.transparent : colorScheme.onSurface.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      todo.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                                      color: todo.isCompleted ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.6),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        todo.title,
                                        style: TextStyle(
                                          color: todo.isCompleted
                                              ? colorScheme.onSurface.withValues(alpha: 0.4)
                                              : colorScheme.onSurface,
                                          fontSize: 15,
                                          decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
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
      ),
    );
  }
}
