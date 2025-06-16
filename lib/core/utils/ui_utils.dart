import 'package:flutter/material.dart';

class UiUtils {
  // Animasi untuk card saat muncul
  static Widget fadeInCard({
    required Widget child,
    required int index,
  }) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeIn,
      child: AnimatedPadding(
        padding: const EdgeInsets.all(0),
        duration: Duration(milliseconds: 300 + (index * 100)),
        curve: Curves.easeOut,
        child: child,
      ),
    );
  }
  
  // Animasi untuk floating action button
  static Widget pulseAnimation({required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.95, end: 1.05),
      duration: const Duration(seconds: 2),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
    );
  }
  
  // Format tanggal untuk tampilan
  static String formatDateRelative(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hour(s) ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day(s) ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}