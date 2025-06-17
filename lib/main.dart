import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/navigation_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/home/providers/home_provider.dart';
import 'features/taskroom/providers/task_provider.dart';
import 'features/thread/providers/thread_provider.dart';
import 'features/taskroom/providers/project_provider.dart';
import 'features/taskroom/providers/project_task_provider.dart';
import 'features/profile/providers/notification_provider.dart';
import 'app.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => ThreadProvider()),
        ChangeNotifierProvider(create: (_) => ProjectTaskProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const TaskVerseApp(),
    ),
  );
}
