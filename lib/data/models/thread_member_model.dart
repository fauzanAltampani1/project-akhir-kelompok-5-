import 'package:flutter/material.dart';
import 'package:taskverse_mobile/data/models/user_model.dart';

enum MemberRole { admin, member, custom }
enum MemberStatus { online, away, offline }

class ThreadMemberModel {
  final UserModel user;
  final MemberRole role;
  final MemberStatus status;
  final String? customRole; // Custom role yang ditambahkan admin
  final DateTime lastActive;
  final Color? roleColor; // Warna untuk custom role

  ThreadMemberModel({
    required this.user,
    required this.role,
    required this.status,
    this.customRole,
    required this.lastActive,
    this.roleColor,
  });

  // Membuat salinan dengan nilai yang diubah
  ThreadMemberModel copyWith({
    UserModel? user,
    MemberRole? role,
    MemberStatus? status,
    String? customRole,
    DateTime? lastActive,
    Color? roleColor,
  }) {
    return ThreadMemberModel(
      user: user ?? this.user,
      role: role ?? this.role,
      status: status ?? this.status,
      customRole: customRole ?? this.customRole,
      lastActive: lastActive ?? this.lastActive,
      roleColor: roleColor ?? this.roleColor,
    );
  }

  // Helper method untuk avatar
  String getInitials() {
    return user.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join('').toUpperCase();
  }
  
  // Factory untuk membuat dari JSON (untuk integrasi backend)
  factory ThreadMemberModel.fromJson(Map<String, dynamic> json) {
    return ThreadMemberModel(
      user: UserModel.fromJson(json['user']),
      role: _getRoleFromString(json['role']),
      status: _getStatusFromString(json['status']),
      customRole: json['custom_role'],
      lastActive: DateTime.parse(json['last_active']),
      roleColor: json['role_color'] != null 
          ? Color(json['role_color'])
          : null,
    );
  }
  
  // Konversi ke JSON (untuk integrasi backend)
  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'role': role.toString().split('.').last,
      'status': status.toString().split('.').last,
      'custom_role': customRole,
      'last_active': lastActive.toIso8601String(),
      'role_color': roleColor?.value,
    };
  }
  
  // Helper untuk parse role dari string
  static MemberRole _getRoleFromString(String? roleStr) {
    switch (roleStr) {
      case 'admin':
        return MemberRole.admin;
      case 'custom':
        return MemberRole.custom;
      case 'member':
      default:
        return MemberRole.member;
    }
  }
  
  // Helper untuk parse status dari string
  static MemberStatus _getStatusFromString(String? statusStr) {
    switch (statusStr) {
      case 'online':
        return MemberStatus.online;
      case 'away':
        return MemberStatus.away;
      case 'offline':
      default:
        return MemberStatus.offline;
    }
  }

  // Dummy data untuk testing
  static List<ThreadMemberModel> dummyMembers = [
    ThreadMemberModel(
      user: UserModel(
        id: '1',
        name: 'Sinister',
        email: 'sinister@example.com',
        avatarUrl: null,
      ),
      role: MemberRole.admin,
      status: MemberStatus.online,
      lastActive: DateTime.now(),
    ),
    ThreadMemberModel(
      user: UserModel(
        id: '2',
        name: 'King',
        email: 'king@example.com',
        avatarUrl: null,
      ),
      role: MemberRole.member,
      status: MemberStatus.away,
      lastActive: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    ThreadMemberModel(
      user: UserModel(
        id: '3',
        name: 'Alex Designer',
        email: 'alex@example.com',
        avatarUrl: null,
      ),
      role: MemberRole.custom,
      customRole: 'UI Designer',
      status: MemberStatus.offline,
      lastActive: DateTime.now().subtract(const Duration(hours: 2)),
      roleColor: Colors.purple,
    ),
    ThreadMemberModel(
      user: UserModel(
        id: '4',
        name: 'Maya Developer',
        email: 'maya@example.com',
        avatarUrl: null,
      ),
      role: MemberRole.member,
      status: MemberStatus.online,
      lastActive: DateTime.now(),
    ),
    ThreadMemberModel(
      user: UserModel(
        id: '5',
        name: 'Reza PM',
        email: 'reza@example.com',
        avatarUrl: null,
      ),
      role: MemberRole.custom,
      customRole: 'Product Manager',
      status: MemberStatus.online,
      lastActive: DateTime.now(),
      roleColor: Colors.teal,
    ),
  ];
}