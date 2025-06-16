import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/thread_provider.dart';
import '../../../data/models/thread_member_model.dart';
import '../../../config/themes/app_colors.dart';

class MemberListWidget extends StatelessWidget {
  const MemberListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThreadProvider>(
      builder: (context, provider, _) {
        final groupedMembers = provider.groupedMembers;
        final currentUserId = '1'; // Gunakan UserModel.currentUser.id di implementasi nyata
        final isAdmin = provider.activeMembers
            .any((m) => m.user.id == currentUserId && m.role == MemberRole.admin);
            
        return Container(
          width: 240,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(-2, 0),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Members (${provider.activeMembers.length})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    if (isAdmin)
                      IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        tooltip: 'Add Members',
                        onPressed: () {
                          _showAddMembersDialog(context, provider);
                        },
                      ),
                  ],
                ),
              ),
              
              // Members list
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    // Admin section
                    if (groupedMembers[MemberRole.admin]!.isNotEmpty) ...[
                      _buildRoleHeader('Admins'),
                      ...groupedMembers[MemberRole.admin]!
                          .map((m) => _buildMemberItem(context, m, provider)),
                    ],
                    
                    // Custom roles section
                    if (groupedMembers[MemberRole.custom]!.isNotEmpty) ...[
                      _buildRoleHeader('Team'),
                      ...groupedMembers[MemberRole.custom]!
                          .map((m) => _buildMemberItem(context, m, provider)),
                    ],
                    
                    // Regular members section
                    if (groupedMembers[MemberRole.member]!.isNotEmpty) ...[
                      _buildRoleHeader('Members'),
                      ...groupedMembers[MemberRole.member]!
                          .map((m) => _buildMemberItem(context, m, provider)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Dialog untuk menambahkan anggota baru
  void _showAddMembersDialog(BuildContext context, ThreadProvider provider) {
    // Implementasi akan terintegrasi dengan backend
    // untuk mendapatkan daftar user yang bisa ditambahkan
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Members'),
        content: const Text(
          'Integration with backend required to list available users.',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRoleHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1,
        ),
      ),
    );
  }
  
  Widget _buildMemberItem(
    BuildContext context, 
    ThreadMemberModel member, 
    ThreadProvider provider
  ) {
    // Get status color
    Color statusColor;
    switch (member.status) {
      case MemberStatus.online:
        statusColor = Colors.green;
        break;
      case MemberStatus.away:
        statusColor = Colors.orange;
        break;
      case MemberStatus.offline:
      default:
        statusColor = Colors.grey;
    }
    
    // Tampilkan custom role color jika ada
    final roleColor = member.roleColor;
    final isCurrentUser = member.user.id == '1'; // Gunakan UserModel.currentUser.id di implementasi nyata
    
    return InkWell(
      onTap: () {
        _showMemberDetailCard(context, member, provider);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Status indicator + Avatar
            Stack(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _getAvatarColor(member.user.name),
                  child: Text(
                    member.getInitials(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Status indicator
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            
            // Name and role
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        member.user.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isCurrentUser)
                        const Text(' (you)', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  Text(
                    member.role == MemberRole.custom
                        ? member.customRole ?? 'Member'
                        : member.role.toString().split('.').last,
                    style: TextStyle(
                      fontSize: 12,
                      color: roleColor ?? Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showMemberDetailCard(
    BuildContext context, 
    ThreadMemberModel member, 
    ThreadProvider provider
  ) {
    final currentUserId = '1'; // Gunakan UserModel.currentUser.id di implementasi nyata
    final isAdmin = provider.activeMembers
        .any((m) => m.user.id == currentUserId && m.role == MemberRole.admin);
    final selectedThread = provider.selectedThread;
        
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              CircleAvatar(
                radius: 40,
                backgroundColor: _getAvatarColor(member.user.name),
                child: Text(
                  member.getInitials(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Name and role
              Text(
                member.user.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                member.role == MemberRole.custom
                    ? member.customRole ?? 'Member'
                    : member.role.toString().split('.').last.toUpperCase(),
                style: TextStyle(
                  color: member.roleColor ?? (member.role == MemberRole.admin
                      ? AppColors.primary
                      : Colors.grey[600]),
                ),
              ),
              Text(
                member.user.email,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              
              // Status
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: member.status == MemberStatus.online
                          ? Colors.green
                          : member.status == MemberStatus.away
                              ? Colors.orange
                              : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    member.status.toString().split('.').last,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      // Placeholder for message action
                      Navigator.pop(context);
                    },
                    child: const Text('Message'),
                  ),
                  // Admin action - Edit role
                  if (isAdmin && selectedThread != null && member.user.id != currentUserId)
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Edit role',
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditRoleDialog(context, provider, selectedThread.id, member);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showEditRoleDialog(
    BuildContext context, 
    ThreadProvider provider, 
    String threadId, 
    ThreadMemberModel member
  ) {
    // Role yang dipilih
    MemberRole selectedRole = member.role;
    // Controller untuk custom role
    final customRoleController = TextEditingController(
      text: member.role == MemberRole.custom ? member.customRole : '',
    );
    // Warna role
    Color? selectedColor = member.roleColor ?? Colors.blue;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Edit Role - ${member.user.name}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Role:'),
                  RadioListTile<MemberRole>(
                    title: const Text('Admin'),
                    value: MemberRole.admin,
                    groupValue: selectedRole,
                    onChanged: (value) {
                      setState(() => selectedRole = value!);
                    },
                  ),
                  RadioListTile<MemberRole>(
                    title: const Text('Member'),
                    value: MemberRole.member,
                    groupValue: selectedRole,
                    onChanged: (value) {
                      setState(() => selectedRole = value!);
                    },
                  ),
                  RadioListTile<MemberRole>(
                    title: const Text('Custom Role'),
                    value: MemberRole.custom,
                    groupValue: selectedRole,
                    onChanged: (value) {
                      setState(() => selectedRole = value!);
                    },
                  ),
                  
                  // Custom role input (hanya tampil jika custom dipilih)
                  if (selectedRole == MemberRole.custom) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: customRoleController,
                      decoration: const InputDecoration(
                        labelText: 'Custom Role Name',
                        hintText: 'e.g. UI Designer',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Role Color:'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildColorSelector(Colors.blue, selectedColor, (color) {
                          setState(() => selectedColor = color);
                        }),
                        _buildColorSelector(Colors.red, selectedColor, (color) {
                          setState(() => selectedColor = color);
                        }),
                        _buildColorSelector(Colors.green, selectedColor, (color) {
                          setState(() => selectedColor = color);
                        }),
                        _buildColorSelector(Colors.orange, selectedColor, (color) {
                          setState(() => selectedColor = color);
                        }),
                        _buildColorSelector(Colors.purple, selectedColor, (color) {
                          setState(() => selectedColor = color);
                        }),
                        _buildColorSelector(Colors.teal, selectedColor, (color) {
                          setState(() => selectedColor = color);
                        }),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Validasi untuk custom role
                  if (selectedRole == MemberRole.custom && 
                      customRoleController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Custom role name is required')),
                    );
                    return;
                  }
                  
                  Navigator.pop(context);
                  
                  // Perbarui role member
                  await provider.updateMemberRole(
                    threadId: threadId,
                    userId: member.user.id,
                    role: selectedRole,
                    customRole: customRoleController.text,
                    roleColor: selectedRole == MemberRole.custom ? selectedColor : null,
                  );
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Member role updated successfully')),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  // Widget selector warna untuk custom role
  Widget _buildColorSelector(
    Color color, 
    Color? selectedColor, 
    Function(Color) onTap
  ) {
    final isSelected = selectedColor == color;
    
    return GestureDetector(
      onTap: () => onTap(color),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 4)]
              : null,
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );
  }
  
  // Generate consistent avatar colors based on name
  Color _getAvatarColor(String name) {
    // Simple hash function for consistent color
    final hash = name.codeUnits.fold(0, (prev, element) => prev + element);
    final hue = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.4).toColor();
  }
}