import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/themes/app_colors.dart';
import '../../../config/themes/app_text_styles.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/user_model.dart';
import '../providers/project_provider.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({Key? key}) : super(key: key);

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  final Map<String, bool> _selectedMembers = {};
  final Map<String, ProjectRole> _memberRoles = {};

  bool _isCreating = false;

  List<UserModel> _availableUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchAvailableUsers();
  }

  Future<void> _fetchAvailableUsers() async {
    try {
      // TODO: Replace with actual backend call or use correct provider method
      // For now, set _availableUsers to empty or fetch from a UserProvider if available
      setState(() {
        _availableUsers = [];
      });
    } catch (e) {
      // Handle error (show snackbar, etc)
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Project Task Room'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<ProjectProvider>(
        builder: (context, projectProvider, child) {
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header description
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Create a Project Task Room',
                          style: AppTextStyles.heading3,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Name your project, invite your teammates, and start building something awesome together.',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Project Name
                  const Text('Project Name *', style: AppTextStyles.heading3),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Enter project name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.folder),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Project name is required';
                      }
                      if (value.trim().length < 3) {
                        return 'Project name must be at least 3 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Project Description
                  const Text(
                    'Description (Optional)',
                    style: AppTextStyles.heading3,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      hintText: 'Describe your project',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),

                  const SizedBox(height: 24),

                  // Team Members Section
                  Row(
                    children: [
                      const Text('Team Members', style: AppTextStyles.heading3),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Minimum 2 members',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Current user (auto-included as admin)
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Text(
                          UserModel.currentUser.name[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text('${UserModel.currentUser.name} (You)'),
                      subtitle: Text(UserModel.currentUser.email),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Admin',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Available team members
                  const Text(
                    'Add Team Members:',
                    style: AppTextStyles.bodyLarge,
                  ),
                  const SizedBox(height: 8),

                  // Members list
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _availableUsers.length,
                    itemBuilder: (context, index) {
                      final user = _availableUsers[index];
                      final isSelected = _selectedMembers[user.id] ?? false;
                      final currentRole =
                          _memberRoles[user.id] ?? ProjectRole.member;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          children: [
                            CheckboxListTile(
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  _selectedMembers[user.id] = value ?? false;
                                });
                              },
                              secondary: CircleAvatar(
                                backgroundColor:
                                    isSelected
                                        ? AppColors.primary
                                        : Colors.grey,
                                child: Text(
                                  user.name[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(user.name),
                              subtitle: Text(user.email),
                              controlAffinity: ListTileControlAffinity.trailing,
                            ),
                            // Role selector (only visible when selected)
                            if (isSelected)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                  bottom: 8,
                                ),
                                child: Row(
                                  children: [
                                    const Text(
                                      'Role: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child:
                                          DropdownButtonFormField<ProjectRole>(
                                            value: currentRole,
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              border: OutlineInputBorder(),
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                            ),
                                            items: const [
                                              DropdownMenuItem(
                                                value: ProjectRole.member,
                                                child: Text('Member'),
                                              ),
                                              DropdownMenuItem(
                                                value: ProjectRole.admin,
                                                child: Text('Admin'),
                                              ),
                                              DropdownMenuItem(
                                                value: ProjectRole.viewer,
                                                child: Text('Viewer'),
                                              ),
                                            ],
                                            onChanged: (value) {
                                              if (value != null) {
                                                setState(() {
                                                  _memberRoles[user.id] = value;
                                                });
                                              }
                                            },
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Validation info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Project Creation Info:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '• A project thread will be automatically created\n'
                                '• All members will have access to the project thread\n'
                                '• You can manage members and permissions later',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Create Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _isCreating || projectProvider.isLoading
                              ? null
                              : _createProject,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child:
                          _isCreating || projectProvider.isLoading
                              ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Creating Project...'),
                                ],
                              )
                              : const Text(
                                'Create Project Room',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),

                  // Error message
                  if (projectProvider.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              projectProvider.errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _createProject() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate minimum members requirement
    final selectedMemberIds =
        _selectedMembers.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList();

    // Total members = current user + selected members
    final totalMembers = selectedMemberIds.length + 1; // +1 for current user

    if (totalMembers < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select at least 1 team member (minimum 2 members total)',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final projectProvider = Provider.of<ProjectProvider>(
        context,
        listen: false,
      );

      // Prepare member roles (only for selected members)
      final memberRoles = <String, ProjectRole>{};
      for (final memberId in selectedMemberIds) {
        memberRoles[memberId] = _memberRoles[memberId] ?? ProjectRole.member;
      }

      // Add current user as admin
      memberRoles[UserModel.currentUser.id] = ProjectRole.admin;

      final request = CreateProjectRequest(
        name: _nameController.text.trim(),
        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
        memberIds: [UserModel.currentUser.id, ...selectedMemberIds],
        memberRoles: memberRoles,
      );

      final newProject = await projectProvider.createProject(request);

      if (newProject != null) {
        // Clear any previous errors
        projectProvider.clearError();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Project "${newProject.name}" created successfully!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                // TODO: Navigate to project detail page
                Navigator.pushReplacementNamed(context, '/taskroom');
              },
            ),
          ),
        );

        // Navigate back to taskroom
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create project: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }
}
