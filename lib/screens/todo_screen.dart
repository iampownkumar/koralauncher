import 'package:flutter/material.dart';
import '../services/todo_service.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final TextEditingController _addController = TextEditingController();
  final FocusNode _addFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    TodoService.init().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _addController.dispose();
    _addFocusNode.dispose();
    super.dispose();
  }

  Future<void> _addTodo() async {
    final text = _addController.text.trim();
    if (text.isEmpty) return;
    await TodoService.addTodo(text);
    _addController.clear();
    if (mounted) setState(() {});
  }

  Future<void> _showEditDialog(int id, String currentTitle) async {
    final ctrl = TextEditingController(text: currentTitle);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text(
          'Edit task',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Task title…',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (_) => Navigator.pop(ctx, true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child:
                const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (confirmed == true && ctrl.text.trim().isNotEmpty && mounted) {
      await TodoService.editTodo(id, ctrl.text.trim());
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final todos = TodoService.todos;
    final pending = todos.where((t) => !t.isCompleted).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              'To-Do',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w300, fontSize: 18),
            ),
            if (pending.isNotEmpty)
              Text(
                '${pending.length} remaining',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
              ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Add task bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addController,
                    focusNode: _addFocusNode,
                    style: const TextStyle(color: Colors.white),
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'Add a task for today…',
                      hintStyle:
                          TextStyle(color: Colors.white.withValues(alpha: 0.25)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    onSubmitted: (_) => _addTodo(),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _addTodo,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.add, color: Colors.black, size: 22),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: todos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 64,
                            color: Colors.white.withValues(alpha: 0.1)),
                        const SizedBox(height: 16),
                        Text(
                          'Your list is clear.',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add a task above to get started.',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.2),
                              fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: 40),
                    itemCount: todos.length,
                    buildDefaultDragHandles: false,
                    onReorderItem: (oldIndex, newIndex) async {
                      await TodoService.reorder(oldIndex, newIndex);
                      if (mounted) setState(() {});
                    },
                    itemBuilder: (context, index) {
                      final todo = todos[index];
                      final isCompleted = todo.isCompleted;
                      return Dismissible(
                        key: ValueKey(todo.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) async {
                          await TodoService.deleteTodo(todo.id);
                          if (mounted) setState(() {});
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                        ),
                        child: Container(
                          key: ValueKey('card_${todo.id}'),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Colors.white.withValues(alpha: 0.02)
                                : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCompleted
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: ListTile(
                            leading: GestureDetector(
                              onTap: () async {
                                await TodoService.toggleTodo(todo.id);
                                if (mounted) setState(() {});
                              },
                              child: Icon(
                                isCompleted
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: isCompleted
                                    ? Colors.cyanAccent
                                    : Colors.white38,
                              ),
                            ),
                            title: Text(
                              todo.title,
                              style: TextStyle(
                                color: isCompleted
                                    ? Colors.white24
                                    : Colors.white,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                fontSize: 15,
                              ),
                            ),
                            trailing: isCompleted
                                ? null
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Edit button
                                      GestureDetector(
                                        onTap: () =>
                                            _showEditDialog(todo.id, todo.title),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Icon(
                                            Icons.edit_outlined,
                                            size: 18,
                                            color: Colors.white.withValues(
                                                alpha: 0.35),
                                          ),
                                        ),
                                      ),
                                      // Drag handle
                                      ReorderableDragStartListener(
                                        index: index,
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Icon(
                                            Icons.drag_handle,
                                            color: Colors.white.withValues(
                                                alpha: 0.25),
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
    );
  }
}
