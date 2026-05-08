import 'package:flutter/material.dart';
import '../services/todo_service.dart';
import 'todo_history_screen.dart';

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
    return b.createdAt.compareTo(a.createdAt);
  }

  Future<void> _addTodo() async {
    final text = _addController.text.trim();
    if (text.isEmpty) return;
    _addController.clear();

    await TodoService.addTodo(text);

    final freshList = List<dynamic>.from(TodoService.todos)..sort(_sortTodos);
    for (int i = 0; i < freshList.length; i++) {
      if (i >= _displayTodos.length ||
          freshList[i].id != _displayTodos[i].id) {
        _displayTodos.insert(i, freshList[i]);
        _listKey.currentState?.insertItem(i,
            duration: const Duration(milliseconds: 300));
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
      return _buildAnimatedItem(removed, animation,
          isRemoving: true, movingToDone: true);
    }, duration: const Duration(milliseconds: 300));

    setState(() {});
    await TodoService.deleteTodo(removed.id);
  }

  Future<void> _toggleTodoState(dynamic todo) async {
    final index = _displayTodos.indexOf(todo);
    if (index == -1) return;

    final wasCompleted = todo.isCompleted;
    final removed = _displayTodos.removeAt(index);

    _listKey.currentState?.removeItem(index, (context, animation) {
      return _buildAnimatedItem(removed, animation,
          isRemoving: true, movingToDone: !wasCompleted);
    }, duration: const Duration(milliseconds: 400));

    setState(() {});

    await TodoService.toggleTodo(todo.id);

    final freshList = List<dynamic>.from(TodoService.todos)..sort(_sortTodos);
    final updated = freshList.firstWhere((t) => t.id == todo.id);
    final targetIndex = freshList.indexOf(updated);

    _displayTodos.insert(targetIndex, updated);

    _listKey.currentState?.insertItem(targetIndex,
        duration: const Duration(milliseconds: 400));
    setState(() {});
  }

  Future<void> _showEditDialog(int id, String currentTitle,
      {bool isIntention = false}) async {
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
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  border:
                      const Border(top: BorderSide(color: Colors.white10)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isIntention
                          ? '🎯 Edit today\'s intention'
                          : 'Edit task',
                      style: TextStyle(
                        color:
                            isIntention ? Colors.cyanAccent : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isIntention)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Also updates your daily goal',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.35),
                              fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: ctrl,
                      autofocus: true,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.07),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        suffixIcon: IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.white38, size: 18),
                            onPressed: () => ctrl.clear()),
                      ),
                      onSubmitted: (v) {
                        savedTitle = v.trim();
                        Navigator.pop(ctx);
                      },
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        savedTitle = ctrl.text.trim();
                        Navigator.pop(ctx);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                          isIntention
                              ? 'Update Intention + Task'
                              : 'Save task',
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (savedTitle != null &&
        savedTitle!.isNotEmpty &&
        savedTitle != currentTitle &&
        mounted) {
      await TodoService.editTodo(id, savedTitle!);
      final updated = List.from(TodoService.todos)..sort(_sortTodos);
      setState(() {
        _displayTodos = updated;
      });
    }
  }

  Future<bool> _confirmDelete(String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Delete task?',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        content: Text('"$title"',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Keep it',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5)))),
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

  Future<void> _handleManualReorder(int oldIndex, int newIndex) async {
    final dragged = _displayTodos[oldIndex];
    final displaced = _displayTodos[newIndex];

    final serviceOldIndex =
        TodoService.todos.indexWhere((t) => t.id == dragged.id);
    final serviceNewIndex =
        TodoService.todos.indexWhere((t) => t.id == displaced.id);

    setState(() {
      final item = _displayTodos.removeAt(oldIndex);
      _displayTodos.insert(newIndex, item);
    });

    await TodoService.reorder(serviceOldIndex, serviceNewIndex);
  }

  // ── Animated list helpers ──────────────────────────────────

  Widget _buildAnimatedItem(dynamic todo, Animation<double> animation,
      {bool isRemoving = false, bool movingToDone = true}) {
    Offset beginOffset;
    if (isRemoving) {
      beginOffset =
          movingToDone ? const Offset(0, 1.2) : const Offset(0, -1.2);
    } else {
      beginOffset =
          movingToDone ? const Offset(0, -1.2) : const Offset(0, 1.2);
    }

    return SizeTransition(
      sizeFactor:
          CurvedAnimation(parent: animation, curve: Curves.easeInOut),
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(begin: beginOffset, end: Offset.zero)
              .animate(CurvedAnimation(
                  parent: animation, curve: Curves.easeOutCubic)),
          child: Builder(builder: (ctx) {
            final doneIndex =
                _displayTodos.indexWhere((t) => t.isCompleted);
            final isFirstDone = todo.isCompleted &&
                todo.id ==
                    _displayTodos.elementAtOrNull(doneIndex)?.id;

            Widget content = _buildInteractiveTile(todo);
            if (isFirstDone) {
              content = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _DoneSectionDivider(),
                  content,
                ],
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14)),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
            SizedBox(height: 2),
            Text('Delete',
                style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      child: baseTile,
    );

    if (!todo.isCompleted) {
      return DragTarget<int>(
        onWillAcceptWithDetails: (details) {
          final targetIndex = _displayTodos.indexOf(todo);
          return details.data != targetIndex &&
              !_displayTodos[details.data].isCompleted;
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
                    child: Opacity(
                        opacity: 0.8, child: _buildTodoTile(todo)),
                  ),
                ),
                childWhenDragging: Opacity(
                    opacity: 0.2, child: _buildTodoTile(todo)),
                child: dismissibleTile,
              ),
            ],
          );
        },
      );
    }
    return dismissibleTile;
  }

  // ── UI ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final totalCount = _displayTodos.length;
    final doneCount = _displayTodos.where((t) => t.isCompleted).length;
    final pendingCount = totalCount - doneCount;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null &&
            details.primaryVelocity! > 150) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF050510),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0A0A1A),
                Color(0xFF050510),
                Color(0xFF080818),
              ],
            ),
          ),
          child: SafeArea(
          child: Column(
            children: [
              _buildHeader(pendingCount),
              if (totalCount > 0) _buildProgressBar(doneCount, totalCount),
              _buildInputField(),
              Expanded(
                child: _displayTodos.isEmpty
                    ? _buildEmptyState()
                    : AnimatedList(
                        key: _listKey,
                        padding: const EdgeInsets.only(bottom: 40),
                        initialItemCount: _displayTodos.length,
                        itemBuilder: (context, index, animation) {
                          return _buildAnimatedItem(
                              _displayTodos[index], animation);
                        },
                      ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildHeader(int pendingCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                color: Colors.white70, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              children: [
                const Text('Tasks',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2)),
                if (pendingCount > 0)
                  Text('$pendingCount remaining',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.history_rounded,
                color: Colors.white.withValues(alpha: 0.4), size: 20),
            tooltip: 'Task History',
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (c, a, s) => const TodoHistoryScreen(),
                  transitionsBuilder: (c, anim, secondary, child) {
                    return FadeTransition(opacity: anim, child: child);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int done, int total) {
    final progress = total > 0 ? done / total : 0.0;
    final allDone = done == total && total > 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    allDone ? Icons.celebration_rounded : Icons.task_alt_rounded,
                    size: 16,
                    color: allDone ? Colors.greenAccent : const Color(0xFF06B6D4),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    allDone ? 'All tasks complete!' : '$done of $total done today',
                    style: TextStyle(
                      color: allDone
                          ? Colors.greenAccent.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  color: allDone
                      ? Colors.greenAccent.withValues(alpha: 0.7)
                      : const Color(0xFF06B6D4).withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    allDone ? Colors.greenAccent : const Color(0xFF06B6D4),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _addController,
                focusNode: _addFocusNode,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: 'What needs doing?',
                  hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.2),
                      fontWeight: FontWeight.w400),
                  prefixIcon: Icon(Icons.add_task_rounded,
                      color: Colors.white.withValues(alpha: 0.15), size: 20),
                  filled: false,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onSubmitted: (_) => _addTodo(),
              ),
            ),
            GestureDetector(
              onTap: _addTodo,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF06B6D4).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: GestureDetector(
        onTap: () => _addFocusNode.requestFocus(),
        child: Container(
          padding: const EdgeInsets.all(40),
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF06B6D4).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_outline_rounded,
                    size: 32,
                    color: const Color(0xFF06B6D4).withValues(alpha: 0.4)),
              ),
              const SizedBox(height: 20),
              Text('Your day is clear',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 17,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Text('Tap above to add your first task',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.2),
                      fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodoTile(dynamic todo) {
    final isCompleted = todo.isCompleted;
    final isIntentionLinked = todo.source == 'intention';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        gradient: isIntentionLinked && !isCompleted
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF06B6D4).withValues(alpha: 0.08),
                  const Color(0xFF0891B2).withValues(alpha: 0.04),
                ],
              )
            : null,
        color: isIntentionLinked && !isCompleted
            ? null
            : isCompleted
                ? Colors.white.withValues(alpha: 0.02)
                : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? Colors.white.withValues(alpha: 0.04)
              : isIntentionLinked
                  ? const Color(0xFF06B6D4).withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.08),
          width: isIntentionLinked && !isCompleted ? 1.5 : 1,
        ),
        boxShadow: isIntentionLinked && !isCompleted
            ? [
                BoxShadow(
                  color: const Color(0xFF06B6D4).withValues(alpha: 0.12),
                  blurRadius: 16,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: const Color(0xFF06B6D4).withValues(alpha: 0.08),
          highlightColor: Colors.white.withValues(alpha: 0.02),
          onTap: () => _toggleTodoState(todo),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Checkbox
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? Colors.greenAccent.withValues(alpha: 0.15)
                        : isIntentionLinked
                            ? const Color(0xFF06B6D4).withValues(alpha: 0.1)
                            : Colors.transparent,
                    border: Border.all(
                      color: isCompleted
                          ? Colors.greenAccent.withValues(alpha: 0.6)
                          : isIntentionLinked
                              ? const Color(0xFF06B6D4).withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check_rounded,
                          size: 16, color: Colors.greenAccent)
                      : null,
                ),
                const SizedBox(width: 14),

                // Title + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isIntentionLinked && !isCompleted)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(
                            children: [
                              const Text('🎯', style: TextStyle(fontSize: 11)),
                              const SizedBox(width: 4),
                              Text(
                                'TODAY\'S INTENTION',
                                style: TextStyle(
                                  color: const Color(0xFF06B6D4).withValues(alpha: 0.8),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Text(
                        todo.title,
                        style: TextStyle(
                          color: isCompleted
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.9),
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                          decorationColor: Colors.white.withValues(alpha: 0.15),
                          fontSize: 15,
                          fontWeight: isCompleted ? FontWeight.w300 : FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions
                if (!isCompleted) ...[
                  GestureDetector(
                    onTap: () => _showEditDialog(todo.id, todo.title,
                        isIntention: isIntentionLinked),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(Icons.edit_outlined,
                          size: 18,
                          color: Colors.white.withValues(alpha: 0.25)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.drag_indicator_rounded,
                        size: 18,
                        color: Colors.white.withValues(alpha: 0.15)),
                  ),
                ],
              ],
            ),
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
              child: Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.06))),
          const SizedBox(width: 12),
          Text('DONE',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2)),
          const SizedBox(width: 12),
          Expanded(
              child: Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.06))),
        ],
      ),
    );
  }
}
