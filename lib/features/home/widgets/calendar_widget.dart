import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/themes/app_colors.dart';
import '../../../config/themes/app_text_styles.dart';

class CalendarWidget extends StatelessWidget {
  const CalendarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final DateTime currentDate = DateTime.now();
    final String currentMonth = DateFormat('MMMM yyyy').format(currentDate);
    
    // Get days of current month
    final int daysInMonth = DateTime(currentDate.year, currentDate.month + 1, 0).day;
    final int firstDayOfWeek = DateTime(currentDate.year, currentDate.month, 1).weekday % 7;
    
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currentMonth,
                  style: AppTextStyles.heading3,
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      onPressed: () {
                        // Previous month
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 20),
                      onPressed: () {
                        // Next month
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Days of week
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                Text('S', style: AppTextStyles.caption),
                Text('M', style: AppTextStyles.caption),
                Text('T', style: AppTextStyles.caption),
                Text('W', style: AppTextStyles.caption),
                Text('T', style: AppTextStyles.caption),
                Text('F', style: AppTextStyles.caption),
                Text('S', style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 8),
            // Calendar grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: firstDayOfWeek + daysInMonth,
              itemBuilder: (context, index) {
                if (index < firstDayOfWeek) {
                  return const SizedBox.shrink();
                }
                
                final int day = index - firstDayOfWeek + 1;
                final bool isToday = day == currentDate.day;
                
                return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isToday ? AppColors.primary : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      day.toString(),
                      style: TextStyle(
                        color: isToday ? Colors.white : AppColors.textPrimary,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}