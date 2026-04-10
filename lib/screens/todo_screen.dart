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

  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<dynamic> _displayTodos = [];

  @override
  void initState() {
    super.initState();
    TodoService.init().then((_) {
      _displayTodos = List.from(TodoService.todos)..sort(_sortTodos);
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _addController.dispose();
    _addFocusNode.dispose();
    super.dispose();
  }

  int _sortTodos(dynamic a, dynamic b) {
    if (!a.isCompleted && b.isCompleted) return -1;
    if (a.isCompleted && !b.isCompleted) return 1;
    if (!a.isCompleted && !b.isCompleted) {
      return a.priority.compareTo(b.priority);
    }
    // Completed: createdAt descending
    return b.createdAt.compareTo(a.createdAt);
  }

  Future<void> _addTodo() async {
    final text = _addController.text.trim();
    if (text.isEmpty) return;
    _addController.clear();
    
    await TodoService.addTodo(text);
    
    final freshList = List<dynamic>.from(TodoService.todos)..sort(_sortTodos);
    for (int i = 0; i < freshList.length; i++) {
      if (i >= _displayTodos.length || freshList[i].id != _displayTodos[i].id) {
         _displayTodos.insert(i, freshList[i]);
         _listKey.currentState?.insertItem(i, duration: const Duration(milliseconds: 300));
         break;
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _deleteTodoFromList(dynamic todo) async {
    final index = _displayTodos.indexOf(todo);
    if (index == -1) return;

    final removed = _displayTodos.removeAt(index);
    _listKey.currentState?.removeItem(index, (context, animation) {
      return _buildAnimatedItem(removed, animation, isRemoving: true, movingToDone: true);
    }, duration: const Duration(milliseconds: 300));
    
    setState(() {});
    await TodoService.deleteTodo(removed.id);
  }

  Future<void> _toggleTodoState(dynamic todo) async {
    final index = _displayTodos.indexOf(todo);
    if (index == -1) return;

    final wasCompleted = todo.isCompleted;
    final removed = _displayTodos.removeAt(index);

    // Fade and slide out
    _listKey.currentState?.removeItem(index, (context, animation) {
      return _buildAnimatedItem(removed, animation, isRemoving: true, movingToDone: !wasCompleted);
    }, duration: const Duration(milliseconds: 400));
    
    setState(() {}); // Instant visual UI separation update

    // Wait for DB to toggle
    await TodoService.toggleTodo(todo.id);

    // Refresh list and find proper sorted insertion target
    final freshList = List<dynamic>.from(TodoService.todos)..sort(_sortTodos);
    final updated = freshList.firstWhere((t) => t.id == todo.id);
    final targetIndex = freshList.indexOf(updated);

    _displayTodos.insert(targetIndex, updated);

    // Fade and slide in
    _listKey.currentState?.insertItem(targetIndex, duration: const Duration(milliseconds: 400));
    setState(() {});
  }

  Future<void> _showEditDialog(int id, String currentTitle, {bool isIntention = false}) async {
    String? savedTitle;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final ctrl = TextEditingController(text: currentTitle)
          ..selection = TextSelection.collapsed(offset: currentTitle.length);
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isIntention ? '🎯 Edit today\'s intention' : 'Edit task',
                      style: TextStyle(
                        color: isIntention ? Colors.cyanAccent : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isIntention)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Also updates your daily goal',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: ctrl,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        filled: true, fillColor: Colors.white.withValues(alpha: 0.07),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        suffixIcon: IconButton(icon: const Icon(Icons.close, color: Colors.white38, size: 18), onPressed: () => ctrl.clear()),
                      ),
                      onSubmitted: (v) { savedTitle = v.trim(); Navigator.pop(ctx); },
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () { savedTitle = ctrl.text.trim(); Navigator.pop(ctx); },
                      style: FilledButton.styleFrom(
                        backgroundColor: isIntention ? Colors.cyanAccent : Colors.cyanAccent, foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(isIntention ? 'Update Intention + Task' : 'Save task', style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (savedTitle != null && savedTitle!.isNotEmpty && savedTitle != currentTitle && mounted) {
      await TodoService.editTodo(id, savedTitle!);
      final updated = List.from(TodoService.todos)..sort(_sortTodos);
      setState(() { _displayTodos = updated; });
    }
  }

  Future<bool> _confirmDelete(String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Delete task?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        content: Text('"$title"', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontStyle: FontStyle.italic)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Keep it', style: TextStyle(color: Colors.white.withValues(alpha: 0.5)))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.8), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _handleManualReorder(int oldIndex, int newIndex) async {
    final dragged = _displayTodos[oldIndex];
    final displaced = _displayTodos[newIndex];

    final serviceOldIndex = TodoService.todos.indexWhere((t) => t.id == dragged.id);
    final serviceNewIndex = TodoService.todos.indexWhere((t) => t.id == displaced.id);

    setState(() {
      final item = _displayTodos.removeAt(oldIndex);
      _displayTodos.insert(newIndex, item);
    });

    await TodoService.reorder(serviceOldIndex, serviceNewIndex);
  }

  Widget _buildAnimatedItem(dynamic todo, Animation<double> animation, {bool isRemoving = false, bool movingToDone = true}) {
    Offset beginOffset;
    if (isRemoving) {
      beginOffset = movingToDone ? const Offset(0, 1.2) : const Offset(0, -1.2);
    } else {
      beginOffset = movingToDone ? const Offset(0, -1.2) : const Offset(0, 1.2);
    }

    return SizeTransition(
      sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)
          ),
          child: Builder(builder: (ctx) {
            final doneIndex = _displayTodos.indexWhere((t) => t.isCompleted);
            final isFirstDone = todo.isCompleted && todo.id == _displayTodos.elementAtOrNull(doneIndex)?.id;
            
            Widget content = _buildInteractiveTile(todo);
            if (isFirstDone) {
               content = Column(
                 crossAxisAlignment: CrossAxisAlignment.stretch,
                 children: [
                   const _DoneSectionDivider(),
                   content,
                 ]
               );
            }
            return content;
          }),
        ),
      ),
    );
  }

  Widget _buildInteractiveTile(dynamic todo) {
    Widget baseTile = _buildTodoTile(todo);

    Widget dismissibleTile = Dismissible(
      key: ValueKey('dismiss_${todo.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(todo.title),
      onDismissed: (_) => _deleteTodoFromList(todo),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delete_outline, color: Colors.redAccent),
            const SizedBox(height: 2),
            Text('Delete', style: TextStyle(color: Colors.redAccent.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      child: baseTile,
    );

    if (!todo.isCompleted) {
      return DragTarget<int>(
        onWillAcceptWithDetails: (details) {
          final targetIndex = _displayTodos.indexOf(todo);
          return details.data != targetIndex && !_displayTodos[details.data].isCompleted;
        },
        onAcceptWithDetails: (details) {
          final targetIndex = _displayTodos.indexOf(todo);
          _handleManualReorder(details.data, targetIndex);
        },
        builder: (context, candidateDetails, rejectedData) {
          final isHovered = candidateDetails.isNotEmpty;
          return Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: isHovered ? 60.0 : 0.0,
              ),
              LongPressDraggable<int>(
                data: _displayTodos.indexOf(todo),
                feedback: Material(
                  color: Colors.transparent,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Opacity(opacity: 0.8, child: _buildTodoTile(todo)),
                  ),
                ),
                childWhenDragging: Opacity(opacity: 0.2, child: _buildTodoTile(todo)),
                child: dismissibleTile,
              ),
            ],
          );
        },
      );
    }
    return dismissibleTile;
  }

  Widget _buildTodoTile(dynamic todo) {
    final isCompleted = todo.isCompleted;
    final isIntentionLinked = todo.source == 'intention';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.white.withValues(alpha: 0.02)
            : isIntentionLinked
                ? Colors.cyanAccent.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? Colors.white.withValues(alpha: 0.05)
              : isIntentionLinked
                  ? Colors.cyanAccent.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: ListTile(
        leading: GestureDetector(
          onTap: () => _toggleTodoState(todo),
          child: Icon(
            isCompleted ? Icons.check_circle : Icons.circle_outlined,
            color: isCompleted
                ? Colors.white38
                : isIntentionLinked
                    ? Colors.cyanAccent.withValues(alpha: 0.8)
                    : Colors.white70,
          ),
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            color: isCompleted ? Colors.white38 : Colors.white.withValues(alpha: 0.87),
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            fontSize: 15,
            fontWeight: isCompleted ? FontWeight.normal : FontWeight.w500,
          ),
        ),
        subtitle: isIntentionLinked && !isCompleted
            ? Text(
                '🎯 Today\'s intention',
                style: TextStyle(
                  color: Colors.cyanAccent.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              )
            : null,
        trailing: isCompleted
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _showEditDialog(todo.id, todo.title, isIntention: isIntentionLinked),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.edit_outlined, size: 18, color: Colors.white38),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.drag_indicator, color: Colors.white24),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _displayTodos.where((t) => !t.isCompleted).length;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 150) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
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
              const Text('To-Do', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w300, fontSize: 18)),
              if (pendingCount > 0)
                Text('$pendingCount remaining', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
            ],
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
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
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
                        filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onSubmitted: (_) => _addTodo(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _addTodo,
                    child: Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(color: Colors.cyanAccent, borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.add, color: Colors.black, size: 22),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _displayTodos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline, size: 64, color: Colors.white.withValues(alpha: 0.1)),
                          const SizedBox(height: 16),
                          Text('Your list is clear.', style: TextStyle(color: Colors.white.withValues(alpha: 0.3))),
                          const SizedBox(height: 8),
                          Text('Add a task above to get started.', style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 13)),
                        ],
                      ),
                    )
                  : AnimatedList(
                      key: _listKey,
                      padding: const EdgeInsets.only(bottom: 40),
                      initialItemCount: _displayTodos.length,
                      itemBuilder: (context, index, animation) {
                        return _buildAnimatedItem(_displayTodos[index], animation);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoneSectionDivider extends StatelessWidget {
  const _DoneSectionDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: Colors.white12)),
          const SizedBox(width: 12),
          const Text('Done', style: TextStyle(color: Colors.white30, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: Colors.white12)),
        ],
      ),
    );
  }
}
