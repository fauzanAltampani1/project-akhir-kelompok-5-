import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/themes/app_colors.dart';
import '../../../config/themes/app_text_styles.dart';
import '../../../data/models/user_model.dart';
import '../providers/project_provider.dart';
import '../../../data/models/project_task_model.dart';

class ProjectTaskCard extends StatelessWidget {
  const ProjectTaskCard({super.key});

  void _handleProjectAction(BuildContext context, String projectId, String projectName) {
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    final project = projectProvider.getProjectById(projectId);
    final isAdmin = project != null && project.isUserAdmin(UserModel.currentUser.id);

    if (isAdmin) {
      // Admin: Delete project
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Project'),
          content: Text('Are you sure you want to delete "$projectName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                projectProvider.deleteProject(projectId);
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    } else {
      // Member: Leave project
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Leave Project'),
          content: Text('Are you sure you want to leave "$projectName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                projectProvider.removeMemberFromProject(projectId, UserModel.currentUser.id);
                Navigator.pop(context);
              },
              child: const Text('Leave', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, projectProvider, child) {
        final userProjects = projectProvider.userProjects;
        final hasProjects = userProjects.isNotEmpty;

        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.group, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Project Tasks', style: AppTextStyles.heading3),
                  ],
                ),
                const SizedBox(height: 16),
                
                if (projectProvider.isLoading)
                  const SizedBox(
                    height: 150,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Loading projects...'),
                        ],
                      ),
                    ),
                  )
                else if (projectProvider.errorMessage != null)
                  SizedBox(
                    height: 150,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to load projects',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          projectProvider.errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.red[700]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => projectProvider.refreshProjects(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                else if (hasProjects)
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.folder_open, color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${userProjects.length} Active Project${userProjects.length > 1 ? 's' : ''}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: userProjects.length,
                          itemBuilder: (context, index) {
                            final project = userProjects[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                dense: true,
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.secondary,
                                  radius: 16,
                                  child: Text(
                                    project.name[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  project.name,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Row(
                                  children: [
                                    Icon(Icons.people, size: 12, color: Colors.grey[600]),
                                    Text(' ${project.members.length}'),
                                    const SizedBox(width: 12),
                                    Icon(Icons.task, size: 12, color: Colors.grey[600]),
                                    Text(' ${project.taskCount}'),
                                    const SizedBox(width: 12),
                                    Icon(Icons.chat, size: 12, color: Colors.grey[600]),
                                    Text(' ${project.threadCount}'),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: project.isUserAdmin(UserModel.currentUser.id) 
                                            ? AppColors.primary.withOpacity(0.1)
                                            : AppColors.secondary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        project.isUserAdmin(UserModel.currentUser.id) ? 'Admin' : 'Member',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: project.isUserAdmin(UserModel.currentUser.id) 
                                              ? AppColors.primary
                                              : AppColors.secondary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                      onPressed: () => _handleProjectAction(context, project.id, project.name),
                                    ),
                                    const Icon(Icons.chevron_right, size: 16),
                                  ],
                                ),
                                onTap: () {
                                  print('🔧 Navigating to project detail: ${project.id} (${project.name})');
                                  Navigator.pushNamed(
                                    context, 
                                    '/project-detail',
                                    arguments: project.id,
                                  ).then((_) {
                                    projectProvider.refreshProjects();
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/create-project').then((_) {
                              projectProvider.refreshProjects();
                            });
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Create New Project'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    height: 150,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('It\'s quiet here...', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text(
                          'Start a project now and invite your teammates to collaborate and get things done together.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/create-project').then((_) {
                              projectProvider.refreshProjects();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(12),
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}