import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class TodoListWidget extends StatefulWidget {
  const TodoListWidget({super.key});

  @override
  State<TodoListWidget> createState() => _TodoListWidgetState();
}

class _TodoListWidgetState extends State<TodoListWidget> {
  late List<String> _todos;
  late List<bool> _states;
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _todos = StorageService.getTodos();
    _states = StorageService.getTodoStates().map((e) => e == 'true').toList();
    
    // Ensure lists are always size 4
    while (_todos.length < 4) _todos.add('');
    while (_states.length < 4) _states.add(false);

    _controllers = _todos.map((text) => TextEditingController(text: text)).toList();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveTodos() {
    StorageService.setTodos(_todos);
    StorageService.setTodoStates(_states.map((e) => e.toString()).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(4, (index) => _buildTodoItem(index)),
        ],
      ),
    );
  }

  Widget _buildTodoItem(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _states[index] = !_states[index];
              });
              _saveTodos();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: _states[index] ? Colors.white : Colors.transparent,
                border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: _states[index] 
                  ? const Icon(Icons.check, size: 14, color: Colors.black)
                  : null,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _controllers[index],
              onChanged: (val) {
                _todos[index] = val;
                _saveTodos();
              },
              style: TextStyle(
                color: _states[index] ? Colors.white.withValues(alpha: 0.4) : Colors.white,
                fontSize: 18,
                decoration: _states[index] ? TextDecoration.lineThrough : null,
                decorationColor: Colors.white.withValues(alpha: 0.4),
              ),
              decoration: InputDecoration(
                hintText: "Add a task...",
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 16),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
