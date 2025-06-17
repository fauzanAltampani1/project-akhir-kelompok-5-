<?php
// Database configuration
define('DB_HOST', 'localhost');
define('DB_NAME', 'taskverse_db');
define('DB_USER', 'root');
define('DB_PASS', '');
define('DB_CHARSET', 'utf8mb4');

// API Settings
define('API_RATE_LIMIT', 100); // requests per minute
define('API_VERSION', '1.0.0');

// Error logging
define('LOG_ERRORS', true);
define('ERROR_LOG_FILE', __DIR__ . '/../logs/api_errors.log');

// Create logs directory if it doesn't exist
if (!file_exists(__DIR__ . '/../logs')) {
    mkdir(__DIR__ . '/../logs', 0777, true);
}
?>