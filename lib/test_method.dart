// This is a test file to validate that methods exist
import 'package:flutter/material.dart';
import 'features/taskroom/providers/project_provider.dart';
import 'features/thread/providers/thread_provider.dart';

void testMethodExists() {
  final projectProvider = ProjectProvider();
  final threadProvider = ThreadProvider();

  // This should compile without errors if the method exists
  projectProvider.setThreadProvider(threadProvider);

  print('Method exists!');
}
