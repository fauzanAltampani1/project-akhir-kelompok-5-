-- TaskVerse Dummy Data SQL
-- Run these queries in your MySQL database to populate with test data

-- First, let's insert some dummy users
INSERT INTO users (id, name, email, password, created_at, updated_at) VALUES
(1, 'John Doe', 'john.doe@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NOW(), NOW()),
(2, 'Jane Smith', 'jane.smith@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NOW(), NOW()),
(3, 'Mike Johnson', 'mike.johnson@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NOW(), NOW()),
(4, 'Sarah Wilson', 'sarah.wilson@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NOW(), NOW()),
(5, 'David Brown', 'david.brown@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NOW(), NOW());

-- Insert dummy projects
INSERT INTO projects (id, name, description, creator_id, task_count, thread_count, status, created_at, updated_at) VALUES
(1, 'E-Commerce Website Redesign', 'Complete redesign of the company e-commerce platform with modern UI/UX', 1, 12, 3, 'active', '2024-12-01 10:00:00', NOW()),
(2, 'Mobile App Development', 'Cross-platform mobile application for task management', 2, 8, 2, 'active', '2024-12-05 14:30:00', NOW()),
(3, 'Database Migration Project', 'Migrate legacy database to new cloud infrastructure', 3, 6, 1, 'in_progress', '2024-12-10 09:15:00', NOW()),
(4, 'Marketing Campaign 2025', 'Digital marketing strategy and implementation for Q1 2025', 4, 15, 4, 'planning', '2024-12-15 16:45:00', NOW()),
(5, 'Security Audit & Enhancement', 'Comprehensive security review and implementation of best practices', 5, 9, 2, 'active', '2024-12-20 11:20:00', NOW());

-- Insert project members
INSERT INTO project_members (project_id, user_id, role, joined_at) VALUES
-- E-Commerce Website Redesign team
(1, 1, 'admin', '2024-12-01 10:00:00'),
(1, 2, 'developer', '2024-12-01 10:30:00'),
(1, 3, 'designer', '2024-12-02 09:00:00'),
(1, 4, 'tester', '2024-12-02 14:00:00'),

-- Mobile App Development team
(2, 2, 'admin', '2024-12-05 14:30:00'),
(2, 1, 'developer', '2024-12-05 15:00:00'),
(2, 5, 'developer', '2024-12-06 10:00:00'),

-- Database Migration Project team
(3, 3, 'admin', '2024-12-10 09:15:00'),
(3, 5, 'developer', '2024-12-10 10:00:00'),
(3, 1, 'consultant', '2024-12-11 09:00:00'),

-- Marketing Campaign 2025 team
(4, 4, 'admin', '2024-12-15 16:45:00'),
(4, 2, 'content_creator', '2024-12-16 09:00:00'),
(4, 3, 'designer', '2024-12-16 10:30:00'),

-- Security Audit & Enhancement team
(5, 5, 'admin', '2024-12-20 11:20:00'),
(5, 1, 'security_specialist', '2024-12-20 12:00:00'),
(5, 3, 'developer', '2024-12-21 09:00:00');

-- Insert dummy tasks
INSERT INTO tasks (id, title, description, assignee_id, project_id, priority, status, due_date, created_at, updated_at) VALUES
-- E-Commerce Website Redesign tasks
(1, 'Design Homepage Mockup', 'Create initial homepage design mockups with modern layout', 3, 1, 'high', 'in_progress', '2025-01-15 00:00:00', '2024-12-01 10:00:00', NOW()),
(2, 'Setup Development Environment', 'Configure development environment for the new website', 2, 1, 'high', 'completed', '2024-12-10 00:00:00', '2024-12-01 11:00:00', NOW()),
(3, 'Database Schema Design', 'Design new database schema for product catalog', 1, 1, 'medium', 'pending', '2025-01-20 00:00:00', '2024-12-02 09:00:00', NOW()),
(4, 'Payment Gateway Integration', 'Integrate Stripe payment gateway', 2, 1, 'high', 'pending', '2025-02-01 00:00:00', '2024-12-03 14:00:00', NOW()),

-- Mobile App Development tasks
(5, 'User Authentication Module', 'Implement login/logout functionality', 5, 2, 'high', 'in_progress', '2025-01-10 00:00:00', '2024-12-05 15:00:00', NOW()),
(6, 'Task Management UI', 'Design and implement task management interface', 2, 2, 'medium', 'pending', '2025-01-25 00:00:00', '2024-12-06 10:00:00', NOW()),
(7, 'Push Notifications', 'Implement push notification system', 1, 2, 'low', 'pending', '2025-02-15 00:00:00', '2024-12-07 11:00:00', NOW()),

-- Database Migration Project tasks
(8, 'Data Backup Strategy', 'Plan and implement comprehensive data backup', 3, 3, 'high', 'completed', '2024-12-25 00:00:00', '2024-12-10 09:15:00', NOW()),
(9, 'Migration Scripts', 'Write scripts for data migration', 5, 3, 'high', 'in_progress', '2025-01-05 00:00:00', '2024-12-12 10:00:00', NOW()),
(10, 'Performance Testing', 'Test performance of new database setup', 1, 3, 'medium', 'pending', '2025-01-15 00:00:00', '2024-12-14 14:00:00', NOW()),

-- Marketing Campaign 2025 tasks
(11, 'Market Research', 'Conduct comprehensive market analysis', 4, 4, 'high', 'in_progress', '2025-01-08 00:00:00', '2024-12-15 17:00:00', NOW()),
(12, 'Content Calendar', 'Create content calendar for Q1 2025', 2, 4, 'medium', 'pending', '2025-01-12 00:00:00', '2024-12-16 09:30:00', NOW()),
(13, 'Social Media Assets', 'Design social media graphics and videos', 3, 4, 'medium', 'pending', '2025-01-20 00:00:00', '2024-12-17 10:00:00', NOW()),

-- Security Audit & Enhancement tasks
(14, 'Vulnerability Assessment', 'Conduct comprehensive security audit', 5, 5, 'high', 'in_progress', '2025-01-03 00:00:00', '2024-12-20 11:30:00', NOW()),
(15, 'SSL Certificate Update', 'Update and configure SSL certificates', 1, 5, 'high', 'pending', '2024-12-30 00:00:00', '2024-12-21 09:30:00', NOW()),
(16, 'Security Documentation', 'Create security guidelines and documentation', 3, 5, 'low', 'pending', '2025-01-30 00:00:00', '2024-12-22 14:00:00', NOW());

-- Insert dummy threads
INSERT INTO threads (id, title, description, creator_id, project_id, status, created_at, updated_at) VALUES
(1, 'Design Discussion', 'Discussion about the overall design direction for the e-commerce site', 3, 1, 'active', '2024-12-02 10:00:00', NOW()),
(2, 'Technical Requirements', 'Technical specifications and requirements discussion', 1, 1, 'active', '2024-12-03 09:00:00', NOW()),
(3, 'Testing Strategy', 'Planning testing approach and methodologies', 4, 1, 'active', '2024-12-04 14:00:00', NOW()),
(4, 'App Architecture', 'Discussion about mobile app architecture and patterns', 2, 2, 'active', '2024-12-06 11:00:00', NOW()),
(5, 'Performance Optimization', 'Mobile app performance optimization strategies', 5, 2, 'active', '2024-12-08 15:30:00', NOW()),
(6, 'Migration Timeline', 'Database migration schedule and milestones', 3, 3, 'active', '2024-12-11 10:00:00', NOW()),
(7, 'Campaign Strategy', 'Marketing campaign strategy and tactics', 4, 4, 'active', '2024-12-16 10:00:00', NOW()),
(8, 'Target Audience', 'Defining target audience and personas', 2, 4, 'active', '2024-12-17 11:30:00', NOW()),
(9, 'Budget Planning', 'Marketing budget allocation and planning', 4, 4, 'active', '2024-12-18 09:00:00', NOW()),
(10, 'Security Protocols', 'Establishing security protocols and procedures', 5, 5, 'active', '2024-12-21 10:00:00', NOW()),
(11, 'Incident Response', 'Security incident response planning', 1, 5, 'active', '2024-12-22 13:00:00', NOW());

-- Insert thread members
INSERT INTO thread_members (thread_id, user_id, role, joined_at) VALUES
-- Design Discussion
(1, 3, 'creator', '2024-12-02 10:00:00'),
(1, 1, 'participant', '2024-12-02 10:30:00'),
(1, 2, 'participant', '2024-12-02 11:00:00'),

-- Technical Requirements
(2, 1, 'creator', '2024-12-03 09:00:00'),
(2, 2, 'participant', '2024-12-03 09:30:00'),
(2, 3, 'participant', '2024-12-03 10:00:00'),

-- App Architecture
(4, 2, 'creator', '2024-12-06 11:00:00'),
(4, 1, 'participant', '2024-12-06 11:30:00'),
(4, 5, 'participant', '2024-12-06 12:00:00'),

-- Campaign Strategy
(7, 4, 'creator', '2024-12-16 10:00:00'),
(7, 2, 'participant', '2024-12-16 10:30:00'),
(7, 3, 'participant', '2024-12-16 11:00:00'),

-- Security Protocols
(10, 5, 'creator', '2024-12-21 10:00:00'),
(10, 1, 'participant', '2024-12-21 10:30:00'),
(10, 3, 'participant', '2024-12-21 11:00:00');

-- Insert messages
INSERT INTO messages (id, thread_id, sender_id, content, message_type, created_at, updated_at) VALUES
(1, 1, 3, 'I think we should go with a clean, modern design approach. What do you all think?', 'text', '2024-12-02 10:05:00', NOW()),
(2, 1, 1, 'Absolutely! I agree with the modern approach. We should focus on user experience.', 'text', '2024-12-02 10:35:00', NOW()),
(3, 1, 2, 'Should we consider mobile-first design?', 'text', '2024-12-02 11:05:00', NOW()),
(4, 2, 1, 'Here are the initial technical requirements for the project...', 'text', '2024-12-03 09:05:00', NOW()),
(5, 2, 2, 'We should use React for the frontend and Node.js for the backend.', 'text', '2024-12-03 09:35:00', NOW()),
(6, 4, 2, 'For the mobile app, I suggest using Flutter for cross-platform development.', 'text', '2024-12-06 11:05:00', NOW()),
(7, 4, 1, 'Flutter sounds good. What about state management?', 'text', '2024-12-06 11:35:00', NOW()),
(8, 4, 5, 'I recommend using Provider or Riverpod for state management.', 'text', '2024-12-06 12:05:00', NOW()),
(9, 7, 4, 'Our target audience should be young professionals aged 25-40.', 'text', '2024-12-16 10:05:00', NOW()),
(10, 7, 2, 'We should focus on digital channels - social media, email marketing, etc.', 'text', '2024-12-16 10:35:00', NOW()),
(11, 10, 5, 'Security should be our top priority. We need to implement multi-factor authentication.', 'text', '2024-12-21 10:05:00', NOW()),
(12, 10, 1, 'Agreed. We should also conduct regular security audits.', 'text', '2024-12-21 10:35:00', NOW());

-- Update project task and thread counts
UPDATE projects SET 
    task_count = (SELECT COUNT(*) FROM tasks WHERE project_id = projects.id),
    thread_count = (SELECT COUNT(*) FROM threads WHERE project_id = projects.id)
WHERE id IN (1, 2, 3, 4, 5);

-- Note: The password hash used above is for 'password123' - you should change these in production
-- You can generate new password hashes using PHP: password_hash('your_password', PASSWORD_BCRYPT)
