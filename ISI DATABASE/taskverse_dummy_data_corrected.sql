-- TaskVerse Dummy Data SQL (Corrected Version)
-- Run these queries in your MySQL database to populate with test data

-- First, let's insert some dummy users (basic columns only)
INSERT INTO users (id, name, email, password) VALUES
(1, 'John Doe', 'john.doe@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'),
(2, 'Jane Smith', 'jane.smith@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'),
(3, 'Mike Johnson', 'mike.johnson@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'),
(4, 'Sarah Wilson', 'sarah.wilson@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'),
(5, 'David Brown', 'david.brown@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi');

-- Insert dummy projects (adjust columns based on your table structure)
INSERT INTO projects (id, name, description, creator_id, task_count, thread_count, status) VALUES
(1, 'E-Commerce Website Redesign', 'Complete redesign of the company e-commerce platform with modern UI/UX', 1, 12, 3, 'active'),
(2, 'Mobile App Development', 'Cross-platform mobile application for task management', 2, 8, 2, 'active'),
(3, 'Database Migration Project', 'Migrate legacy database to new cloud infrastructure', 3, 6, 1, 'in_progress'),
(4, 'Marketing Campaign 2025', 'Digital marketing strategy and implementation for Q1 2025', 4, 15, 4, 'planning'),
(5, 'Security Audit & Enhancement', 'Comprehensive security review and implementation of best practices', 5, 9, 2, 'active');

-- Insert project members
INSERT INTO project_members (project_id, user_id, role) VALUES
-- E-Commerce Website Redesign team
(1, 1, 'admin'),
(1, 2, 'developer'),
(1, 3, 'designer'),
(1, 4, 'tester'),

-- Mobile App Development team
(2, 2, 'admin'),
(2, 1, 'developer'),
(2, 5, 'developer'),

-- Database Migration Project team
(3, 3, 'admin'),
(3, 5, 'developer'),
(3, 1, 'consultant'),

-- Marketing Campaign 2025 team
(4, 4, 'admin'),
(4, 2, 'content_creator'),
(4, 3, 'designer'),

-- Security Audit & Enhancement team
(5, 5, 'admin'),
(5, 1, 'security_specialist'),
(5, 3, 'developer');

-- Insert dummy tasks (basic columns - without assignee_id)
INSERT INTO tasks (id, title, description, project_id, priority, status, due_date) VALUES
-- E-Commerce Website Redesign tasks
(1, 'Design Homepage Mockup', 'Create initial homepage design mockups with modern layout', 1, 'high', 'in_progress', '2025-01-15'),
(2, 'Setup Development Environment', 'Configure development environment for the new website', 1, 'high', 'completed', '2024-12-10'),
(3, 'Database Schema Design', 'Design new database schema for product catalog', 1, 'medium', 'pending', '2025-01-20'),
(4, 'Payment Gateway Integration', 'Integrate Stripe payment gateway', 1, 'high', 'pending', '2025-02-01'),

-- Mobile App Development tasks
(5, 'User Authentication Module', 'Implement login/logout functionality', 2, 'high', 'in_progress', '2025-01-10'),
(6, 'Task Management UI', 'Design and implement task management interface', 2, 'medium', 'pending', '2025-01-25'),
(7, 'Push Notifications', 'Implement push notification system', 2, 'low', 'pending', '2025-02-15'),

-- Database Migration Project tasks
(8, 'Data Backup Strategy', 'Plan and implement comprehensive data backup', 3, 'high', 'completed', '2024-12-25'),
(9, 'Migration Scripts', 'Write scripts for data migration', 3, 'high', 'in_progress', '2025-01-05'),
(10, 'Performance Testing', 'Test performance of new database setup', 3, 'medium', 'pending', '2025-01-15'),

-- Marketing Campaign 2025 tasks
(11, 'Market Research', 'Conduct comprehensive market analysis', 4, 'high', 'in_progress', '2025-01-08'),
(12, 'Content Calendar', 'Create content calendar for Q1 2025', 4, 'medium', 'pending', '2025-01-12'),
(13, 'Social Media Assets', 'Design social media graphics and videos', 4, 'medium', 'pending', '2025-01-20'),

