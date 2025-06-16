import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../config/themes/app_colors.dart';
import '../../../config/themes/app_text_styles.dart';
import '../../../data/models/project_task_model.dart';
import '../providers/project_provider.dart';
import '../providers/project_task_provider.dart';

class ProjectTaskCard extends StatelessWidget {
  final ProjectTaskModel task;

  const ProjectTaskCard({super.key, required this.task});

  String _getAssigneeNames(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context);
    final project = projectProvider.getProjectById(task.projectId);
    if (project == null) return 'Unknown';

    if (task.assigneeIds.isEmpty) {
      return 'All Members';
    }

    final names = task.assigneeIds
        .map((id) => project.members.firstWhere((m) => m.userId == id).user.name)
        .join(', ');
    return names;
  }

  void _deleteTask(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<ProjectTaskProvider>(context, listen: false)
                  .deleteProjectTask(task.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(
          task.title,
          style: AppTextStyles.heading3,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null) ...[
              Text(task.description!, style: AppTextStyles.bodySmall),
              const SizedBox(height: 4),
            ],
            Text(
              'Assigned to: ${_getAssigneeNames(context)}',
              style: AppTextStyles.bodySmall,
            ),
            Text(
              'Due: ${DateFormat('d MMMM yyyy').format(task.dueDate)}',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: task.isCompleted,
              onChanged: (value) {
                Provider.of<ProjectTaskProvider>(context, listen: false)
                    .updateProjectTask(task.id, isCompleted: value);
              },
              activeColor: AppColors.primary,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteTask(context),
            ),
          ],
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/edit-task-in-project',
            arguments: task,
          );
        },
      ),
    );
  }
}