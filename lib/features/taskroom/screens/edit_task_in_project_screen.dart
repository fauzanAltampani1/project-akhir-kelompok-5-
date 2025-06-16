import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../config/themes/app_colors.dart';
import '../../../config/themes/app_text_styles.dart';
import '../../../data/models/project_task_model.dart';
import '../providers/project_task_provider.dart';
import '../providers/project_provider.dart';
import '../widgets/assignee_selector_widget.dart';
import '../../../shared/widgets/empty_state_widget.dart';

class EditTaskInProjectScreen extends StatefulWidget {
  const EditTaskInProjectScreen({super.key});

  @override
  _EditTaskInProjectScreenState createState() =>
      _EditTaskInProjectScreenState();
}

class _EditTaskInProjectScreenState extends State<EditTaskInProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _dueDate;
  List<String> _assigneeIds = [];
  late ProjectTaskModel _task;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _task = ModalRoute.of(context)!.settings.arguments as ProjectTaskModel;
      _titleController.text = _task.title;
      _descriptionController.text = _task.description ?? '';
      _dueDate = _task.dueDate;
      _assigneeIds = List.from(_task.assigneeIds);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _dueDate != null) {
      final provider = Provider.of<ProjectTaskProvider>(context, listen: false);
      final success = await provider.updateProjectTask(
        _task.id,
        title: _titleController.text,
        description:
            _descriptionController.text.isNotEmpty
                ? _descriptionController.text
                : null,
        dueDate: _dueDate,
        assigneeIds: _assigneeIds,
      );
      if (success == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task updated successfully')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to update task'),
          ),
        );
      }
    } else if (_dueDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a due date')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context);
    final project = projectProvider.getProjectById(_task.projectId);

    if (project == null) {
      return const EmptyStateWidget(
        message: 'Project not found',
        icon: Icons.error,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Project Task', style: AppTextStyles.heading3),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) => value!.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Due Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _dueDate != null
                        ? DateFormat('d MMMM yyyy').format(_dueDate!)
                        : 'Select due date',
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AssigneeSelectorWidget(
                members: project.members,
                selectedIds: _assigneeIds,
                onChanged: (ids) => setState(() => _assigneeIds = ids),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text('Save Changes', style: AppTextStyles.button),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
