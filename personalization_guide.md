# Personalized User Experience Guide

## Overview

This guide outlines how the personalization features work in the TaskVerse application, ensuring each user only sees and interacts with their own tasks and projects.

## PersonalizationHelper Components

### 1. Personalized Greetings

- Time-based greetings (Good morning/afternoon/evening)
- Productivity messages based on task completion

### 2. User-Specific Project Filtering

- Only displays projects where the user is a member
- Shows appropriate role designation (Creator, Admin, Member)
- Color-coding for different roles

### 3. Priority Task Management

- Identifies tasks due within 48 hours
- Labels tasks appropriately (Overdue, Due Today, Due Tomorrow, etc.)
- Special highlighting for overdue tasks

## Implementation Details

### Key Methods in PersonalizationHelper

- `getPersonalizedGreeting(userName)`: Returns time-appropriate greeting
- `getProductivityMessage(completedTasksCount)`: Motivational message based on productivity
- `getCurrentUserProjects(allProjects)`: Filters projects for current user
- `getUserRoleInProject(project)`: Returns user's role in specific project
- `getPriorityTasks(tasks)`: Identifies high-priority tasks needing attention
- `getTaskDueDateLabel(task)`: Returns appropriate due date label

### How Features Are Integrated

1. HomeScreen uses personalized greeting and productivity message
2. ProjectListWidget displays only the current user's projects with role indicators
3. ReminderWidget shows priority tasks that need attention soon
4. TaskProvider and ProjectProvider filter data for the current user

## Best Practices

1. Always filter data at the provider level before passing to UI
2. Use PriorityTasksWidget to display urgent tasks consistently
3. Ensure role-based UI elements reflect accurate permissions
4. Use the PersonalizationHelper methods to maintain consistency

## Future Enhancements

1. User preferences for notifications and task sorting
2. More granular personalization based on user activity patterns
3. Dashboard customization options