-- Security Audit & Enhancement tasks
(14, 'Vulnerability Assessment', 'Conduct comprehensive security audit', 5, 'high', 'in_progress', '2025-01-03'),
(15, 'SSL Certificate Update', 'Update and configure SSL certificates', 5, 'high', 'pending', '2024-12-30'),
(16, 'Security Documentation', 'Create security guidelines and documentation', 5, 'low', 'pending', '2025-01-30');

-- Insert dummy threads (basic columns)
INSERT INTO threads (id, title, description, creator_id, project_id, status) VALUES
(1, 'Design Discussion', 'Discussion about the overall design direction for the e-commerce site', 3, 1, 'active'),
(2, 'Technical Requirements', 'Technical specifications and requirements discussion', 1, 1, 'active'),
(3, 'Testing Strategy', 'Planning testing approach and methodologies', 4, 1, 'active'),
(4, 'App Architecture', 'Discussion about mobile app architecture and patterns', 2, 2, 'active'),
(5, 'Performance Optimization', 'Mobile app performance optimization strategies', 5, 2, 'active'),
(6, 'Migration Timeline', 'Database migration schedule and milestones', 3, 3, 'active'),
(7, 'Campaign Strategy', 'Marketing campaign strategy and tactics', 4, 4, 'active'),
(8, 'Target Audience', 'Defining target audience and personas', 2, 4, 'active'),
(9, 'Budget Planning', 'Marketing budget allocation and planning', 4, 4, 'active'),
(10, 'Security Protocols', 'Establishing security protocols and procedures', 5, 5, 'active'),
(11, 'Incident Response', 'Security incident response planning', 1, 5, 'active');

-- Insert thread members (basic columns)
INSERT INTO thread_members (thread_id, user_id, role) VALUES
-- Design Discussion
(1, 3, 'creator'),
(1, 1, 'participant'),
(1, 2, 'participant'),

-- Technical Requirements
(2, 1, 'creator'),
(2, 2, 'participant'),
(2, 3, 'participant'),

-- App Architecture
(4, 2, 'creator'),
(4, 1, 'participant'),
(4, 5, 'participant'),

-- Campaign Strategy
(7, 4, 'creator'),
(7, 2, 'participant'),
(7, 3, 'participant'),

-- Security Protocols
(10, 5, 'creator'),
(10, 1, 'participant'),
(10, 3, 'participant');

-- Insert messages (basic columns)
INSERT INTO messages (id, thread_id, sender_id, content, message_type) VALUES
(1, 1, 3, 'I think we should go with a clean, modern design approach. What do you all think?', 'text'),
(2, 1, 1, 'Absolutely! I agree with the modern approach. We should focus on user experience.', 'text'),
(3, 1, 2, 'Should we consider mobile-first design?', 'text'),
(4, 2, 1, 'Here are the initial technical requirements for the project...', 'text'),
(5, 2, 2, 'We should use React for the frontend and Node.js for the backend.', 'text'),
(6, 4, 2, 'For the mobile app, I suggest using Flutter for cross-platform development.', 'text'),
(7, 4, 1, 'Flutter sounds good. What about state management?', 'text'),
(8, 4, 5, 'I recommend using Provider or Riverpod for state management.', 'text'),
(9, 7, 4, 'Our target audience should be young professionals aged 25-40.', 'text'),
(10, 7, 2, 'We should focus on digital channels - social media, email marketing, etc.', 'text'),
(11, 10, 5, 'Security should be our top priority. We need to implement multi-factor authentication.', 'text'),
(12, 10, 1, 'Agreed. We should also conduct regular security audits.', 'text');

-- Update project task and thread counts
UPDATE projects SET 
    task_count = (SELECT COUNT(*) FROM tasks WHERE project_id = projects.id),
    thread_count = (SELECT COUNT(*) FROM threads WHERE project_id = projects.id)
WHERE id IN (1, 2, 3, 4, 5);

-- Note: 
-- 1. The password hash used above is for 'password123'
-- 2. If you get errors about missing columns, first run the ALTER TABLE statements from check_table_structure.sql
-- 3. You may need to adjust column names based on your actual table structure
