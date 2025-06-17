import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/themes/app_colors.dart';
import '../../../config/themes/app_text_styles.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/user_model.dart';
import '../providers/project_provider.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

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
      // TODO: Implement user provider to fetch available users
      setState(() {
        _availableUsers = [];
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch users: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createProject() async {
    if (!_formKey.currentState!.validate()) return;

    final selectedMemberIds =
        _selectedMembers.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList();

    final totalMembers = selectedMemberIds.length + 1;

    if (totalMembers < 2) {
      if (!mounted) return;
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
      if (!mounted) return;
      final projectProvider = Provider.of<ProjectProvider>(
        context,
        listen: false,
      );

      final memberRoles = <String, ProjectRole>{};
      for (final memberId in selectedMemberIds) {
        memberRoles[memberId] = _memberRoles[memberId] ?? ProjectRole.member;
      }
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

      if (!mounted) return;

      if (newProject != null) {
        projectProvider.clearError();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Project "${newProject.name}" created successfully!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/taskroom');
              },
            ),
          ),
        );

        if (!mounted) return;
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create project: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isCreating = false;
      });
    }
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
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 26),
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

                  if (projectProvider.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 26),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 77),
                        ),
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
}
