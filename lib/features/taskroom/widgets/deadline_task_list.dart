import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../config/themes/app_colors.dart';
import '../../../data/models/task_model.dart';
import '../providers/task_provider.dart';
import '../../../shared/widgets/empty_state_widget.dart';

class DeadlineTaskList extends StatelessWidget {
  const DeadlineTaskList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final deadlineTasks = taskProvider.deadlineTasks;

        if (deadlineTasks.isEmpty) {
          return EmptyStateWidget(
            message:
                'No deadline tasks yet. Add your first task with a deadline!',
            icon: Icons.calendar_today,
            actionText: 'Add Deadline Task',
            onAction: () {
              Navigator.pushNamed(context, '/create-task');
            },
          );
        }

        // Sort tasks by due date
        deadlineTasks.sort((a, b) {
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: deadlineTasks.length,
          itemBuilder: (context, index) {
            final task = deadlineTasks[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              // Tambahkan shape dengan border warna
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color:
                      task.isCompleted
                          ? Colors.green.withOpacity(0.5) // Completed
                          : _isTaskOverdue(task)
                          ? Colors.red.withOpacity(0.5) // Overdue
                          : Colors.transparent, // Normal
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: Checkbox(
                      value: task.isCompleted,
                      activeColor: AppColors.secondary,
                      onChanged: (value) {
                        taskProvider.updateTask(
                          task.copyWith(isCompleted: value),
                        );
                      },
                    ),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        decoration:
                            task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (task.description != null) Text(task.description!),
                        if (task.dueDate != null)
                          Row(
                            children: [
                              const Icon(Icons.event, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat(
                                  'MMM dd, yyyy',
                                ).format(task.dueDate!),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPriorityBadge(task.priority),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            taskProvider.deleteTask(task.id);
                          },
                        ),
                      ],
                    ),
                  ),
                  // Tampilkan penanda jika task sudah selesai
                  if (task.isCompleted)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 8,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Completed task will be removed at midnight',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPriorityBadge(TaskPriority? priority) {
    if (priority == null) return const SizedBox.shrink();

    Color color;
    String label;

    switch (priority) {
      case TaskPriority.low:
        color = Colors.green;
        label = 'Low';
        break;
      case TaskPriority.medium:
        color = Colors.orange;
        label = 'Medium';
        break;
      case TaskPriority.high:
        color = Colors.red;
        label = 'High';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Helper method untuk cek overdue
  bool _isTaskOverdue(TaskModel task) {
    if (task.dueDate == null) return false;
    final now = DateTime.now();
    // Task overdue jika tanggal jatuh tempo sudah lewat
    return task.dueDate!.isBefore(DateTime(now.year, now.month, now.day));
  }
}
