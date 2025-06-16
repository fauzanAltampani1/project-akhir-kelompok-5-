import 'package:flutter/material.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/taskroom/screens/taskroom_screen.dart';
import '../../features/thread/screens/thread_screen.dart';
import '../../features/profile/screens/profile_screen.dart';

class AppNavigation {
  static int currentIndex = 0;
  
  static final List<Widget> screens = [
    const HomeScreen(),
    const TaskRoomScreen(),
    const ThreadScreen(),
    const ProfileScreen(),
  ];
  
  static void navigateToIndex(BuildContext context, int index) {
    currentIndex = index;
    
    // Use this if you prefer pushing new routes
    final routes = ['/home', '/taskroom', '/thread', '/profile'];
    Navigator.pushReplacementNamed(context, routes[index]);
    
    // Alternatively, if using a centralized state management:
    // Provider.of<NavigationProvider>(context, listen: false).setIndex(index);
  }
}