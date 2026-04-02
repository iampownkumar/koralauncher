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
    // Use a bottom sheet for a cleaner, keyboard-friendly UX
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Edit task',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.07),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white38, size: 18),
                      onPressed: () => ctrl.clear(),
                    ),
                  ),
                  onSubmitted: (_) => Navigator.pop(ctx),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Save task',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Read text BEFORE disposing the controller
    final newTitle = ctrl.text.trim();
    ctrl.dispose();
    if (newTitle.isNotEmpty && newTitle != currentTitle && mounted) {
      await TodoService.editTodo(id, newTitle);
      setState(() {});
    }
  }

  Future<bool> _confirmDelete(String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Delete task?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        content: Text(
          '"$title"',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep it',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    return confirmed == true;
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
                        confirmDismiss: (_) => _confirmDelete(todo.title),
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
                            color: Colors.redAccent.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.delete_outline, color: Colors.redAccent),
                              const SizedBox(height: 2),
                              Text('Delete', style: TextStyle(
                                color: Colors.redAccent.withValues(alpha: 0.8),
                                fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
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
