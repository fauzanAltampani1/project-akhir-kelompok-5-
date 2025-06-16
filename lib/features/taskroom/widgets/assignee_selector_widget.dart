import 'package:flutter/material.dart';
import '../../../config/themes/app_colors.dart';
import '../../../config/themes/app_text_styles.dart';
import '../../../data/models/project_model.dart';

class AssigneeSelectorWidget extends StatefulWidget {
  final List<ProjectMember> members;
  final List<String> selectedIds;
  final Function(List<String>) onChanged;

  const AssigneeSelectorWidget({
    super.key,
    required this.members,
    required this.selectedIds,
    required this.onChanged,
  });

  @override
  _AssigneeSelectorWidgetState createState() => _AssigneeSelectorWidgetState();
}

class _AssigneeSelectorWidgetState extends State<AssigneeSelectorWidget> {
  late List<String> _selectedIds;
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedIds);
    _selectAll = _selectedIds.isEmpty && widget.members.isNotEmpty;
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      _selectedIds = _selectAll ? [] : widget.members.map((m) => m.userId).toList();
      widget.onChanged(_selectedIds);
    });
  }

  void _toggleAssignee(String userId, bool? value) {
    setState(() {
      if (value == true) {
        _selectedIds.add(userId);
      } else {
        _selectedIds.remove(userId);
      }
      _selectAll = _selectedIds.isEmpty;
      widget.onChanged(_selectedIds);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assign To',
          style: AppTextStyles.heading3,
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: Text('All Members', style: AppTextStyles.bodyMedium),
          value: _selectAll,
          onChanged: _toggleSelectAll,
          activeColor: AppColors.primary,
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.members.length,
          itemBuilder: (context, index) {
            final member = widget.members[index];
            final isSelected = _selectedIds.contains(member.userId);
            return CheckboxListTile(
              title: Text(member.user.name, style: AppTextStyles.bodyMedium),
              value: isSelected && !_selectAll,
              onChanged: _selectAll ? null : (value) => _toggleAssignee(member.userId, value),
              activeColor: AppColors.primary,
            );
          },
        ),
      ],
    );
  }
}