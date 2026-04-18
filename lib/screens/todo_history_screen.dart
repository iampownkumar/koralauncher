import 'package:flutter/material.dart';
import '../services/todo_service.dart';
import '../database/kora_database.dart';

class TodoHistoryScreen extends StatefulWidget {
  const TodoHistoryScreen({super.key});

  @override
  State<TodoHistoryScreen> createState() => _TodoHistoryScreenState();
}

class _TodoHistoryScreenState extends State<TodoHistoryScreen> {
  late Future<Map<DateTime, List<DailySnapshot>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = TodoService.getHistoryGroupedByDay();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const weekdays = [
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
    ];
    
    // Check if it's yesterday
    final today = DateTime.now();
    final yesterday = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 1));
    final normalizedDate = DateTime(date.year, date.month, date.day);
    
    if (normalizedDate.isAtSameMomentAs(yesterday)) {
      return "Yesterday (${months[date.month - 1]} ${date.day})";
    }

    final dayName = weekdays[date.weekday - 1];
    return "$dayName, ${months[date.month - 1]} ${date.day}";
  }

  @override
  Widget build(BuildContext context) {
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
          title: const Text('Task History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w300, fontSize: 18)),
          centerTitle: true,
        ),
        body: FutureBuilder<Map<DateTime, List<DailySnapshot>>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white24));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history_toggle_off, size: 64, color: Colors.white.withOpacity(0.1)),
                    const SizedBox(height: 16),
                    Text('No history yet.', style: TextStyle(color: Colors.white.withOpacity(0.3))),
                    const SizedBox(height: 8),
                    Text('Completed and missed tasks will appear here\nafter the midnight reset.', 
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 13)
                    ),
                  ],
                ),
              );
            }

            final grouped = snapshot.data!;
            final dates = grouped.keys.toList();

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 40, top: 10),
              itemCount: dates.length,
              itemBuilder: (context, index) {
                final date = dates[index];
                final tasks = grouped[date]!;
                
                final completedCount = tasks.where((t) => t.completed).length;
                final totalCount = tasks.length;

                return _buildDaySection(date, tasks, completedCount, totalCount);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDaySection(DateTime date, List<DailySnapshot> tasks, int completedCount, int totalCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(date),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$completedCount / $totalCount completed',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Tasks Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              children: tasks.map((task) => _buildTaskRow(task)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskRow(DailySnapshot task) {
    final isIntention = task.source == 'intention';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            task.completed ? Icons.check_circle : Icons.cancel_outlined,
            size: 20,
            color: task.completed 
                ? (isIntention ? Colors.cyanAccent.withOpacity(0.6) : Colors.white38) 
                : Colors.white.withOpacity(0.15),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.taskTitle,
                  style: TextStyle(
                    color: task.completed 
                        ? Colors.white.withOpacity(0.6) 
                        : Colors.white.withOpacity(0.3),
                    decoration: task.completed ? TextDecoration.lineThrough : null,
                    fontSize: 15,
                  ),
                ),
                if (isIntention)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '🎯 Daily Intention',
                      style: TextStyle(
                        color: Colors.cyanAccent.withOpacity(0.5),
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
