-- First, let's check what tables and columns exist in your database
-- Run this query to see the structure of your users table:
DESCRIBE users;

-- If you need to add the missing columns, run these ALTER TABLE statements first:
ALTER TABLE users ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE users ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;

-- Then run the corrected dummy data inserts below
