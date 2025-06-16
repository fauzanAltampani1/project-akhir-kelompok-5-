import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/themes/app_colors.dart';
import '../../../config/themes/app_text_styles.dart';
import '../../../data/models/user_model.dart';
import '../../../shared/navigation/bottom_nav_bar.dart';
import '../../auth/providers/auth_provider.dart';
import '../../taskroom/providers/project_provider.dart';
import '../../taskroom/providers/project_task_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final int _currentIndex = 3; // Profile selected

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final projectProvider = Provider.of<ProjectProvider>(context);
    final taskProvider = Provider.of<ProjectTaskProvider>(context);
    final user = authProvider.currentUser ?? UserModel.currentUser;

    if (user.id.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final projectsCount = projectProvider.userProjects.length;
    final tasksCount = taskProvider.assignedTasks.length;
    final completedTasksCount =
        taskProvider.assignedTasks.where((task) => task.isCompleted).length;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Profile avatar
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primary,
                child: Text(
                  user.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // User name
              Text(
                user.name,
                style: AppTextStyles.heading1.copyWith(fontFamily: 'Montserrat'),
              ),
              Text(
                user.email,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontFamily: 'Montserrat',
                ),
              ),
              const SizedBox(height: 32),
              // Stats
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Tasks', tasksCount.toString()),
                    _buildStatItem('Projects', projectsCount.toString()),
                    _buildStatItem('Completed', completedTasksCount.toString()),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Recent Activities
              _buildRecentActivities(context, taskProvider, projectProvider),
              const SizedBox(height: 24),
              // Profile sections
              _buildProfileSection(
                icon: Icons.settings,
                title: 'Settings',
                onTap: () {
                  Navigator.pushNamed(context, '/settings');
                },
              ),
              _buildProfileSection(
                icon: Icons.notifications,
                title: 'Notifications',
                onTap: () {
                 Navigator.pushNamed(context, '/notifications');
                },
              ),
              _buildProfileSection(
                icon: Icons.privacy_tip,
                title: 'Privacy',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Privacy settings not implemented yet')),
                  );
                },
              ),
              _buildProfileSection(
                icon: Icons.help,
                title: 'Help & Support',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Help & Support not implemented yet')),
                  );
                },
              ),
              _buildProfileSection(
                icon: Icons.logout,
                title: 'Log Out',
                textColor: Colors.red,
                onTap: () async {
                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/splash',
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == _currentIndex) return;

          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/taskroom');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/thread');
              break;
            case 3:
              // Already on Profile
              break;
          }
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.primary,
            fontFamily: 'Montserrat',
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(fontFamily: 'Montserrat'),
        ),
      ],
    );
  }

  Widget _buildProfileSection({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: textColor ?? AppColors.iconColor),
        title: Text(
          title,
          style: AppTextStyles.bodyLarge.copyWith(
            color: textColor,
            fontFamily: 'Montserrat',
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

 Widget _buildRecentActivities(
  BuildContext context,
  ProjectTaskProvider taskProvider,
  ProjectProvider projectProvider,
) {
  final tasks = taskProvider.assignedTasks
      .where((task) => task.dueDate.isAfter(DateTime.now().subtract(const Duration(days: 7))))
      .take(5)
      .toList();
  tasks.sort((a, b) => b.dueDate.compareTo(a.dueDate)); // Sort by dueDate descending (newer due dates first)

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Recent Activities',
        style: AppTextStyles.heading3.copyWith(fontFamily: 'Montserrat'),
      ),
      const SizedBox(height: 12),
      tasks.isEmpty
          ? Card(
              child: ListTile(
                title: Text(
                  'No recent activities',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
            )
          : Column(
              children: tasks
                  .asMap()
                  .entries
                  .map(
                    (entry) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          entry.value.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: entry.value.isCompleted ? AppColors.success : AppColors.primary,
                        ),
                        title: Text(
                          entry.value.title,
                          style: AppTextStyles.bodyMedium.copyWith(fontFamily: 'Montserrat'),
                        ),
                        subtitle: Text(
                          'In ${projectProvider.getProjectById(entry.value.projectId)?.name ?? 'Unknown Project'} • Due ${entry.value.dueDate.day}/${entry.value.dueDate.month}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/project-detail',
                            arguments: entry.value.projectId,
                          );
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
    ],
  );
}
}